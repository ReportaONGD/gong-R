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
# Controlador encargado de la gestion de la entidad GrupoUsuario 
#
# Controlador encargado de la gestión de grupos de usuarios. Este controlador es utilizado desde las secciones:
# * Sección administración: se utiliza para crear grupos y asignarles usuarios.
class GrupoUsuarioController < ApplicationController

  before_filter :autorizar_admin, only: [:listado, :editar_nuevo, :modificar_crear, :eliminar]
  before_filter :autorizar_admin_o_rol_agente, except: [:listado, :editar_nuevo, :modificar_crear, :eliminar]
  
  # en administracion: se redirecciona por defecto a ordenado
  def index
    redirect_to :action => 'listado'
  end

  # en administracion: lista las agentes que hay en el sistema
  def listado
    @grupos = @paginado = GrupoUsuario.order("nombre").
                                       paginate(page: params[:page], per_page: (session[:por_pagina] or 20) )
  end

  # en administracion: prepara el formulario de edición o creación
  def editar_nuevo
    @grupo = GrupoUsuario.find_by_id(params[:id]) || GrupoUsuario.new
    @roles_proyecto = Rol.where(seccion: "proyectos").order("nombre").collect{|r| [r.nombre, r.id]}
    render :partial => "formulario"
  end

  # en administracion: modifica o crea
  def modificar_crear
    @grupo = GrupoUsuario.find_by_id(params[:id]) || GrupoUsuario.new
    @grupo.update_attributes params[:grupo]
    msg @grupo
    redirect_to :action => "listado"
  end

  # en administracion: elimina
  def eliminar
    @grupo = GrupoUsuario.find(params[:id])
    @grupo.destroy
    msg_eliminar @grupo
    redirect_to :action => 'listado'
  end

  #++
  # Asignar GRUPOS 
  #--

  def asignar_grupo
    @objeto = eval( params[:objeto].split('_').map(&:capitalize).join ).find( params[:id].to_s )
    @listado_grupos = GrupoUsuario.find(:all, :order => "nombre").collect{ |u| [u.nombre, u.id] } - @objeto.grupo_usuario.collect{ |u| [u.nombre, u.id] }
    @grupo_actual = GrupoUsuario.find( params[:grupo_id] ) if params[:grupo_id]
    case params[:objeto]
      when "libro" then
        @objeto_nombre = "Cuenta"
      when "proyecto" then
        @objeto_nombre = "Proyecto"
        @roles = Rol.where(seccion: "proyectos").collect{|r| [r.nombre, r.id]}
        @roles_agente = Rol.where(seccion: "agentes").collect{|r| [r.nombre, r.id]}
      when "agente" then
        @objeto_nombre = "Agente"
        @roles = Rol.where(seccion: "agentes").collect{|r| [r.nombre, r.id]}
      else
        @objeto_nombre = params[:objeto].titleize
    end
    @gxo = eval( "@objeto.grupo_usuario_x_" + params[:objeto] ).find_by_grupo_usuario_id(params[:grupo_id]) ||
           eval( "@objeto.grupo_usuario_x_" + params[:objeto] ).new(grupo_usuario_id: params[:grupo_id])
    render :partial => "grupo_usuario/asignar_grupo", :locals => {:objeto => params[:objeto], :update => params[:update]}
  end

  def crear_modificar_asignacion
    @objeto = eval( params[:objeto].split('_').map(&:capitalize).join ).find( params[:id].to_s )
    @gxo = eval( "@objeto.grupo_usuario_x_" + params[:objeto] ).find_by_id(params[:gxo_id]) ||
           eval( "@objeto.grupo_usuario_x_" + params[:objeto] ).new()
    @gxo.update_attributes params[:gxo]

    if @gxo.errors.empty?
      # Si queremos propagar permisos (en proyectos o agentes), lo hacemos
      if params[:selector] && params[:selector][:forzar_permisos] && params[:selector][:forzar_permisos] == "1"
        # Asigna los implementadores
        @objeto.implementador.each do |implementador|
          if GrupoUsuarioXAgente.find_by_grupo_usuario_id_and_agente_id(@gxo.grupo_usuario_id,implementador.id).nil?
            guxa = GrupoUsuarioXAgente.new(grupo_usuario_id: @gxo.grupo_usuario_id, agente_id: implementador.id)
            guxa.update_attribute(:rol_id, params[:selector][:rol_agentes]) 
          end
        end if @objeto.class.name == "Proyecto" && params[:selector][:rol_agentes]
        # Asigna los libros
        @objeto.libro.each do |libro|
          GrupoUsuarioXLibro.find_or_create_by_grupo_usuario_id_and_libro_id(@gxo.grupo_usuario_id,libro.id)
        end
      end
    end

    @grupos_x = eval( "@objeto.grupo_usuario_x_" + params[:objeto] )
    render :update do |page|
      page.replace params[:update] + "_grupos", :partial => "grupo_usuario/grupos"
      page.replace 'formulario', :inline => '<%= mensaje_error(@gxo) %><br>'
    end
  end

  def desasignar_grupo
    @objeto = eval( params[:objeto].split('_').map(&:capitalize).join ).find( params[:id].to_s )
    eval( "GrupoUsuarioX" + params[:objeto].split('_').map(&:capitalize).join + ".find( params[:grupo_usuario_x_objeto_id] ).destroy" )
    @grupos_x = eval( "@objeto.grupo_usuario_x_" + params[:objeto] )
    render :update do |page|
      page.replace params[:update] + "_grupos", :partial => "grupo_usuario/grupos"
      page.replace_html 'MB_content', :inline => '<%= mensaje_error(@objeto, :eliminar => true) %><br>'
      page.call("Modalbox.resizeToContent")
    end
  end

end
