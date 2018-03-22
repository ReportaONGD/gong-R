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

# Clases del modelo que gestiona la entidad PresupuestoDetallado, es decir el detalle temporal de cada linea de presupuesto
class PresupuestoDetallado< ActiveRecord::Base

  before_destroy :verifica_etapa

  belongs_to :presupuesto
  before_save :adaptacion_datos

  validate :verifica_etapa

 private
  # Fuerza el importe a cero si no estuviera ya
  def adaptacion_datos
    importe ||= 0.0
  end

  # Comprueba si es posible imputar el detalle de presupuesto por no estar la etapa en no presupuestable
  def verifica_etapa
    pres = self.presupuesto
    if pres.nil? || pres.etapa.nil? || pres.etapa.cerrada || !pres.etapa.presupuestable
      errors.add(_("Etapa"), _("La etapa esta cerrada. No se puede modificar el presupuesto detallado."))
      return false
    end
  end
  
end
