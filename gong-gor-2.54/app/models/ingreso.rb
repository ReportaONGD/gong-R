# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2015 Free Software's Seed
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
class Ingreso < ActiveRecord::Base
 
  before_destroy :verifica_borrado
 
  belongs_to :moneda
  belongs_to :partida_ingreso
  belongs_to :agente
  belongs_to :financiador, class_name: "Agente", foreign_key: "financiador_id"
  belongs_to :proyecto
  belongs_to :tasa_cambio
  belongs_to :proveedor

  # Auditado de modificaciones, comentarios y marcado
  include ::Auditable
  has_many :comentario, as: :elemento, dependent: :destroy
  belongs_to :marcado
  
  validates_presence_of :importe, :message => _("Importe") +  " " + _("no puede estar vacío.")
  validates_presence_of :moneda_id, :message => _("Moneda") +  " " + _("no puede estar vacía.")
  validates_presence_of :agente_id, :message => _("Agente") +  " " + _("no puede estar vacío.")
  validates_presence_of :partida_ingreso_id, :message => _("Partida") + " " + _("no puede estar vacío.")
  validates_presence_of :fecha, :message => _("Fecha") + " " + _("no puede estar vacía.")

  validate :verifica_plugins, :verifica_periodo_cerrado

  before_save :adaptacion_datos

  # Para que los plugins puedan modificar saltandose la validacion "verifica_plugins"
  # OJO!: Siempre que se hagan modificaciones desde migraciones hay que tener en cuenta esto y 
  #       actualizar el elemento incluyendo "evitar_validacion_plugins: true"!
  attr_accessor :evitar_validacion_plugins


  # Devuelve el importe en la moneda base (principal) del agente
  def importe_en_base
    ixtc = (self.importe||0) * self.tasa_cambio.tasa_cambio if self.tasa_cambio
    return ('%.2f' % ixtc).to_s + " " + self.agente.moneda_principal.abreviatura if ixtc
  end


 private

  # Agrupa todas las validaciones para el borrado anteponiendo una variable de clase que permita saber que estamos antes de un borrado
  def verifica_borrado
    @eliminando_ingreso = true
    # Agrupamos todos con AND para que el solo se devuelva true si todos devuelven true 
    return ( verifica_periodo_cerrado && verifica_plugins )
  end

  def verifica_periodo_cerrado
    # Comprueba posibles etapas del agente
    if self.agente
      et_nueva_1 = self.agente.etapa.first(:conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", fecha, fecha] )
      et_vieja_1 = fecha_was ? self.agente.etapa.first(:conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", fecha_was, fecha_was] ) : nil
      if self.agente_id_was && (self.agente_id_was != self.agente_id)
        aw = Agente.find_by_id(agente_id_was)
        et_nueva_2 = aw.etapa.first(:conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", fecha, fecha] )
        et_vieja_2 = fecha_was ? aw.etapa.first(:conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", fecha_was, fecha_was] ) : nil
      else
        et_nueva_2 = nil
        et_vieja_2 = nil
      end
      if (et_nueva_1 && et_nueva_1.cerrada) || (et_vieja_1 && et_vieja_1.cerrada)
        errors.add(_("Etapa"), _("El agente") + " " + self.agente.nombre + " " +_("ha cerrado la etapa imputada en el ingreso. No se pueden modificar ingresos de esas fechas."))
      end
      if (et_nueva_2 && et_nueva_2.cerrada) || (et_vieja_2 && et_vieja_2.cerrada)
        errors.add(_("Etapa"), _("El agente") + " " + aw.nombre + " " +_("ha cerrado la etapa imputada en el ingreso. No se pueden modificar ingresos de esas fechas."))
      end
    end
    return self.errors.empty?
  end

  # Verifica que los plugins permitan la edicion
  # OJO!: Siempre que se hagan movimientos en los gastos desde migraciones hay que tener en cuenta esto!
  def verifica_plugins
    Plugin.activos.each do |plugin|
      begin
        eval(plugin.clase + "::Ingreso").verifica self, @eliminando_ingreso
      rescue => ex
      end
    end unless self.evitar_validacion_plugins
    return self.errors.empty?
  end

  # Permite la ejecucion de metodos de plugins no existentes en el modelo
  def method_missing(method_sym, *arguments, &block)
    clase = nil
    # Primero averigua que plugins tienen la clase "Ingreso" y cuales de ellos el metodo pedido
    Plugin.activos.each do |plugin|
      begin
        clase = plugin.clase if eval(plugin.clase)::Ingreso.respond_to?(method_sym)
      rescue => ex
      end
    end
    # Invoca al ultimo plugin que haya encontrado (o al super si no hay ninguno)
    clase ? eval(clase)::Ingreso.send(method_sym,self) : super
  end

  # Convierte el concepto a mayusculas y actualiza el valor de la tasa de cambio usada
  def adaptacion_datos
    # Concepto en mayusculas
    self.concepto = self.concepto.upcase
    # Cambia la tasa de cambio si es nuevo o se ha actualizado etapa o moneda
    if (self.id.nil? || self.fecha_changed? || self.moneda_id_changed?)
      tc = TasaCambio.tasa_cambio_para_gasto(self,self.agente)
      self.tasa_cambio_id = tc ? tc.id : nil
    end
  end


end
