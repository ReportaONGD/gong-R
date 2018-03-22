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
class VPresupuesto < ActiveRecord::Base
  #untranslate_all

  # En todos los metodos, si no se indica columna_id se desglosa por financiadores o implementadores

  # Devuelve sumas por partidas.
  # Sustituye a partida_implementador, partida_financiador y partida_financiador_agrupado
  scope :sum_partida, lambda { |valores| {
                                 :select => "partida_id as fila_id, #{importe valores} as importe, #{columna valores} as columna_id",
                                 :group => "proyecto_id, partida_id #{moneda valores[:moneda]} #{agente valores} #{etapa valores[:etapa]}",
                                 :conditions => condiciones(valores) } }

  # Devuelve sumas por actividades.
  # Sustituye a actividad_implementador, actividad_financiador y actividad_financiador_agrupado
  scope :sum_actividad, lambda { |valores| {
                                 :select => "actividad_id as fila_id, #{importe valores} as importe, #{columna valores} as columna_id",
                                 :group => "proyecto_id, actividad_id #{moneda valores[:moneda]} #{agente valores} #{etapa valores[:etapa]}",
                                 :conditions => condiciones(valores) } }


  # Devuelve sumas por partidas del proyecto.
  # Sustituye a partida_proyecto_implementador, partida_proyecto_financiador y partida_proyecto_financiador_agrupado
  scope :sum_partida_proyecto, lambda { |valores| {
                                 :select => "partida_proyecto_id as fila_id, #{importe valores} as importe, #{columna valores} as columna_id",
                                 :group => "proyecto_id, partida_proyecto_id #{moneda valores[:moneda]} #{agente valores} #{etapa valores[:etapa]}",
                                 :conditions => condiciones(valores) } }

  # Suma sin hacer agrupaciones devolviendo solo el importe total
  # Sustituye a financiador, subpartida_partida, subpartida_partida_proyecto, partida y partida_proyecto
  scope :sum_total, lambda { |valores| {
                                 :select => "#{importe valores} as importe",
                                 :conditions => condiciones(valores) } }

 # +++
 # Sobrecargamos la clase para incluir agrupaciones 
 # ---
 class << self

   # Para agrupaciones de datos, tenemos que construir la tabla columna a columna
   def partida_x_grupos valores={}
     proyecto = valores[:proyecto].class.name == "Proyecto" ? valores[:proyecto] : Proyecto.find_by_id(valores[:proyecto])
     valores[:agente_rol] = "financiador"
     datos = []
     # Informacion del financiador principal
     datos  = sum_partida(valores.merge(agente: proyecto.agente.id, columna_id: 0))
     # Otras aportaciones publicas externas
     datos += sum_partida(valores.merge(agente: proyecto.financiador_externo_publico, columna_id: 1))
     # ONG/Agrupacion externa
     datos += sum_partida(valores.merge(agente: proyecto.financiador_externo_ong, columna_id: 2))
     # Otras aportaciones privadas externas
     datos += sum_partida(valores.merge(agente: proyecto.financiador_externo_privado, columna_id: 3))
     # ONG Local
     datos += sum_partida(valores.merge(agente: proyecto.financiador_local_ong, columna_id: 4))
     # Aportaciones publicas locales
     datos += sum_partida(valores.merge(agente: proyecto.financiador_local_publico, columna_id: 5))
     # Aportaciones privadas locales
     datos += sum_partida(valores.merge(agente: proyecto.financiador_local_privado, columna_id: 6))

     return datos
   end

   def partida_proyecto_x_grupos valores={}
     proyecto = valores[:proyecto].class.name == "Proyecto" ? valores[:proyecto] : Proyecto.find_by_id(valores[:proyecto])
     valores[:agente_rol] = "financiador" 
     datos = []
     # Informacion del financiador principal
     datos  = sum_partida_proyecto(valores.merge(agente: proyecto.agente.id, columna_id: 0))
     # Otras aportaciones publicas externas
     datos += sum_partida_proyecto(valores.merge(agente: proyecto.financiador_externo_publico, columna_id: 1))
     # ONG/Agrupacion externa
     datos += sum_partida_proyecto(valores.merge(agente: proyecto.financiador_externo_ong, columna_id: 2))
     # Otras aportaciones privadas externas
     datos += sum_partida_proyecto(valores.merge(agente: proyecto.financiador_externo_privado, columna_id: 3))
     # ONG Local
     datos += sum_partida_proyecto(valores.merge(agente: proyecto.financiador_local_ong, columna_id: 4))
     # Aportaciones publicas locales
     datos += sum_partida_proyecto(valores.merge(agente: proyecto.financiador_local_publico, columna_id: 5))
     # Aportaciones privadas locales
     datos += sum_partida_proyecto(valores.merge(agente: proyecto.financiador_local_privado, columna_id: 6))

     return datos
   end

   def actividad_x_grupos valores={}
     proyecto = valores[:proyecto].class.name == "Proyecto" ? valores[:proyecto] : Proyecto.find_by_id(valores[:proyecto])
     valores[:agente_rol] = "financiador"
     datos = []
     # Informacion del financiador principal
     datos  = agrupa_sum_actividad(valores.merge(agente: proyecto.agente.id, columna_id: 0))
     # Otras aportaciones publicas externas
     datos += agrupa_sum_actividad(valores.merge(agente: proyecto.financiador_externo_publico, columna_id: 1))
     # ONG/Agrupacion externa
     datos += agrupa_sum_actividad(valores.merge(agente: proyecto.financiador_externo_ong, columna_id: 2))
     # Otras aportaciones privadas externas
     datos += agrupa_sum_actividad(valores.merge(agente: proyecto.financiador_externo_privado, columna_id: 3))
     # ONG Local
     datos += agrupa_sum_actividad(valores.merge(agente: proyecto.financiador_local_ong, columna_id: 4))
     # Aportaciones publicas locales
     datos += agrupa_sum_actividad(valores.merge(agente: proyecto.financiador_local_publico, columna_id: 5))
     # Aportaciones privadas locales
     datos += agrupa_sum_actividad(valores.merge(agente: proyecto.financiador_local_privado, columna_id: 6))

     return datos
   end

   def resultado_x_grupos valores={}
     proyecto = valores[:proyecto].class.name == "Proyecto" ? valores[:proyecto] : Proyecto.find_by_id(valores[:proyecto])
     valores[:agente_rol] = "financiador"
     datos = []
     # Informacion del financiador principal
     datos  = agrupa_sum_resultado(valores.merge(agente: proyecto.agente.id, columna_id: 0))
     # Otras aportaciones publicas externas
     datos += agrupa_sum_resultado(valores.merge(agente: proyecto.financiador_externo_publico, columna_id: 1))
     # ONG/Agrupacion externa
     datos += agrupa_sum_resultado(valores.merge(agente: proyecto.financiador_externo_ong, columna_id: 2))
     # Otras aportaciones privadas externas
     datos += agrupa_sum_resultado(valores.merge(agente: proyecto.financiador_externo_privado, columna_id: 3))
     # ONG Local
     datos += agrupa_sum_resultado(valores.merge(agente: proyecto.financiador_local_ong, columna_id: 4))
     # Aportaciones publicas locales
     datos += agrupa_sum_resultado(valores.merge(agente: proyecto.financiador_local_publico, columna_id: 5))
     # Aportaciones privadas locales
     datos += agrupa_sum_resultado(valores.merge(agente: proyecto.financiador_local_privado, columna_id: 6))

     return datos
   end

   def oe_x_grupos valores={}
     proyecto = valores[:proyecto].class.name == "Proyecto" ? valores[:proyecto] : Proyecto.find_by_id(valores[:proyecto])
     valores[:agente_rol] = "financiador"
     datos = []
     # Informacion del financiador principal
     datos  = agrupa_sum_oe(valores.merge(agente: proyecto.agente.id, columna_id: 0))
     # Otras aportaciones publicas externas
     datos += agrupa_sum_oe(valores.merge(agente: proyecto.financiador_externo_publico, columna_id: 1))
     # ONG/Agrupacion externa
     datos += agrupa_sum_oe(valores.merge(agente: proyecto.financiador_externo_ong, columna_id: 2))
     # Otras aportaciones privadas externas
     datos += agrupa_sum_oe(valores.merge(agente: proyecto.financiador_externo_privado, columna_id: 3))
     # ONG Local
     datos += agrupa_sum_oe(valores.merge(agente: proyecto.financiador_local_ong, columna_id: 4))
     # Aportaciones publicas locales
     datos += agrupa_sum_oe(valores.merge(agente: proyecto.financiador_local_publico, columna_id: 5))
     # Aportaciones privadas locales
     datos += agrupa_sum_oe(valores.merge(agente: proyecto.financiador_local_privado, columna_id: 6))

     return datos
   end

  # Devuelve un array de hashes con las actividades del convenio agrupadas (correccion para convenios) para financiadores
  # Sustituye a agrupa_actividad_de_financiador
  def agrupa_sum_actividad valores={}
    default_col_id = valores[:columna_id]||2
    unless valores[:proyecto].class.name=="Fixnum" || valores[:proyecto].class.name=="Proyecto"
      pacs = valores[:proyecto] if valores[:proyecto].first.class.name == "Proyecto"
      proyecto = pacs.first.convenio if pacs
    else
      pacs = nil
      proyecto = Proyecto.find_by_id(valores[:proyecto])
    end

    # Si estamos con un convenio, devolvemos los agrupados segun las partidas de financiacion del convenio (no de los pacs)
    if (pacs)
      p = sum_actividad valores.merge(proyecto: pacs.collect{|p| p.id})
      pptos = []
      p.each do |a|
        # Hacemos el mapeo del mapeo de actividades
        actividad_proyecto = Actividad.find_by_id(a.fila_id)
        columna_id = a.columna_id || default_col_id
        actividad_convenio = actividad_proyecto ? proyecto.actividad.find_by_id(actividad_proyecto.actividad_convenio_id) : nil
        pptos = sum_array( pptos, { "columna_id" => columna_id, "importe" => a.importe , "fila_id" => (actividad_convenio ? actividad_convenio.id : nil) } )
      end
    else
      p = sum_actividad valores.merge(proyecto: proyecto)
      pptos = p.collect {|a| {"columna_id" => (a.columna_id||default_col_id), "importe" => a.importe , "fila_id" => a.fila_id }}
    end

    return pptos
  end

  # Devuelve un array de hashes con los resultados del proyecto agrupados para financiadores (usa la correccion para convenios de agrupa_actividad_de_financiador)
  # Sustituye a agrupa_resultado_de_financiador
  def agrupa_sum_resultado valores={}
    default_col_id = valores[:columna_id]||2
    pptos_actividades = agrupa_sum_actividad valores
    pptos = []

    # Recorre todas las actividades generando los gastos por resultado
    pptos_actividades.each do |ppto|
      actividad = Actividad.find_by_id ppto["fila_id"]
      # Si no hay actividad ponemos nil y si la hay pero no tiene resultado_id ponemos 0 (acts. generales)
      resultado_id = actividad ? actividad.resultado_id||0 : nil
      pptos = sum_array( pptos, {"columna_id" => (ppto["columna_id"]||default_co_id), "importe" => ppto["importe"], "fila_id" => resultado_id} ) 
    end
    return pptos 
  end

  # Devuelve un array de hashes con los oe del proyecto agrupados para financiadores (usa la correccion para convenios de agrupa_actividad_de_financiador)
  # Sustituye a agrupa_oe_de_financiador
  def agrupa_sum_oe valores={}
    default_col_id = valores[:columna_id]||2
    pptos_resultados = agrupa_sum_resultado valores
    pptos = []

    # Recorre todos los resultados generando los pptos por oe 
    pptos_resultados.each do |ppto|
      # Se no habia resultado para la actividad era global, ponemos 0
      if ppto["fila_id"] == 0
        oe_id = 0
      # Si no era con resultado 0 puede que este huerfana de oe o que lo tenga
      else
        resultado = Resultado.find_by_id ppto["fila_id"]
        oe_id = resultado ? resultado.objetivo_especifico_id : nil
      end
      pptos = sum_array( pptos, {"columna_id" => (ppto["columna_id"]||default_col_id), "importe" => ppto["importe"], "fila_id" => oe_id} )
    end
    return pptos 
  end

 end

  def self.columnas_financiador_agrupado proyecto
    return [
                {"id" => 0, "nombre" => proyecto.agente.nombre},
                {"id" => 1, "nombre" => _("Otras Aportaciones Públicas Externas")},
                {"id" => 2, "nombre" => _("ONG/Agrupación")},
                {"id" => 3, "nombre" => _("Otras Aportaciones Privadas Externas")},
                {"id" => 4, "nombre" => _("ONG Local")},
                {"id" => 5, "nombre" => _("Aportaciones Públicas Locales")},
                {"id" => 6, "nombre" => _("Población Beneficiaria/Aportaciones Privadas")}
           ]
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

  def self.etapa etapa_id 
    return (etapa_id.nil? || etapa_id == "todas") ? "" : ", etapa_id" 
  end

  # No entiendo bien el sentido de esto... se usa solo en el group, pero no veo para que...
  #   quizas una herencia de haberse copiado desde la vista de presupuestos o tiene que ver con agentes? 
  # Le he metido otra condicion para que lo ignore cuando lo que se manda es un array de agentes (financiadores agrupados)
  def self.agente valores={}
    agente_rol = valores[:agente_rol]||"financiador"
    return ", #{agente_rol}_id "
  end

  # Define la "columna_id" a mostrar en la vista"
  def self.columna valores={}
    agente_rol = valores[:agente_rol]||"financiador"
    return valores[:columna_id]||"#{agente_rol}_id"
  end
  
  # Establece las condiciones para los scopes
  def self.condiciones valores={}
    agente_rol = valores[:agente_rol]||"financiador"
    condiciones = {}
    condiciones["proyecto_id"] = valores[:proyecto] if valores[:proyecto]
    condiciones["etapa_id"] = valores[:etapa] unless valores[:etapa].nil? || valores[:etapa] == "todas"
    condiciones["moneda_id"] = valores[:moneda] unless valores[:moneda].nil? || valores[:moneda] == "todas"
    condiciones[agente_rol + "_id"] = valores[:agente] unless valores[:agente].nil? || valores[:agente] == "todos"
    condiciones["partida_id"] = valores[:partida] if valores[:partida]
    condiciones["partida_proyecto_id"] = valores[:partida_proyecto] if valores[:partida_proyecto]
    condiciones["subpartida_id"] = valores[:subpartida] if valores[:subpartida]
    condiciones["subpartida_id"] = nil if valores[:subpartida] == "isnull"
    condiciones["pais_id"] = valores[:pais] unless valores[:pais].nil? || valores[:pais] == "todos"
    condiciones["pais_id"] = nil if valores[:pais] == "regional"
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
