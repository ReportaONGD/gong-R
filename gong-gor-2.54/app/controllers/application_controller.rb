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
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  #include UserInfo

  # Esto es para poder usar el number_with_delimiter
  #include ActionView::Helpers::NumberHelper

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  #protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # helper :all # include all helpers, all the time
  helper :layout, :nueva_edicion, :listado, :xls
  before_filter :configurar_idioma
  before_filter :autorizar, :sesion_timeout, :objeto_seccion, :xls_request, :tiempo_comienzo, :por_pagina, :autorizar_rol, :except => [:entrada, :identificacion, :registro_envio, :avisolegal ]

  #Siempre incluimos el mismo layout general menos en identificacion
  layout "layout", :except => ["entrada","identificacion"]



  #--
  # Gestion de sesiones
  #++

  # Inicia una sesion para un usuario dado
  def sesion_iniciar usuario=nil
    if usuario.class.name == "Usuario"
      session[:por_pagina] = 20
      session[:usuario_identificado_id] = usuario.id
      session[:idioma_seleccionado] = params[:selector] ? params[:selector][:idioma] : "es"
      # Limpiamos session[:ir_a] para no reutilizarlo en veces sucesivas y nos cargamos comprobacion de :ir_a_usuarios por no usarse
      session[:timeout] = Time.now
      params[:ir_a] ||= session.delete(:ir_a)
      redireccion = params[:ir_a] || {:seccion => :inicio, :controller => "/info"}
    else
      redireccion = main_app.identifica_path
    end
    return redireccion
  end

  # Termina la sesion
  def sesion_terminar
    if session
      # Oauth2: Borramos los tokens y grants que tenga el usuario.
      Doorkeeper::AccessToken.destroy_all(:resource_owner_id => session[:usuario_identificado_id])
      Doorkeeper::AccessGrant.destroy_all(:resource_owner_id => session[:usuario_identificado_id])

      # Nos cargamos todos los elementos de la sesion
      session[:usuario_identificado_id] = nil
      session[:timeout] = nil
      reset_session
    end
  end

  # Comprobacion de inactividad. Configurado a 1 hora.
  def sesion_timeout
    session[:timeout] ||= Time.now
    if Time.now - session[:timeout] > 3600
      sesion_terminar
      mensaje = _("Tiempo de inactividad en el sistema superado. Vuelva a identificarse para acceder.")
      if request.xhr?
        # Si la peticion es ajax
        render (:update) {|page|  page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"} if params[:update]
        render (:update) {|page|  page.mensaje_informacion params[:update_listado], mensaje, :tipo_mensaje => "mensajefallo"} if params[:update_listado]
      else
        # Si la peticion no es ajax
        flash[:mensaje] = mensaje
        session[:ir_a] = "#{request.fullpath}"
        redirect_to main_app.entrada_path
      end
    end
    session[:timeout] = Time.now
  end


  #--
  # Autorizaciones
  #++

  # Se comprueba si el acceso tiene un usuario identificado, y se comprueba tambien que el usuario tiene permisos para acceder la seccion en la que se esta navegando.
  def autorizar
    #puts "------------------> ERROR!!!!! No existe la variable de sesion para usuario_identificado_id" unless session[:usuario_identificado_id]
    #puts "------------------> Tenemos la sesion: " + session.inspect
    @usuario_identificado = Usuario.find_by_id session[:usuario_identificado_id]
    #puts "------------------> @usuario_identificado -> " + @usuario_identificado.inspect
    unless @usuario_identificado.class.name == "Usuario" 
      msg_error _("Debe identificarse para acceder al sistema.")
      session[:ir_a] = "#{request.fullpath}"
      redirect_to main_app.entrada_path
      return false
    end
    
    unless params[:seccion] == "inicio" or params[:seccion] == "info" or ( @usuario_identificado and @usuario_identificado.send( params[:seccion] ) == true )
      msg_error _( "no tiene los derechos para ir a la sección " ) + params[:seccion]
      redirect_to :seccion => :inicio, :controller => :tarea
      return false
    end

    UserInfo.current_user = @usuario_identificado 
  end

  # Autoriza solo para el administrador o presenta el mensaje de derecho insuficiente
  def autorizar_admin
      autorizado = @usuario_identificado.administracion
      dibuja_derecho_insuficiente unless autorizado
      return autorizado
  end

  # Autoriza solo al administrador o al rol especifico del agente
  def autorizar_admin_o_rol_agente
    autorizar_rol if @agente
    autorizar_admin unless @agente
  end

  # Autoriza el rol o presenta el mensaje de derecho insuficiente
  def autorizar_rol
    # Si no está autorizado, devuelve error
    if @proyecto || @agente
      # Nuevo metodo... dejamos trazas de ambos
      autorizado = comprobar_permisos_rol
      dibuja_derecho_insuficiente unless autorizado
      return autorizado
    end
  end

  # Comprueba si el usuario dispone del rol necesario para la accion solicitada
  def comprobar_permisos_rol
    # Comprobamos si lo que se quiere es modificar segun el nombre de la accion
    queremos_modificar = params[:action] =~ /^(anadir|nuevo|editar|modificar|crear|eliminar)/
    # Y establecemos el permiso buscado
    filtro_permisos = queremos_modificar ? {cambiar: true} : {ver: true}
    filtro_permisos[:menu] = params[:menu]
    filtro_permisos[:controlador] = params[:controller]
    # Obtiene los roles en el proyecto o en el agente
    permisos = PermisoXRol.joins(rol: :usuario_x_proyecto).where("rol.seccion" == params[:seccion]).
                           where("usuario_x_proyecto.usuario_id" => @usuario_identificado.id, "usuario_x_proyecto.proyecto_id" => @proyecto.id).
                           where(filtro_permisos) if @proyecto
    permisos = PermisoXRol.joins(rol: :usuario_x_agente).where("rol.seccion" == params[:seccion]).
                           where("usuario_x_agente.usuario_id" => @usuario_identificado.id, "usuario_x_agente.agente_id" => @agente.id).
                           where(filtro_permisos) if @agente
    #logger.info "--AUTORIZACION--> Permiso %s (nuevo) garantizado por %s"%[(queremos_modificar ? "escritura" : "lectura"), permisos.inspect] unless permisos.empty?
    logger.info "--AUTORIZACION--> Permiso %s (nuevo) denegado"%[(queremos_modificar ? "escritura" : "lectura")] if permisos.empty?
    return !permisos.empty? 
  end

  # Revisar para que se usa esto
  def obtener_usuario
    puts "-------------> Obteniendo usuario!!!!"
  end

  # Metodo al que invoca este mismo controlador, asi como el application controller de los plugins para dibujar
  # en pantalla que no se tienen los derechos necesarios para la accion
  def dibuja_derecho_insuficiente
    if request.xhr?
      render :update do |page|
        page.mensaje_cambio "mensaje_cabecera_2", :errors => _("No tiene permisos suficientes para realizar esta acción.")
        page.replace_html "MB_content", :partial => "comunes/derecho_insuficiente"
        page.call("Modalbox.resizeToContent")
      end
    else
      render "comunes/derecho_insuficiente"
    end
  end



  #--
  # Inicializaciones de la peticion
  #++

  # Cada peticion se mira el idioma de la session del usuario y se configura el locale.
  def configurar_idioma
    if session[:idioma_seleccionado].nil? or session[:idioma_seleccionado] == ""
      #set_locale "es_ES"
      FastGettext.locale = I18n.locale = ENV['LANG']||'es_ES'
    else
      #set_locale session[:idioma_seleccionado]
      FastGettext.locale = I18n.locale = session[:idioma_seleccionado]
    end
  end

  def por_pagina
   session[:por_pagina] = params[:por_pagina] if params[:por_pagina]
  end

  # Metodo general para representar al final del layout cuando se esta en modo development el tiempo total de una peticion.
  def tiempo_comienzo
    @tiempo_comienzo = Time.now
  end


  #--
  # MENSAJES
  #++

  def msg objeto, otros={}
    cadena = nil
    if objeto.class == String
      cadena = objeto.to_s
    elsif objeto.class == Array
      cadena = "<ul>" + objeto.inject("") {|suma, e | suma + "<li>" + e + "</li>"} + "</ul>"
    elsif objeto.methods.include?(:errors)
      if objeto.errors.empty?
        otros[:ok] = true
        cadena = _("Los datos se han guardado correctamente.") unless otros[:eliminar]
        cadena = _("Se ha eliminado correctamente.") if otros[:eliminar]
      else
        otros[:error] = true
        cadena = _("Se han producido errores.") + "<br>"
        objeto.errors.each {|a, m| cadena << m + "<br>" }
      end 
    end
    if cadena
      if otros[:now]
        flash.now[:mensaje_error] = (flash[:mensaje_error] ? flash[:mensaje_error] + "<br>" : "") + cadena if otros[:error]
        flash.now[:mensaje_ok] = (flash[:mensaje_ok] ? flash[:mensaje_ok] + "<br>" : "") + cadena if otros[:ok]
        flash.now[:mensaje] = (flash[:mensaje] ? flash[:mensaje] + "<br>" : "") + cadena unless otros[:error] || otros[:ok]
      else
        flash[:mensaje_error] = cadena if otros[:error]
        flash[:mensaje_ok] = cadena if otros[:ok]
        flash[:mensaje] = cadena unless otros[:error] || otros[:ok]
      end
    end
  end

  # dibuja el mensaje de error o de exito
  def msg_error mensaje, otros={}
    otros[:error] = true 
    msg mensaje, otros 
  end

  # dibuja el mensaje de error o de exito al eliminar un objeto
  def msg_eliminar objeto
    msg objeto, :eliminar => true
  end


  #--
  # Transformaciones de elementos
  # FIXME: Esto habria que hacerlo a traves del uso de los locales
  #++

  # Conversiones entre formatos de moneda accesibles desde todos los controladores
  # Esto deberiamos hacerlo asi: view_context.float_a_moneda(numero)
  def float_a_moneda numero 
    #number_with_delimiter(('%.2f' % numero).to_s , :separator => ",", :delimiter => ".") if numero
    ('%.2f' % numero).to_s.sub(".",",") if numero
  end

  def moneda_a_float cadena
    if cadena
      # Eliminamos los espacios iniciales y finales de la cadena
      cadena.strip!
      # primero comprobamos que el punto corresponde a miles ( formato => n.nnn )
      # y solo en ese caso lo eliminamos => Permitimos especificar decimales con punto
      numero = (cadena =~ /[\d]+\.[\d]{3}/) ? cadena.delete(".") : cadena
      # Si se esta usando la coma decimal, la cambiamos por un punto ( formato => n,nn o n,n )
      # REVISAR: Esto permite que haya coma para miles, pero impide que metan mas de 2 decimales con coma
      numero = numero.sub(/,/,".") if numero =~ /[\d]+,[\d]{1,2}$/
      return numero.to_f
    end
  end

  # Este metodo general esta aqui para que los controladores puedan crear objetos fechas desde parametros del date_select
  # FIXME: Parece algo tonto pero no consigo resolverlo de otra forma
  def fecha parametros
    if parametros["(1i)"] && parametros["(2i)"] && parametros["(3i)"]
      begin
        resultado = Date.new parametros["(1i)"].to_i, parametros["(2i)"].to_i, parametros["(3i)"].to_i
      rescue
        resultado =  Date.new parametros["(1i)"].to_i, parametros["(2i)"].to_i, 1
      end
    else
      resultado = Date.today
    end

    return resultado
  end


  #--
  # Batiburrillo
  #++

  # Devuelve el nombre de la seccion en singular
  def singularizar_seccion
    params[:seccion].gsub(/(.*)(s)/) {$1.gsub(/one/, "on")}
  end

  # Este metodo devuelve la entidad dentro de la seccion con la que estamos trabajando. 
  # En el caso de la seccion proyectos pone en @proyecto el proyecto con el que estamos trabajando
  # En el caso de la seccion agentes pone en @agente el agente con el que estamos trabajando
  def objeto_seccion
    case params[:seccion]
    when "proyectos" then
      # Hacemos este apaño por causa de la subida de imagenes en tiny_mce (donde viaja el proyecto_id en params[:hint])
      params[:proyecto_id] ||= params[:hint] if params[:hint]
      @proyecto = Proyecto.find_by_id(params[:proyecto_id]) if params[:proyecto_id]
      # Para evitar errores si el proyecto ya no existe en BBDD
      if @proyecto.nil? && params[:proyecto_id]
        redirect_to main_app.proyectos_path
        return false
      end
      if @proyecto
        @permitir_configuracion = ( @proyecto.definicion_estado.nil? || !@proyecto.definicion_estado.cerrado ) && params[:menu] == "configuracion"
        @permitir_identificacion = @proyecto.definicion_estado && !@proyecto.definicion_estado.cerrado && @proyecto.definicion_estado.formulacion && params[:menu] == "identificacion"
        @permitir_formulacion = @proyecto.definicion_estado && !@proyecto.definicion_estado.cerrado && @proyecto.definicion_estado.formulacion && params[:menu] == "formulacion"
        @permitir_ejecucion = @proyecto.definicion_estado && !@proyecto.definicion_estado.cerrado && @proyecto.definicion_estado.ejecucion && params[:menu] =~ /^ejecucion_/
      end
    when "agentes" then
      @agente = Agente.find_by_id(params[:agente_id])
      # Para evitar errores si el agente ya no existe en BBDD
      if @agente.nil? && params[:agente_id]
        redirect_to main_app.agentes_path
        return false
      end
    end
  end

  # Devuelve los pares "clave: valor" generales para la generacion de plantillas
  def campos_plantilla
    {
      "usuario.nombre" => @usuario_identificado.nombre_completo,
      "usuario.uid" => @usuario_identificado.nombre,
      "usuario.mail" => @usuario_identificado.correoe,
      "fecha_actual" => I18n.l(Date.today),
      "fecha_actual.texto" => I18n.l(Date.today, format: :long)
    }
  end

  # Cambia el formato de respuesta cuando se pide un XLS
  def xls_request
    request.format = :xls if (params[:selector] && (params[:selector][:salida] == 'fichero' || params[:selector][:fichero] == '1')) || params[:fichero] == "1"
    request.format = :docx if params[:selector] && params[:selector][:docx] == '1'
  end

  # Para usar en exportaciones a XLS
  def xls_filename
    params[:seccion] + "-" + params[:controller] + "-" + params[:action] + ".xls"
  end

  # Comprobamos que se han creado por lo menos un periodo de justificación final para el proyecto.
  def comprobar_periodo_identificador_financiador
    mensaje = ""
    if @proyecto and @proyecto.estado_actual and @proyecto.estado_actual.definicion_estado.reporte and params[:controller]
      # Evitamos alerta de periodo de justificacion final para PACs
      if @proyecto.periodo.where("tipo_periodo_id = 1").empty? && @proyecto.convenio_id.nil?
        mensaje += _("El proyecto no tiene un periodo de justificación del informe final. Compruebe los periodos de justificación del proyecto.")
      end
    end
    if @proyecto and @proyecto.estado_actual and @proyecto.estado_actual.definicion_estado.reporte and @proyecto.identificador_financiador.empty?
        mensaje += "<br>".html_safe unless mensaje.empty?
        mensaje += _("El proyecto esta aprobado y no tiene el codigo identificador de financiador. Compruebe las relaciones en configuración de proyecto.")
    end
    msg_error mensaje, :now => true unless mensaje.empty?
  end

end
