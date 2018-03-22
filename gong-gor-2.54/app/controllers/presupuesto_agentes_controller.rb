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
# Controlador encargado de la gestion de la entidad presupuesto. Este controlador es utilizado desde las secciones:
# * Sección agentes: se utiliza para la gestión del presupuesto relacionado con agente.
#

class PresupuestoAgentesController < ApplicationController
  before_filter :verificar_etapa
  #before_filter :filtro_presupuesto_x_actividad, :only => [ :presupuesto_x_actividad, :modificar_crear_presupuesto_x_actividad, :eliminar_presupuesto_x_actividad ]

  def verificar_etapa
    if @agente.etapa.empty?
      msg_error _("Tiene que definir por lo menos una etapa para acceder a la gestión del presupuesto")
      redirect_to :menu => :configuracion_agente, :controller => :datos_agente, :action => :etapas
    end
  end

  # --
  # METODOS DE GESTION DE Presupuesto
  # ++

  # en agentes: se redirecciona por defecto a listado
  def index
    redirect_to :action => :filtrado_ordenado_iniciales
  end

  def filtrado_ordenado_iniciales
    session[:presupuesto_agentes_asc_desc] = "ASC" 
    session[:presupuesto_agentes_cadena_orden] = "partida.codigo"
    session[:presupuesto_agentes_filtro_etapa] = "todas" 
    session[:presupuesto_agentes_filtro_partida] = "todas"
    redirect_to :action => :listado
  end

  def ordenado
    session[:presupuesto_agentes_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    session[:presupuesto_agentes_cadena_orden] = session[:presupuesto_agentes_orden] = params[:orden] ? params[:orden] : "fecha"
    session[:presupuesto_agentes_cadena_orden] = "partida.codigo" if params[:orden] == "partida.codigo_nombre"
    redirect_to :action => "listado"
  end

  def filtrado
    session[:presupuesto_agentes_filtro_etapa] = params[:filtro][:etapa]
    session[:presupuesto_agentes_filtro_partida] = params[:filtro][:partida]
    redirect_to :action => :listado
  end


  def elementos_filtrado
    session[:presupuesto_agentes_filtro_etapa]   ||= "todas"
    session[:presupuesto_agentes_filtro_partida] ||= "todas"
    session[:presupuesto_agentes_cadena_orden]   ||= "partida.codigo"
    session[:presupuesto_agentes_asc_desc]       ||= "ASC"

    filtro_etapa = [["Todas", "todas"]] + @agente.etapa.sort{ |a, b| a.fecha_inicio <=> b.fecha_inicio }.collect{ |e| [e.nombre, e.id.to_s] }
    filtro_partida = [["Todas", "todas"]] + Partida.order(:codigo).all.collect {|p| [p.codigo_nombre, p.id.to_s]}

    @opciones_filtrado = [{:rotulo =>  _("Seleccione etapa"), :nombre => "etapa", :opciones => filtro_etapa},
                      	  {:rotulo =>  _("Seleccione partida"), :nombre => "partida", :opciones => filtro_partida} ]

    @etapa = Etapa.find( session[:presupuesto_agentes_filtro_etapa]) unless session[:presupuesto_agentes_filtro_etapa] == "todas"
    @accion_filtrado = {:action => :filtrado, :listado => :listado}

    @estado_filtrado = [(session[:presupuesto_agentes_filtro_etapa] == "todas" ? _("Cualquier etapa") : (@etapa.nombre + " (" + @etapa.fecha_inicio.to_s + "/" + @etapa.fecha_fin.to_s + ")")), 
            (session[:presupuesto_agentes_filtro_partida] == "todas" ? _("Cualquier partida") : Partida.find(session[:presupuesto_agentes_filtro_partida]).nombre) ] 

  end


  # en agentes: listado de presupuestos para el agente de la sessión
  def listado
    elementos_filtrado
    condiciones = { "agente_id" => @agente.id, "proyecto_id" => nil }
    condiciones["presupuesto.etapa_id"] = session[:presupuesto_agentes_filtro_etapa] unless session[:presupuesto_agentes_filtro_etapa] == "todas"
    condiciones["presupuesto.partida_id"] = session[:presupuesto_agentes_filtro_partida] unless session[:presupuesto_agentes_filtro_partida] == "todas"
    @presupuestos = @paginado = Presupuesto.includes([:partida, :presupuesto_x_agente, :libro, :subpartida]).
                                            where(condiciones).
                                            order(session[:presupuesto_agentes_cadena_orden]).
                                            paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                                     per_page: (params[:format_xls_count] || session[:por_pagina]))

    @formato_xls = @presupuestos.total_entries
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "presupuesto_agentes"
        @objetos = @presupuestos
        nom_fich = "presupuesto_" + @agente.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end


  def datos_formulario
   @etapas = @agente.etapa.collect {|a| [a.nombre, a.id]}
    @partidas = Partida.where(ocultar_agente: false).order(:codigo).collect {|a| [a.codigo_nombre, a.id]}
    @monedas = @agente.moneda.collect {|a| [a.abreviatura, a.id]}
  end


  # en agentes: prepara el formulario de edición o creación de presupuesto
  def editar_nuevo
    datos_formulario
    @presupuesto = @agente.presupuesto.find_by_id(params[:id]) || Presupuesto.new(agente_id: @agente.id)
    render (:update) {|page| page.formulario :partial => "formulario", :update => params[:update]}
  end

  # en agentes: modifica o crea un presupuesto
  def modificar_crear
    # Asignamos los valores al presupueseto sin guadarlos para poder comprobar_fechas_etapa
    @presupuesto = @agente.presupuesto.find_by_id(params[:id]) || Presupuesto.new(agente_id: @agente.id)
    etapa_anterior_id =  @presupuesto.etapa_id 

    # Se asegura de que el importe sea el calculo de numero_unidades y coste_unitario
    if params[:presupuesto] && params[:presupuesto][:numero_unidades] && params[:presupuesto][:coste_unitario_convertido]
      coste_unitario = moneda_a_float params[:presupuesto][:coste_unitario_convertido]
      params[:presupuesto][:importe] = params[:presupuesto][:numero_unidades].to_f * coste_unitario
    end

    # Guarda cambios
    @presupuesto.attributes = params[:presupuesto]
    @presupuesto.save
    if @presupuesto.errors.empty?
      @presupuesto.dividir_por_mes(@presupuesto.etapa.fecha_inicio, @presupuesto.etapa.fecha_fin) if (params[:id].nil? or etapa_anterior_id != @presupuesto.etapa_id)
    end
    if @presupuesto.errors.empty?
      # Si no ha habido fallos grabando
      @presupuesto.reload if params[:id] #recargamos el objeto por si se ha producido un error que visualmetne no aparezca modificado
      render (:update){|page|  page.modificar :update => params[:update], :partial => "presupuesto", :locals => { :presupuesto => @presupuesto }, :mensaje => { :errors => @presupuesto.errors } } if params[:id]
      # Si es un nuevo presupuesto
      render :update do |page|
         page.show "mensaje_nuevo"
         page.nueva_fila :update => "nuevo", :partial => "presupuesto", :nueva_fila => @presupuesto.id.to_s, :locals => { :presupuesto => @presupuesto }, :mensaje => { :errors => @presupuesto.errors }
      end unless params[:id]
    else
    # Si hay fallo grabando el presupuesto (y es un nuevo presupuesto) mostramos el formulario con el mensaje de error 
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @presupuesto.errors} }
    end


  end

  # en agentes: elimina un presupuesto
  def eliminar
    @presupuesto = @agente.presupuesto.find_by_id params[:id]
    @presupuesto.destroy if @presupuesto
    render(:update) do |page| 
      page.eliminar :update => params[:update], :mensaje =>  {:errors => @presupuesto.errors, :eliminar => true} if @presupuesto
    end
  end


  def auto_complete_for_presupuesto_subpartida_nombre
    if params[:presupuesto] && params[:presupuesto][:partida_id]
      condiciones = ['nombre like ? and agente_id = ? and partida_id = ?', "%#{params[:search]}%", params[:agente_id].to_s, params[:presupuesto][:partida_id].to_s ]
    else
      condiciones = ['nombre like ? and agente_id = ?', "%#{params[:search]}%", params[:agente_id].to_s]
    end
    @subpartidas = Subpartida.find(:all, :conditions => condiciones)
    render :inline => "<%= auto_complete_result_3 @subpartidas, :nombre %>"
  end
end

