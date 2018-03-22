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
# MonedaXPais: relaciona moneda con pais

class MonedaXPais < ActiveRecord::Base

  #untranslate_all

  # acts_as_reportable
  belongs_to :moneda
  belongs_to :pais

  validates_presence_of :moneda_id, :message => _("Moneda") + " " + _("no puede estar vacía.")
  validates_associated :moneda, :message => _("La moneda asociada no es correcta.")
  validates_presence_of :pais_id, :message => _("País") + " " + _("no puede estar vacío.")
  validates_associated :pais, :message =>  _("El país asociado no es correcto.")

  validates_uniqueness_of :moneda_id, :scope => :pais_id, :message => _("Moneda ya asignada.")
end
