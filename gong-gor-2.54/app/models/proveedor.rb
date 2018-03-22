# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2015 Free Software's Seed
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

class Proveedor < ActiveRecord::Base

  before_destroy :verificar_borrado

  validate :mayusculas

  validates_uniqueness_of :nombre, :scope => [:nif, :agente_id], :message => _("Ya existe un proveedor con ese nombre para ese NIF."), :case_sensitive => false
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  validates_presence_of :agente, :message => _("Agente") + " " + _("no puede estar vacío.")

  belongs_to :agente
  belongs_to :pais
  has_many :gasto

  # Devuelve el nombre (esto es necesario para hacer comunes los helpers en el listado de subcuentas)
  def codigo_nombre
    self.nombre
  end

  # Devuelve nombre (nif)
  def nombre_nif
    self.nombre + (self.nif.blank? ? "" : " (" + _("NIF") + ": " + self.nif + ")")
  end

 private
 
  def mayusculas
    self.nombre = self.nombre.upcase if self.nombre
    self.nif = self.nif.upcase if self.nif
  end

  def verificar_borrado
    errors.add( "gasto",_("hay gastos vinculados")) unless self.gasto.empty?
    errors[:base] << ( _("Un proveedor tiene que estar vacío para poder ser borrado.") ) unless errors.empty?
    return errors.empty?
  end

end
