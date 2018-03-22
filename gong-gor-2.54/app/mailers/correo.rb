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

class Correo < ActionMailer::Base
  if self.included_modules.include?(AbstractController::Callbacks)
    raise "You've already included AbstractController::Callbacks, remove this line."
  else
    include AbstractController::Callbacks
  end

  before_filter :add_inline_attachments!

  # FROM = "gong.development@gmail.com"
  default from: (GorConfig.getValue("EMAIL_FROM")||"no-reply@gong.org.es")

  INSTANCIA = GorConfig.getValue("APP_NAME")||"GONG"

  # es llamado por EstadoController::cambio_estado para generar el mail de notificación
  def cambio_estado(host, usuario, tipo, objeto, estado)
    @host = host
    @usuario = usuario
    @proyecto = objeto 
    @estado = estado
    # Solo notifica si el objeto no es un proyecto, o siendolo permitimos notificaciones suyas
    if ( objeto.class.name != "Proyecto" || (@usuario.usuario_x_proyecto.find_by_proyecto_id(objeto.id) && @usuario.usuario_x_proyecto.find_by_proyecto_id(objeto.id).notificar_estado) )
      variables_comentario("", host, nil, objeto)
      mail :to => "#{usuario.nombre_completo} <#{usuario.correoe}>", :subject => "[#{INSTANCIA}] %s: "%[objeto.nombre] + _("Cambio de estado") 
    end
  end

  def cambio_tarea(host, usuario, tarea)
    @usuario = usuario
    @tarea = tarea
    objeto = @tarea.proyecto || @tarea.agente
    texto_subject  = "[#{INSTANCIA}] "
    texto_subject += (objeto.nombre + ": ") if objeto
    texto_subject += _("Noficación de Tarea")
    variables_comentario("Tarea", host, tarea, objeto)
    mail :to => "#{usuario.nombre_completo} <#{usuario.correoe}>", :subject => texto_subject 
  end

  def nuevo_comentario(host, usuario, tipo, objeto, objeto_relacionado, comentario)
    #puts "----> Recibimos tipo: " + tipo.inspect + " objeto: " + objeto.inspect + " objeto_relacionado: " + objeto_relacionado.inspect + " comentario: " + comentario.inspect
    @usuario = usuario
    @objeto = objeto 
    @objeto_relacionado = objeto_relacionado
    @comentario = comentario 
    # Solo notifica si el objeto no es un proyecto, o siendolo permitimos notificaciones suyas
    if ( objeto.class.name != "Proyecto" || (@usuario.usuario_x_proyecto.find_by_proyecto_id(objeto.id) && @usuario.usuario_x_proyecto.find_by_proyecto_id(objeto.id).notificar_comentario) )
      variables_comentario(tipo, host, objeto, objeto_relacionado)
      mail :to => "#{usuario.nombre_completo} <#{usuario.correoe}>", :subject => "[#{INSTANCIA}] " + (objeto ? objeto.nombre + ": " : "") + _("Nuevo Comentario en") + " " + _(objeto_relacionado.class.name)
    end
  end

  def nuevo_proyecto(host, usuario, proyecto, creador)
    @usuario = usuario
    @creador = creador
    @objeto = proyecto
    variables_comentario("", host, proyecto, proyecto)
    mail :to => "#{usuario.nombre_completo} <#{usuario.correoe}>", :subject => "[#{INSTANCIA}] " + _("Nuevo proyecto creado")
  end

  def asignar_usuario(host, usuario, usuario_asignado, rol, objeto)
    @usuario = usuario
    @usuario_asignado = usuario_asignado
    @objeto = objeto
    @objeto_nombre = objeto.nombre unless objeto.class.name == "Espacio"
    @objeto_nombre = objeto.ruta + " / " + objeto.nombre if objeto.class.name == "Espacio"
    # Solo notifica si el objeto no es un proyecto, o siendolo permitimos notificaciones suyas
    if ( objeto.class.name != "Proyecto" || (@usuario.usuario_x_proyecto.find_by_proyecto_id(objeto.id) && @usuario.usuario_x_proyecto.find_by_proyecto_id(objeto.id).notificar_usuario) )
      variables_comentario("", host, usuario, objeto)
      subject = _("Usuario asignado al") + " " + _(objeto.class.name.capitalize) + ": " + objeto.nombre 
      mail :to => "#{usuario.nombre_completo} <#{usuario.correoe}>", :subject => "[#{INSTANCIA}] %s: "%[objeto.nombre] + _("Usuario asignado") 
    end
  end

  def registro (host, destinatario, registro, nombre_usuario, contraseña)
    @registro, @nombre_usuario, @contrasena = registro, nombre_usuario, contraseña 
    @url = host
    mail :to => destinatario, :subject => "[#{INSTANCIA}] " + _("Bienvenido a la demo de GONG")
  end

  # Envio de correo de proxima finalizacion de una tarea general
  def finalizacion_tarea usuario, tarea
    @tarea = tarea
    @usuario = usuario
    @url = { host: GorConfig.getValue("URL_HOST"), protocol: GorConfig.getValue("URL_PROTOCOL"), only_path: false }
    elemento = tarea.proyecto || tarea.agente
    @texto_url = elemento ? elemento.nombre : (tarea.tipo_tarea ? tarea.tipo_tarea.nombre : tarea.titulo)
    subject = "[#{INSTANCIA}][Tarea] " + @texto_url + ": " + _("Próximo fin de %s")%[tarea.titulo]
    logger.info "=========== Enviando mail de aviso de tarea '#{tarea.titulo}' a '#{usuario.nombre_completo}'"
    mail to: "#{usuario.nombre_completo} <#{usuario.correoe}>", subject: subject
  end

  # Envio de correo de proxima finalizacion de una tarea del workflow
  def finalizacion_tarea_workflow usuario, tarea
    @tarea = tarea
    @usuario = usuario
    @url = { host: GorConfig.getValue("URL_HOST"), protocol: GorConfig.getValue("URL_PROTOCOL"), only_path: false,
             seccion: "proyectos", menu: "resumen", controller: "info", proyecto_id: tarea.proyecto_id }
    @texto_url = tarea.proyecto.nombre
    subject = "[#{INSTANCIA}][AVISO] " + @texto_url + ": " + _("Próximo fin de %s")%[tarea.titulo]

    # Calucula los porcentajes de ejecucion economica y de actividades
    presupuesto_total = @tarea.proyecto.presupuesto_total
    @porcentaje_economico = (presupuesto_total.blank? || presupuesto_total == 0.0) ? "N/A" : (100 * (@tarea.proyecto.gasto_total_sin_financiador||0.0) / presupuesto_total).round.to_s + " %"
    activ_total = @tarea.proyecto.actividad.count
    activ_valor = @tarea.proyecto.actividad.sum do |a|
      vixa = ValorIntermedioXActividad.joins(:actividad_x_etapa).
                                       where("actividad_x_etapa.actividad_id" => a.id).
                                       order("valor_intermedio_x_actividad.fecha").last
      vixa ? vixa.porcentaje||0.0 : 0.0
    end
    @porcentaje_actividad = activ_total == 0 ? "N/A" : (100 * activ_valor / activ_total).round.to_s + " %"

    # Envia el correo al usuario
    logger.info "=========== Enviando mail de aviso de tarea de workflow '#{tarea.titulo}' a '#{usuario.nombre_completo}'"
    mail to: "#{usuario.nombre_completo} <#{usuario.correoe}>", subject: subject
  end


 private
  def variables_comentario tipo, host, objeto, objeto_relacionado
    url = {:seccion => tipo, :host => host, :only_path => false}
    if tipo == "proyectos"
      estado_proyecto = (objeto.estado_actual.definicion_estado.formulacion ? "formulacion" : "ejecucion_tecnica") if objeto.estado_actual
      url[:proyecto_id] = objeto.id
      case objeto_relacionado.class.name
        when "Presupuesto"
          url[:menu] = "formulacion"
          url[:controller] = "presupuesto_proyectos"
          descripcion = objeto_relacionado.concepto
        when "Gasto"
          url[:menu] = "ejecucion_economica"
          url[:controller] = "gasto_proyectos"
          descripcion = "#{I18n.l objeto_relacionado.fecha} (#{objeto_relacionado.importe} #{objeto_relacionado.moneda.abreviatura}): #{objeto_relacionado.concepto}"
        when "Contrato"
          url[:menu] = "ejecucion_economica"
          url[:controller] = "contrato"
          descripcion = objeto_relacionado.nombre + (objeto_relacionado.codigo ? " (COD:" + objeto_relacionado.codigo + ")" : "")
        when "Tarea"
          url[:menu] = "resumen"
          url[:controller] = "tarea"
          descripcion = objeto_relacionado.titulo
        when "Documento"
          url[:menu] = "documentos_proyecto"
          url[:controller] = "documento"
          descripcion = objeto_relacionado.adjunto_file_name
        when "Actividad"
          url[:menu] = estado_proyecto
          url[:controller] = "actividad"
          descripcion = objeto_relacionado.codigo
        when "Subactividad"
          url[:menu] = estado_proyecto
          url[:controller] = "actividad"
          descripcion = objeto_relacionado.descripcion
        when "Indicador"
          url[:menu] = estado_proyecto
          url[:controller] = "indicador"
          descripcion = objeto_relacionado.codigo
        when "FuenteVerificacion"
          url[:menu] = estado_proyecto
          url[:controller] = "fuente_verificacion"
          descripcion = objeto_relacionado.codigo
        when "ObjetivoEspecifico"
          url[:menu] = estado_proyecto
          url[:controller] = "matriz"
          descripcion = objeto_relacionado.codigo + " " + objeto_relacionado.descripcion
        when "Resultado"
          url[:menu] = estado_proyecto
          url[:controller] = "matriz"
          descripcion = objeto_relacionado.codigo + " " + objeto_relacionado.descripcion
      end
    elsif tipo == "agentes"
      url[:agente_id] = objeto.id
      case objeto_relacionado.class.name
        when "Presupuesto"
          url[:menu] = "economico_agente"
          url[:controller] = "presupuesto_agentes"
          descripcion = objeto_relacionado.concepto + (objeto_relacionado.etapa ? " (" + objeto_relacionado.etapa.nombre + ")" : "")
        when "PresupuestoIngreso"
          url[:menu] = "economico_agente"
          url[:controller] = "presupuesto_ingresos"
          descripcion = objeto_relacionado.partida_ingreso.nombre + ": " + objeto_relacionado.concepto + " (" + objeto_relacionado.etapa.nombre + ")"
        when "Gasto"
          url[:menu] = "economico_agente"
          url[:controller] = "gasto_agentes"
          descripcion = "#{I18n.l objeto_relacionado.fecha} (#{objeto_relacionado.importe} #{objeto_relacionado.moneda.abreviatura}): #{objeto_relacionado.concepto}"
        when "Ingreso"
          url[:menu] = "economico_agente"
          url[:controller] = "ingreso"
          descripcion = "#{I18n.l objeto_relacionado.fecha} (#{objeto_relacionado.importe} #{objeto_relacionado.moneda.abreviatura}): #{objeto_relacionado.concepto}"
        when "Contrato"
          url[:menu] = "economico_agente"
          url[:controller] = "contrato"
          descripcion = objeto_relacionado.nombre + (objeto_relacionado.codigo ? " (COD:" + objeto_relacionado.codigo + ")" : "")
        when "Tarea"
          url[:menu] = "resumen_agente"
          url[:controller] = "tarea"
          descripcion = objeto_relacionado.titulo
        when "Documento"
          url[:menu] = "documentos_agente"
          url[:controller] = "documento"
          descripcion = objeto_relacionado.adjunto_file_name
        else
          url[:menu] = "resumen_agente"
          url[:controller] = "info"
          descripcion = objeto.nombre
      end
    elsif tipo == "Tarea"
      case objeto_relacionado.class.name
        when "Proyecto"
          url[:seccion] = "proyectos"
          url[:menu] = "resumen"
          url[:controller] = "tarea"
          url[:proyecto_id] = objeto_relacionado.id
          descripcion = objeto_relacionado.nombre
        when "Agente"
          url[:seccion] = "agentes"
          url[:menu] = "resumen_agente"
          url[:controller] = :tarea
          url[:agente_id] = objeto_relacionado.id
          descripcion = objeto_relacionado.nombre
        else
          url[:seccion] = "inicio"
          url[:controller] = :tarea
          descripcion = "Gong" 
      end
    else
      case objeto_relacionado.class.name
        when "Proyecto"
          url[:seccion] = "proyectos"
          url[:menu] = "resumen"
          url[:controller] = :info
          url[:proyecto_id] = objeto_relacionado.id
          descripcion = objeto_relacionado.nombre
        when "Agente"
          url[:seccion] = "agentes"
          url[:menu] = "resumen_agente"
          url[:controller] = :tarea
          url[:agente_id] = objeto_relacionado.id
          descripcion = objeto_relacionado.nombre
        when "Tarea"
          url[:seccion] = "inicio"
          url[:controller] = :tarea
          descripcion = objeto_relacionado.titulo
        else
          url[:seccion] = "inicio"
          url[:controller] = "info"
          descripcion = "Gong"
      end
    end
    @url = url
    @texto_url = descripcion
  end

 private
  def add_inline_attachments!
    attachments.inline['logo_gong_boletin.jpg'] = File.read('app/assets/images/logo_gong_boletin.jpg')
    attachments.inline['cabecera_boletin.jpg'] = File.read('app/assets/images/cabecera_boletin.jpg')
    attachments.inline['logo_gong_pie.jpg'] = File.read('app/assets/images/logo_gong_pie.jpg')
    attachments.inline['licencia_creativecommons.jpg'] = File.read('app/assets/images/licencia_creativecommons.jpg')
  end
end
