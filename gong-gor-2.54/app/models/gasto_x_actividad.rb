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
# GastoXActividad: recoge la relacion entre gasto y actividad con porcentaje

class GastoXActividad < ActiveRecord::Base

  before_destroy :comprobar_estado_proyecto, :comprobar_periodos_proyecto

  #untranslate_all
  belongs_to :gasto
  belongs_to :actividad
  belongs_to :proyecto

  validates_presence_of :actividad_id, :message => _("Actividad") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :actividad_id, :scope => [:gasto_id, :proyecto_id], :message => _("Actividad asociada al gasto repetida")
  validates_presence_of :importe, :message => _("Importe") + " " + _("no puede estar vacío.")
  # Permitimos gastos negativos para aceptar devoluciones
  #validates_numericality_of :importe, :greater_than => 0, :message => _("Importe para la actividad") + " " + _("no puede estar vacío.")

  validate :comprobar_estado_proyecto, :comprobar_periodos_proyecto

  # Comprueba que el estado del proyecto para el que se esta modificando el GastoXAgente
  def comprobar_estado_proyecto
    errors.add(_("Proyecto"),  _("El proyecto '%{proy}' se encuentra en estado '%{est}'.")%{proy: proyecto.nombre, est: proyecto.estado_actual.definicion_estado.nombre} + " " +
                               _("En este estado no se puede modificar el gasto.")) if proyecto && proyecto.estado_actual && !proyecto.estado_actual.definicion_estado.ejecucion
    return errors.empty? 
  end

  def comprobar_periodos_proyecto
    for periodo in proyecto.periodo
      if periodo.gastos_cerrados and (gasto.fecha >= periodo.fecha_inicio and gasto.fecha <= periodo.fecha_fin) 
        texto = _("El gasto está asociado al proyecto") + ": " + proyecto.nombre + ". " + _("El periodo de justificación: ") + " " + periodo.tipo_periodo.nombre + " (" + periodo.fecha_inicio.to_s + "/" + periodo.fecha_inicio.to_s + ") " +  _("esta cerrado y no se puede modificar el gasto.")
        errors.add(_("Proyecto"), texto) 
      end
    end if proyecto
    return errors.empty?
  end



end
