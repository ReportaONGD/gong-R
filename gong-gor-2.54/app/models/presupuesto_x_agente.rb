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
# Clases del modelo que gestiona la entidad PresupuestoXAgente que recoge la relacion entre presupuesto y agente financiador con porcentaje.

class PresupuestoXAgente < ActiveRecord::Base
  #untranslate_all
  belongs_to :presupuesto
  belongs_to :agente

  validates_presence_of :agente, :message => _("Financiador no es válido.")
  validates_uniqueness_of :agente_id, :scope => [:presupuesto_id], :message =>  _("Financiador repetido.")
  validates_numericality_of :importe, :greater_than => 0, :message => _("Financiador con importe 0 no se guarda.")


  # Porcentaje para la visualizacion.
  def porcentaje_to_s
    return (self.porcentaje * 100).to_i.to_s + "%"
  end

  # Campos para visualización de la relación en los listados.
  def self.campos_listado
    return [[_("Contribuyente"),"1" ,"agente.nombre"], ["%","1_4" ,"porcentaje_to_s"], [_("Importe"), "1_2_td", "importe"]] 
  end

end
