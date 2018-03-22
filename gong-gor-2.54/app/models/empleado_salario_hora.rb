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
class EmpleadoSalarioHora < ActiveRecord::Base
  belongs_to :empleado
  validates_presence_of :empleado_id, :message => _("Empleado") + " " + _("no puede estar vacío.")
  validates_presence_of :salario_hora, :message => _("Salario por Hora") + " " + _("no puede estar vacío.")
  validates_presence_of :fecha_inicio, :message => _("Facha inicio") + " " + _("no puede estar vacía.")
  validates_presence_of :fecha_fin, :message => _("Fecha Fin") + " " + _("no puede estar vacía.")
 
  validate :comprobar_fechas

  # Comprueba que las fechas son correctas.
  def comprobar_fechas
    if fecha_fin and fecha_inicio
      # Comprueba que la fecha de inicio sea anterior a la de fin
      errors.add("fecha_fin", _("Fecha fin tiene que ser mayor que fecha inicio")) if self.fecha_fin <= self.fecha_inicio
      # Comprueba que las fechas no se solapen con otra Etapa
      empleado.empleado_salario_hora.each do |esh|
         if esh.id != id && (
           (fecha_inicio >= esh.fecha_inicio && fecha_inicio <= esh.fecha_fin) ||
           (fecha_fin >= esh.fecha_inicio && fecha_fin <= esh.fecha_fin) ||
           (fecha_inicio <= esh.fecha_inicio && fecha_fin >= esh.fecha_fin) )
           errors.add("fecha", _("Las fechas del periodos para el salario hora descrito se solapan con las fechas de otro periodo para el empleado"))
         end
      end
    else
      errors.add("fecha", _("fecha no puede esta vacio") )
    end
  end

end
