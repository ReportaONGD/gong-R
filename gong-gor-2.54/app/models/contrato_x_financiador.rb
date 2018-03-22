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
class ContratoXFinanciador < ActiveRecord::Base
  #untranslate_all
  belongs_to :contrato
  belongs_to :agente

  validates_presence_of :contrato_id, :message => _("Contrato") + " " + _("no puede estar vacío.")
  validates_associated :contrato, message: _("El contrato no es válido.")
  validates_presence_of :agente_id, :message => _("Agente") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :agente_id, :scope => :contrato_id, :message => _("Financiador repetido.")
  validates_associated :agente, message: _("El agente financiador no es válido.")
  validates_numericality_of :importe, :greater_than => 0, :message =>_("Importe debe ser mayor que cero.")

  before_destroy :estado_contrato
  before_save :comprueba_proyecto
  validate :comprueba_importe_total_financiador
  validate :estado_contrato

 private

  # Comprueba que la suma de todos los importes de contrato_x_financiador no sea superior
  # al importe total presupuestado para el financiador 
  # Trabajamos siempre en la moneda del proyecto
  def comprueba_importe_total_financiador
    importe_total = 0.0

    # Asumimos siempre la primera etapa del proyecto
    etapa = contrato.proyecto.etapa.first

    # Recorre todos los contratos_x_financiador calculando su importe en la moneda del proyecto
    # Se evita ademas a si mismo por si se ha modificado el importe 
    Contrato.where(proyecto_id: contrato.proyecto_id).joins(:contrato_x_financiador).where("contrato_x_financiador.agente_id" => self.agente_id).
             where("contrato_x_financiador.id != ?", self.id).
             group("contrato.moneda_id").sum("contrato_x_financiador.importe").each do |moneda_id, importe_moneda|
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
    suma_ppto = contrato.proyecto.presupuesto_total_con_tc( financiador: agente.id ).to_f
    if importe_total > suma_ppto
      msg_error = _("El importe asignado en todos los contratos para el financiador '%{nom}' (%{imp_agt}) supera el presupuesto total de esta (%{imp_tot}).")%{nom: agente.nombre, imp_agt: importe_total, imp_tot: suma_ppto}
      errors.add(:base, msg_error)
    end
    return errors.empty?
  end

  # Se asegura de que el estado del contrato permita cambiar financiadores
  def estado_contrato
    # Comprueba que el contrato no este cerrado o que si esta en ejecucion este tambien en formulacion
    errors.add(:base, _("El contrato está cerrado.")) if contrato.cerrado?
    errors.add(:base, _("El contrato no está en un estado que permita su modificación.")) if contrato.aprobado? && !contrato.formulacion?

    return errors.empty?
  end

  # comprueba que exista el proyecto asociado
  def comprueba_proyecto
    errors.add(:base, _("El contrato asociado no pertenece a ningun proyecto válido.")) unless contrato && contrato.proyecto

    return errors.empty?
  end

end
