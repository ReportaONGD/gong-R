# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2015 Free Software's Seed
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

# Gestiona roles y permisos por rol
class RolController < ApplicationController

  before_filter :solo_administracion
  before_filter :rol, except: [ :index, :ordenado, :listado ]

  # --
  # Metodos de Gestión de Roles de usuario 
  # ++

  def index
    redirect_to :action => :listado 
  end

  # establece los parametros de ordenación
  def ordenado
    session[:rol_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    params[:orden] = "seccion, nombre" if params[:orden].nil? || params[:orden] == "nombre_seccion"
    session[:rol_orden] = params[:orden]
    redirect_to :action => :listado
  end

  # lista los roles 
  def listado
    @roles = @paginado = Rol.order((session[:rol_orden]||"seccion, nombre") + " " + (session[:rol_asc_desc]||"ASC")).
                             paginate(page: params[:page], per_page: session[:por_pagina] )
  end

  # prepara el formulario de crear o editar
  def editar_nuevo
    @rol ||= Rol.new
    datos_formulario
    if params[:copiar_desde_id] && @rol.id.nil?
      @copiar_desde = Rol.find_by_id(params[:copiar_desde_id])
      @rol = @copiar_desde.dup
      @rol.nombre = nil
    end
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

  # modifica o crea un rol
  def modificar_crear
    @rol ||= Rol.new
    if params[:copiar_desde_id] && @rol.id.nil?
      @copiar_desde = Rol.find_by_id(params[:copiar_desde_id])
      @rol = @copiar_desde.dup if @copiar_desde
    end
    @rol.update_attributes params[:rol]
    if @rol.errors.empty?
      # Si se ha enviado el parametro "copiar_desde_id" y el rol es nuevo, le copia todos los permisos
      @rol.copiar_permisos_desde(@copiar_desde) if @copiar_desde 
      # Si es uno ya existente, modifica la linea
      render(:update) { |page| page.modificar :update => params[:update], :partial => "rol" , :mensaje => { :errors => @rol.errors } } if params[:id]
      # Si es uno nuevo lo incluye en la parte superior del listado
      render :update do |page|
        page.show "nuevos_roles"
        page.modificar :update => "rol_nuevo_" + params[:i], :partial => "nuevo_rol", :mensaje => { :errors => @rol.errors }
        page.replace "formulario_anadir_anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>"
      end unless params[:id] 
    else
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @rol.errors} }
    end 
  end

  # elimina un rol 
  def eliminar
    @rol.destroy if @rol
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @rol.errors, :eliminar => true}}
  end


  # --
  # Metodos de Gestión de Documentos asociados a Tipos de Contrato
  # Esto lo hacemos asi y no en el controlador de documentos para poder filtrar que documentos asociamos
  # ++

  # Lista todos los documentos asociados al tipo de contrato proporcionado
  def listado_permisos
    @permisos = @rol.permiso_x_rol
    render(:update) { |page| page.replace_html(params[:update], partial: "listado_permisos", locals: {update_listado: params[:update]}) }
  end

  # Prepara el formulario de asociacion de documento 
  def editar_nuevo_permiso
    @permiso = @rol.permiso_x_rol.find_by_id(params[:permiso_id]) || @rol.permiso_x_rol.new
    datos_formulario_permiso
    render(:update){ |page| page.formulario partial: "formulario_permiso", update: params[:update] }
  end

  def cambia_menu_seccion
    @controladores_menu = datos_formulario_controladores_menu(params[:opcion_menu])
    render :partial => "permiso_menu_controlador"
  end

  # Registra una nueva asociacion de tipo de contrato  
  def modificar_crear_permiso
    @permiso = @rol.permiso_x_rol.find_by_id(params[:permiso_id]) || @rol.permiso_x_rol.new
    @permiso.update_attributes params[:permiso]

    if @permiso.errors.empty?
      @permisos = @rol.permiso_x_rol
      render(:update) do |page|
        page.modificar :update => params[:update_listado], :partial => "listado_permisos", mensaje: { errors: @permiso.errors }, locals: { update_listado: params[:update_listado] }
      end
    else
      datos_formulario_permiso
      render(:update) { |page| page.recargar_formulario partial: "formulario_permiso", mensaje: {errors: @permiso.errors} }
    end
  end

  # Elimina la asocicion con el tipo de contrato proporcionado
  def eliminar_permiso
    @permiso = @rol.permiso_x_rol.find_by_id(params[:permiso_id])
    @permiso.destroy if @permiso
    @permisos = @rol.permiso_x_rol
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @permiso.errors, :eliminar => true}}
  end

 private
  # Se asegura de que estemos en administracion y podamos hacer esto
  def solo_administracion
    return params[:seccion] == "administracion" && @usuario_identificado.administracion
  end

  # devuelve el rol a utilizar segun los parametros
  def rol
    @rol = Rol.find_by_id(params[:id]) 
  end

  # datos del formulario de edicion
  def datos_formulario
    @secciones = Rol::SECCIONES.collect{|k,v| [v, k]}
  end

  # datos del formulario de edicion de permisos 
  def datos_formulario_permiso
    @menus_seccion = view_context.menu_seccion(@rol.seccion).collect{|m| [m[:rotulo], m[:url][:menu]]}
    menu = @permiso.menu || @menus_seccion.first[1]
    @controladores_menu = datos_formulario_controladores_menu(menu)
  end

  # obtiene la informacion de los controladores de un menu concreto
  def datos_formulario_controladores_menu menu=nil
    controladores = {}
    existentes = @rol.permiso_x_rol.where(menu: menu).collect{|p| p.controlador}
    view_context.controladores_menu({menu: menu}).each do |c|
      # Analiza el propio controlador
      unless existentes.include?(c[:url][:controller].to_s) && (@permiso.nil? || @permiso.controlador != c[:url][:controller].to_s)
        controladores[c[:url][:controller].to_s] ||= []
        controladores[c[:url][:controller].to_s].push("'" + c[:rotulo] + "'")
      end
      # Y los controladores secundarios
      c[:otros].each do |otro|
        unless existentes.include?(otro.to_s) && (@permiso.nil? || @permiso.controlador != otro.to_s)
          controladores[otro.to_s] ||= []
          controladores[otro.to_s].push("'" + c[:rotulo] + "'")
        end
      end if c[:otros]
    end 
    controladores.collect {|k,v| [_("'%{controlador}' - Usado en %{opciones}")%{controlador: k, opciones: v.join(", ").gsub(/^(.{90,}?).*$/m,'\1...')}, k ]}
  end
end

