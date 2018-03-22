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
class VGastoAgente < ActiveRecord::Base
  #untranslate_all
  belongs_to :partida
  belongs_to :subpartida


  # Devuelve los gastos de agente por partidas de sistema
  # Sustituye a partida
  scope :sum_partida, lambda { |valores| {
                    :select => "partida_id as fila_id, #{importe valores} as importe, #{valores[:columna_id]||"'n/a'"} as columna_id",
                    :group => "partida_id, implementador_id #{moneda valores[:moneda]}",
                    :conditions => condiciones(valores) } }

  # Suma devolviendo solo los totales por proyecto
  scope :sum_proyecto, lambda { |valores| {
                    :select => "proyecto_id as fila_id, #{importe valores} as importe, #{valores[:columna_id]||"'n/a'"} as columna_id",
                    :group => "proyecto_id #{moneda valores[:moneda]}",
                    :conditions => condiciones(valores) } }

  scope :sum_subpartida_proyecto, lambda { |valores| {
                    :select => "subpartida_id, subpartida_nombre, partida_id, partida_nombre, implementador_id, #{importe valores} as importe, proyecto_nombre",
                    :group => "partida_id, implementador_id, subpartida_id, proyecto_id",
                    :conditions => condiciones(valores) } }

  # Suma sin hacer agrupaciones devolviendo solo el importe total
  scope :sum_total, lambda { |valores| {
                    :select => "#{importe valores} as importe",
                    :conditions => condiciones(valores) } }
                    
  scope :listado_gastos, lambda { |valores| {
                                  :select => "#{importe valores} as importe, gasto_id",
                                  :conditions => condiciones(valores),
                                  :group => "gasto_id"} }

  scope :empleados, lambda { |valores| {
                               :select => "empleado_id, sum(importe_moneda_base) as importe", 
                               :group => " empleado_id",
                               :conditions => condiciones(valores)  } }

  scope :empleados_proyectos, lambda { |valores| {
                                :select => "empleado_id, proyecto_id, sum(importe_moneda_base) as importe", 
                                :group => " empleado_id, proyecto_id",
                                :conditions => condiciones(valores)  } }

  scope :empleados_horas, lambda { |valores| {
                               :select => "empleado_id, sum(horas) as horas", 
                               :group => " empleado_id",
                               :conditions => condiciones(valores)  } }

  scope :empleados_horas_proyectos, lambda { |valores| {
                                :select => "empleado_id, proyecto_id, sum(horas) as horas", 
                                :group => " empleado_id, proyecto_id",
                                :conditions => condiciones(valores)  } }


 private

  def self.importe valores={}
    moneda_id = valores[:moneda]||"todas"
    tasa_cambio = valores[:tasa_cambio]||"1"
    return (moneda_id == "todas" || tasa_cambio == "1") ? "sum(importe_moneda_base)" : "sum(importe)"
  end

  def self.moneda moneda_id=nil
    return (moneda_id.nil? || moneda_id == "todas") ? "" : ", moneda_id "
  end

  # Las condiciones las generamos como array en lugar de hash para permitir
  # el filtro de gastos asignados a delegacion 
  def self.condiciones valores={}
    cons = []
    vals = []
    if valores[:fecha_inicio] && valores[:fecha_fin]
      cons.push("fecha BETWEEN ? AND ?")
      vals += [valores[:fecha_inicio], valores[:fecha_fin]]
    end
    if valores[:agente]
      cons.push("implementador_id IN (?)")
      vals.push(valores[:agente]) 
    end
    if valores[:moneda] && valores[:moneda] != "todas"
      cons.push("moneda_id IN (?)")
      vals.push(valores[:moneda])
    end
    if valores[:partida]
      cons.push("partida_id IN (?)")
      vals.push(valores[:partida])
    end
    if valores[:subpartida]
      cons.push("subpartida_id IS NULL") if valores[:subpartida] == "isnull"
      cons.push("subpartida_id IN (?)") unless valores[:subpartida] == "isnull"
      vals.push(valores[:subpartida]) unless valores[:subpartida] == "isnull"
    end
    if valores[:proyecto]
      cons.push("proyecto_id IS NOT NULL") if valores[:proyecto] == "isnotnull"
      cons.push("proyecto_id IS NULL") if valores[:proyecto] == "isnull"
      cons.push("proyecto_id IN (?)") unless valores[:proyecto] == "isnotnull" || valores[:proyecto] == "isnull"
      vals.push(valores[:proyecto]) unless valores[:proyecto] == "isnotnull" || valores[:proyecto] == "isnull"
    end
    return [ cons.join(" AND ") ] + vals
  end

end
