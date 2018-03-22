# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2015 Free Software's Seed, CENATIC y IEPALA
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
class SubtipoMovimiento < ActiveRecord::Base

  before_destroy :verificar_borrado

  has_many :transferencia

  validates_uniqueness_of :nombre, :scope => :tipo_asociado, :message => _("Nombre repetido."), :case_sensitive => false
  validates_presence_of :nombre
  validate :nombre_mayusculas, :tipo_asociado_vacio

private

  def nombre_mayusculas
    self.nombre = self.nombre.strip.mb_chars.upcase
  end
  def tipo_asociado_vacio
    self.tipo_asociado = nil if self.tipo_asociado == ""
  end

  def verificar_borrado
   errors.add( "transferencia", _("Existen transferencias asociadas al subtipo de movimiento") ) unless transferencia.empty?
   return errors.empty?
  end

end
