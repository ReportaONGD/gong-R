# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2016 Free Software's Seed, OEI, CENATIC y IEPALA
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
# Controlador encargado de la gestion de relaciones del usuario.

class RelacionesUsuarioController < ApplicationController

  #++
  # Asignar USUARIOS (ayudas para asignacion de usuarios en otros controladores)
  #--
	# en administracion: muestra el listado de usuarios y grupos vinculados
  def usuarios
    @objeto = eval( params[:objeto].split('_').map(&:capitalize).join ).find( params[:id] )
    @usuarios_x = @objeto.usuario_x_vinculado.joins(:usuario).order("usuario.nombre")
    # En los listados de asignaciones incluiremos una caja de grupos si existe modelo que lo gestione
    @grupos_x = eval("@objeto.grupo_usuario_x_" + params[:objeto] ) if @objeto.respond_to?("grupo_usuario_x_" + params[:objeto]) 
    render :update do |page|
      page.replace_html params[:update], :partial => "relaciones_usuario/usuarios"
      page.insert_html :after, params[:update] + "_usuarios", :partial => "grupo_usuario/grupos" if @grupos_x
    end 
  end

  def asignar_usuario
    @objeto = eval( params[:objeto].split('_').map(&:capitalize).join ).find( params[:id].to_s )
    @listado_usuarios = Usuario.where(bloqueado: false).order("nombre").collect{ |u| [u.nombre_detallado, u.id] } - @objeto.usuario_x_vinculado.collect{ |u| [(u.usuario ? u.usuario.nombre_detallado : ""), u.usuario_id] }
    @usuario_actual = Usuario.find( params[:usuario_id] ) if params[:usuario_id]
    case params[:objeto]
      when "libro" then
        @objeto_nombre = "Cuenta"
      when "proyecto" then
        @objeto_nombre = "Proyecto"
        @roles = Rol.where(seccion: "proyectos").order(:nombre).collect{|r| [r.nombre, r.id]}
        @roles_agente = Rol.where(seccion: "agentes").order(:nombre).collect{|r| [r.nombre, r.id]}
      when "agente" then
        @objeto_nombre = "Agente"
        @roles = Rol.where(seccion: "agentes").order(:nombre).collect{|r| [r.nombre, r.id]}
      else
        @objeto_nombre = params[:objeto].titleize
    end
    @uxo = eval( "@objeto.usuario_x_" + params[:objeto] ).find_by_usuario_id(params[:usuario_id]) ||
           eval( "@objeto.usuario_x_" + params[:objeto] ).new(usuario_id: params[:usuario_id])
    render :partial => "relaciones_usuario/asignar_usuario", :locals => {:objeto => params[:objeto], :update => params[:update]}
  end

  def crear_modificar_asignacion
    @objeto = eval( params[:objeto].split('_').map(&:capitalize).join ).find( params[:id].to_s )

    @uxo = eval( "@objeto.usuario_x_" + params[:objeto] ).find_by_id(params[:uxo_id]) ||
           eval( "@objeto.usuario_x_" + params[:objeto] ).new()
    @uxo.update_attributes params[:uxo]

    if @uxo.errors.empty?
      # Si queremos propagar permisos, lo hacemos
      if params[:selector] && params[:selector][:forzar_permisos] && params[:selector][:forzar_permisos] == "1"
        # Asigna los implementadores
        @objeto.implementador.each do |implementador|
          if UsuarioXAgente.find_by_usuario_id_and_agente_id(@uxo.usuario_id,implementador.id).nil?
            uxa = UsuarioXAgente.new(usuario_id: @uxo.usuario_id, agente_id: implementador.id)
            uxa.update_attribute(:rol_id, params[:selector][:rol_agentes])
          end
        end if @objeto.class.name == "Proyecto" && params[:selector][:rol_agentes]
        # Asigna los libros
        @objeto.libro.each do |libro|
          UsuarioXLibro.find_or_create_by_usuario_id_and_libro_id(@uxo.usuario_id,libro.id)
        end
      end
      # Enviamos mensaje de advertencia
      usuario_asignado = @uxo.usuario
      @objeto.reload.usuario.uniq.each do |usuario|
        begin
          Correo.asignar_usuario(request.host_with_port, usuario, usuario_asignado, params[:usuario] ? params[:usuario][:rol_id] : nil, @objeto).deliver
        rescue
          @message = _("No se ha podido mandar el mail a algún usuario")
        end
      end
    end

    @usuarios_x = @objeto.usuario_x_vinculado.joins(:usuario).order("usuario.nombre")
    render :update do |page|
      page.replace params[:update] + "_usuarios", :partial => "relaciones_usuario/usuarios"
      page.replace 'formulario', :inline => '<%= mensaje_error @uxo %><br>'
    end 
  end

  def desasignar_usuario
    @objeto = eval( params[:objeto].split('_').map(&:capitalize).join ).find( params[:id].to_s )
    eval( "UsuarioX" + params[:objeto].split('_').map(&:capitalize).join + ".find( params[:usuario_x_objeto_id] ).destroy" )
    @usuarios_x = @objeto.usuario_x_vinculado.joins(:usuario).order("usuario.nombre")
    render :update do |page|
      page.replace params[:update] + "_usuarios", :partial => "relaciones_usuario/usuarios"
      page.replace_html 'MB_content', :inline => '<%= mensaje_error(@objeto, :eliminar => true) %><br>'
      page.call("Modalbox.resizeToContent")
    end
  end
end
