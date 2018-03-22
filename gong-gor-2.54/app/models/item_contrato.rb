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

class ItemContrato < ActiveRecord::Base

  before_destroy :verificar_borrado

  belongs_to :contrato

  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  validates_numericality_of :cantidad, :greater_than => 0, :message => _("Número de unidades") + " " + _("no puede estar vacío.")
  validates_numericality_of :coste_unitario, :greater_than => 0, :message => _("Coste unitario") + " " + _("no puede estar vacío.")

  # Devuelve el valor del importe de la linea
  def importe
    cantidad * coste_unitario
  end

 private
 
  def verificar_borrado
    errors.add :base, _("El contrato está cerrado. No se puede modificar.") if contrato.cerrado?
    return errors.empty?
  end

end
