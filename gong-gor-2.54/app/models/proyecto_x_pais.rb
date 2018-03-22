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
class ProyectoXPais < ActiveRecord::Base
  #untranslate_all
  belongs_to :pais
  belongs_to :proyecto

  validates_uniqueness_of :pais_id, :scope => :proyecto_id, :message => _("País ya asignado.")

  after_create :asociar_monedas, :crear_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs


 private

  def asociar_monedas
    self.pais.moneda.each { |mon| ProyectoXMoneda.find_or_create_by_proyecto_id_and_moneda_id(self.proyecto_id, mon.id) }
  end

    # Si el proyecto asociado es un convenio, copia la relacion a los pacs existentes
  def crear_asociacion_pacs
    self.proyecto.pacs.each {|p| p.proyecto_x_pais.find_or_create_by_pais_id(self.pais_id) } if self.proyecto.convenio?
  end

    # Si el proyecto asociado es un convenio, elimina la relacion de los pacs existentes
  def eliminar_asociacion_pacs
    self.proyecto.pacs.each {|p| ProyectoXPais.destroy_all(:proyecto_id => p.id, :pais_id => self.pais_id) } if self.proyecto.convenio?
  end
end
