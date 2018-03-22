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
# Controlador encargado de la gestión de la matriz. Este controlador es utilizado desde las secciones:
# * Sección proyectos: se utiliza para los objetivos especificos, resultados, actividades...

class IndicadorController < ApplicationController

  before_filter :verificar_estado_formulacion_ajax, :only => [	:modificar_crear_variable, :eliminar_variable,
                                                                :modificar_crear_indicador_general, :eliminar_indicador_general ]
  before_filter :verificar_estado_ejecucion_ajax, :only => [	:modificar_crear_valor_indicador, :eliminar_valor_indicador,
								:modificar_crear_valor_variable, :eliminar_valor_variable,
                                                                :modificar_crear_valor_indicador_general, :eliminar_valor_indicador_general ]

  def verificar_estado_formulacion_ajax
    unless @permitir_formulacion
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("Es necesario definirle un estado al proyecto.")    if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se pueden modificar los indicadores.") unless @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end

  def verificar_estado_ejecucion_ajax
    unless @permitir_ejecucion
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("Es necesario definirle un estado al proyecto.")    if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se puede hacer seguimiento de los indicadores.") unless @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end


  #--
  # LISTADO DE INDICADORES
  #--

  def index
    redirect_to :action => "listado"
  end

        # en proyectos: listado de variables de indicadores
  def listado
    # Segun de donde se venga, se recoge el indicador elegido (puede venir desde el filtrado o desde el listado de indicadores)
    indicador_id = params[:indicador_id] if params[:indicador_id] && !params[:indicador_id].nil?
    indicador_id = params[:filtro][:indicador] if params[:filtro] && params[:filtro][:indicador] != "todos"

    # Obtiene los listados de indicadores segun las condiciones de donde estemos...
    if indicador_id
      # Metemos las condiciones aqui para evitar que manden por parametros un indicador que no sea del proyecto
      condiciones = ["objetivo_especifico.proyecto_id=? OR resultado.proyecto_id=?",@proyecto.id,@proyecto.id]
      @indicadores = Indicador.includes(:objetivo_especifico, :resultado).where(condiciones).where(id: indicador_id)
    else
      @indicadores = []
      # Hacemos las busquedas anidadas para ir incluyendo poco a poco
      @proyecto.objetivo_especifico.each do |oe|
        # Primero los indicadores propios del OE y luego los de cada resultado del oe
        @indicadores += oe.indicador.order(:codigo)
        # Y luego los indicadores de cada Resultado del OE
        oe.resultado.order(:codigo).each { |res| @indicadores += res.indicador.order(:codigo) }
      end
    end

    # Obtiene las relaciones con los indicadores generales 
    @igxps = @proyecto.indicador_general_x_proyecto.
                       joins(:indicador_general).
                       order("indicador_general.nombre")
  end


  #--
  # MEDICIONES DEL INDICADOR
  #++

  def valores_indicador
    @valores = ValorIntermedioXIndicador.all(:order => "fecha DESC", :conditions => {:indicador_id => params[:indicador_id]})
    render(:update) { |page| page.replace_html params[:update], :partial => "valores_indicador", :locals => {:update_listado => params[:update]} }
  end

  def editar_nuevo_valor_indicador
    @indicador = Indicador.find_by_id(params[:indicador_id])
    @valor = ValorIntermedioXIndicador.find_by_id(params[:id]) || ValorIntermedioXIndicador.new()
    render(:update) { |page| page.formulario :partial => "formulario_valor_indicador", :update => params[:update] }
  end

  def modificar_crear_valor_indicador
    @indicador = Indicador.find_by_id(params[:indicador_id])
    @valor = @indicador.valor_intermedio_x_indicador.find_by_id(params[:id]) || ValorIntermedioXIndicador.new(:indicador_id => params[:indicador_id])
    # Cualquier modificacion o creacion es del usuario que modifica
    params[:valor][:usuario_id] = @usuario_identificado.id
    # Actualizamos
    @valor.update_attributes params[:valor]
    # Si no hay errores al guardar la medicion...
    if @valor.errors.empty?
      @valores = ValorIntermedioXIndicador.all(:order => "fecha DESC", :conditions => {:indicador_id => params[:indicador_id]})
      render(:update) do |page|
        # Primero actualizamos la linea del indicador
        page.modificar :update => params[:update_objeto], :partial => "indicador", :mensaje => { :errors => @valor.errors }, :locals => {:fila => params[:update_objeto]}
        # ... y luego actualizamos el listado de valores
        page.replace_html params[:update_listado], :partial => "valores_indicador", :locals => {:update_listado => params[:update_listado]}
      end
    # ... si hay errores al guardar la medicion, volvemos al formulario
    else
      render(:update){ |page|  page.recargar_formulario :partial => "formulario_valor_indicador", :mensaje => { :errors => @valor.errors } }
    end
  end

  def eliminar_valor_indicador
    @indicador = Indicador.find_by_id(params[:indicador_id])
    @objeto = ValorIntermedioXIndicador.find_by_id(params[:id])
    @objeto.destroy
    @valores = ValorIntermedioXIndicador.all(:order => "fecha DESC", :conditions => {:indicador_id => params[:indicador_id]})
    render(:update) do |page|
      # Primero actualizamos la linea del indicador
      page.actualizar :update => params[:update_objeto], :partial => "indicador", :mensaje => { :errors => @objeto.errors, :eliminar => true }, :locals => {:fila => params[:update_objeto]}
      # ... y luego actualizamos el listado de valore
      page.replace_html params[:update], :partial => "valores_indicador", :locals => {:update_listado => params[:update]}
    end 
  end

  #--
  # VARIABLES DE INDICADORES
  #++

	# en proyectos: prepara el formulario de edicion o creacion de una variable de indicador
  def editar_variable
    @variable = params[:id] ? VariableIndicador.find(params[:id]) : VariableIndicador.new(:indicador_id => params[:indicador_id])
    if @variable.id
      @valor_base = @variable.valor_base
      @valor_objetivo = @variable.valor_objetivo
    end 
    render(:update) { |page| page.formulario :partial => "formulario_variable", :update => params[:update] }
  end

	# en proyectos modifica o crea una variable de indicador
  def modificar_crear_variable
    @variable = params[:id] ? VariableIndicador.find(params[:id]) : VariableIndicador.new(:indicador_id => params[:indicador_id])
    @variable.update_attributes params[:variable]
    @indicador = @variable.indicador
    if @variable.errors.empty?
      valor_base = @variable.valor_base || ValorVariableIndicador.new()
      valor_base.update_attributes params[:valor_base]
      @variable.valor_base = valor_base

      valor_objetivo = @variable.valor_objetivo || ValorVariableIndicador.new()
      valor_objetivo.update_attributes params[:valor_objetivo]
      @variable.valor_objetivo = valor_objetivo

      @variable.save
    end

    render(:update){ |page| page.modificar( :update_listado => params[:update_listado], :partial => "variables", :mensaje => { :errors => @variable.errors }) } if @variable.id
    render(:update){ |page| page.recargar_formulario :partial => "formulario_variable", :mensaje => { :errors => @variable.errors } } unless @variable.id
  end

	# en proyectos: elimina la variable de un indicador
  def eliminar_variable
    @variable = VariableIndicador.find(params[:id])
    @indicador = @variable.indicador
    @variable.destroy
    render(:update) { |page|  page.eliminar(:update => params[:update], :mensaje => { :errors => @variable.errors, :eliminar => true }) }
  end


  #--
  # VALORES DE VARIABLES DE INDICADOR
  #++

	# en proyectos, presenta un sublistado de valores intermedios de variables
  def valores_variable
    variable = VariableIndicador.find(params[:variable_indicador_id])
    @valores = variable.valor_medido.find(:all,:order => "fecha")
    render(:update) { |page| page.replace_html params[:update], :partial => "valores_variable", :locals => {:update_listado => params[:update]} }
  end

  def editar_nuevo_valor_variable
    @valor_variable = params[:id] ? ValorVariableIndicador.find(params[:id]) : ValorVariableIndicador.new
    render(:update) { |page| page.formulario :partial => "formulario_valor_variable", :update => params[:update] }
  end

  def modificar_crear_valor_variable
    @valor_variable = params[:id] ? ValorVariableIndicador.find(params[:id]) : ValorVariableIndicador.new(:variable_indicador_id => params[:variable_indicador_id])
    @valor_variable.update_attributes params[:valor_variable]
    @valores = VariableIndicador.find(params[:variable_indicador_id]).valor_medido.find(:all, :order => "fecha")
    if @valor_variable.id
      render(:update){ |page|  page.modificar(:update_listado => params[:update_listado], :partial => "valores_variable", :mensaje => { :errors => @valor_variable.errors}, :tipo_update => "sublistado") }
    else
      render(:update){ |page|  page.recargar_formulario :partial => "formulario_valor_variable", :mensaje => { :errors => @valor_variable.errors } }
    end
  end

  def eliminar_valor_variable
    @objeto = ValorVariableIndicador.find(params[:id])
    @objeto.destroy
    @valores = VariableIndicador.find(params[:variable_indicador_id]).valor_medido.find(:all, :order => "fecha")
    render(:update) { |page| page.replace_html params[:update], :partial => "valores_variable", :locals => {:update_listado => params[:update]} }
  end

  #--
  # INDICADORES GENERALES
  # ++

  # Presenta el formulario de edicion de un indicador general para el proyecto
  def editar_nuevo_indicador_general
    # Si se ha enviado indicador general, se obtiene o crea el elemento
    @igxp = @proyecto.indicador_general_x_proyecto.find_by_indicador_general_id(params[:id]) || @proyecto.indicador_general_x_proyecto.new
    # Escoge el listado de indicadores generales que mostraremos
    if (indicador = IndicadorGeneral.find_by_id params[:id])
      indicadores = [ indicador ]
    else
      indicadores = IndicadorGeneral.order(:nombre) - @proyecto.indicador_general
    end
    @indicadores = indicadores.collect{|i| [ i.nombre, i.id ] }
    # Si tenemos un indicador general para el proyecto, obtenemos su valor base y objetivo
    if @igxp.id
      @valor_base = @igxp.valor_base
      @valor_objetivo = @igxp.valor_objetivo
    end
    # Renderiza el formulario
    render(:update) { |page| page.formulario :partial => "formulario_indicador_general", :update => params[:update] }
  end

  # Guarda o crea los valores de asociacion del indicador general en el proyecto
  def modificar_crear_indicador_general
    guardado = false
    # Si se ha enviado indicador general, se obtiene o crea el elemento
    @igxp = @proyecto.indicador_general_x_proyecto.find_by_indicador_general_id(params[:id]) || @proyecto.indicador_general_x_proyecto.new
    # Si hemos encontrado un igxp eliminamos el enviado para no pisar
    params[:igxp].delete(:indicador_general_id) if @igxp.id
    @igxp.update_attributes params[:igxp]
    # Si hemos guardado los datos de la vinculacion...
    errors = @igxp.errors
    if @igxp.errors.empty?
      guardado = true
      # ... actualizamos valor base y valor objetivo
      valor_base = @igxp.valor_base || ValorXIndicadorGeneral.new
      valor_base.update_attributes params[:valor_base]
      if valor_base.errors.empty?
        @igxp.update_attributes valor_base_id: valor_base.id
      else
        errors = valor_base.errors
      end
      valor_objetivo = @igxp.valor_objetivo || ValorXIndicadorGeneral.new
      valor_objetivo.update_attributes params[:valor_objetivo]
      if valor_objetivo.errors.empty?
        @igxp.update_attributes valor_objetivo_id: valor_objetivo.id
      else
        errors = valor_objetivo.errors
      end
      # Obtiene las relaciones con los indicadores generales 
      @igxps = @proyecto.indicador_general_x_proyecto.
                         joins(:indicador_general).
                         order("indicador_general.nombre")
    # Si hemos tenido problemas al guardar...
    else
      # ... recargamos los datos del formulario
      indicadores = @igx.indicador_general ? [ @igx.indicador_general ] : IndicadorGeneral.order(:nombre) - @proyecto.indicador_general
      @indicadores = indicadores.collect{|i| [ i.nombre, i.id ] }
      if @igxp.id
        @valor_base = @igxp.valor_base
        @valor_objetivo = @igxp.valor_objetivo
      end
    end

    render(:update){ |page| page.modificar( update_listado: params[:update_listado], partial: "indicadores_generales", mensaje: { errors: errors }) } if guardado 
    render(:update){ |page| page.recargar_formulario partial: "formulario_indicador_general", mensaje: { errors: errors } } unless guardado 
  end

  # Elimina la vinculacion del indicador en el proyecto
  def eliminar_indicador_general
    @igxp = @proyecto.indicador_general_x_proyecto.find_by_indicador_general_id params[:id]
    # Se carga la relacion si no esta definido por el programa marco
    @igxp.destroy if @igxp &&  IndicadorGeneralXProgramaMarco.where(programa_marco_id: @proyecto.programa_marco_id, indicador_general_id: params[:id]).empty?
    render(:update) { |page|  page.eliminar(:update => params[:update], :mensaje => { :errors => @igxp.errors, :eliminar => true }) }
  end

  #--
  # VALORES DE INDICADORES GENERALES
  # ++

  # Muestra los valores medidos para un indicador general
  def valores_indicador_general
    igxp = @proyecto.indicador_general_x_proyecto.find_by_indicador_general_id params[:indicador_general_id]
    @valores = igxp.valor_medido.order(:fecha)
    render(:update) { |page| page.replace_html params[:update], :partial => "valores_indicador_general", :locals => {:update_listado => params[:update]} }
  end

  # Presenta el formulario de edicion o de creacion de una medicion de indicador general
  def editar_nuevo_valor_indicador_general
    igxp = @proyecto.indicador_general_x_proyecto.find_by_indicador_general_id params[:indicador_general_id]
    @valor = igxp.valor_medido.find_by_id(params[:id]) || igxp.valor_medido.new
    render(:update) { |page| page.formulario :partial => "formulario_valor_indicador_general", :update => params[:update] }
  end

  # Actualiza o crea el valor medido de un indicador general
  def modificar_crear_valor_indicador_general
    igxp = @proyecto.indicador_general_x_proyecto.find_by_indicador_general_id params[:indicador_general_id]
    @valor = igxp.valor_medido.find_by_id(params[:id]) || igxp.valor_medido.new
    @valor.update_attributes params[:valor]

    if @valor.id
      @valores = igxp.valor_medido.order(:fecha)
      render(:update){ |page|  page.modificar(update_listado: params[:update_listado], partial: "valores_indicador_general",
                                              mensaje: { errors: @valor.errors}, tipo_update: "sublistado") }
    else
      render(:update){ |page|  page.recargar_formulario partial: "formulario_valor_indicador_general", mensaje: { errors: @valor.errors } }
    end
  end

  # Elimina una medida de valor de indicador general
  def eliminar_valor_indicacor_general
    igxp = @proyecto.indicador_general_x_proyecto.find_by_indicador_general_id params[:indicador_general_id]
    @objeto = igxp.valor_medido.find_by_id params[:id]
    @objeto.destroy
    @valores = igxp.valor_medido.order(:fecha)
    render(:update) { |page| page.replace_html params[:update], :partial => "valores_indicador_general", :locals => {:update_listado => params[:update]} }
  end
end
