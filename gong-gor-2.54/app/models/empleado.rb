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
class Empleado < ActiveRecord::Base
  belongs_to :agente
  has_many :presupuesto
  has_many :empleado_salario_hora

  # calcula el importe para el empleado en el periodo
  def suma_presupuesto(etapa_id)
    presupuesto.where(etapa_id: etapa_id).sum(:importe)
  end

  # calcula numero de presupuesto para el empleado en el periodo
  def numero_presupuesto(etapa_id)
    presupuesto.where(etapa_id: etapa_id).count
  end

  # calcula el importe para el empleado imputado al agente en el periodo
  def importe_presupuesto_agente(etapa_id)
    presupuesto.where(etapa_id: etapa_id).joins(:presupuesto_x_proyecto).where("presupuesto_x_proyecto.proyecto_id IS NULL").sum("presupuesto_x_proyecto.importe")
  end

  # calcula el importe para el empleado imputado a proyecto en el periodo
  def importe_presupuesto_proyecto(etapa_id)
    presupuesto.where(etapa_id: etapa_id).joins(:presupuesto_x_proyecto).where("presupuesto_x_proyecto.proyecto_id IS NOT NULL").sum("presupuesto_x_proyecto.importe")
  end

  # porcentage de los presupuestos imputados al agente
  def porcentaje_presupuesto_agente(etapa_id)
    importe = importe_presupuesto_agente(etapa_id)
    importe > 0 ? importe_presupuesto_agente(etapa_id) / suma_presupuesto(etapa_id) * 100 : 0
  end

  # porcentage de los presupuestos imputados a proyectos
  def porcentaje_presupuesto_proyecto(etapa_id)
    importe = importe_presupuesto_proyecto(etapa_id)
    importe > 0 ? importe_presupuesto_proyecto(etapa_id) / suma_presupuesto(etapa_id) * 100 : 0
  end
end
