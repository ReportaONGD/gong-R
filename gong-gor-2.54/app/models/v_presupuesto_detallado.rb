# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2014 Free Software's Seed
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
class VPresupuestoDetallado < ActiveRecord::Base
  #untranslate_all

  # Devuelve sumas por partidas.
  # Sustituye a partida_de_implementador, partida_de_financiador e implementador_sin_proyecto (uso de proyecto_id y proyecto_nombre)
  scope :sum_partida, lambda { |valores| {
                                 :select => "partida_id as fila_id, #{importe valores} as importe, proyecto_id, proyecto_nombre",
                                 :group => "proyecto_id, partida_id #{moneda valores[:moneda]} #{agente valores}",
                                 :conditions => condiciones(valores) } }

  # Devuelve sumas por partidas. Es como :sum_partida, pero sin separar por proyectos (group)
  # Sustituye a partida_de_implementador_sin_proyecto
  scope :sum_partida_sin_proyecto, lambda { |valores| {
                                 :select => "partida_id as fila_id, #{importe valores} as importe",
                                 :group => "partida_id #{moneda valores[:moneda]} #{agente valores}",
                                 :conditions => condiciones(valores) } }


  # Devuelve sumas por actividades.
  # Sustituye a actividad_de_implementador y actividad_de_financiador
  scope :sum_actividad, lambda { |valores| {
                                 :select => "actividad_id as fila_id, #{importe valores} as importe",
                                 :group => "proyecto_id, actividad_id #{moneda valores[:moneda]} #{agente valores}",
                                 :conditions => condiciones(valores) } }


  # Devuelve sumas por partidas del financiador
  # Sustituye a partida_proyecto_de_implementador y partida_proyecto_de_financiador
  scope :sum_partida_proyecto, lambda { |valores| {
                                 :select => "partida_proyecto_id as fila_id, #{importe valores} as importe",
                                 :group => "proyecto_id, partida_proyecto_id #{moneda valores[:moneda]} #{agente valores}",
                                 :conditions => condiciones(valores) } }


  # Suma sin hacer agrupaciones devolviendo solo el importe total
  # Sustituye a subpartida_partida y a subpartida_partida_proyecto
  scope :sum_total, lambda { |valores| {
                                 :select => "#{importe valores} as importe",
                                 :conditions => condiciones(valores) } }

  # Suma agrupando solo por proyectos
  scope :sum_proyecto, lambda { |valores| {
                                 :select => "proyecto_id as fila_id, #{importe valores} as importe, #{valores[:columna_id]||"'n/a'"} as columna_id",
                                 :group => "proyecto_id #{moneda valores[:moneda]} #{agente valores}",
                                 :conditions => condiciones(valores) } }

  # Devuelve la suma por lineas de presupuesto para un rango de fechas
  # Sustituye a implementador_sin_proyecto
  scope :sum_presupuesto, lambda { |valores| {
                                 :select => "partida_id, partida_codigo, #{importe valores} as importe, proyecto_nombre, presupuesto_id, presupuesto_concepto",
                                 :group => "presupuesto_id #{moneda valores[:moneda]}  #{agente valores}",
                                 :conditions => condiciones(valores),
                                 :order => "partida_codigo" } }

  # +++
  # Sobrecargamos la clase para incluir agrupaciones 
  # ---
  class << self

    # Devuelve un array de hashes con las partidas agrupadas (correccion para convenios)
    def agrupa_sum_partida valores={}
      columna_id = valores[:columna_id]||1
      pptos = sum_partida valores
      return pptos.collect {|p| {"columna_id" => columna_id.to_s, "importe" => p.importe , "fila_id" => p.fila_id }}
    end

    # Devuelve un array de hashes con las partidas de proyecto agrupadas (correccion para convenios)
    def agrupa_sum_partida_proyecto valores={}
      columna_id = valores[:columna_id]||1
      pptos = sum_partida_proyecto valores
      return pptos.collect {|p| {"columna_id" => columna_id.to_s, "importe" => p.importe , "fila_id" => p.fila_id }}
    end

    # Devuelve un array de hashes con las actividades del proyecto agrupados
    # Sustituye a agrupa_actividad_de_financiador y a agrupa_actividad_de_implementador
    def agrupa_sum_actividad valores={}
      columna_id = valores[:columna_id]||1
      pptos = sum_actividad valores
      return pptos.collect {|p| {"columna_id" => columna_id.to_s, "importe" => p.importe , "fila_id" => p.fila_id }}
    end

    # Devuelve un array de hashes con los resultados del proyecto agrupados
    # Sustituye a agrupa_resultado_de_financiador y a agrupa_resultado_de_implementador
    def agrupa_sum_resultado valores={}
      columna_id = valores[:columna_id]||1
      pptos_actividades = agrupa_sum_actividad valores
      pptos = []

      # Recorre todas las actividades generando los gastos por resultado
      pptos_actividades.each do |ppto|
        actividad = Actividad.find_by_id ppto["fila_id"]
        # Si no hay actividad ponemos nil y si la hay pero no tiene resultado_id ponemos 0 (acts. generales)
        resultado_id = actividad ? actividad.resultado_id||0 : nil
        pptos = sum_array( pptos, {"columna_id" => columna_id.to_s, "importe" => ppto["importe"], "fila_id" => resultado_id} )
      end
      return pptos
    end

    # Devuelve un array de hashes con los oe del proyecto agrupados
    # Sustituye a agrupa_oe_de_financiador y a agrupa_oe_de_implementador
    def agrupa_sum_oe valores={}
      columna_id = valores[:columna_id]||1
      pptos_resultados = agrupa_sum_resultado valores
      pptos = []

      # Recorre todos los resultados generando los gastos por oe 
      pptos_resultados.each do |ppto|
        # Se no habia resultado para la actividad era global, ponemos 0
        if ppto["fila_id"] == 0
          oe_id = 0
        # Si no era con resultado 0 puede que este huerfana de oe o que lo tenga
        else
          resultado = Resultado.find_by_id ppto["fila_id"]
          oe_id = resultado ? resultado.objetivo_especifico_id : nil
        end
        pptos = sum_array( pptos, {"columna_id" => columna_id.to_s, "importe" => ppto["importe"], "fila_id" => oe_id} )
      end
      return pptos 
    end

  end

 private

  # Metodos de ayuda para completar los scopes
  def self.importe valores={}
    moneda_id = valores[:moneda]||"todas"
    tasa_cambio = valores[:tasa_cambio]||"1"
    importe = if  moneda_id == "todas";  "sum(importe_moneda_base)"
               elsif tasa_cambio == "0"; "sum(importe)"
               elsif tasa_cambio == "1"; "sum(importe_moneda_base)"; end
  end

  # No entiendo bien el sentido de esto... se usa solo en el group, pero no veo para que...
  #   quizas una herencia de haberse copiado desde la vista de presupuestos o tiene que ver con agentes?
  def self.moneda moneda_id
      return (moneda_id.nil? || moneda_id == "todas") ? "" : ", moneda_id "
  end

  # No entiendo bien el sentido de esto... se usa solo en el group, pero no veo para que...
  #   quizas una herencia de haberse copiado desde la vista de presupuestos o tiene que ver con agentes? 
  # Le he metido otra condicion para que lo ignore cuando lo que se manda es un array de agentes (financiadores agrupados)
  def self.agente valores={}
    agente_rol = valores[:agente_rol]||"financiador"
    agente_id = valores[:agente]||"todos"
    return (agente_id == "todos" || agente_id.class.name == "Array") ? "" : ", #{agente_rol}_id "
  end

  # Establece las condiciones para los scopes
  def self.condiciones valores={}
    agente_rol = valores[:agente_rol]||"financiador"
    condiciones = {}
    if valores[:fecha_inicio] && valores[:fecha_fin]
      condiciones["fecha_inicio"] = valores[:fecha_inicio]..valores[:fecha_fin]
      condiciones["fecha_fin"] = valores[:fecha_inicio]..valores[:fecha_fin]
    end
    if valores[:proyecto]
      condiciones["proyecto_id"] = valores[:proyecto] if valores[:proyecto]
    else
      condiciones["proyecto_aprobado"] = valores[:proyecto_aprobado] if valores[:proyecto_aprobado]
      condiciones["convenio_accion"] = nil
    end
    condiciones["moneda_id"] = valores[:moneda] unless valores[:moneda].nil? || valores[:moneda] == "todas"
    condiciones[agente_rol + "_id"] = valores[:agente] unless valores[:agente].nil? || valores[:agente] == "todos"
    # Condiciones
    condiciones["partida_id"] = valores[:partida] if valores[:partida]
    condiciones["partida_proyecto_id"] = valores[:partida_proyecto] if valores[:partida_proyecto]
    condiciones["subpartida_id"] = valores[:subpartida] if valores[:subpartida]
    condiciones["subpartida_id"] = nil if valores[:subpartida] == "isnull"
    condiciones["pais_id"] = valores[:pais] unless valores[:pais].nil? || valores[:pais] == "todos"
    condiciones["pais_id"] = nil if valores[:pais] == "regional"
    # Condiciones especiales para filtrado adicional por implementador o financiador
    condiciones["financiador_id"] = valores[:financiador_id] if valores[:financiador_id] && valores[:financiador_id] != "todos"
    condiciones["implementador_id"] = valores[:implementador_id] if valores[:implementador_id] && valores[:implementador_id] != "todos"
    # Devuelve las condiciones a aplicar
    return condiciones
  end

  # suma elementos en el array principal
  def self.sum_array total, element
    found = false
    total.each do |el|
      if el["columna_id"] == element["columna_id"] && el["fila_id"] == element["fila_id"]
        el["importe"] += element["importe"]
        found = true
      end
    end
    total.push element unless found
    return total
  end

end
