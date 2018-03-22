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

# Clase del modelo que gestiona la entidad ContratoXActividad que recoge la relacion entre contrato y actividad con importe 
class ContratoXActividad < ActiveRecord::Base
  #untranslate_all
  belongs_to :contrato
  belongs_to :actividad

  before_destroy :validar_cambios

  validates_presence_of :actividad, :message => _("Actividad no es válida.")
  validates_presence_of :contrato, :message => _("Contrato no es válido.")
  validates_uniqueness_of :actividad_id, :scope => [:contrato_id], :message => _("Actividad repetida para el contrato.")
  validates_numericality_of :importe, :greater_than => 0, :message =>_("Importe debe ser mayor que cero.")

  validate :comprueba_importe_total_actividad
  validate :validar_cambios

 private

  # Comprueba que la suma de todos los importes de contrato_x_actividad no sea superior
  # al importe total presupuestado para la actividad
  # Trabajamos siempre en la moneda del proyecto
  def comprueba_importe_total_actividad
    importe_total = 0.0
    # Actuamos como si solo hubiera una etapa por proyecto
    # PENDIENTE: Dividir el contrato en las etapas del proyecto, promediar importes y actuar conforme a esas TC
    etapa =  actividad.proyecto.etapa.first
    # Recorre todos los contratos_x_actividad calculando su importe en la moneda del proyecto
    Contrato.joins(:contrato_x_actividad).where("contrato_x_actividad.actividad_id" => self.actividad_id).
             group("contrato.moneda_id").sum("contrato_x_actividad.importe").each do |moneda_id, importe_moneda|
      # Averigua la tasa de cambio de presupuesto para esta moneda
      tc = TasaCambio.tasa_cambio_para_presupuesto(etapa, moneda_id)
      importe_total += importe_moneda * tc.tasa_cambio if tc
    end

    # Como estamos destruyendo/creando (ver modelo de contrato) el importe actual nunca esta incluido
    # Asi que se lo sumamos antes de comparar.
    tc = TasaCambio.tasa_cambio_para_presupuesto(etapa, contrato.moneda_id)
    importe_total += importe * tc.tasa_cambio if tc

    # Mostramos error si el importe total es superior al presupuestado
    # (por algun motivo raro, "suma_presupuesto" devuelve String aqui (desde consola devuelve BigDecimal)
    suma_ppto = actividad.suma_presupuesto.to_f
    if importe_total > suma_ppto 
      msg_error = _("El importe asignado en todos los contratos para la actividad '%{act}' (%{imp_act}) supera el presupuesto total de esta (%{imp_tot}).")%{act: actividad.codigo, imp_act: importe_total, imp_tot: suma_ppto}
      errors.add(:base, msg_error)
    end
    return errors.empty?
  end

  # Valida que la actividad pueda ser creada/modificada o eliminada
  def validar_cambios
    # Comprueba que el contrato no este cerrado o que si esta en ejecucion este tambien en formulacion
    errors.add(:base, _("El contrato está cerrado.")) if contrato.cerrado?
    errors.add(:base, _("El contrato no está en un estado que permita su modificación.")) if contrato.aprobado? && !contrato.formulacion?

    return errors.empty?
  end
end
