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
class VPresupuestoAgenteDetallado < ActiveRecord::Base
  #untranslate_all
  belongs_to :subpartida
  belongs_to :partida

  # valores[0] = agente_id, valores[1] = etapa_id, valores[2] = moneda_id, valores[3] = tasa_cambio, valores[4] = partida_id
  scope :subpartidas_etapa, lambda { |*valores| {
                                 :select => "subpartida_id as fila_id, implementador_id as columna_id, #{importe valores[2], valores[3]} as importe, proyecto_id as proyecto_id", 
                                 :group => "etapa_id, #{valores[2] == "todas" ? "" : " moneda_id, "} partida_id, implementador_id, proyecto_id, subpartida_id",
                                 :conditions => condiciones(valores[0], valores[1], valores[2], valores[4])  } }



  # valores[0] = agente_id, valores[1] = fecha_inicio, valores[2] = fecha_fin, valores[3] = moneda_id, valores[4] = tasa_cambio, valores[5] = partida_id
  scope :partida, lambda { |*valores| {
                                 :select => "partida_id, implementador_id, #{importe valores[3], valores[4]} as importe", 
                                 :group => "partida_id, implementador_id",
                                 :conditions => condiciones(valores[0], valores[1], valores[2], valores[3], valores[5])  } }

  # valores[0] = agente_id, valores[1] = fecha_inicio, valores[2] = fecha_fin, valores[3] = moneda_id, valores[4] = tasa_cambio, valores[5] = partida_id, valores[6] = subpartida_id,  valores[7] = subpartida_nil
  scope :subpartida, lambda { |*valores| {
                                 :select => "partida_id, subpartida_id, implementador_id, #{importe valores[3], valores[4]} as importe, proyecto_id", 
                                 :group => " #{valores[3] == "todas" ? "" : " moneda_id, "} partida_id, implementador_id, proyecto_id, subpartida_id",
                                 :conditions => condiciones(valores[0], valores[1], valores[2], valores[3], valores[5], :subpartida => valores[6], :subpartida_nil => valores[7])  } }

  scope :empleados, lambda { |valores| {
                               :select => "empleado_id, sum(importe_imputado) as importe", 
                               :group => " empleado_id",
                               :conditions => condiciones_hash(valores)  } }

  scope :empleados_proyectos, lambda { |valores| {
                                :select => "empleado_id, proyecto_imputado_id, sum(importe_imputado) as importe", 
                                :group => " empleado_id, proyecto_imputado_id",
                                :conditions => condiciones_hash(valores)  } }



  def self.importe moneda_id, tasa_cambio
    importe = if  moneda_id == "todas";  "sum(importe_moneda_base)"
               elsif tasa_cambio == "0"; "sum(importe)"
               elsif tasa_cambio == "1"; "sum(importe_moneda_base)"; end
  end  

  def self.condiciones agente_id, fecha_inicio, fecha_fin, moneda_id, partida_id, otros = {}
     condiciones = {"implementador_id" => agente_id, "fecha_inicio" => fecha_inicio..fecha_fin, "fecha_fin" => fecha_inicio..fecha_fin, "proyecto_id" => nil }
     condiciones["moneda_id"] = moneda_id unless moneda_id == "todas"
     condiciones["partida_id"] = partida_id if partida_id
     condiciones["subpartida_id"] = otros[:subpartida] if otros[:subpartida]
     condiciones["subpartida_id"] = nil if otros[:subpartida_nil]
     return condiciones
  end

  # CREAMOS OTROS CONDICIONES PARA PASAR LOS VALORES EN FORMA DE HASH. Habria que convertir a este modo el resto de busquedas, que es mas comodo.
  def self.condiciones_hash valores
    # Emepezamos poniendo el proyecto_id a NULL por que son presupuestos de AGENTES. Quiza deberia estar configurado asi en la propia VIEW
     cons = ["proyecto_id IS NULL"]
     vals = []
     if valores[:agente_id]
       cons.push("implementador_id IN (?)")
       vals.push(valores[:agente_id]) 
     end
     if valores[:fecha_inicio] && valores[:fecha_fin]
       cons.push("fecha_inicio BETWEEN ? AND ?")
       vals += [valores[:fecha_inicio], valores[:fecha_fin]]
       cons.push("fecha_fin BETWEEN ? AND ?")
        vals += [valores[:fecha_inicio], valores[:fecha_fin]]
     end
     if valores[:moneda_id] && valores[:moneda_id] != "todas"
       cons.push("moneda_id IN (?)")
       vals.push(valores[:moneda_id])
     end
     if valores[:partida_id]
       cons.push("partida_id IN (?)")
       vals.push(valores[:partida])
     end
     if valores[:subpartida_id]
       cons.push("subpartida_id IS NULL") if valores[:subpartida_id] == "isnull"
       cons.push("subpartida_id IN (?)") unless valores[:subpartida_id] == "isnull"
       vals.push(valores[:subpartida]) unless valores[:subpartida_id] == "isnull"
     end
     if valores[:proyecto_imputado_id]
       cons.push("proyecto_imputado_id IS NOT NULL") if valores[:proyecto_imputado_id] == "isnotnull"
       cons.push("proyecto_imputado_id IS NULL") if valores[:proyecto_imputado_id] == "isnull"
       cons.push("proyecto_imputado_id IN (?)") unless valores[:proyecto_imputado_id] == "isnotnull" || valores[:proyecto_imputado_id] == "isnull"
       vals.push(valores[:proyecto_imputado_id]) unless valores[:proyecto_imputado_id] == "isnotnull" || valores[:proyecto_imputado_id] == "isnull"
     end
     return [ cons.join(" AND ") ] + vals

   end
end