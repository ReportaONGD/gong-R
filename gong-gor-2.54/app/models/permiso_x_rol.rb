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

# Definición de permisos por rol
class PermisoXRol < ActiveRecord::Base

  belongs_to :rol

  validates_presence_of :rol_id, message: _("Rol") + " " + _("no puede estar vacío.")
  validates_associated :rol, message: _("El rol asociado no es válido.")
  validates_presence_of :menu, message: _("Menú") + " " + _("no puede estar vacío.")
  validates_presence_of :controlador, message: _("Controlador") + " " + _("no puede estar vacío.")

  validates_uniqueness_of :rol_id, scope: [:menu, :controlador], message: _("El rol ya está definido para ese controlador de menú.")

end
