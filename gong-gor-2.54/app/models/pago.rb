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
class Pago < ActiveRecord::Base
  # Auditado de modificaciones, comentarios y marcado 
  include ::Auditable
  
  belongs_to :gasto
  belongs_to :libro

  validates_presence_of :importe, :message => _("Importe") + " " + _("no puede estar vacío.")
  validates_presence_of :fecha,  :message => _("Fecha") + " " + _("no puede estar vacío.")
  validates_presence_of :gasto_id, :message => _("Gasto") + " " + _("no puede estar vacío.")
  validates_presence_of :libro_id, :mensage => _("Cuenta") + " " + _("no puede estar vacía.")
  #validates_associated :gasto, :message =>  _("El gasto asociado no es correcto.")
  validates_associated :libro, :message => _("La cuenta asociada no es correcta.")

  validate :comprueba_libro_moneda, :verifica_fechas, :verifica_plugins
  before_destroy :verifica_borrado
  before_save :ajusta_forma_pago_manual, :ajusta_observaciones

  # Para que los plugins puedan modificar saltandose la validacion "verifica_plugins"
  attr_accessor :evitar_validacion_plugins

  # Agrupa todas las validaciones para el borrado anteponiendo una variable de clase que permita saber que estamos antes de un borrado
  def verifica_borrado
    @eliminando_pago = true
    return ( verifica_fechas && verifica_plugins )
  end

  # Comprueba que el libro pertenezca al agente implementador del gasto asociado
  # y que el libro tiene la misma moneda que el gasto
  def comprueba_libro_moneda
    errors.add("Pago", _("No existe libro asociado al pago!")) unless libro
    errors.add("Libro", _("El libro '%{nom}' no pertenece al implementador del gasto relacionado.")%{nom: libro.nombre}) if gasto.nil? || (libro && libro.agente != gasto.agente)
    errors.add("Libro", _("El libro '%{nom}' no tiene la moneda del gasto relacionado.")%{nom: libro.nombre}) if gasto.nil? || (libro && libro.moneda != gasto.moneda)
    errors.add("Libro", _("El libro '%{nom}' está bloqueado. No es posible asignarle pagos.")%{nom: libro.nombre}) if libro && libro.bloqueado
    return self.errors.empty?
  end

  # Comprueba que la etapa del agente implantador no este cerrada o que haya proyectos cofinanciados cerrados
  def verifica_fechas
    # Comprueba posibles etapas del agente
    if self.gasto && (agente = self.gasto.agente)
      et_nueva_1 = agente.etapa.first(:conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", fecha, fecha] )
      et_vieja_1 = fecha_was ? agente.etapa.first(:conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", fecha_was, fecha_was] ) : nil
      if (et_nueva_1 && et_nueva_1.cerrada) || (et_vieja_1 && et_vieja_1.cerrada)
        errors.add(_("Etapa"), _("El agente") + " " + agente.nombre + " " +_("ha cerrado la etapa donde se ejecuta el pago. No se pueden modificar pagos de esas fechas."))
      end
    end
    return self.errors.empty?
  end

  def ajusta_forma_pago_manual
    unless Libro.find_by_id(self.libro_id).tipo == "banco"
      self.forma_pago = _("Metálico")
      self.referencia_pago = nil
    end
  end

  def ajusta_observaciones
    self.observaciones = self.gasto.concepto if self.gasto && (self.observaciones.nil? || self.observaciones == "")
  end

    # +++
    # Sobrecargamos la clase para incluir etiquetas 
    # ---
  class << self
    def formas_de_pago
      [ _("Transferencia"), _("Cheque"), _("Metálico") ]
    end
  end

 private

  # Verifica que los plugins permitan la edicion
  def verifica_plugins
    Plugin.activos.each do |plugin|
      begin
        eval(plugin.clase + "::Pago").verifica self, @eliminando_pago 
      rescue => ex
      end
    end unless self.evitar_validacion_plugins
    return self.errors.empty?
  end

end
