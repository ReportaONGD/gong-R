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
class ProyectoXSectorIntervencion < ActiveRecord::Base
  #untranslate_all
  belongs_to :proyecto
  belongs_to :sector_intervencion

  validates_uniqueness_of :sector_intervencion_id, :scope => :proyecto_id, :message => _("El sector de intervención ya está definido para el proyecto.")
  validate :porcentaje_total

  after_create :crear_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs

 private

    # Comprueba que el porcentaje total para el proyecto no sea mayor de 1
  def porcentaje_total
    # En la suma incluimos el actual porque aun no estan las relaciones establecidas
    suma = porcentaje + proyecto.proyecto_x_sector_intervencion.collect{|pxsi| pxsi.porcentaje}.sum
    errors.add( :base, "Los porcentajes de los sectores de intervención para el proyecto suman más del 100%") if (100*suma).to_i > 100
    return unless errors.empty?
  end

    # Si el proyecto asociado es un convenio, copia la relacion a los pacs existentes
  def crear_asociacion_pacs
    self.proyecto.pacs.each do |p|
      pxsi = ProyectoXSectorIntervencion.find_or_create_by_proyecto_id_and_sector_intervencion_id(p.id, self.sector_intervencion_id)
      pxsi.update_attributes :porcentaje => self.porcentaje 
    end if self.proyecto.convenio?
  end

    # Si el proyecto asociado es un convenio, elimina la relacion de los pacs existentes
  def eliminar_asociacion_pacs
    self.proyecto.pacs.each {|p| ProyectoXSectorIntervencion.destroy_all(:proyecto_id => p.id, :sector_intervencion_id => self.sector_intervencion_id) } if self.proyecto.convenio?
  end

end
