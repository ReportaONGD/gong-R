# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2014 Free Software's Seed
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
class Personal < ActiveRecord::Base
  belongs_to :tipo_personal
  belongs_to :proyecto
  belongs_to :moneda

  validates_presence_of :proyecto_id, :message => _("Proyecto") + " " + _("no puede estar vacío.")
  validates_associated :proyecto, :message => _("El proyecto asociado no es correcto.")

  validates_presence_of :tipo_personal_id, :message => _("Tipo de Personal") + " " + _("no puede estar vacío.")
  validates_associated :tipo_personal, :message => _("El Tipo de Personal asociado no es correcto.")

  validates_presence_of :moneda_id, :message => _("Moneda") + " " + _("no puede estar vacía.")
  validates_associated :moneda, :message => _("La moneda asociada no es correcta.")

  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  validates_presence_of :tipo_contrato, :message => _("Tipo de Contrato") + " " + _("no puede estar vacío.")
  validates_presence_of :horas_imputadas, :message => _("Horas/Semana Imputadas") + " " + _("no puede estar vacío.")
  validates_presence_of :salario_mensual, :message => _("Salario Bruto Mensual") + " " + _("no puede estar vacío.")
  validates_presence_of :meses, :message => _("Meses") + " " + _("no puede estar vacío.")
  validates_presence_of :salario_total, :message => _("Salario Bruto Total") + " " + _("no puede estar vacío.")
end
