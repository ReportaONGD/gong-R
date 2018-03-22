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

# Clase del modelo que gestiona la entidad PresupuestoXActividad que recoge la relacion entre presupuesto y actividad con porcentaje
class PresupuestoXActividad < ActiveRecord::Base
  #untranslate_all
  belongs_to :presupuesto
  belongs_to :actividad

  validates_presence_of :actividad, :message => _("Actividad no es válida.")
  validates_presence_of :presupuesto, :message => _("Presupuesto no es válido.")
  validates_uniqueness_of :actividad_id, :scope => [:presupuesto_id], :message => _("Actividad repetida para el presupuesto.")
  validates_numericality_of :importe, :greater_than => 0, :message =>_("Importe debe ser mayor que cero.")
  validates_numericality_of :numero_unidades, :greater_than_or_equal_to => 0, :message =>_("Número de unidades debe ser mayor que cero.")

  validate :comprobar_etapa

  # Comprueba que la etapa asignada a la linea de presupuesto esta permitida para la actividad seleccionada
  def comprobar_etapa
    errors.add("Etapa", _("La actividad '%{codigo}' no está asignada a la etapa '%{nombre}'.") % {:codigo => actividad.codigo, :nombre => presupuesto.etapa.nombre}) if presupuesto and actividad and (actividad.etapa.nil? || actividad.etapa.find_by_id(presupuesto.etapa_id).nil? )
  end

end
