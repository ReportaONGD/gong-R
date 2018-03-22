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

class Moneda < ActiveRecord::Base

  before_destroy :verificar_borrado

  validate :abreviatura_mayusculas
  validates_uniqueness_of :abreviatura, :message => _("Abreviatura repetida."), :case_sensitive => false
  validates_uniqueness_of :nombre, :message => _("Nombre repetido.")
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  has_many :libro
  has_many :moneda
  has_many :gasto
  has_many :presupuesto
  has_many :financiacion
  has_many :proyecto_x_moneda, :dependent => :destroy
  has_many :proyecto, :through => :proyecto_x_moneda, :uniq => true
  has_many :tasa_cambio, :dependent => :destroy
  #has_and_belongs_to_many :proyecto,  :join_table => "proyecto_x_moneda", :uniq => true

  
  def abreviatura_mayusculas
    self.abreviatura = self.abreviatura.upcase
  end

  def verificar_borrado
    #errors.add( "financiacion", _("hay financiaciones")) unless self.financiacion.empty?
    errors.add( "presupuesto",_("hay presupuestos")) unless self.presupuesto.empty?
    errors.add( "gasto", _("hay gastos")) unless self.gasto.empty?
    errors.add( "libro", _("hay libros")) unless self.libro.empty?
    errors[:base] << ( _("Un agente tiene que estar vacío para poder ser borrado.") ) unless errors.empty?
    return errors.empty?
 end

end
