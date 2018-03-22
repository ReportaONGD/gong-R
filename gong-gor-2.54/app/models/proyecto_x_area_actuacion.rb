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
class ProyectoXAreaActuacion < ActiveRecord::Base
  #untranslate_all
  belongs_to :proyecto
  belongs_to :area_actuacion

  validates_uniqueness_of :area_actuacion_id, :scope => :proyecto_id, :message => _("El área de actuación ya está definida para el proyecto.")
  validate :porcentaje_total

  after_create :crear_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs

 private

    # Comprueba que el porcentaje total para el proyecto no sea mayor de 1
  def porcentaje_total
    # En la suma incluimos el actual porque aun no estan las relaciones establecidas
    suma = porcentaje + proyecto.proyecto_x_area_actuacion.collect{|pxaa| pxaa.porcentaje}.sum
    errors.add( :base, "Los porcentajes de las areas de actuacion para el proyecto suman más del 100%") if (100*suma).to_i > 100
    return unless errors.empty?
  end

    # Si el proyecto asociado es un convenio, copia la relacion a los pacs existentes
  def crear_asociacion_pacs
    self.proyecto.pacs.each do |p|
      pxaa = ProyectoXAreaActuacion.find_or_create_by_proyecto_id_and_area_actuacion_id(p.id, self.area_actuacion_id)
      pxaa.update_attributes :porcentaje => self.porcentaje
    end if self.proyecto.convenio?
  end

    # Si el proyecto asociado es un convenio, elimina la relacion de los pacs existentes
  def eliminar_asociacion_pacs
    self.proyecto.pacs.each {|p| ProyectoXAreaActuacion.destroy_all(:proyecto_id => p.id, :area_actuacion_id => self.area_actuacion_id) } if self.proyecto.convenio?
  end

end