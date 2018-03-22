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
# versiones de contratos 

class VersionContrato < ActiveRecord::Base

  belongs_to :contrato
  belongs_to :moneda
  belongs_to :estado_contrato

  validates_uniqueness_of :contrato_id, scope: [:estado_contrato_id], message: _("Ya existe una versión del contrato para el estado propuesto.")
  validates_presence_of :contrato_id, message: _("Contrato") + " " + _("no puede estar vacío.")
  validates_associated :contrato, message: _("El contrato asociado no es correcto.")
  validates_presence_of :estado_contrato_id, message: _("Estado del Contrato") + " " + _("no puede estar vacío.")
  validates_associated :estado_contrato, message: _("El estado de contrato asociado no es correcto.")
  validates_presence_of :moneda_id, message: _("Moneda") + " " + _("no puede estar vacía.")
  validates_format_of :fecha_inicio, with: /\d{4}-\d{1,2}-\d{1,2}/
  validates_format_of :fecha_fin, with: /\d{4}-\d{1,2}-\d{1,2}/

  # Devuelve el codigo de la version 
  def codigo_version
    codigo  = contrato.codigo
    codigo += "_V" + updated_at.utc.strftime("%Y%m%d%H%M%S") if contrato.version_contrato.count > 1
    return codigo
  end
end
