# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2017 Free Software's Seed, CENATIC y IEPALA
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
# Controlador encargado de la gestion de programas marco. Este controlador es utilizado desde las secciones:
# * Sección administracion: se utiliza para crear y asociar proyectos marco
# * Sección proyectos: se utiliza para seleccionar el proyecto y cargar lo en la sessión

class ProgramaMarcoController < ApplicationController

  def index
    redirect_to :action => "listado" if params[:seccion] == "administracion"
    redirect_to :action => "listado_usuario" unless params[:seccion] == "administracion"
  end

  def filtrado_condiciones
    # Valores iniciales de orden y filtros
    session[:programa_marco_asc_desc] ||= "ASC"
    session[:programa_marco_orden] ||= "programa_marco.nombre"
    session[:programa_marco_filtro_nombre] ||= ""
    session[:programa_marco_filtro_estado] ||= "todos"
    session[:programa_marco_filtro_pais] ||= []

    @condiciones = []
    @includes = []
    # Averigua las condiciones...
    @condiciones.push({activo: true}) if session[:programa_marco_filtro_estado] == "activos" 
    @condiciones.push({activo: false}) if session[:programa_marco_filtro_estado] == "cerrados"
    @condiciones.push(["programa_marco.nombre LIKE ?", session[:programa_marco_filtro_nombre]]) unless session[:programa_marco_filtro_nombre].blank?
    unless session[:programa_marco_filtro_pais].blank?
      @condiciones.push({"proyecto_x_pais.pais_id" => session[:programa_marco_filtro_pais]})
      @includes.push({proyecto: :proyecto_x_pais})
    end

    paises = Pais.order("nombre").collect {|p| [p.nombre, p.id.to_s]}
    estados =  [[_("Todos"), "todos"]] + [[_("Programas activos"),"activos"], [_("Programas cerrados"),"cerrados"]]
    @opciones_filtrado = [  {rotulo: _("Seleccione Nombre"), nombre: "nombre", tipo: "texto"},
                            {rotulo: _("Seleccione Estado"), nombre: "estado", opciones: estados},
                            {rotulo: _("Seleccione Países"), nombre: "pais", opciones: paises, tipo: "multiple"} ]
    @accion_filtrado = {action: :filtrado}
  end

  # en administracion: lista
  def listado
    filtrado_condiciones
    # Usamos esta forma tan exotica de filtrar para poder usar un array de filtros
    @programas_marco = @paginado = @condiciones.inject(ProgramaMarco.includes(@includes)){|result,condition| result.where(condition)}.
                                                order(session[:programa_marco_orden] + " " + session[:programa_marco_asc_desc] ).
                                                paginate(page: params[:page], per_page: (session[:por_pagina] or 20) )

    @formato_xls = @programas_marco.total_entries

    respond_to do |format|
      format.html
      format.xls do
        @tipo = "programa_marco"
        @objetos = @programas_marco
        nom_fich = "programas_marco_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

  # en administracion y proyectos: establece los parametros de ordenación
  def ordenado
    session[:programa_marco_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"   
    session[:programa_marco_orden] = params[:orden] ? params[:orden] : "nombre"
    if params[:seccion].nil? || params[:seccion] == "programas_marco"
      redirect_to :action => "listado_usuario"
    else
      redirect_to :action => "listado"
    end
  end


  # Condiciones de filtrado del listado de proyectos
  def filtrado
    if params[:filtro]
      session[:programa_marco_filtro_estado] = params[:filtro][:estado]
      session[:programa_marco_filtro_pais] = params[:filtro][:pais].reject!(&:blank?) if params[:filtro][:pais].class.name == "Array"
      session[:programa_marco_filtro_nombre] = params[:filtro][:nombre]
      session[:proyecto_filtro_financiador] = params[:filtro][:financiador]
      session[:proyecto_filtro_ano] = params[:filtro][:ano]
      session[:proyecto_filtro_convocatoria] = params[:filtro][:convocatoria]
      session[:proyecto_filtro_tipo_convocatoria] = params[:filtro][:tipo_convocatoria]
      session[:proyecto_filtro_sector_intervencion] = params[:filtro][:sector_intervencion]
      session[:proyecto_filtro_area_actuacion] = params[:filtro][:area_actuacion]
      session[:proyecto_filtro_sector_poblacion] = params[:filtro][:sector_poblacion]
      session[:proyecto_filtro_cuenta_contable] = params[:filtro][:cuenta_contable]
    end
    if params[:seccion].nil? || params[:seccion] == "programas_marco"
      redirect_to :action => "listado_usuario"
    else
      redirect_to :action => "listado"
    end
  end
 
  # en administracion: prepara el formulario de edición o creación
  def editar_nuevo
    @programa_marco = ProgramaMarco.find_by_id(params[:id]) || ProgramaMarco.new
    @monedas = Moneda.order(:abreviatura).collect{|m| [m.abreviatura + " - " + m.nombre, m.id]}
    render partial: "formulario"
  end

  # en administracion: modifica o crea
  def modificar_crear
    @programa_marco = ProgramaMarco.find_by_id(params[:id]) || ProgramaMarco.new
    @programa_marco.update_attributes params[:programa_marco]
    msg @programa_marco
    redirect_to :action => "listado"
  end

  # en administracion: elimina
  def eliminar
    @programa_marco = ProgramaMarco.find_by_id(params[:id])
    @programa_marco.destroy if @programa_marco
    msg_eliminar @programa_marco
    redirect_to :action => 'listado'
  end
  
  # en proyectos: lista los proyectos asociados al usuario declarado en la sessión
  def listado_usuario
    filtrado_condiciones
    # Usamos esta forma tan exotica de filtrar para poder usar un array de filtros
    @programas_marco = @paginado = @condiciones.inject(ProgramaMarco.includes(@includes)){|result,condition| result.where(condition)}.
                                                order(session[:programa_marco_orden] + " " + session[:programa_marco_asc_desc] ).
                                                paginate(page: params[:page], per_page: (session[:por_pagina] or 20) )
  end

  ####
  # Proyectos asociados a los proyectos marco
  ###

  # en administracion lista los proyectos asociados
  def listado_asociados
    marco = ProgramaMarco.find_by_id params[:programa_marco_id]
    @proyectos = marco ? marco.proyecto : []
    render :update do |page|
      page.replace_html params[:update], partial: "listado_proyectos", locals: {update: params[:update]}
    end
  end

  # Presenta el formulario de asociacion de un nuevo proyecto
  def editar_nuevo_asociado
    # Presenta un formulario de asociacion con todos los proyectos no asociados previamente 
    if GorConfig::getValue("ALLOW_ASSIGN_CLOSED_PROJECTS_ON_FRAMEWORK_PROGRAMS") == "TRUE"
      proyectos = Proyecto.where("programa_marco_id IS NULL")
    else
      proyectos = Proyecto.where("programa_marco_id IS NULL").
                           joins(:definicion_estado).
                           where("definicion_estado.cerrado" => false)
    end
    @proyectos = proyectos.order(:nombre).collect{|p| [p.nombre, p.id]}
    render(:update) {|page| page.formulario partial: "formulario_asociado", update: params[:update] }
  end

  # Asocia un proyecto al programa marco asociado
  def modificar_crear_asociado
    if marco = ProgramaMarco.find_by_id(params[:programa_marco_id])
      proyecto = Proyecto.where("programa_marco_id IS NULL").find_by_id params[:proyecto][:id] if params[:proyecto]
      # Asocia el proyecto
      proyecto.update_attributes(programa_marco_id: marco.id) if proyecto
      @proyectos = marco.proyecto
    else
      @proyectos = []
    end
    render :update do |page|
      page.replace_html params[:update_listado], :partial => "listado_proyectos", locals: {update: params[:update_listado]}
    end
  end

  # Elimina un proyecto de la asociacion con el programa marco
  def eliminar_asociado
    marco = ProgramaMarco.find_by_id params[:programa_marco_id]
    proyecto = Proyecto.where(programa_marco_id: marco.id).find_by_id params[:id] if marco
    # Elimina la asociacion
    proyecto.update_attributes(programa_marco_id: nil) if proyecto && marco 
    render(:update) {|page| page.eliminar update: params[:update], mensaje: {errors: proyecto ? proyecto.errors : nil, eliminar: true}}
  end

  ####
  # Indicadores generales de los proyectos marco
  ###

  # en administracion lista los indicadores asociados
  def listado_indicadores
    marco = ProgramaMarco.find_by_id params[:programa_marco_id]
    @indicadores = marco.indicador_general
    render :update do |page|
      page.replace_html params[:update], partial: "listado_indicadores", locals: {update: params[:update]}
    end
  end

  # Presenta el formulario de asociacion de un nuevo indicador 
  def editar_nuevo_indicador
    if (marco = ProgramaMarco.find_by_id params[:programa_marco_id])
      # Presenta un formulario de asociacion con todos los indicadores no asociados previamente 
      indicadores = IndicadorGeneral.order(:nombre) - marco.indicador_general
      @indicadores = indicadores.collect{|p| [p.nombre, p.id]}
      render(:update) {|page| page.formulario partial: "formulario_indicador", update: params[:update] }
    end
  end

  # Asocia un indicador al programa marco asociado
  def modificar_crear_indicador
    if marco = ProgramaMarco.find_by_id(params[:programa_marco_id])
      indicador = IndicadorGeneral.find_by_id params[:indicador][:id] if params[:indicador]
      # Asocia el indicador 
      marco.indicador_general_x_programa_marco.find_or_create_by_indicador_general_id indicador.id if indicador
      @indicadores = marco.indicador_general
    else
      @indicadores = []
    end
    render :update do |page|
      page.replace_html params[:update_listado], :partial => "listado_indicadores", locals: {update: params[:update_listado]}
    end
  end

  # Elimina un proyecto de la asociacion con el programa marco
  def eliminar_indicador
    @igxpm = IndicadorGeneralXProgramaMarco.find_by_programa_marco_id_and_indicador_general_id params[:programa_marco_id], params[:id]
    # Elimina la asociacion
    @igxpm.destroy if @igxpm
    render(:update) {|page| page.eliminar update: params[:update], mensaje: {errors: @igxpm ? @igxpm.errors : nil, eliminar: true}}
  end
end
