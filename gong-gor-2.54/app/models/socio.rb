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
# socio

class Socio < ActiveRecord::Base

  before_destroy :verificar_borrado

  has_one :informacion_socio, :dependent => :destroy
  belongs_to :naturaleza_socio
  has_many :pago_socio
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  after_create :crear_informacion

  def nombre_completo
    self.nombre + " " + self.apellido1 + " " + self.apellido2
  end

private
  def crear_informacion
       self.build_informacion_socio
  end

  def verificar_borrado
    errors.add( "pago_socio", _("Hay pagos de este socio")) unless self.pago_socio.empty?
    errors[:base] << ( _("Los datos relacionados con un Socio tienen que estar vacíos para que pueda ser borrado.") ) unless errors.empty?
    return false unless errors.empty?
  end
end
#done
