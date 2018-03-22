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

# Clases del modelo que gestiona la entidad Transferencia.

class Transferencia < ActiveRecord::Base

  before_destroy :comprueba_etapas_agente, :verifica_plugins

  belongs_to :libro_origen, :class_name => "Libro", :foreign_key => "libro_origen_id"
  belongs_to :libro_destino, :class_name => "Libro", :foreign_key => "libro_destino_id"
  belongs_to :proyecto
  belongs_to :subtipo_movimiento
  
  has_many :comentario, as: :elemento, dependent: :destroy
  belongs_to :marcado

  # Para vinculacion con financiadores
  has_many :transferencia_x_agente, :dependent => :destroy
  has_many :financiador, :through => :transferencia_x_agente, :source => :agente, :order => "nombre"

  # Para vinculacion con gastos 
  has_many :gasto_x_transferencia, :dependent => :destroy
  has_many :gasto, :through => :gasto_x_transferencia

  # Para vinculacion con documentos
  has_many :transferencia_x_documento
  has_many :documento, :through => :transferencia_x_documento

  validates_presence_of :tipo, :message => _("Tipologia de movimiento no definida")
  #validates_presence_of :libro_origen_id, :if => "tipo =~ /transferencia|cambio|retirada|ingreso/", :message => _("Cuenta secundaria") + _(" no puede estar vacía.")

  # Validaciones
  validate :comprueba_fechas
  validate :comprueba_etapas_agente, :verifica_plugins
  validate :comprueba_libros
  validate :comprueba_importes
  validate :comprueba_tasa_cambio

  # Usamos estos callbacks para invocar la regeneracion de tasas de cambio
  after_save 'TasaCambio.actualiza_ponderadas(self)'
  after_destroy 'TasaCambio.actualiza_ponderadas(self)'

  # Para que los plugins puedan modificar saltandose la validacion "verifica_plugins"
  attr_accessor :evitar_validacion_plugins

    # +++
    # Sobrecargamos la clase para incluir metodos generales 
    # ---
  class << self
    # Devuelve un array con los tipos de movimientos posibles
    def tipos_movimiento
      [ [_("Transferencia"),"transferencia"],[_("Cambio"),"cambio"],[_("Retirada"),"retirada"],[_("Ingreso"),"ingreso"],
        [_("Adelanto"),"adelanto"], [_("Devolucion"),"devolucion"], [_("Intereses"),"intereses"],
        [_("Subvencion"),"subvencion"],[_("Reintegro de Subvención"), "reintegro"], [_("IVA Recuperado"),"iva"] ]
    end
  end

  # Valida las fechas
  def comprueba_fechas
    # Comprueba que se reciba despues de enviar
    if (fecha_enviado && fecha_recibido && fecha_enviado > fecha_recibido) || (fecha_enviado.nil? && fecha_recibido.nil?)
      errors.add(_("Fecha"), _("La fecha de envío debe ser anterior a la de recepción."))
      return false
    end
    # Si esta asignada a un proyecto, comprueba que caiga dentro de una etapa de este
    if (self.proyecto)
      if self.proyecto.etapa.empty?
        errors.add(_("Fecha"), _("El proyecto '%{nombre}' no tiene etapas definidas.")%{nombre: proyecto.nombre})
      else
        # Comprueba que el proyecto no este cerrado
        errors.add(_("Fecha"), _("El proyecto '%{nombre}' está cerrado.")%{nombre: proyecto.nombre}) if self.proyecto.estado_actual.definicion_estado.cerrado
        errors.add(_("Fecha"), _("El proyecto '%{nombre}' no está en estado de ejecución.")%{nombre: proyecto.nombre}) unless self.proyecto.estado_actual.definicion_estado.ejecucion
        # Comprueba que las fechas de envio y recepcion esten dentro de etapas del proyecto
        # NOTA: Esto se ha eliminado intencionadamente... no tiene porque tener sentido impedir transferencias fuera de fecha 
        #f_origen_ok = fecha_enviado.nil?
        #f_destino_ok = fecha_recibido.nil?
        #self.proyecto.etapa.each do |etp|
        #  f_origen_ok = true unless fecha_enviado && (fecha_enviado < etp.fecha_inicio || fecha_enviado > etp.fecha_fin)
        #  f_destino_ok = true unless fecha_recibido && (fecha_recibido < etp.fecha_inicio || fecha_recibido > etp.fecha_fin)
        #end
        #errors.add(_("Fecha"), _("La fecha de envío está fuera de las etapas del proyecto.")) unless f_origen_ok 
        #errors.add(_("Fecha"), _("La fecha de recepción está fuera de las etapas del proyecto.")) unless f_destino_ok
      end
    # Si no lo esta, comprueba que caiga dentro de una etapa del agente/agentes
    else
      # Comprueba que las fechas caigan dentro de la etapa del agente del libro origen
      f_origen_ok = fecha_enviado.nil? || self.libro_origen.nil?
      self.libro_origen.agente.etapa.each do |etp|
        f_origen_ok = true unless fecha_enviado < etp.fecha_inicio || fecha_enviado > etp.fecha_fin
      end if !f_origen_ok && self.libro_origen && self.libro_origen.agente
      f_destino_ok = fecha_recibido.nil? || self.libro_destino.nil?
      self.libro_destino.agente.etapa.each do |etp|
        f_destino_ok = true unless fecha_recibido < etp.fecha_inicio || fecha_recibido > etp.fecha_fin
      end if !f_destino_ok && self.libro_destino && self.libro_destino.agente
      errors.add(_("Fecha"), _("La fecha de envío está fuera de las etapas del agente %{nombre}.")%{:nombre => self.libro_origen.agente.nombre}) unless f_origen_ok
      errors.add(_("Fecha"), _("La fecha de recepción está fuera de las etapas del agente %{nombre}.")%{:nombre => self.libro_destino.agente.nombre}) unless f_destino_ok
    end
  end

  # Comprueba que no se hagan modificaciones de etapas cerradas por el agente
  def comprueba_etapas_agente
    # Obtiene las etapas posibles para el movimiento de envio
    et_envia_1 = (fecha_enviado && self.libro_origen) ? self.libro_origen.agente.etapa.first(:conditions => ["fecha_inicio < ? AND fecha_fin > ?", fecha_enviado, fecha_enviado] ) :nil
    et_envia_2 = (fecha_enviado_was && self.libro_origen) ? self.libro_origen.agente.etapa.first(:conditions => ["fecha_inicio < ? AND fecha_fin > ?", fecha_enviado_was, fecha_enviado_was] ) :nil
    if (self.libro_origen_id_was && self.libro_origen_id != self.libro_origen_id_was)
      low = Libro.find_by_id(libro_origen_id_was)
      et_envia_3 = fecha_enviado ? low.agente.etapa.first(:conditions => ["fecha_inicio < ? AND fecha_fin > ?", fecha_enviado, fecha_enviado] ) :nil
      et_envia_4 = fecha_enviado_was ? low.agente.etapa.first(:conditions => ["fecha_inicio < ? AND fecha_fin > ?", fecha_enviado_was, fecha_enviado_was] ) :nil
    else
      et_envia_3 = nil
      et_envia_4 = nil
    end
    # Obtiene las etapas posibles para el movimiento de recepcion
    et_recibe_1 = (fecha_recibido && self.libro_destino) ? self.libro_destino.agente.etapa.first(:conditions => ["fecha_inicio < ? AND fecha_fin > ?", fecha_recibido, fecha_recibido] ) :nil
    et_recibe_2 = (fecha_recibido_was && self.libro_destino) ? self.libro_destino.agente.etapa.first(:conditions => ["fecha_inicio < ? AND fecha_fin > ?", fecha_recibido_was, fecha_recibido_was] ) :nil
    if (self.libro_destino_id_was && self.libro_destino_id != self.libro_destino_id_was)
      ldw = Libro.find_by_id(libro_destino_id_was)
      et_recibe_3 = fecha_recibido ? ldw.agente.etapa.first(:conditions => ["fecha_inicio < ? AND fecha_fin > ?", fecha_recibido, fecha_recibido] ) :nil
      et_recibe_4 = fecha_recibido_was ? ldw.agente.etapa.first(:conditions => ["fecha_inicio < ? AND fecha_fin > ?", fecha_recibido_was, fecha_recibido_was] ) :nil
    else
      et_recibe_3 = nil
      et_recibe_4 = nil
    end
    # Comprueba que las modificaciones no afecten a la etapa de los agentes involucrados
    if (et_envia_1 && et_envia_1.cerrada) || (et_envia_2 && et_envia_2.cerrada)
      errors.add(_("Etapa"), _("El agente") + " " + self.libro_origen.agente.nombre + " " + _("ha cerrado la cuenta de origen para esa fecha. No se puede modificar la transferencia."))
      return false
    end
    if low && ((et_envia_3 && et_envia_3.cerrada) || (et_envia_4 && et_envia_4.cerrada))
      errors.add(_("Etapa"), _("El agente") + " " + low.agente.nombre + " " + _("ha cerrado la cuenta de origen para esa fecha. No se puede modificar la transferencia."))
      return false
    end
    if (et_recibe_1 && et_recibe_1.cerrada) || (et_recibe_2 && et_recibe_2.cerrada)
      errors.add(_("Etapa"), _("El agente") + " " + self.libro_destino.agente.nombre + " " + _("ha cerrado la cuenta de destino para esa fecha. No se puede modificar la transferencia."))
      return false
    end
    if ldw && ((et_recibe_3 && et_recibe_3.cerrada) || (et_recibe_4 && et_recibe_4.cerrada))
      errors.add(_("Etapa"), _("El agente") + " " + ldw.agente.nombre + " " + _("ha cerrado la cuenta de destino para esa fecha. No se puede modificar la transferencia."))
      return false
    end
  end

  # Valida libros
  def comprueba_libros
    # Las cuentas no pueden ser iguales (salvo que sea un remanente)
    # Lo comentamos por problemas con la migracion
    #if libro_origen == libro_destino && !remanente
    #  errors.add(_("Libro"), _("Los libros de origen y destino son el mismo."));
    #end
    # Para los siguientes tipos, tiene que haber ambos libros
    if self.tipo =~ /transferencia|cambio|retirada|ingreso/ && ( libro_origen.nil? || libro_destino.nil? )
      errors.add(_("Libro"), _("Falta libro origen o destino.")) 
    end
    # Para los siguientes tipos, debe existir libro destino pero no origen
    if self.tipo =~ /intereses|iva|subvencion/ && (libro_destino.nil? || !libro_origen.nil? )
      errors.add(_("Libro"), _("No existe el libro destino del movimiento de") + " " + _(self.tipo)) 
    end
    # Para los siguientes tipos, debe existir libro origen pero no destino
    if self.tipo =~ /reintegro/ && (!libro_destino.nil? || libro_origen.nil? )
      errors.add(_("Libro"), _("No existe el libro origen del movimiento de") + " " + _(self.tipo))
    end
    # Para los siguientes tipos, o existe el origen o existe el destino
    if self.tipo =~ /adelanto/ && ( libro_destino_id && libro_origen_id )
      errors.add(_("Libro"), _("No se pueden definir dos libros para el movimiento"))
    end
    # Impide realizar transferencias sobre libros bloqueados
    errors.add("Libro", _("El libro origen está bloqueado. No es posible realizar movimientos con él.")) if libro_origen && libro_origen.bloqueado
    errors.add("Libro", _("El libro destino está bloqueado. No es posible realizar movimientos con él.")) if libro_destino && libro_destino.bloqueado
    return false unless errors.empty?
  end

  # Valida importes (permitiendo excepciones en remanentes)
  def comprueba_importes
    # No hay ningun importe o los importes no son positivos 
    if ( (importe_enviado.nil? || importe_enviado == 0) && (importe_cambiado.nil? || (importe_cambiado == 0 && !remanente)))
      errors.add(_("Importe"), _("Los importes no pueden estar vacíos"))
    end
    # El enviado debe existir si se ha definido fecha
    if  fecha_enviado && ( importe_enviado.nil? || importe_enviado == 0)
      errors.add(_("Importe Enviado"), _("El importe enviado debe ser mayor que cero"))
    end
    # El cambiado debe existir si se ha definido fecha (salvo que sea un remanente)
    if  fecha_recibido && (importe_cambiado.nil? || (importe_cambiado == 0 && !remanente))
      errors.add(_("Importe Recibido"), _("El importe ingresado debe ser mayor que cero"))
    end
    # Ajusta importe recibido si es necesario
    if self.tipo =~ /intereses|iva|subvencion|adelanto/
      self.importe_recibido = importe_cambiado
    else
      self.importe_recibido = importe_enviado if importe_enviado && (importe_recibido.nil? || importe_recibido == 0)
    end
    return false unless errors.empty?
  end

  # Comprueba (no valida) la suma por financiadores
  def comprobar_financiadores
    # Estos tipos no tienen envio, con lo que se usa el recibido 
    if self.tipo =~ /intereses|iva|subvencion|adelanto|remanente/
      validar=self.importe_recibido 
    else
      validar=self.importe_enviado
    end
    return validar == transferencia_x_agente.inject(0) {|suma, f| suma + f.importe} if self.proyecto_id
    return true unless self.proyecto_id
  end

  # Valida la TC
  def comprueba_tasa_cambio
    # Si las monedas de los libros son la misma, la TC es siempre 1
    if libro_origen && libro_destino && libro_origen.moneda_id == libro_destino.moneda_id
      self.tasa_cambio = 1
    # Si no existe importe enviado o cambiado la tc es nil
    elsif self.libro_origen == nil? || self.libro_destino.nil? || (importe_enviado.nil? || importe_enviado == 0) || (importe_cambiado.nil? || importe_cambiado == 0)
      self.tasa_cambio = nil
    # Calcula la TC si existen importes recibidos y cambiados 
    elsif importe_cambiado && importe_recibido && importe_cambiado != 0
      # Incluimos el format, porque si no la inclusion inline deja todos los decimales de la TC
      self.tasa_cambio = format("%.8f",importe_recibido / importe_cambiado).to_f
    # Y si no existen, la TC es nil
    else
      self.tasa_cambio = nil
    end
  end

   # Actualiza el listado de agentes con los que se ha asociado la transferencia 
   def actualizar_transferencia_x_agente listado
     transferencia_x_agente.each {|f| f.destroy}
     listado.each do |key, value|
       if value["importe_convertido"] && value["importe_convertido"] != "" && value["agente_id"] && value["agente_id"] != ""
         txa = transferencia_x_agente.create(value)
         errors.add("", txa.errors.inject('') {|total, e| total + e[1]  }) unless txa.errors.empty?
       end
     end unless listado.nil? || listado.empty? 
     #if  listado.inject(0) {|suma, value| suma + value.pop[:importe_convertido].to_f} != ( self.importe_enviado || self.importe_recibido ) 
     #  errors.add( _('Importes'), _("Los importes de los financiadores no suman el importe total de la transferencia."))
     #end
   end

  # Obtiene las monedas origen y destino
  def moneda_enviada
    return Moneda.find_by_id(self.libro_origen.moneda_id) if self.libro_origen && self.importe_enviado && self.importe_enviado != 0
  end
  def moneda_recibida
    if self.libro_origen
      mon = Moneda.find_by_id(self.libro_origen.moneda_id)
      return mon if self.importe_enviado && self.importe_enviado != 0
    else
      mon = Moneda.find_by_id(self.libro_destino.moneda_id)
      return mon
    end 
  end 
  def moneda_cambiada
    return Moneda.find_by_id(self.libro_destino.moneda_id) if self.libro_destino && self.importe_cambiado && self.importe_cambiado != 0
  end

  # Devuelve en una cadena los nombres de los financiadores
  def nombres_financiadores
    self.transferencia_x_agente.collect{|txf| txf.agente.nombre}.join(", ")
  end

  # Devuelve un array con los importes por financiador
  def importes_por_financiadores
    salida = Array.new
    condiciones = Hash.new
    txf = self.transferencia_x_agente.all
    mon = self.libro_origen ? self.libro_origen.moneda.abreviatura : ""
    txf.each {|txf| salida.push( txf.agente.nombre + ": " + txf.importe.to_s + " " + mon + (self.importe_enviado && self.importe_enviado > 0 ? " (" + (100*txf.importe/self.importe_enviado).round(2).to_s + "%)" : "") )}
    return salida
  end  

  # Comprueba que la fecha está dentro de la etapa seleccionada
  def comprobar_fecha_etapa etapa
    if self.fecha_enviado >= etapa.fecha_inicio and self.fecha_recibido <= etapa.recha_recibido
      return true
    else
      errors.add(_("Fecha"), _("Las fechas deben estar dentro de la etapa")) ; return false
    end
  end
  # Proyecto al que se ha asignado la transferencia
  def proyecto
    return Proyecto.find_by_id(self.proyecto_id) if self.proyecto_id  
  end

  # Devuelve el tipo completo de la transferencia
  def tipo_completo
    return self.tipo.capitalize + " " + self.entrante_saliente unless self.tipo == "intereses" || self.tipo == "subvencion" || self.tipo == "iva"
    return self.tipo.capitalize if self.tipo == "intereses" || self.tipo == "subvencion" || self.tipo == "iva"
  end

  # Moneda a la que hace referencia la tasa de cambio
  def moneda_tasa_cambio
    #return "" if entrante_saliente == "saliente"
    #return "(" + (libro_receptor_emisor_id ? Libro.find_by_id(libro_receptor_emisor_id).moneda.abreviatura : libro.moneda.abreviatura) + ")"
    return "(" + moneda_destino.abreviatura + ")" if moneda_destino
  end

  # Devuelve si la transferencia esta completa o no 
  def completa?
    !((self.fecha_enviado.nil? || self.fecha_recibido.nil?) && self.tipo =~ /transferencia|cambio|retirada|ingreso/)
  end

  def chequea_avisos
    avisos = []
    avisos.push _("Los datos del movimiento son erroneos: no corresponden con ningún tipo registrado.") if tipo == "REVISAME" 
    avisos.push _("La transferencia no está completada.") unless completa?
    avisos.push _("No se dispone de informacion del envío.") if !completa? && !fecha_enviado
    avisos.push  _("No se dispone de informacion de la recepción.") if !completa? && !fecha_recibido
    avisos.push _("La suma por financiadores no es correcta.") unless comprobar_financiadores
    Plugin.activos.each do |plugin|
      begin
        avisos_plugin = eval(plugin.clase + "::Transferencia").chequea_avisos(self)
        avisos += avisos_plugin if avisos_plugin.class.name == "Array" 
      rescue => ex
      end
    end
    return avisos
  end

 private

  # Verifica que los plugins permitan la edicion
  def verifica_plugins
    Plugin.activos.each do |plugin|
      begin
        eval(plugin.clase + "::Transferencia").verifica self
      rescue => ex
      end
    end unless self.evitar_validacion_plugins
    return self.errors.empty?
  end

end
