# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2015 Free Software's Seed
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

# Clases del modelo que gestiona la entidad PeriodoContrato: detalle temporal de cada contrato 
class PeriodoContrato < ActiveRecord::Base

  before_destroy :validar_cambios

  belongs_to :contrato

  validates_presence_of :contrato_id, message: _("Contrato") + " " + _("no puede estar vacío.")
  validate :comprobar_fechas
  validate :comprobar_importes
  validate :validar_cambios

  before_save :adaptacion_datos

  # Devuelve los pares "clave: valor" a incluir en plantillas
  def campos_plantilla
    # Incorporamos tambien los campos del contrato
    contrato.campos_plantilla.merge({
        "periodo.descripcion" => descripcion,
        "periodo.fecha_inicio" => I18n.l(fecha_inicio),
        "periodo.fecha_fin" => I18n.l(fecha_fin),
        "periodo.fecha_inicio.texto" => I18n.l(fecha_inicio, format: :long),
        "periodo.fecha_fin.texto" => I18n.l(fecha_fin, format: :long),
        "periodo.importe" => importe_convertido,
    })
  end
 private

  # Fuerza el importe a cero si no estuviera ya
  def adaptacion_datos
    importe ||= 0.0
  end

  # Comprueba que las fechas introducidas sean correctas
  def comprobar_fechas
    # Comprobamos que existan ambas y que siempre sea posterior al fin que al comienzo
    if self.fecha_inicio && self.fecha_fin && self.fecha_inicio <= self.fecha_fin
      # Nos aseguramos de que las fechas esten dentro de las fechas del contrato
      errors.add(:base, _("Las fechas están fuera del contrato.")) if fecha_inicio < contrato.fecha_inicio || fecha_fin > contrato.fecha_fin
      # Y por ultimo, que no se solape con otro periodo de contrato
      superpuestos = PeriodoContrato.where(contrato_id: contrato.id).where("id != ? AND fecha_fin > ? AND fecha_inicio < ?", id, fecha_inicio, fecha_fin)
      errors.add(:base, _("Las fechas se solapan con otro periodo del contrato.")) unless superpuestos.empty?
    else
      errors.add(:base, _("Las fechas no pueden estar vacías.") ) unless self.fecha_inicio && self.fecha_fin
      errors.add("fecha_fin", _("Fecha fin tiene que ser mayor que fecha inicio.")) if self.fecha_inicio && self.fecha_fin && self.fecha_fin < self.fecha_inicio
    end
    return errors.empty?
  end

  # Comprueba que los importes de pagos de hito no sean superiores al total del contrato
  def comprobar_importes
    # Obtenemos el total del resto de periodos
    total = PeriodoContrato.where(contrato_id: contrato.id).where("id != ?", id).sum(:importe)
    # Y le sumamos el actual
    total += importe
    
    errors.add(:base, _("La suma de los pagos de los hitos es mayor que el total del contrato.")) if total > contrato.importe
    return errors.empty?
  end

  # Valida que el periodo pueda ser creado/modificado o eliminado
  def validar_cambios
    # Comprueba que el contrato no este cerrado o que si esta en ejecucion este tambien en formulacion
    errors.add(:base, _("El contrato está cerrado.")) if contrato.cerrado?
    errors.add(:base, _("El contrato no está en un estado que permita su modificación.")) if contrato.aprobado? && !contrato.formulacion?

    # Comprueba si el contrato esta en un proyecto cerrado
    proyecto = contrato.proyecto
    errors.add(:base, _("El proyecto está cerrado.")) if proyecto && proyecto.definicion_estado && proyecto.definicion_estado.cerrado?

    # Comprueba si las etapas del agente estan cerradas
    agente = contrato.agente
    agente.etapa.where(["(fecha_inicio <= ? AND fecha_fin >= ?) OR (fecha_inicio <= ? AND fecha_fin >= ?)", fecha_inicio, fecha_inicio, fecha_fin, fecha_fin]).each do |etapa|
      errors.add(:base, _("La etapa '%{etp}' del gestor está cerrada.")%{etp: etapa.nombre}) if etapa.cerrada
    end

    return errors.empty?
  end
  
end
