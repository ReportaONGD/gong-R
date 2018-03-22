# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2016 Free Software's Seed
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
class GorConfig < ActiveRecord::Base
  validates_uniqueness_of :name, message: _("Nombre de parámetro repetido."), case_sensitive: false
  validates_presence_of   :name, message: _("Parámetro") + " " + _("no puede estar vacío.")

  def self.getValue param_name
    gc = GorConfig.find_by_name(param_name.to_s)
    gc ? gc.value : nil
  end
end
