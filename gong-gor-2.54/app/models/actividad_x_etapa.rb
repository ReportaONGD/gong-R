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
class ActividadXEtapa < ActiveRecord::Base
  #untranslate_all
  belongs_to :etapa
  belongs_to :actividad

  has_many :valor_intermedio_x_actividad, :order => "fecha DESC", :dependent => :destroy

  #validates_uniqueness_of :etapa_id, :scope => :actividad_id, :message => _("Etapa ya asignada.")
  before_destroy :verificar_borrado

  def estado_actual
    return valor_intermedio_x_actividad.first 
  end

  def porcentaje_actual
    return estado_actual ? estado_actual.porcentaje : 0.0
  end

  # Esto no funciona por la forma en que hacemos la asignacion (linea 182 del controlador de matriz)
  def verificar_borrado
    if PresupuestoXActividad.find(:all, :include => "presupuesto", :conditions => { "actividad_id" => actividad, "presupuesto.etapa_id" => etapa })
      errors.add( "presupuesto", _("Hay líneas de presupuesto asignadas a esa actividad y etapa"))
      return false
    end
  end

end
