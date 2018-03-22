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
class IndicadorGeneralXProyecto < ActiveRecord::Base
  # Ponemos el before_destroy al principio para adelantarnos a los dependent: :destroy de despues
  before_destroy :verifica_borrado

  belongs_to :indicador_general
  belongs_to :proyecto
  # Valor base
  belongs_to :valor_base, foreign_key: :valor_base_id, class_name: "ValorXIndicadorGeneral", dependent: :destroy 
  # Valor objetivo 
  belongs_to :valor_objetivo, foreign_key: :valor_objetivo_id, class_name: "ValorXIndicadorGeneral", dependent: :destroy 
  # Valores medidos
  has_many :valor_medido, foreign_key: :indicador_general_x_proyecto_id, class_name: "ValorXIndicadorGeneral", dependent: :destroy

  validates_uniqueness_of :indicador_general_id, :scope => :proyecto_id, :message => _("Indicador General ya asignado al Proyecto.")

  after_create :crear_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs

  # Ultimo valor medido para el indicador en el proyecto
  def ultimo_valor
    valor_medido.order(:fecha).last
  end

  # Devuelve si el indicador proviene de un programa marco o esta elegido a capon
  def proviene_de_programa_marco?
    proyecto && proyecto.programa_marco &&
      proyecto.programa_marco.
               indicador_general_x_programa_marco.
               where(indicador_general_id: self.indicador_general_id).any?
  end

 private

  # Elimina un indicador general de un proyecto solo si no tiene datos de seguimiento
  def verifica_borrado
    errors.add( :base, _("Existe informacion de seguimiento")) unless valor_medido.empty?
    return errors.empty?
  end

  # Si el proyecto asociado es un convenio, copia la relacion a los pacs existentes
  def crear_asociacion_pacs
    self.proyecto.pacs.each {|p| p.indicador_general_x_proyecto.find_or_create_by_indicador_general_id(self.indicador_general_id) } if self.proyecto.convenio?
  end

  # Si el proyecto asociado es un convenio, elimina la relacion de los pacs existentes
  def eliminar_asociacion_pacs
    self.proyecto.pacs.each {|p| IndicadorGeneralXProyecto.destroy_all(:proyecto_id => p.id, :indicador_general_id => self.indicador_general_id) } if self.proyecto.convenio?
  end
end
