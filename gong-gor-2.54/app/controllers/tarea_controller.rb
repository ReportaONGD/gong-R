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
# Controlador encargado de la gestion de proyecto. Este controlador es utilizado desde las secciones:
# * Sección inicio: visualizar las tareas asignadas al usuario identificado
# * Sección proyectos: visualizar y gestionar las tareas del proyecto

class TareaController  < ApplicationController


  # en proyectos y delegaciones: se redirecciona por defecto a listado 
  def index
    redirect_to :action =>  "listado"
  end

  # en inicio y proyectos: establece los parametros de ordenación
  def ordenado
    session[:tarea_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"   
    session[:tarea_orden] = params[:orden] ? params[:orden] : "titulo" 
    redirect_to :action => "listado"
  end

  def filtrado
    session[:tarea_filtro_activo] = params[:filtro][:activo]
    # Chapucilla
    session[:gor] = "gor"
    redirect_to :action => "listado"
  end
  
  def condiciones_y_filtro
    session[:tarea_orden] ||= "titulo"
    session[:tarea_filtro_activo] ||= _("Tareas activas")
    session[:tarea_asc_desc] ||= "ASC"
    @condiciones = Hash.new
    case session[:tarea_filtro_activo]
      #when _("Cualquier estado") then @condiciones["estado_tarea.activo"] = true 
      when _("Tareas activas") then @condiciones["estado_tarea.activo"] = true
      when _("Tareas no activas") then @condiciones["estado_tarea.activo"] = false
    end
    case params[:seccion]
      #when "inicio" then @condiciones[:usuario_asignado_id] = @usuario_identificado.id
      when "inicio" then @condiciones_seccion = ["usuario_asignado_id = ? OR usuario_id = ? OR (proyecto_id IN (?) && usuario_asignado_id IS NULL)", @usuario_identificado.id, @usuario_identificado.id, @usuario_identificado.proyecto]
      when "proyectos" then @condiciones[:proyecto_id] = @proyecto.id
      when "agentes" then @condiciones[:agente_id] = @agente.id
    end
    @opciones_filtrado =  [{:rotulo => _("Seleccione estado"), :nombre=> "activo", :opciones =>[ _("Tareas activas"), _("Tareas no activas"), _("Cualquier estado")] }] 
    @accion_filtrado = {:action => :filtrado }
  end  
    
  def listado
    condiciones_y_filtro
    #@tareas = @paginado =  Tarea.where(@condiciones_seccion).
    #                             joins([:tipo_tarea, :estado_tarea]).
    #                             where(@condiciones).
    #                             order(session[:tarea_orden] + " " + session[:tarea_asc_desc]).
    #                             paginate(page: params[:page], per_page: (session[:por_pagina]))
    @tareas = @paginado = Tarea.joins(:estado_tarea).where(@condiciones).
                                order(session[:tarea_orden] + " " + session[:tarea_asc_desc]).
                                paginate(page: params[:page], per_page: (session[:por_pagina]))
  end

  # en inicio: selecciona el proyecto de la tarea y lo carga en la sessión
  def ir_tareas
    tarea = Tarea.find_by_id(params[:id])
    if tarea.proyecto_id
      redirect_to :seccion => 'proyectos', :proyecto_id => tarea.proyecto_id, :menu => "resumen",  :controller => 'tarea', :action => "listado"
    else
      redirect_to :seccion => 'agentes', :agente_id => tarea.agente_id, :menu => "tarea", :controller => 'tarea', :action => 'listado'
    end
  end

  # en proyectos y delegaciones: prepara el formulario de edición o creación
  def editar_nuevo
    editar_nuevo_formulario
    render :partial => "formulario"
  end

  # Metodo comun a editar_nuevo y editar_nuevo_formulario
  def editar_nuevo_formulario
    @tarea = Tarea.find_by_id(params[:id]) || Tarea.new(:fecha_inicio => Date.today)
    if params[:seccion] == "proyectos"
      @usuarios = Proyecto.find_by_id(@proyecto.id).usuario.collect{ |a| [a.nombre_detallado, a.id] }.uniq
      @tipo_tarea = TipoTarea.where(:tipo_proyecto => true).all(:order => "nombre").collect{ |a| [a.nombre, a.id] }
    elsif params[:seccion] == "agentes"
      @usuarios = Agente.find_by_id(@agente.id).usuario.collect{ |a| [a.nombre_detallado, a.id] }.uniq
      @tipo_tarea = TipoTarea.where(:tipo_agente => true).all(:order => "nombre").collect{ |a| [a.nombre, a.id] }
    else
      @usuarios = Usuario.all(:order => "nombre").collect{ |a| [a.nombre_detallado, a.id] }.uniq
      @tipo_tarea = TipoTarea.where(:tipo_proyecto => false, :tipo_agente => false).all(:order => "nombre").collect{ |a| [a.nombre, a.id] }
    end
    if @tarea.id
      if session[:usuario_identificado_id] == @tarea.usuario_asignado_id
        @estado_tarea = EstadoTarea.all.collect{ |a| [a.nombre, a.id] }       
      else
        @estado_tarea = EstadoTarea.all(:conditions => {:seleccionable => true}).collect{ |a| [a.nombre, a.id] }  
      end
    else
      @estado_tarea = EstadoTarea.all(:conditions => {:activo => true}).collect{ |a| [a.nombre, a.id] }
    end
  end


  # en proyectos: modifica o crea
  def modificar_crear
    @msg = ""
    @tarea = params[:id] ?  Tarea.find(params[:id]) : Tarea.new( :usuario_id => @usuario_identificado.id, :fecha_inicio => Time.now() )
    #@tarea.fecha_fin = Time.now if params[:tarea][:estado] == "cerrada"
    params[:tarea][:agente_id] = @agente.id if @agente && params[:tarea]
    params[:tarea][:proyecto_id] = @proyecto.id if @proyecto && params[:tarea]
    @tarea.update_attributes params[:tarea]
    usuarios = Usuario.find( :all, :conditions => { :id => @tarea.usuario_id } )
    usuarios += Usuario.find( :all, :conditions => { :id => @tarea.usuario_asignado_id } ) unless @tarea.usuario_id == @tarea.usuario_asignado_id
    for usuario in usuarios
      begin
        Correo.cambio_tarea(request.host_with_port, usuario, @tarea).deliver
      rescue
        @msg << "no se ha podido mandar el mail a " + usuario.correoe + "<br>"
      end
    end if @tarea.errors.empty?
    msg @tarea
    redirect_to :action => "listado"
  end
  
  # en proyectos: elimina
  def eliminar
    @tarea = Tarea.find(params[:id])
    @tarea.destroy
    msg_eliminar @tarea
    redirect_to :action => 'listado'
  end


  # --
  ########## TAREAS VINCULADAS A PERIODOS (AJAX) ##########
  # ++


  # Listado de tareas para un periodo
  def listado_tarea_periodo
    @tareas = Periodo.find(params[:periodo_id]).tarea 
    render :update do |page|
      page.replace_html params[:update], :partial => "listado_tarea_periodo"
    end
  end


  def editar_nuevo_tarea_periodo
    editar_nuevo_formulario
    render (:update) { |page|  page.formulario :update => params[:update], :partial => "formulario" }
  end
  

  # en proyectos: modifica o crea
  def modificar_crear_tarea_periodo
    @tarea = params[:id] ?  Tarea.find(params[:id]) : 
                            Tarea.new( :usuario_id => @usuario_identificado.id, :fecha_inicio => Time.now(),
                                       :proyecto_id => @proyecto.id, :periodo_id => params[:periodo_id])
    @tarea.update_attributes params[:tarea]
    begin
      Correo.cambio_tarea(request.host_with_port, @tarea.usuario, @tarea).deliver
      unless @tarea.usuario_id == @tarea.usuario_asignado_id or @tarea.usuario_asignado.nil?
        Correo.cambio_tarea(request.host_with_port, @tarea.usuario_asignado, @tarea).deliver 
      end
    rescue
    end

    msg @tarea
    @periodo = Periodo.find(params[:periodo_id])
    @tareas = @periodo.tarea 
    render :update do |page|  
      page.modificar( :update =>"periodo_"+ @periodo.id.to_s, :partial => "datos_proyecto/periodo_linea", :locals => {periodo: @periodo, tipo_periodo: params[:tipo_periodo]}, :mensaje => { :errors => @tarea.errors } )
      page.replace_html params[:update], :partial => "listado_tarea_periodo"
      #page.modificar( :update_listado => params[:update_listado], :partial => "listado_tarea_periodo", :mensaje => { :errors => @tarea.errors })
    end
  end
  
  def eliminar_tarea_periodo
    @tarea = Tarea.find(params[:id]).destroy
    render(:update) { |page|  page.eliminar(:update => params[:update], :mensaje => { :errors => @tarea.errors, :eliminar => true }) }
  end



end
#done
