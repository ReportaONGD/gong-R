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

# Clase del modelo que gestiona la relacion entre Gastos y Contratos
class GastoXContrato < ActiveRecord::Base

  before_destroy :verifica_relacion

  belongs_to :contrato
  belongs_to :gasto

  validates_presence_of :contrato, :message => _("Contrato no es válido.")
  validates_presence_of :gasto, :message => _("Gasto no es válido.")
  validates_uniqueness_of :gasto_id, :message => _("Gasto ya asociado a otro contrato.")

  validate :verifica_relacion

 private

  # Hace las validaciones de creacion/modificacion/borrado
  def verifica_relacion
    # Solo deja vincular o desvincular el gasto si el contrato esta en ejecucion y no cerrado
    errors.add(:base, _("El contrato no está en estado de ejecucion.")) unless contrato.ejecucion?
    errors.add(:base, _("El contrato está cerrado.")) if contrato.cerrado?
    # Y si el gasto esta dentro de las fechas del contrato
    errors.add(:base, _("El gasto está fuera de las fechas de ejecución del contrato.")) unless gasto.fecha >= contrato.fecha_inicio && gasto.fecha <= contrato.fecha_fin
    # Y si el proveedor del contrato es el proveedor del gasto
    errors.add(:base, _("El gasto está asignado a otro proveedor distinto del contratado.")) if gasto.proveedor.nil? || gasto.proveedor_id != contrato.proveedor_id
    # Y si la moneda del contrato es la moneda del gasto
    errors.add(:base, _("La moneda del gasto no es la definida en el contrato.")) if gasto.moneda_id != contrato.moneda_id
    return errors.empty?
  end

end
