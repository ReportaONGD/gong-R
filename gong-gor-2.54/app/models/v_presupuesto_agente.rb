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
class VPresupuestoAgente < ActiveRecord::Base

  #untranslate_all
  # Atributos: valores[0] = agente_id, valores[1] = etapa_id, valores[2] = moneda_id, valores[3] = tasa_cambio, valores[4] = partida_id
  scope :subpartidas_partida, lambda { |*valores| {
                                 :select => "subpartida_id as fila_id, implementador_id as columna_id, #{importe valores[2], valores[3]} as importe, proyecto_id as proyecto_id", 
                                 :group => "etapa_id, #{valores[2] == "todas" ? "" : " moneda_id, "} partida_id, implementador_id, proyecto_id, subpartida_id",
                                 :conditions => condiciones(valores[0], valores[1], valores[2], valores[4])  } }



  # Atributos: valores[0] = agente_id, valores[1] = etapa_id, valores[2] = moneda_id, valores[3] = tasa_cambio, valores[4] = partida_id
  scope :partida_implementador, lambda { |*valores| {
                                 :select => "partida_id as fila_id, implementador_id as columna_id, #{importe valores[2], valores[3]} as importe, proyecto_id as proyecto_id", 
                                 :group => "etapa_id, #{valores[2] == "todas" ? "" : " moneda_id, "} partida_id, implementador_id, proyecto_id",
                                 :conditions => condiciones(valores[0], valores[1], valores[2], valores[4])  } }

  # Atributos: valores[0] = agente_id, valores[1] = etapa_id, valores[2] = moneda_id, valores[3] = tasa_cambio
  scope :subpartidas, lambda { |*valores| {
                                 :select => "subpartida_id as fila_id, implementador_id as columna_id, #{importe valores[2], valores[3]} as importe, proyecto_id as proyecto_id", 
                                 :group => "etapa_id, #{valores[2] == "todas" ? "" : " moneda_id, "} partida_id, implementador_id, proyecto_id, subpartida_id",
                                 :conditions => condiciones(valores[0], valores[1], valores[2], nil)  } }

  # Atributos: valores[0] = agente_id, valores[1] = etapa_id, valores[2] = moneda_id, valores[3] = tasa_cambio, , valores[4] = partida_id, , valores[5] = subpartida_id
  scope :subpartida_partida, lambda { |*valores| {
                                 :select => "subpartida_id as fila_id, implementador_id as columna_id, #{importe valores[2], valores[3]} as importe, proyecto_id as proyecto_id", 
                                 :group => "etapa_id, #{valores[2] == "todas" ? "" : " moneda_id, "} partida_id, implementador_id, proyecto_id, subpartida_id",
                                 :conditions => condiciones(valores[0], valores[1], valores[2], valores[4], :subpartida => valores[5])  } }



  def self.importe moneda_id, tasa_cambio
    importe = if  moneda_id == "todas";  "sum(importe_moneda_base)"
               elsif tasa_cambio == "0"; "sum(importe)"
               elsif tasa_cambio == "1"; "sum(importe_moneda_base)"; end
  end  

  def self.condiciones agente_id, etapa_id, moneda_id, partida_id, otros = {}
     condiciones = {"implementador_id" => agente_id, "etapa_id" => etapa_id, "proyecto_id" => nil }
     condiciones["moneda_id"] = moneda_id unless moneda_id == "todas"
     condiciones["partida_id"] = partida_id if partida_id
     condiciones["subpartida_id"] = otros[:subpartida] if otros[:subpartida]
     return condiciones
  end

end
