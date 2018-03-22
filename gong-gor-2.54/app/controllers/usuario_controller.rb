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
# Controlador encargado de la gestion de usuario. Este controlador es utilizado desde las secciones:
# * Sección administracion: crear, modificar, eliminar usuarios
# * Sección entrada: autentifica y carga en la sessión
# * En cualquier sección: salir

class UsuarioController < ApplicationController

  include SimpleCaptcha::ControllerHelpers

  before_filter :obtiene_usuario, only: [:listado, :editar_nuevo, :modificar_crear, :eliminar,
                                         :datos_personales, :cambiar_datos_personales,
                                         :listado_relaciones, :asignar_relacion, :modificar_crear_relacion, :desasignar_relacion]
  before_filter :admin_usuarios, only: [:editar_nuevo, :modificar_crear, :eliminar,
                                        :listado_relaciones, :asignar_relacion, :modificar_crear_relacion, :desasignar_relacion]
  before_filter :admin_delegacion, only: [:modificar_crear_relacion, :desasignar_relacion]

  ############################################
  ## Acciones de usuario
  ############################################

  # Entrada al sistema. Valida si debe usarse la identificacio propia (render de identificacion) o externa 
  def entrada
    # Averiguamos si ya tenemos sesion en cuyo caso redirigimos y esperamos que los filtros la validen
    if session && session[:usuario_identificado_id]
      redirect_to params[:ir_a] || session[:ir_a] || {:seccion => :inicio, :controller => "/info"}
    # Si no tenemos, enviamos a la autentificacion propia o de plugin
    else
      # Hemos incorporado esta linea para que cada vez que se entre en la aplicación
      # recargue los plugins
      Plugin.search_external_auth
      # Comprueba si debe hacerse una auth externa
      auth_externa = Rails.configuration.external_auth.first
      if auth_externa && auth_externa.respond_to?(:auth_endpoint) && auth_externa.auth_endpoint
        redirect_to auth_externa.auth_endpoint || :identifica
      else
        render :identificacion
      end
    end
  end
  
  # Presenta el formulario de identificacion y hace la validacion
  def identificacion
    if params[:usuario] && (usuario = Usuario.identificacion(params[:usuario][:nombre], params[:usuario][:contrasena]))
      redirect_to sesion_iniciar(usuario)
    elsif params[:usuario]
      msg_error _("Identificación incorrecta.<br>Compruebe su usuario y contraseña.")
      # Hacemos este redirect to back para ocultar el metodo cuando entramos de cero
      redirect_to :back
    end
  end

  # en cualquier sección: pon a nil el usuario_identificado en la sessión
  def salir
    sesion_terminar
    # Comprueba si estamos usando una auth externa
    auth_externa = Rails.configuration.external_auth.first
    # Y redirige a donde deba
    redirect_to (auth_externa && auth_externa.respond_to?(:logout_url) && auth_externa.logout_url) ? auth_externa.logout_url : entrada_path
  end

  # Presenta la modal de datos personales
  def datos_personales
    if request.xhr?
      @usuario = @usuario_identificado
      render :partial => "datos_personales"
    else
      redirect_to :proyectos
    end
  end

  # Modificacion de datos personales
  def cambiar_datos_personales
    @usuario = @usuario_identificado
    if Usuario.hash_contrasena(params[:comprobar][:contrasena_antigua]) == @usuario.contrasena and params[:comprobar][:contrasena_nueva] == params[:comprobar][:contrasena_repetida]
      @usuario.update_attribute :contrasena,  Usuario.hash_contrasena(params[:comprobar][:contrasena_nueva]) unless params[:comprobar][:contrasena_nueva] == ""
    else
      fallo_comprobacion = params[:comprobar][:contrasena_nueva] != ""
    end
    @usuario.update_attributes params[:usuario]

    unless !@usuario.errors.empty? || fallo_comprobacion
      # Actualiza las notificaciones de proyectos de comentarios
      params[:comentario].each do |valores|
        # Como podemos tener asignado el proyecto directamente o a traves de un grupo, recorremos todos...
        UsuarioXProyecto.all(:conditions => {:usuario_id => @usuario.id, :proyecto_id => valores[0]}).each do |uxp|
          uxp.update_attribute :notificar_comentario, (valores[1] == "1")
        end
      end if params[:comentario]
      # Actualiza las notificaciones de proyectos de cambios de estado
      params[:estado].each do |valores|
        # Como podemos tener asignado el proyecto directamente o a traves de un grupo, recorremos todos...
        UsuarioXProyecto.all(:conditions => {:usuario_id => @usuario.id, :proyecto_id => valores[0]}).each do |uxp|
          uxp.update_attribute :notificar_estado, (valores[1] == "1")
        end
      end if params[:estado]
     # Actualiza las notificaciones de proyectos de asignacion de usuarios
      params[:asignar_usuario].each do |valores|
        # Como podemos tener asignado el proyecto directamente o a traves de un grupo, recorremos todos...
        UsuarioXProyecto.all(:conditions => {:usuario_id => @usuario.id, :proyecto_id => valores[0]}).each do |uxp|
          uxp.update_attribute :notificar_usuario, (valores[1] == "1")
        end
      end if params[:asignar_usuario]
    end
    render :update do |page|
      @mensaje = fallo_comprobacion ? _("Error en los datos de comprobación") : @usuario
      page.replace_html 'MB_content', :inline => '<%= mensaje_error(@mensaje) %><br>'
      page.call("Modalbox.resizeToContent")
    end
  end



  ############################################
  ## Métodos de gestion de usuarios
  ############################################

  # en administracion: se redirecciona por defecto a ordenado
  def index
    redirect_to :action => 'ordenado'
  end

  # Condiciones para listados segun el filtro
  def filtrado_condiciones
    session[:usuario_orden] ||= "usuario.nombre"
    session[:usuario_asc_desc] ||= "ASC"
    session[:usuario_filtro_nombre] ||= "" 

    @condiciones = "usuario.nombre LIKE " + ActiveRecord::Base.connection.quote(session[:usuario_filtro_nombre]) unless session[:usuario_filtro_nombre].blank?
    @opciones_filtrado = [      {:rotulo => _("Seleccione Nombre"), :nombre => "nombre", :tipo => "texto"} ]
    @accion_filtrado = {:action => :filtrado }
  end

  # en administracion: lista
  def listado
    filtrado_condiciones
    if @proyecto
      pre_usuarios = UsuarioXProyecto.where(proyecto_id: @proyecto.id).
                                      joins(:usuario).where("usuario.bloqueado IS NOT TRUE").
                                      includes(:grupo_usuario).
                                      where("grupo_usuario_id IS NULL OR grupo_usuario.ocultar_proyecto IS NOT TRUE")
    else
      condicion = @agente ? {agente_id: @agente.id} : {}
      pre_usuarios = Usuario.where(condicion)
    end
    @usuarios = @paginado =  pre_usuarios.where(@condiciones). 
                                          reorder(session[:usuario_orden] + " " + session[:usuario_asc_desc]).
                                          paginate(page: params[:page], per_page: session[:por_pagina])
  end

  # en administracion: establece los parametros de ordenación 
  def ordenado
    session[:usuario_orden] = params[:orden] ? params[:orden] : "usuario.nombre" 
    session[:usuario_orden] = "usuario.nombre" if params[:orden] == "nombre"
    session[:usuario_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    redirect_to :action => "listado"
  end
 
  # Condiciones de filtrado del listado de usuarios
  def filtrado
    if params[:filtro]
      session[:usuario_filtro_nombre] = params[:filtro][:nombre]
    end
    redirect_to action: "listado"
  end

  # en administracion: prepara el formulario de edición o creación
  def editar_nuevo
    @agentes = Agente.where(implementador: true, socia_local: false).order(:nombre).collect{|o| [o.nombre, o.id]} unless @agente
    @agentes = [ [@agente.nombre, @agente.id] ] if @agente
    render :partial => "formulario"
  end


  # en administracion: modifica o crea
  def modificar_crear
    @usuario ||= Usuario.new
    # Fuerza la oficina por si se modificaran los parametros
    params[:usuario][:agente_id] = @agente.id if @agente
    # Elimina el parametro de "adminitracion" si el usuario no es administrador
    params[:usuario].delete(:administracion) unless @usuario_identificado.administracion
    @usuario.update_attributes params[:usuario]
    @usuario.update_attribute :contrasena,  Usuario.hash_contrasena(params[:usuario][:contrasena]) if params[:usuario][:contrasena] && @usuario.errors.empty?
    @usuario_identificado.reload if @usuario.id == @usuario_identificado.id
    msg @usuario
    redirect_to :action => "listado"
  end

  # en administracion: añade un campo "contraseña al formulario
  def contrasena
    render :inline => "<%= contrasena 'Contraseña', 'usuario', 'contrasena', '1' %>"
  end

  # en administracion: elimina usuario.
  def eliminar
    # Solo podemos eliminar usuarios administradores si nosotros somos administradores
    error = _("No se puede borrar un usuario administrador.") if @usuario && @usuario.administracion && !@usuario_identificado.administracion
    # Evitamos borrar cosas que no existen
    error = _("No se pudo borrar el usuario especificado.") unless @usuario
    if error
      msg_error error
    else
      @usuario.destroy
      msg_eliminar @usuario
    end
    redirect_to :action => 'listado'
  end


  #++
  # Asigna el usuario actual a otros objetos
  #--

  # Listado de relaciones
  def listado_relaciones
    proyectos = usuario_x_proyecto
    agentes = usuario_x_agente
    libros = usuario_x_libro
    render :update do |page|
      page.replace_html params[:update], :partial => "listado_relaciones", :locals => { proyectos: proyectos, agentes: agentes, libros: libros }
    end
  end

  def asignar_relacion
    @elemento = eval("UsuarioX" + params[:tipo].capitalize).find_by_id(params[:elemento_id]) || eval("UsuarioX" + params[:tipo].capitalize).new
    # Obtenemos todos los elementos no vinculados aun
    elementos_posibles
    render(:update){ |page| page.formulario :partial => "formulario_relacion", :update => params[:update] }
  end

  def modificar_crear_relacion
    @elemento = eval("UsuarioX" + params[:tipo].capitalize).find_by_id(params[:elemento_id]) || eval("UsuarioX" + params[:tipo].capitalize).new(usuario_id: @usuario.id)
    @elemento.update_attributes(params[:elemento])
    elementos = eval("usuario_x_" + params[:tipo])
    if @elemento.errors.empty?
      render :update do |page|
        page.replace_html params[:update_listado], :partial => "listado_relaciones_elemento", :locals => { elementos: elementos, tipo: params[:tipo] }
      end
    else
      # Obtenemos todos los elementos no vinculados aun
      elementos_posibles
      render(:update) { |page| page.recargar_formulario :partial => "formulario_relacion", :mensaje => {:errors => @elemento.errors} }
    end
  end

  def desasignar_relacion
    elemento = eval("UsuarioX" + params[:tipo].capitalize).find_by_id(params[:elemento_id])
    elemento.destroy
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => elemento.errors, :eliminar => true}}
  end
 
  #++
  # Registro y aviso legal
  #--

  # Envio del formulario de registro
  def registro_envio
    if ENV['DEMO'] && simple_captcha_valid?
      if params[:registro] &&
         params[:registro][:nombre] != "" && params[:registro][:correoe] != "" &&
         params[:registro][:pais] != "" && params[:registro][:empresa] != "" && 
         params[:registro][:interes] != ""
        begin
          # Situación provisional. Habria que pensar en la necesidad de crear usuarios, vincularlo a proyectos,...
          destinatario = params[:registro][:nombre] + " <" + params[:registro][:correoe] + ">"
          Correo.registro(request.host_with_port, destinatario, params[:registro], "admin", DEMO_PASS).deliver
          logger.info "----------------> Se ha enviado correo de registro" + destinatario
          Correo.registro(request.host_with_port, DEMO_CORREO_INFO, params[:registro], "admin", DEMO_PASS).deliver
          logger.info "----------------> Se ha enviado correo de registro" + DEMO_CORREO_INFO
          msg_error _("Gracias por registrarse. Revise su correo con el usuario y contraseña necesarios para acceder al sistema"), :ok => true
        rescue => ex
          logger.error "----------------> Se ha producido un error enviando algun mail: " + ex.inspect
          msg_error _("Lo sentimos. No se ha podido enviar el correo con la información para el registro")
        end
      else
        msg_error _("Rellene todos los datos del formulario")
      end
    else
      msg_error _("El código introducido no coincide con la imagen") if ENV['DEMO']
    end
    redirect_to :entrada and return
  end

  # Aviso legal
  def avisolegal
    if request.xhr?
      render :update do |page|
        page.replace_html "explicacion_cuerpo", :partial => "avisolegal_" + (FastGettext.locale||"es")[0..1]
      end
    else
      redirect_to :proyectos
    end
  end

 private

  # Obtiene el usuario actual
  def obtiene_usuario
    @usuario = Usuario.where(agente_id: @agente.id).find_by_id(params[:id]) if @agente
    @usuario = Usuario.find_by_id(params[:id]) unless @agente
  end

  # Averigua si estamos en una seccion de administracion y bloquea por codigo cuando no es asi
  def admin_usuarios
    redirect_to :action => "listado" unless params[:seccion] == "administracion" || params[:seccion] == "agentes"
  end

  # Permite solo modificar asignaciones de usuarios a agentes si estamos en administracion
  # o somos administradores de la delegacion
  def admin_delegacion
    if params[:seccion] != "administracion" && params[:tipo] == "agente" &&
       ( @agente.nil? || @usuario_identificado.usuario_x_agente.where(agente_id: @agente.id).joins(:rol_asignado).where("rol.admin" => true).blank? )
      mensaje = _("No tiene permisos suficientes para realizar esta acción.")
      render :update do |page|
        page.mensaje_informacion params[:update], mensaje, tipo_mensaje: "mensajefallo"
      end
    end
    # Además, si estamos en agentes, nos aseguramos que el agente sea el actual 
    params[:elemento][:agente_id] = @agente.id if @agente && params[:elemento]
  end

  # Devuelve los usuario_x_proyecto para un usuario concreto
  def usuario_x_proyecto
    condiciones = {"proyecto.convenio_id" => nil}
    # Si estamos en un agente, mostramos solo los proyectos en los que es gestor
    condiciones["proyecto.gestor_id"] = @agente.id if @agente
    @usuario.usuario_x_proyecto.joins(:proyecto).where(condiciones).joins(:proyecto => [:estado_actual => :definicion_estado]).where("definicion_estado.cerrado" => false).order("proyecto.nombre")
  end

  # Devuelve los usuario_x_agente para un usuario concreto
  def usuario_x_agente
    condiciones = {"agente.implementador" => true, "agente.socia_local" => false}
    @usuario.usuario_x_agente.joins(:agente).where(condiciones).order("agente.nombre")
  end

  # Devuelve los usuario_x_libro para un usuario concreto
  def usuario_x_libro
    condiciones = {"libro.bloqueado" => false}
    # Si estamos en un agente, mostramos solo los libros propios
    condiciones["libro.agente_id"] = @agente.id if @agente
    @usuario.usuario_x_libro.joins(:libro).where(condiciones).order("libro.nombre")
  end

  # Devuelve los elementos posibles para la asignacion teniendo en cuenta que solo pueden gestionarse los propios si estamos en una oficina
  def elementos_posibles
    @elementos = []
    case params[:tipo]
      when "proyecto"
        condiciones = {convenio_id: nil}
        condiciones[:gestor_id] = @agente.id if @agente
        elems = Proyecto.where(condiciones).joins(estado_actual: :definicion_estado).where("definicion_estado.cerrado" => false).order("nombre")
        @elementos = elems - @usuario.proyecto.where("usuario_x_proyecto.grupo_usuario_id" => nil)
      when "agente"
        condiciones = {implementador: true}
        condiciones[:id] = @agente.id if @agente
        @elementos = Agente.where(condiciones).order("nombre") - @usuario.agente.where("usuario_x_agente.grupo_usuario_id" => nil)
      when "libro"
        condiciones = {bloqueado: false}
        condiciones[:agente_id] = @agente.id if @agente
        @elementos = Libro.where(condiciones).order("nombre") - @usuario.libro.where("usuario_x_libro.grupo_usuario_id" => nil)
    end
    @elementos.push @elemento.send(params[:tipo]) if @elemento && @elemento.id
  end
 
end
