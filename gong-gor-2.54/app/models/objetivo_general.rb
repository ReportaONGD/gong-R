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
# objetivo general 

class ObjetivoGeneral < ActiveRecord::Base

  validates_uniqueness_of :proyecto_id, :message => _("Ya existe objetivo general para el proyecto.")
  belongs_to :proyecto

  after_create :crear_asociacion_pacs
  after_update :modificar_asociacion_pacs

  def crear_asociacion_pacs
    self.proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        miog = self.dup
        miog.proyecto_id = p.id
        miog.save
      end
    end if self.proyecto.convenio?
  end

 private

  def modificar_asociacion_pacs
    self.proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        p.objetivo_general.update_attribute(:descripcion, self.descripcion)
      end
    end if self.proyecto.convenio?
  end


end
