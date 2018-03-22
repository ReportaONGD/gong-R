# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2017 OEI y Free Software's Seed
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
# Recoge todos los indicadores asociados a un programa marco concreto
#
class IndicadorGeneralXProgramaMarco < ActiveRecord::Base
  belongs_to :indicador_general
  belongs_to :programa_marco

  validates_uniqueness_of :indicador_general_id, :scope => :programa_marco_id, :message => _("Indicador General ya asignado.")

  after_create :crear_asociacion_proyectos
  after_destroy :eliminar_asociacion_proyectos

 private

  # Copia la relacion a los proyectos del programa
  def crear_asociacion_proyectos
    self.programa_marco.proyecto.each {|p| p.indicador_general_x_proyecto.find_or_create_by_indicador_general_id(self.indicador_general_id) }
  end

  # Elimina la relacion a los proyectos del programa
  def eliminar_asociacion_proyectos
    self.programa_marco.proyecto.each {|p| IndicadorGeneralXProyecto.destroy_all(:proyecto_id => p.id, :indicador_general_id => self.indicador_general_id) }
  end
end
