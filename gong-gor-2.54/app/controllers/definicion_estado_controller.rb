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
# Controlador encargado de la gestión del workflow

class DefinicionEstadoController < ApplicationController
  # en administracion: se redirecciona por defecto a ordenado
  def index
    redirect_to :action => 'ordenado'
  end

  # en administracion: lista las definicion_estados que hay en el sistema
  def listado
    session[:definicion_estado_asc_desc] ||= "ASC"
    session[:definicion_estado_orden] ||= "orden"
    @definicion_estados = @paginado =  DefinicionEstado.order(session[:definicion_estado_orden] + " " + session[:definicion_estado_asc_desc]).
                                                        paginate(:page => params[:page], :per_page => (session[:por_pagina] or 20))
  end

  # en administracion o en definicion_estados: establece los parametros de ordenación
  def ordenado
    session[:definicion_estado_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"   
    session[:definicion_estado_orden] = params[:orden] ? params[:orden] : "orden" 
    redirect_to :action => "listado" 
  end
  
  # en administracion: prepara el formulario de edición o creación
  def editar_nuevo
    @estados_padre = DefinicionEstado.find(:all).collect{ |a| [a.nombre, a.id]}
    @definicion_estados_padres = DefinicionEstado.find(:all) 
    #@definicion_estado = params[:id] ?  DefinicionEstado.find(params[:id]) : nil
    @definicion_estado = DefinicionEstado.find_by_id(params[:id]) || DefinicionEstado.new
    @paises = Pais.find(:all).collect {|p| [p.nombre, p.id]}
    render :partial => "formulario"
  end

  # en administracion: modifica o crea
  def modificar_crear
    @definicion_estado = DefinicionEstado.find_by_id(params[:id]) || DefinicionEstado.new 
    @definicion_estado.update_attributes params[:definicion_estado]
    @definicion_estado.estado_padre_ids = params["definicion_estado_padre"].to_a.collect {|p| p[0] if p[1] == "1"}
    msg @definicion_estado
    redirect_to :action => "listado"
  end

  # en administracion: elimina
  def eliminar
    @definicion_estado = DefinicionEstado.find(params[:id])
    @definicion_estado.destroy
    msg_eliminar @definicion_estado
    redirect_to :action => 'listado'
  end

  #--
  # DOCUMENTOS
  #++

	# en proyectos: prepara el formulario de edición o creación de una actividad
  def  editar_nueva_etiqueta
    @definicion_estado =  DefinicionEstado.find(params[:id])
    @etiquetas = Etiqueta.find_all_by_tipo("proyecto")
    render :partial => "formulario_etiqueta", :locals => { :definicion_estado_id => params[:definicion_estado_id], :update => params[:update]}
  end

	# en proyectos: modifica o crea una actividad
  def modificar_crear_etiqueta
    @definicion_estado = DefinicionEstado.find(params[:id])
    @definicion_estado.etiqueta_ids = params["etiqueta"].to_a.collect {|p| p[0] if p[1] == "1"}
    render :update do |page|
      page.replace_html 'formulario', :inline => '<%= mensaje_error(@definicion_estado) %><br>'
      page.visual_effect :highlight, params[:update] , :duration => 3
    end
  end


  #--
  # TAREAS
  #++
	# en proyectos: lista las actividades de un resultado
  def tareas
    @tareas = DefinicionEstado.find(params[:definicion_estado_id]).definicion_estado_tarea.sort! {|x, y|  x.titulo <=> y.titulo }
    render :update do |page|
      page.replace_html params[:update], :partial => "tareas"
    end
  end

	# en proyectos: prepara el formulario de edición o creación de una actividad
  def nueva_editar_tarea
    @tarea = params[:id] ? DefinicionEstadoTarea.find(params[:id]) : DefinicionEstadoTarea.new
    @tipo_tarea = TipoTarea.order(:nombre).collect {|t| [t.nombre, t.id]}
    @estado_tarea = EstadoTarea.order(:nombre).collect {|t| [t.nombre, t.id]}
    render :partial => "formulario_tarea", :locals => { :definicion_estado_id => params[:definicion_estado_id], :update => params[:update]}
  end

	# en proyectos: modifica o crea una actividad
  def modificar_crear_tarea
    @tarea = params[:id] ? DefinicionEstadoTarea.find(params[:id]) : DefinicionEstadoTarea.new
    params[:tarea][:definicion_estado_id] = params[:definicion_estado_id]
    @tarea.update_attributes params[:tarea]
    @tareas = DefinicionEstado.find(params[:definicion_estado_id]).definicion_estado_tarea
    render :update do |page|
      page.replace_html 'formulario', :inline => '<%= mensaje_error(@tarea) %><br>'
      page.replace_html params[:update], :partial => "tareas"
      page.visual_effect :highlight, params[:update] , :duration => 3
    end
  end

  def eliminar_tarea
    @tarea = params[:id] ? DefinicionEstadoTarea.find(params[:id]) : DefinicionEstadoTarea.new
    @tarea.destroy 
    @tareas = DefinicionEstado.find(params[:definicion_estado_id]).definicion_estado_documento
    render :update do |page|
      page.replace_html params[:update], :partial => "tareas"
      page.visual_effect :highlight, params[:update] , :duration => 3
      page.replace_html 'MB_content', :inline => '<%= mensaje_error(@tarea, :eliminar => true) %><br>'
      page.call("Modalbox.resizeToContent")
    end
  end

end
