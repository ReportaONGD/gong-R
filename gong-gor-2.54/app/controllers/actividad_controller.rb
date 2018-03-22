# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2013 Free Software's Seed, CENATIC y IEPALA
#
# Licencia con arreglo a la EUPL, Versión 1.1 o –en cuanto sean aprobadas por la Comisión Europea– 
# versiones posteriores de la EUPL (la «Licencia»);
# Solo podrá usarse esta obra si se respeta la Licencia.
# Puede obtenerse una copia de la Licencia en:
#
# http://www.osor.eu/eupl/european-union-public-licence-eupl-v.1.1
#
# Salvo cuando lo exija la legislación aplicable o se acuerde por escrito, 
# el programa distribuido con arreglo a la Licencia se distribuye «TAL CUAL»,
# SIN GARANTÍAS NI CONDICIONES DE NINGÚN TIPO, ni expresas ni implícitas.
# Véase la Licencia en el idioma concreto que rige los permisos y limitaciones que establece la Licencia.
#################################################################################
#
#++
# Controlador encargado de la gestión del seguimiento de indicadores de proyectos

class ActividadController < ApplicationController

  before_filter :verificar_etapa
  before_filter :elementos_filtrado, :only => [:listado]
  before_filter :verificar_estado_ejecucion_ajax, :only => [	:crear_modificar_valor_actividad, :eliminar_valor_actividad,
								:crear_modificar_valor_subactividad, :eliminar_valor_subactividad ]

  def verificar_estado_ejecucion_ajax
    unless @permitir_ejecucion
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("Es necesario definirle un estado al proyecto.")    if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se puede modificar el estado de las actividades.") unless @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end

  def verificar_etapa
    if @proyecto.etapa.empty?
      msg_error _("Tiene que definir por lo menos una etapa para acceder al seguimiento de actividades.")
      redirect_to :menu => :configuracion, :controller => :datos_proyecto, :action => :etapas
    end
  end

  def elementos_filtrado
    # Hacemos esto tan raro del filtro para evitar que se propaguen etapas erroneas cuando navegamos entre pestañas de proyectos
    session[:actividad_filtro_etapa] = @proyecto.etapa.first.id unless session[:actividad_filtro_etapa] && @proyecto.etapa.find_by_id(session[:actividad_filtro_etapa])

    filtro_etapa = @proyecto.etapa.sort{ |a, b| a.fecha_inicio <=> b.fecha_inicio }.collect{ |e| [e.nombre, e.id.to_s] } unless @proyecto.etapa.empty?
    @opciones_filtrado = [ {:rotulo =>  _("Seleccione etapa"), :nombre => "etapa", :opciones => filtro_etapa} ]
    @etapa = Etapa.find_by_id( session[:actividad_filtro_etapa] )
    @accion_filtrado = {:action => :filtrado, :listado => :listado}

    @estado_filtrado = [( @etapa.nil? ? _("Etapa no válida") : (@etapa.nombre + " (" + @etapa.fecha_inicio.to_s + "/" + @etapa.fecha_fin.to_s + ")")) ]
  end

  #--
  # LISTADO DE ACTIVIDADES
  #--

  def index
    redirect_to :action => "listado"
  end

  def filtrado
    session[:actividad_filtro_etapa] = params[:filtro][:etapa]
    redirect_to :action => params[:listado]
  end

        # en proyectos: listado de actividades
  def listado
    # Filtra las actividades por la etapa seleccionada
    #condiciones = {"actividad_x_etapa.etapa_id" => session[:actividad_filtro_etapa]}
    #@actividades = @proyecto.actividad.all(:order => "codigo", :include=>["actividad_x_etapa"],:conditions => condiciones)
    @actividades = ActividadXEtapa.all(	:include => ["actividad"], :order => "actividad.codigo",
					:conditions => {"actividad.proyecto_id" => @proyecto.id, "etapa_id" => @etapa} )

    @actividades_sin_etapa = @proyecto.actividad.includes(:actividad_x_etapa).where("actividad_x_etapa.id IS NULL").collect{|a| a.codigo_nombre}
  end


  #--
  # MEDICIONES DE ACTIVIDADES
  #++

  def valores_actividad
    @valores = ValorIntermedioXActividad.all(:order => "fecha DESC", :conditions => {:actividad_x_etapa_id => params[:actividad_x_etapa_id]})
    render(:update) { |page| page.replace_html params[:update], :partial => "valores_actividad", :locals => {:update_listado => params[:update]} }
  end

  def nuevo_editar_valor_actividad
    #@actividad_x_etapa = ActividadXEtapa.find_by_id(params[:actividad_x_etapa_id])
    @valor = ValorIntermedioXActividad.find_by_id(params[:id]) || ValorIntermedioXActividad.new()
    render(:update) { |page| page.formulario :partial => "formulario_valor_actividad", :update => params[:update] }
  end

  def crear_modificar_valor_actividad
    @actividad_x_etapa = ActividadXEtapa.find_by_id(params[:actividad_x_etapa_id])
    @valor = @actividad_x_etapa.valor_intermedio_x_actividad.find_by_id(params[:id]) || ValorIntermedioXActividad.new(:actividad_x_etapa_id => params[:actividad_x_etapa_id])
    # Cualquier modificacion o creacion es del usuario que modifica
    params[:valor][:usuario_id] = @usuario_identificado.id
    # Actualizamos
    @valor.update_attributes params[:valor]
    # Si no hay errores al guardar la medicion...
    if @valor.errors.empty?
      @valores = ValorIntermedioXActividad.all(:order => "fecha DESC", :conditions => {:actividad_x_etapa_id => params[:actividad_x_etapa_id]})
      render(:update) do |page|
        # Primero actualizamos la linea de la actividad
        page.modificar :update => params[:update_objeto], :partial => "actividad", :mensaje => { :errors => @valor.errors }, :locals => {:fila => params[:update_objeto]}
        # ... y luego actualizamos el listado de valores
        page.replace_html params[:update_listado], :partial => "valores_actividad", :locals => {:update_listado => params[:update_listado]}
      end
    # ... si hay errores al guardar la medicion, volvemos al formulario
    else
      render(:update){ |page|  page.recargar_formulario :partial => "formulario_valor_actividad", :mensaje => { :errors => @valor.errors } }
    end
  end

  def eliminar_valor_actividad
    @actividad_x_etapa = ActividadXEtapa.find_by_id(params[:actividad_x_etapa_id])
    @objeto = ValorIntermedioXActividad.find_by_id(params[:id])
    @objeto.destroy
    @valores = ValorIntermedioXActividad.all(:order => "fecha DESC", :conditions => {:actividad_x_etapa_id => params[:actividad_x_etapa_id]})
    render(:update) do |page|
      # Primero actualizamos la linea de la actividad
      page.actualizar :update => params[:update_objeto], :partial => "actividad", :mensaje => { :errors => @objeto.errors, :eliminar => true }, :locals => {:fila => params[:update_objeto]}
      # ... y luego actualizamos el listado de valore
      page.replace_html params[:update], :partial => "valores_actividad", :locals => {:update_listado => params[:update]}
    end 
  end


  #--
  # MEDICIONES DE SUBACTIVIDADES 
  #++

        # en proyectos, presenta un sublistado de valores intermedios de variables
  def valores_subactividad
    @valores = ValorIntermedioXSubactividad.all(:order => "fecha DESC", :conditions => {:subactividad_id => params[:subactividad_id]})
    render(:update) { |page| page.replace_html params[:update], :partial => "valores_subactividad", :locals => {:update_listado => params[:update]} }
  end

  def nuevo_editar_valor_subactividad
    @valor = ValorIntermedioXSubactividad.find_by_id(params[:id]) || ValorIntermedioXSubactividad.new
    render(:update) { |page| page.formulario :partial => "formulario_valor_subactividad", :update => params[:update] }
  end

  def crear_modificar_valor_subactividad
    @subactividad = Subactividad.find_by_id(params[:subactividad_id])
    @valor = @subactividad.valor_intermedio_x_subactividad.find_by_id(params[:id]) || ValorIntermedioXSubactividad.new(:subactividad_id => params[:subactividad_id])
    # Cualquier modificacion o creacion es del usuario que modifica
    params[:valor][:usuario_id] = @usuario_identificado.id
    # Actualizamos
    @valor.update_attributes params[:valor]
    # Si no hay errores al guardar la medicion...
    if @valor.errors.empty?
      @valores = ValorIntermedioXSubactividad.all(:order => "fecha DESC", :conditions => {:subactividad_id => params[:subactividad_id]})
      render(:update) do |page|
        # Primero actualizamos la linea de la actividad
        page.modificar :update => params[:update_objeto], :partial => "subactividad", :mensaje => { :errors => @valor.errors }, :locals => {:fila => params[:update_objeto]}
        # ... y luego actualizamos el listado de valores
        page.replace_html params[:update_listado], :partial => "valores_subactividad", :locals => {:update_listado => params[:update_listado]}
      end
    # ... si hay errores al guardar la medicion, volvemos al formulario
    else
      render(:update){ |page|  page.recargar_formulario :partial => "formulario_valor_subactividad", :mensaje => { :errors => @valor.errors } }
    end
  end

  def eliminar_valor_subactividad
    @subactividad = Subactividad.find_by_id(params[:subactividad_id])
    @objeto = ValorIntermedioXSubactividad.find_by_id(params[:id])
    @objeto.destroy
    @valores = ValorIntermedioXSubactividad.all(:order => "fecha DESC", :conditions => {:subactividad_id => params[:subactividad_id]})
    render(:update) do |page|
      # Primero actualizamos la linea de la subactividad
      page.actualizar :update => params[:update_objeto], :partial => "subactividad", :mensaje => { :errors => @objeto.errors, :eliminar => true }, :locals => {:fila => params[:update_objeto]}
      # ... y luego actualizamos el listado de valore
      page.replace_html params[:update], :partial => "valores_subactividad", :locals => {:update_listado => params[:update]}
    end
  end

  
end
