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
class ProyectoXFinanciador < ActiveRecord::Base
  #untranslate_all
  belongs_to :proyecto
  belongs_to :agente

  validates_presence_of :proyecto_id, :message => _("Proyecto") + " " + _("no puede estar vacío.")
  validates_presence_of :agente_id, :message => _("Agente") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :agente_id, :scope => :proyecto_id, :message => _("Financiador repetido.")

  after_create :crear_asociacion_pacs
  before_destroy :verificar_borrado
  after_destroy :eliminar_asociacion_pacs


 private

    # Si el proyecto asociado es un convenio, copia la relacion a los pacs existentes
  def crear_asociacion_pacs
    self.proyecto.pacs.each {|p| p.proyecto_x_financiador.find_or_create_by_agente_id(self.agente_id) } if self.proyecto.convenio?
  end

    # Si el proyecto asociado es un convenio, elimina la relacion de los pacs existentes
  def eliminar_asociacion_pacs
    self.proyecto.pacs.each {|p| ProyectoXFinanciador.destroy_all(:proyecto_id => p.id, :agente_id => self.agente_id) } if self.proyecto.convenio?
  end

  # Se asegura de que el financiador no este aportando nada en el proyecto
  def verificar_borrado
    errors.add( "presupuesto",_("hay líneas de presupuesto financiadas")) unless PresupuestoXAgente.where(agente_id: self.agente_id).
                           joins(:presupuesto).where("presupuesto.proyecto_id" => self.proyecto_id).empty?
    errors.add( "gasto", _("hay gastos financiados")) unless GastoXAgente.where(agente_id: self.agente_id, proyecto_id: self.proyecto_id).empty?
    errors.add( "transferencia", _("hay transferencias")) unless TransferenciaXAgente.where(agente_id: self.agente_id).
                           joins(:transferencia).where("transferencia.proyecto_id" => self.proyecto_id).empty?
    errors[:base] << ( _("Un agente tiene que estar vacío para poder desvincularlo.") ) unless errors.empty?
    return errors.empty?
  end
end
