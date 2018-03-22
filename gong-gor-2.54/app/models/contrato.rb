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
# definición de contratos 

class Contrato < ActiveRecord::Base

  before_destroy :comprobar_etapas
  before_destroy :verificar_borrado

  belongs_to :agente
  belongs_to :proyecto
  belongs_to :proveedor
  belongs_to :moneda
  belongs_to :tipo_contrato
  has_many :campo_tipo_contrato, through: :tipo_contrato
  has_many :periodo_contrato, order: :fecha_inicio, dependent: :destroy
  has_many :estado_contrato, dependent: :destroy, include: :workflow_contrato
  has_many :version_contrato, dependent: :destroy
  has_one  :estado_actual, class_name: "EstadoContrato", foreign_key: "contrato_id", conditions: ["estado_contrato.estado_actual"]
  has_one  :workflow_contrato, through: :estado_actual
  has_many :contrato_x_documento, through: :estado_contrato
  has_many :documento, through: :contrato_x_documento

  has_many :contrato_x_financiador, dependent: :destroy
  has_many :financiador, through: :contrato_x_financiador, source: :agente, order: "nombre"

  has_many :contrato_x_campo_tipo_contrato, dependent: :destroy

  has_many :gasto_x_contrato, dependent: :destroy
  has_many :gasto, through: :gasto_x_contrato

  has_many :item_contrato, dependent: :destroy
  has_many :contrato_x_actividad, dependent: :destroy
  has_many :actividad, through: :contrato_x_actividad, order: "actividad.codigo"

  # Auditado de modificaciones, comentarios y marcado
  include ::Auditable
  has_many :comentario, as: :elemento, dependent: :destroy
  belongs_to :marcado

  validates_uniqueness_of :codigo, allow_blank: true, message: _("Código repetido.")
  validates_associated :tipo_contrato, message: _("El tipo de contrato asociado no es válido.")
  validates_associated :agente, message: _("El agente implementador no es válido.")
  validates_associated :moneda, message: _("La moneda del contrato no es válida.")
  validates_presence_of :nombre, message: _("Nombre") + " " + _("no puede estar vacío.")
  validates_presence_of :agente_id, message: _("Implementador") + " " + _("no puede estar vacío.")
  validates_presence_of :moneda_id, message: _("Moneda") + " " + _("no puede estar vacío.")
  validates_presence_of :importe, :message => _("Importe") + " " + _("no puede estar vacío.")
  validates_format_of :fecha_inicio, with: /\d{4}-\d{1,2}-\d{1,2}/
  validates_format_of :fecha_fin, with: /\d{4}-\d{1,2}-\d{1,2}/
  validate :comprobar_fechas
  validate :comprobar_etapas
  validate :comprobar_estado

  # Asigna el estado inicial a un contrato recien creado
  after_create :asignar_estado_inicial
  # Revisa si es necesario generar versiones del contrato
  after_save :generar_version_contrato

  # No lo guardaremos tal cual, sino en el contraol de versiones
  attr_accessor :observaciones_cambio

  # Devuelve si el contrato esta en metaestado formulacion
  def formulacion?
    self.workflow_contrato && self.workflow_contrato.formulacion
  end

  # Devuelve si el contrato esta en metaestado formulacion
  def ejecucion?
    self.workflow_contrato && self.workflow_contrato.ejecucion
  end

  # Devuelve si el contrato esta en metaestado aprobado
  def aprobado?
    self.workflow_contrato && self.workflow_contrato.aprobado
  end

  # Devuelve si el contrato esta en metaestado cerrado
  def cerrado?
    self.workflow_contrato && self.workflow_contrato.cerrado
  end

  # Devuelve nombre (descripción) para uso de plantillas de exportación
  def nombre_descripcion
    self.nombre + ( self.descripcion.blank? ? "" : " (" + self.descripcion + ")" )
  end

  # Devuelve la fecha en la que el contrato fue aprobado inicialmente
  def fecha_aprobado
    primero = estado_contrato.joins(:workflow_contrato).where("workflow_contrato.aprobado" => true).first
    primero ? primero.fecha_inicio : nil
  end

  # Devuelve el importe en moneda de justificacion del elemento indicado usando el presupuesto detallado del contrato
  def presupuesto_con_tc_proyecto 
    total = 0.0
  end
  def presupuesto_con_tc_agente
    total = 0.0
  end
 
  # Actualiza los datos particulares vinculados al tipo de contrato
  def actualizar_datos_tipo_contrato listado
    anteriores = contrato_x_campo_tipo_contrato.collect{|c| c.campo_tipo_contrato_id.to_s }
    # Recorre todos los campos enviados
    listado ||= {}
    listado.each do |k,v|
      campo = contrato_x_campo_tipo_contrato.find_by_campo_tipo_contrato_id(k) || contrato_x_campo_tipo_contrato.new(campo_tipo_contrato_id: k)
      campo.update_attribute( :valor_dato, v )
      errors.add( :base, _("Error actualizando datos particulares") + ": " + campo.errors.inspect) unless campo.errors.empty?
    end
    # Y elimina los que sobren si no ha habido errores (esto es por si ha cambiado el tipo de contrato
    if self.errors.empty?
      (anteriores - listado.keys.collect{|c| c.to_s}).each do |c|
        cxc = contrato_x_campo_tipo_contrato.find_by_campo_tipo_contrato_id c
        cxc.destroy if cxc
      end
    end 
  end

  # Devuelve si el contrato esta involucrando a todas las actividades del proyecto
  # (metemos un parametro de entrada, que en realidad no se usa, solo por compatibilidad de metodos)
  def todas_actividades? proy=nil
    return proy ? (contrato_x_actividad.size == proy.actividad.size) : false 
  end

  # Divide por igual entre las actividades elegidas
  def dividir_por_actividades actividades
    unless actividades.size == 0
      detalle = Hash.new
      importe_x_actividad, resto_importe = importe.divmod(actividades.size)
      for actividad in actividades
        if actividad.class.name == "Actividad"
          if actividad == actividades.last
            importe_x_actividad += resto_importe
          end
          detalle[actividad.id] = { "importe_convertido" => importe_x_actividad, "actividad_id" => actividad.id }
        end
      end
      actualizar_contrato_x_actividad detalle
    end
  end

  # Actualiza el listado de actividades con los que se ha asociado el contrato para un determinado proyecto.
  def actualizar_contrato_x_actividad listado
    # Hay que averiguar si estamos modificando las actividades
    existentes = contrato_x_actividad
    modificar = (existentes.size != listado.size)
    listado.each do |k,v|
      existente = existentes.find_by_actividad_id v["actividad_id"]
      modificar = true if existente.nil? || existente.importe_convertido.to_s != v["importe_convertido"].to_s
    end unless modificar

    # Cuando queremos modificar las actividades y estamos en formulacion o aun no tenemos estado definido...
    if modificar && (self.formulacion? || self.workflow_contrato.nil?)
      # Pendiente: gestionar estos cambios sin borrar/crear todo, solo con modificaciones...
      # (si se modifica en lugar de borrar/crear, revisar la validacion de importe por actividad
      #  en el modelo contrato_x_actividad para evitar que se dupliquen imputaciones)
      ContratoXActividad.transaction do
        contrato_x_actividad.clear
        listado.each do |key, value|
          if value["actividad_id"] && !value["actividad_id"].blank?
            value.delete("proyecto_id")
            cxa = contrato_x_actividad.create(value)
            errors.add("", cxa.errors.inject('') {|total, e| total + e[1] + " " }) unless cxa.errors.empty?
          end
        end
        # Si ha habido algun error creando actividades en el contrato, hace un rollback y no guardamos los cambios
        raise(ActiveRecord::Rollback, "Hacemos un rollback") unless errors.empty?
        # Actualiza info de marcado si no ha habido errores
        comentario << Comentario.create( usuario_id: UserInfo.current_user.id, texto: _("Actividades modificadas") ) if errors.empty?
        # Revisa que coincida el importe total con la suma por actividades
        if  listado.inject(0) {|suma, value| suma + moneda_a_float(value.pop["importe_convertido"])} != self.importe
          errors.add(:base, _("Los importes de las actividades no suman el importe total del contrato."))
        end
      end
    else
      errors.add(:base, _("El estado del contrato no permite la modificación de las actividades.")) if modificar
    end
  end

  # Actualiza el listado de financiadores con los enviados desde el formulario
  def actualizar_contrato_x_financiador listado
    items = []
    # Se queda solo con los items que tienen algo de chicha
    listado.each{|k,v| items.push(v) unless v["importe_convertido"].blank?}
    # Primero se carga los financiadores que ya no existen
    items_borrar = financiador_ids - items.collect{|v| v["agente_id"].to_i}
    ContratoXFinanciador.destroy_all(contrato_id: self.id, agente_id: items_borrar)
    # Luego modifica o crea el resto
    items.each do |item_data|
      item = contrato_x_financiador.find_by_agente_id(item_data["agente_id"]) || ContratoXFinanciador.new(contrato_id: self.id)
      item.update_attributes(item_data)
      errors.add(:base, _("Errores actualizando financiador del contrato.") + " " + item.errors.messages.collect{|k,m| m}.join(" ") ) unless item.errors.empty?
    end
  end

  # Actualiza el listado de items con los enviados desde el formulario
  def actualizar_contrato_x_items listado
    items = [] 
    # Se queda solo con los items que tienen algo de chicha
    listado.each{|k,v| items.push(v) unless v["nombre"].blank? || v["cantidad"].blank? || v["coste_unitario_convertido"].blank?}
    # Primero se carga los items que ya no existen
    items_borrar = item_contrato_ids - items.collect{|v| v["id"].to_i} 
    ItemContrato.destroy_all(contrato_id: self.id, id: items_borrar)
    # Luego modifica o crea el resto
    items.each do |item_data|
      item = item_contrato.find_by_id(item_data.delete("id")) || ItemContrato.new(contrato_id: self.id)
      item.update_attributes(item_data)
      errors.add(:base, _("Errores actualizando item de contrato.") + " " + item.errors.messages.collect{|k,m| m}.join(" ") ) unless item.errors.empty?
    end
  end

  # Actualiza el listado de periodos con los enviados desde el formulario
  def actualizar_contrato_x_periodos listado
    periodos = []
    # Se queda solo con los items que tienen algo de chicha
    listado.each{|k,v| periodos.push(v) unless v["fecha_inicio"].blank? || v["fecha_fin"].blank? || v["importe_convertido"].blank?}
    # Primero se carga los periodos que ya no existen
    periodos_borrar = periodo_contrato_ids - periodos.collect{|v| v["id"].to_i}
    PeriodoContrato.destroy_all(contrato_id: self.id, id: periodos_borrar)
    # Luego modifica o crea el resto
    periodos.each do |periodo_data|
      periodo = periodo_contrato.find_by_id(periodo_data.delete("id")) || PeriodoContrato.new(contrato_id: self.id)
      periodo.update_attributes(periodo_data)
      errors.add(:base, _("Errores actualizando periodo de contrato.") + periodo.errors.messages.collect{|k,m| m}.join(" ") ) unless periodo.errors.empty?
    end
    if errors.empty? && periodo_contrato.count > 0 && periodo_contrato.sum(:importe) != importe
      errors.add(:base, _("Los importes de los periodos no suman el importe total del contrato."))
    end
  end

  # Devuelve un array con los importes por actividad con su codigo
  def importes_por_actividades
    contrato_x_actividad.joins(:actividad).order("actividad.codigo").collect {|cxa| cxa.actividad.codigo + ": " + cxa.importe_convertido + " " + moneda.abreviatura }
  end
  # Devuelve un array con los importes por actividad detallada
  def importes_por_actividades_detallado
    contrato_x_actividad.joins(:actividad).order("actividad.codigo").collect {|cxa| cxa.actividad.codigo_descripcion + ": " + cxa.importe_convertido + " " + moneda.abreviatura }
  end
  # Devuelve un array con los importes por financiador
  def importes_por_financiadores
    contrato_x_financiador.joins(:agente).order("agente.nombre").collect {|cxa| cxa.agente.nombre + ": " + cxa.importe_convertido + " " + moneda.abreviatura }
  end
  # Devuelve un array con los porcentajes por financiador
  def porcentajes_por_financiadores
    contrato_x_financiador.joins(:agente).order("agente.nombre").collect {|cxa| cxa.agente.nombre + ": " + (100 * cxa.importe / importe).to_i.to_s + "%" }
  end

  # Devuelve el total de importe ejecutado
  def importe_ejecutado
    gasto.sum(:importe)
  end
  def importe_ejecutado_convertido
    float_a_moneda importe_ejecutado
  end

  # Devuelve el total de importe ejecutado y pagado
  def importe_pagado
    gasto.joins(:pago).sum("pago.importe")
  end
  def importe_pagado_convertido
    float_a_moneda importe_pagado
  end

  # Valida que el total por actividades coincida con el total del contrato
  def comprobar_actividades
    proyecto ? contrato_x_actividad.inject(0) {|suma, f| suma + f.importe} == importe : true 
  end

  # Valida que el total por financiadores coincida con el total del contrato
  def comprobar_financiadores
    proyecto ? contrato_x_financiador.inject(0) {|suma, f| suma + f.importe} == importe : true
  end

  # Valida que el total por periodos coincida con el total del contrato
  def comprobar_periodos
    periodo_contrato.inject(0) {|suma,f| suma + f.importe} == importe
  end

  # Valida que el total por items coincida con el total del contrato
  def comprobar_items
    item_contrato.inject(0) {|suma,f| suma + (f.cantidad * f.coste_unitario)} == importe
  end

  # Valida que se cumplan las condiciones particulares segun tipo de contrato
  def comprobar_condiciones_tipo_contrato
    # Recorre todos los campos posibles segun el tipo de contrato
    tipo_contrato.campo_tipo_contrato.each do |campo|
      sin_errores = campo.valida_valor( contrato_x_campo_tipo_contrato.find_by_campo_tipo_contrato_id(campo.id) )
      errors.add :base, _("No se cumple la condición '%{condicion}'.")%{condicion: campo.etiqueta} unless sin_errores 
    end if tipo_contrato
    return errors.empty? 
  end

  # Devuelve los pares "clave: valor" a incluir en plantillas
  def campos_plantilla
    campos = {
        "contrato.codigo" => codigo,
        "contrato.nombre" => nombre,
        "contrato.descripcion" => descripcion,
        "contrato.observaciones" => observaciones,
        "contrato.nombre_descripcion" => nombre + ( descripcion.blank? ? "" : " (" + descripcion + ")" ),
        "contrato.fecha_inicio" => I18n.l(fecha_inicio),
        "contrato.fecha_fin" => I18n.l(fecha_fin),
        "contrato.fecha_inicio.texto" => I18n.l(fecha_inicio, format: :long),
        "contrato.fecha_fin.texto" => I18n.l(fecha_fin, format: :long),
        "contrato.importe" => importe_convertido,
        "contrato.importe.texto" => importe_convertido_texto,
        "contrato.importe_ejecutado" => importe_ejecutado_convertido,
        "contrato.importe_pagado" => importe_pagado_convertido,
        "contrato.moneda" => moneda.nombre,
        "contrato.mon" => moneda.abreviatura,
        "contrato.actividades" => importes_por_actividades.join(" - "),
        "contrato.actividades.detallado" => importes_por_actividades_detallado.join("; "),
        "contrato.financiadores" => importes_por_financiadores.join("; "),
        "contrato.financiadores.porcentaje" => porcentajes_por_financiadores.join("; "),
        "contrato.tipo_contrato" => (tipo_contrato ? tipo_contrato.nombre : ""),
        "proyecto.nombre" => (proyecto ? proyecto.nombre : ""),
        "proyecto.titulo" => (proyecto ? proyecto.titulo : ""),
        "agente.nombre" => agente.nombre,
        "agente.nombre_completo" => agente.nombre_completo,
        "agente.nif" => agente.nif,
        "agente.pais" => agente.pais.nombre,
        "proveedor.nombre" => proveedor ? proveedor.nombre : "_________________",
        "proveedor.nif" => proveedor ? proveedor.nif : "_________________",
        "proveedor.pais" => proveedor ? proveedor.pais.nombre : "_________________",
    }
    # Incluye miembros del agente por roles
    Rol.where(seccion: "agentes").each do |rol|
      campos["agente.rol." + rol.nombre.downcase] = agente.usuario.where("usuario_x_agente.rol_id" => rol.id).collect {|u| u.nombre_completo}.uniq.join(", ")
    end
    # Incluye miembros del proyecto por roles
    Rol.where(seccion: "proyectos").each do |rol|
      campos["proyecto.rol." + rol.nombre.downcase] = proyecto.usuario.where("usuario_x_proyecto.rol_id" => rol.id).collect {|u| u.nombre_completo}.uniq.join(", ")
    end if proyecto
    # Incluye los campos particulares del tipo de contrato
    campo_tipo_contrato.each do |campo|
      campos["contrato.tipo_contrato." + campo.nombre] = campo.etiqueta
      valor_campo = contrato_x_campo_tipo_contrato.find_by_campo_tipo_contrato_id(campo.id)
      campos["contrato.tipo_contrato." + campo.nombre + ".valor"] = valor_campo ? valor_campo.valor_adaptado : ""
    end
    return campos
  end

 private

  # Comprueba que el proyecto no este cerrado, ni la etapa del agente correspondiente
  def comprobar_etapas
    # Comprueba si el contrato esta en un proyecto cerrado
    errors.add(:base, _("El proyecto está cerrado.")) if proyecto && proyecto.definicion_estado && proyecto.definicion_estado.cerrado?
    # Comprueba si las etapas del agente estan cerradas
    agente.etapa.where(["(fecha_inicio <= ? AND fecha_fin >= ?) OR (fecha_inicio <= ? AND fecha_fin >= ?)", fecha_inicio, fecha_inicio, fecha_fin, fecha_fin]).each do |etapa|
      errors.add(:base, _("La etapa '%{etp}' del gestor está cerrada.")%{etp: etapa.nombre}) if etapa.cerrada
    end
    return errors.empty?
  end

  # Verifica que las fechas sean correctas
  def comprobar_fechas
    # Comprobamos que existan ambas y que siempre sea posterior al fin que al comienzo
    if self.fecha_inicio && self.fecha_fin && self.fecha_inicio <= self.fecha_fin
      # Cuando tratamos con un proyecto, comprobamos que las fechas esten dentro de sus etapas
      if proyecto
        if proyecto.fecha_de_inicio && proyecto.fecha_de_fin
          errors.add(:base, _("Las fechas están fuera de las etapas del proyecto.")) if self.fecha_inicio < proyecto.fecha_de_inicio || self.fecha_fin > proyecto.fecha_de_fin
        else 
          errors.add(:base, _("No hay etapas definidas en el proyecto."))
        end
      end
      # Comprobamos que no hayamos cambiado las fechas dejando fuera a pagos
      fechas_dentro = periodo_contrato.where("fecha_inicio < ? OR fecha_fin > ?", self.fecha_inicio, self.fecha_fin).empty?
      errors.add(:base, _("Las nuevas fechas dejan fuera algún periodo de ejecución del contrato")) unless fechas_dentro
    else
      errors.add(:base, _("Las fechas no pueden estar vacías.") ) unless self.fecha_inicio && self.fecha_fin
      errors.add("fecha_fin", _("Fecha fin tiene que ser mayor que fecha inicio.")) if self.fecha_inicio && self.fecha_fin && self.fecha_fin < self.fecha_inicio
    end
    return errors.empty?
  end

  # Verificaciones sobre el estado del contrato 
  def comprobar_estado
    # Si existe el proveedor y estamos en un estado aceptado, verifica que no haya otro contrato igual
    # Si el contrato esta aprobado
    workflow_contrato = estado_actual.workflow_contrato if estado_actual
    if workflow_contrato && workflow_contrato.aprobado
      errors.add(:base, _("Un contrato aceptado debe tener código.")) if codigo.blank?
      errors.add(:base, _("Un contrato aceptado debe tener proveedor.")) unless proveedor
      errors.add(:base, _("No está definido el tipo de contrato.")) unless tipo_contrato
      errors.add(:base, _("No existe financiación definida para el contrato.")) if proyecto && contrato_x_financiador.empty?
      # Mira si existe algun contrato similar aprobado para el mismo intervalo de fechas
      if proveedor
        # Si se solapan se cumple: (StartDate1 <= EndDate2) and (EndDate1 >= StartDate2)
        contratos = Contrato.where(agente_id: agente_id, proyecto_id: proyecto_id, proveedor_id: proveedor_id).
                             where("contrato.id != ?", self.id).
                             joins(estado_actual: :workflow_contrato).
                             where("workflow_contrato.primer_estado" => true).
                             where("contrato.fecha_inicio <= ? AND contrato.fecha_fin >= ?", self.fecha_inicio, self.fecha_fin)
        errors.add(:base, _("Ya existe un contrato abierto en el proyecto para el proveedor.")) unless contratos.empty?
      end
    end

    # Permite modificaciones solo si está en formulación y no está cerrado
    if self.changed? && (aprobado? || cerrado?)
      errors.add(:base, _("El contrato no está en un estado que permita su modificación.")) unless !cerrado? && (!aprobado? || formulacion?)
      errors.add(:base, _("El contrato está cerrado. No se puede modificar.")) if cerrado?
    end

    return errors.empty?
  end

  # Asigna el estado inicial a un contrato recien creado
  def asignar_estado_inicial
    estado = WorkflowContrato.find_by_primer_estado(true)
    user = UserInfo.current_user
    est = EstadoContrato.new contrato_id: self.id, workflow_contrato: estado, usuario: user, estado_actual: true, fecha_inicio: Date.today 
    # Si todo va ok, le asigna una version al contrato
    if est.valid?
      est.save
      VersionContrato.create(contrato_id: self.id, estado_contrato_id: est.id, importe: importe, moneda_id: moneda_id,
                             fecha_inicio: fecha_inicio, fecha_fin: fecha_fin, observaciones: observaciones)
    else
      mensaje_error = _("Errores al crear el estado inicial") + ": " + est.errors.to_s
      errors.add(:base, mensaje_error)
    end
  end

  # Genera una version del contrato siempre que se cambie alguno de los datos
  def generar_version_contrato
    if self.estado_actual && (self.importe_changed? || self.moneda_id_changed? || !observaciones_cambio.blank? || self.fecha_inicio_changed? || self.fecha_fin_changed?)
      version = version_contrato.find_by_estado_contrato_id(estado_actual.id) || VersionContrato.new(contrato_id: self.id, estado_contrato_id: estado_actual.id)
      version.update_attributes( importe: importe, moneda_id: moneda_id, fecha_inicio: fecha_inicio, fecha_fin: fecha_fin, observaciones: observaciones_cambio )
    end 
  end

  # Verifica el borrado del contrato
  def verificar_borrado
   return errors.empty?
  end

end
