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

# Define las relaciones de cofinanciacion entre dos proyectos
class ProyectoXProyecto < ActiveRecord::Base
  #untranslate_all
  belongs_to :proyecto_cofinanciado, :foreign_key => "proyecto_id", :class_name => "Proyecto"
  belongs_to :proyecto_cofinanciador, :class_name => "Proyecto"


  # Evita que se repitan asociaciones
  validates_uniqueness_of :proyecto_cofinanciador_id, :scope => :proyecto_id, :message => _("El proyecto ya está asociado")
  # Evita que se vincule con sigomismo
  validate :no_soy_yo

  before_save :valida_importe
  before_destroy :verificar_borrado

  def no_soy_yo
    errors.add(:base, _("No se puede asociar un proyecto a si mismo") ) if proyecto_id == proyecto_cofinanciador_id
  end

  # Evita que se deje el importe vacio
  def valida_importe
    self.importe||= 0.0
  end

  def verificar_borrado
    errors.add(:base, _("Existen gastos asociados desde ese proyecto cofinanciador")) unless Gasto.count(:all, :include => [:gasto_x_proyecto], :conditions => {:proyecto_origen_id => self.proyecto_cofinanciador_id, "gasto_x_proyecto.proyecto_id" => self.proyecto_id}) == 0
    return errors.empty?
  end
end

