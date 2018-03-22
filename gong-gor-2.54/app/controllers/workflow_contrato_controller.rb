# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2015 Free Software's Seed, CENATIC y IEPALA
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
# Controlador encargado de la gestión del workflow de contratos

class WorkflowContratoController < ApplicationController
  before_filter :verificar_condiciones_admin, only: [:modificar_crear, :eliminar]
  before_filter :verificar_condiciones_agente, only: [:modificar_crear_etiqueta]

  # en administracion: se redirecciona por defecto a ordenado
  def index
    redirect_to :action => 'ordenado'
  end

  # en administracion: lista las workflow_contratos que hay en el sistema
  def listado
    session[:workflow_contrato_asc_desc] ||= "ASC"
    session[:workflow_contrato_orden] ||= "orden"
    @workflow_contratos = @paginado =  WorkflowContrato.order(session[:workflow_contrato_orden] + " " + session[:workflow_contrato_asc_desc] ).
                                                        paginate(page: params[:page], :per_page => (session[:por_pagina] or 20) )
  end

  # en administracion o en workflow_contratos: establece los parametros de ordenación
  def ordenado
    session[:workflow_contrato_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"   
    session[:workflow_contrato_orden] = params[:orden] ? params[:orden] : "orden" 
    redirect_to :action => "listado" 
  end
  
  # en administracion: prepara el formulario de edición o creación
  def editar_nuevo
    @estados_padre = WorkflowContrato.find(:all).collect{ |a| [a.nombre, a.id]}
    @workflow_contratos_padres = WorkflowContrato.find(:all) 
    @workflow_contrato = WorkflowContrato.find_by_id(params[:id]) || WorkflowContrato.new
    @paises = Pais.find(:all).collect {|p| [p.nombre, p.id]}
    render :partial => "formulario"
  end

  # en administracion: modifica o crea
  def modificar_crear
    @workflow_contrato = WorkflowContrato.find_by_id(params[:id]) || WorkflowContrato.new 
    @workflow_contrato.update_attributes params[:workflow_contrato]
    @workflow_contrato.estado_padre_ids = params["workflow_contrato_padre"].to_a.collect {|p| p[0] if p[1] == "1"}
    msg @workflow_contrato
    redirect_to :action => "listado"
  end

  # en administracion: elimina
  def eliminar
    @workflow_contrato = WorkflowContrato.find(params[:id])
    @workflow_contrato.destroy
    msg_eliminar @workflow_contrato
    redirect_to :action => 'listado'
  end

  #--
  # ETIQUETAS DOCUMENTALES 
  #++

  # prepara el formulario de edición o creación de una etiqueta documental 
  def editar_nueva_etiqueta
    @workflow_contrato = WorkflowContrato.find_by_id params[:id]
    @etiquetas = Etiqueta.where(tipo: "contrato").order(:nombre)
    render :partial => "formulario_etiqueta", :locals => { :workflow_contrato_id => params[:workflow_contrato_id], :update => params[:update]}
  end

  # en proyectos: modifica o crea una etiqueta documental
  def modificar_crear_etiqueta
    @workflow_contrato = WorkflowContrato.find(params[:id])
    @workflow_contrato.set_etiqueta_ids(@agente, params["etiqueta"].to_a.select{|e| e[1]=="1"})
    render :update do |page|
      page.replace_html 'formulario', :inline => '<%= mensaje_error(@workflow_contrato) %><br>'
      page.visual_effect :highlight, params[:update] , :duration => 3
    end
  end


  #--
  # TAREAS
  #++
	# en proyectos: lista las actividades de un resultado
  def tareas
    @tareas = WorkflowContrato.find(params[:workflow_contrato_id]).workflow_contrato_tarea.sort! {|x, y|  x.titulo <=> y.titulo }
    render :update do |page|
      page.replace_html params[:update], :partial => "tareas"
    end
  end

	# en proyectos: prepara el formulario de edición o creación de una actividad
  def nueva_editar_tarea
    @tarea = params[:id] ? WorkflowContratoTarea.find(params[:id]) : WorkflowContratoTarea.new
    @tipo_tarea = TipoTarea.find(:all).collect {|t| [t.nombre, t.id]}
    @estado_tarea = EstadoTarea.find(:all).collect {|t| [t.nombre, t.id]}
    render :partial => "formulario_tarea", :locals => { :workflow_contrato_id => params[:workflow_contrato_id], :update => params[:update]}
  end

	# en proyectos: modifica o crea una actividad
  def modificar_crear_tarea
    @tarea = params[:id] ? WorkflowContratoTarea.find(params[:id]) : WorkflowContratoTarea.new
    params[:tarea][:workflow_contrato_id] = params[:workflow_contrato_id]
    @tarea.update_attributes params[:tarea]
    @tareas = WorkflowContrato.find(params[:workflow_contrato_id]).workflow_contrato_tarea
    render :update do |page|
      page.replace_html 'formulario', :inline => '<%= mensaje_error(@tarea) %><br>'
      page.replace_html params[:update], :partial => "tareas"
      page.visual_effect :highlight, params[:update] , :duration => 3
    end
  end

  def eliminar_tarea
    @tarea = params[:id] ? WorkflowContratoTarea.find(params[:id]) : WorkflowContratoTarea.new
    @tarea.destroy 
    @tareas = WorkflowContrato.find(params[:workflow_contrato_id]).workflow_contrato_documento
    render :update do |page|
      page.replace_html params[:update], :partial => "tareas"
      page.visual_effect :highlight, params[:update] , :duration => 3
      page.replace_html 'MB_content', :inline => '<%= mensaje_error(@tarea, :eliminar => true) %><br>'
      page.call("Modalbox.resizeToContent")
    end
  end

 private

  def verificar_condiciones_admin
    unless @usuario_identificado.administracion
      msg_error _("No tiene permisos suficientes para modificar el workflow de contratos.")
      redirect_to action: 'listado'
    end
  end

  def verificar_condiciones_agente
    rol = @agente ? @agente.usuario_autorizado?(@usuario_identificado) : nil
    if rol.blank?
      msg_error _("No tiene permisos suficientes para modificar las condiciones del workflow de contratos.")
      redirect_to action: 'listado'
    end
  end
end
