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
class VGasto < ActiveRecord::Base
  #untranslate_all

  # Este sustituye a partida_de_financiador y partida_de_implementador
  scope :sum_partida, lambda { |valores| {
                                 :select => "partida_id as fila_id, #{importe valores} as importe",
                                 :group => "proyecto_id, partida_id #{moneda valores[:moneda]}  #{agente valores} ",
                                 :conditions => condiciones(valores)  } }

  # Este sustituye a actividad_de_implementador y actividad_de_financiador
  scope :sum_actividad, lambda { |valores| {
                                 :select => "actividad_id as fila_id, #{importe valores} as importe",
                                 :group => "proyecto_id, actividad_id #{moneda valores[:moneda]}  #{agente valores} ",
                                 :conditions => condiciones(valores)  } }

  # Este sustituye a partida_proyecto_de_implementador y partida_proyecto_de_financiador
  scope :sum_partida_proyecto, lambda { |valores| {
                                 :select => "partida_proyecto_id as fila_id, #{importe valores} as importe",
                                 :group => "proyecto_id, partida_proyecto_id #{moneda valores[:moneda]} #{agente valores} ",
                                 :conditions => condiciones(valores)  } }

  # valores =  proyecto_id (0), moneda_id (1), agente_id (2), fecha_inicio (3), fecha_fin (4), tasa_cambio (5) 
  scope :sum_actividad_por_partida, lambda { |valores| {
                                 :select => "partida_id as fila_id, #{importe valores} as importe",
                                 :group => "proyecto_id, partida_proyecto_id, actividad_id #{moneda valores[:moneda]} #{agente valores} ",
                                 :conditions => condiciones(valores)  } }

  # Suma agrupando solo por proyectos
  scope :sum_proyecto, lambda { |valores| {
                                 :select => "proyecto_id as fila_id, #{importe valores} as importe, #{valores[:columna_id]||"'n/a'"} as columna_id",
                                 :group => "proyecto_id #{moneda valores[:moneda]} #{agente valores}",
                                 :conditions => condiciones(valores) } }

  # Sustituye a subpartida_partida y a subpartida_partida_proyecto
  # Suma sin hacer agrupaciones devolviendo solo el importe total
  scope :sum_total, lambda { |valores| {
                                 :select => "#{importe valores} as importe",
                                 :conditions => condiciones(valores) } }
                                 
  scope :listado_gastos, lambda { |valores| {
                                  :select => "#{importe valores} as importe, gasto_id",
                                  :conditions => condiciones(valores),
                                  :group => "gasto_id"} }


 # +++
 # Sobrecargamos la clase para incluir agrupaciones 
 # ---
 class << self

  def partida_x_grupos valores={}
    proyecto = valores[:proyecto].class.name == "Proyecto" ? valores[:proyecto] : Proyecto.find_by_id(valores[:proyecto])
    valores[:agente_rol] ||= "financiador"
    # Informacion del financiador principal
    datos  = agrupa_sum_partida(valores.merge(agente: proyecto.agente.id, columna_id: 0))
    # Otras aportaciones publicas externas
    datos += agrupa_sum_partida(valores.merge(agente: proyecto.financiador_externo_publico, columna_id: 1))
    # ONG/Agrupacion externa
    datos += agrupa_sum_partida(valores.merge(agente: proyecto.financiador_externo_ong, columna_id: 2))
    # Otras aportaciones privadas externas
    datos += agrupa_sum_partida(valores.merge(agente: proyecto.financiador_externo_privado, columna_id: 3))
    # ONG Local
    datos += agrupa_sum_partida(valores.merge(agente: proyecto.financiador_local_ong, columna_id: 4))
    # Aportaciones publicas locales
    datos += agrupa_sum_partida(valores.merge(agente: proyecto.financiador_local_publico, columna_id: 5))
    # Aportaciones privadas locales
    datos += agrupa_sum_partida(valores.merge(agente: proyecto.financiador_local_privado, columna_id: 6))
    return datos
  end

  def partida_proyecto_x_grupos valores={}
    proyecto = valores[:proyecto].class.name == "Proyecto" ? valores[:proyecto] : Proyecto.find_by_id(valores[:proyecto])
    valores[:agente_rol] ||= "financiador"
    # Informacion del financiador principal
    datos  = agrupa_sum_partida_proyecto(valores.merge(agente: proyecto.agente.id, columna_id: 0))
    # Otras aportaciones publicas externas
    datos += agrupa_sum_partida_proyecto(valores.merge(agente: proyecto.financiador_externo_publico, columna_id: 1))
    # ONG/Agrupacion externa
    datos += agrupa_sum_partida_proyecto(valores.merge(agente: proyecto.financiador_externo_ong, columna_id: 2))
    # Otras aportaciones privadas externas
    datos += agrupa_sum_partida_proyecto(valores.merge(agente: proyecto.financiador_externo_privado, columna_id: 3))
    # ONG Local
    datos += agrupa_sum_partida_proyecto(valores.merge(agente: proyecto.financiador_local_ong, columna_id: 4))
    # Aportaciones publicas locales
    datos += agrupa_sum_partida_proyecto(valores.merge(agente: proyecto.financiador_local_publico, columna_id: 5))
    # Aportaciones privadas locales
    datos += agrupa_sum_partida_proyecto(valores.merge(agente: proyecto.financiador_local_privado, columna_id: 6))
    return datos
  end

  def actividad_x_grupos valores={}
    proyecto = valores[:proyecto].class.name == "Proyecto" ? valores[:proyecto] : Proyecto.find_by_id(valores[:proyecto])
    valores[:agente_rol] ||= "financiador"
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
    valores[:agente_rol] ||= "financiador"
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
    valores[:agente_rol] ||= "financiador"
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

  # Devuelve un array de hashes con las partidas de proyecto agrupadas (correccion para convenios)
  # Sustituye a agrupa_partida_proyecto_de_financiador y agrupa_partida_proyecto_de_implementador
  def agrupa_sum_partida_proyecto valores={}
    columna_id = valores[:columna_id]||2
    proyecto, pacs = VGasto.proyecto_y_pacs valores

    # Si estamos con un convenio, devolvemos los agrupados segun las partidas de financiacion del convenio (no de los pacs)
    if (pacs)
      g = sum_partida_proyecto valores.merge(proyecto: pacs.collect{|p| p.id})
      gastos = []
      g.each do |p|
        # Hacemos el mapeo del mapeo de partidas
        pf = PartidaFinanciacion.find_by_id(p.fila_id)
        partida_convenio = proyecto.partida_financiacion.find_by_codigo(pf.codigo) if pf
        gastos = sum_array( gastos, { "columna_id" => columna_id, "importe" => p.importe , "fila_id" => partida_convenio.id } ) if partida_convenio
      end
    else
      g = sum_partida_proyecto valores
      gastos = g.collect {|p| {"columna_id" => columna_id, "importe" => p.importe , "fila_id" => p.fila_id }}
    end

    return gastos
  end

  # Devuelve un array de hashes con las partidas de sistema agrupadas (correccion para convenios)
  # Sustituye a agrupa_partida_de_financiador y agrupa_partida_de_implementador
  def agrupa_sum_partida valores={}
    columna_id = valores[:columna_id]||2
    proyecto, pacs = VGasto.proyecto_y_pacs valores

    # Si estamos con un convenio, devolvemos los agrupados segun las partidas de financiacion del convenio (no de los pacs)
    if (pacs)
      g = sum_partida valores.merge(proyecto: pacs.collect{|p| p.id})
      gastos = []
      g.each do |p|
        gastos = sum_array( gastos, { "columna_id" => columna_id, "importe" => p.importe , "fila_id" => p.fila_id } )
      end
    else
      g = sum_partida valores
      gastos = g.collect {|p| {"columna_id" => columna_id, "importe" => p.importe , "fila_id" => p.fila_id }}
    end

    return gastos
  end

  # Devuelve un array de hashes con las actividades del convenio agrupadas (correccion para convenios) para financiadores
  # Sustituye a agrupa_actividad_de_financiador y agrupa_actividad_de_implementador
  def agrupa_sum_actividad valores={}
    columna_id = valores[:columna_id]||2
    proyecto, pacs = VGasto.proyecto_y_pacs valores

    # Si estamos con un convenio, devolvemos los agrupados segun las partidas de financiacion del convenio (no de los pacs)
    if (pacs)
      g = sum_actividad valores.merge(proyecto: pacs.collect{|p| p.id})
      gastos = []
      g.each do |p|
        # Hacemos el mapeo del mapeo de actividades
        actividad_proyecto = Actividad.find_by_id(p.fila_id)
        actividad_convenio = actividad_proyecto ? proyecto.actividad.find_by_id(actividad_proyecto.actividad_convenio_id) : nil
        gastos = sum_array( gastos, { "columna_id" => columna_id, "importe" => p.importe , "fila_id" => (actividad_convenio ? actividad_convenio.id : nil) } )
      end
    else
      g = sum_actividad valores
      gastos = g.collect {|p| {"columna_id" => columna_id, "importe" => p.importe , "fila_id" => p.fila_id }}
    end

    return gastos
  end

  # Devuelve un array de hashes con los resultados del proyecto agrupados para financiadores (usa la correccion para convenios de agrupa_actividad_de_financiador)
  # Sustituye a agrupa_resultado_de_financiador y agrupa_resultado_de_implementador
  def agrupa_sum_resultado valores={}
    columna_id = valores[:columna_id]||2
    gastos_actividades = agrupa_sum_actividad valores
    gastos = []

    # Recorre todas las actividades generando los gastos por resultado
    gastos_actividades.each do |gasto|
      actividad = Actividad.find_by_id gasto["fila_id"]
      # Si no hay actividad ponemos nil y si la hay pero no tiene resultado_id ponemos 0 (acts. generales)
      resultado_id = actividad ? actividad.resultado_id||0 : nil
      gastos = sum_array( gastos, {"columna_id" => columna_id, "importe" => gasto["importe"], "fila_id" => resultado_id} ) 
    end
    return gastos
  end

  # Devuelve un array de hashes con los oe del proyecto agrupados para financiadores (usa la correccion para convenios de agrupa_actividad_de_financiador)
  # Sustituye a agrupa_oe_de_financiador y agrupa_oe_de_implementador
  def agrupa_sum_oe valores={}
    columna_id = valores[:columna_id]||2
    gastos_resultados = agrupa_sum_resultado valores
    gastos = []

    # Recorre todos los resultados generando los gastos por oe 
    gastos_resultados.each do |gasto|
      # Se no habia resultado para la actividad era global, ponemos 0
      if gasto["fila_id"] == 0
        oe_id = 0
      # Si no era con resultado 0 puede que este huerfana de oe o que lo tenga
      else
        resultado = Resultado.find_by_id gasto["fila_id"]
        oe_id = resultado ? resultado.objetivo_especifico_id : nil
      end
      gastos = sum_array( gastos, {"columna_id" => columna_id, "importe" => gasto["importe"], "fila_id" => oe_id} )
    end
    return gastos
  end

 end


 private

  # Segun los valores, obtiene el proyecto al que se hace referencia (el convenio si es un grupo de pacs) y los pacs involucrados
  def self.proyecto_y_pacs valores={}
    proyecto = nil
    pacs = nil
    # A no ser que proyecto este a nil o sea un id o una clase proyecto, asumimos que es un array o un resultset de pacs
    unless valores[:proyecto].nil? || valores[:proyecto].class.name=="Fixnum" || valores[:proyecto].class.name=="Proyecto"
      pacs = valores[:proyecto] if valores[:proyecto].first.class.name == "Proyecto"
      proyecto = pacs.first.convenio if pacs
    # Cuando estamos con una clase proyecto o con un id
    else
      proyecto = Proyecto.find_by_id(valores[:proyecto]) unless valores[:proyecto].class.name=="Proyecto"
      proyecto = valores[:proyecto] if valores[:proyecto].class.name=="Proyecto"
      pacs = proyecto.pacs if proyecto && proyecto.convenio?
    end
    return proyecto, pacs 
  end

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
    condiciones["fecha"] = valores[:fecha_inicio]..valores[:fecha_fin] if valores[:fecha_inicio] && valores[:fecha_fin]
    condiciones["proyecto_id"] = valores[:proyecto] if valores[:proyecto]
    condiciones["moneda_id"] = valores[:moneda] unless valores[:moneda].nil? || valores[:moneda] == "todas"
    condiciones[agente_rol + "_id"] = valores[:agente] unless valores[:agente].nil? || valores[:agente] == "todos"
    condiciones["partida_id"] = valores[:partida] if valores[:partida]
    condiciones["partida_proyecto_id"] = valores[:partida_proyecto] if valores[:partida_proyecto]
    condiciones["subpartida_id"] = valores[:subpartida] if valores[:subpartida]
    condiciones["subpartida_id"] = nil if valores[:subpartida] == "isnull"
    condiciones["pais_id"] = valores[:pais] unless valores[:pais].nil? || valores[:pais] == "todos"
    condiciones["pais_id"] = nil if valores[:pais] == "regional"
    # Condiciones especiales para filtrado adicional por implementador o financiador
    #condiciones["financiador_id"] = valores[:financiador_id] if valores[:financiador_id] && valores[:financiador_id] != "todos"
    #condiciones["implementador_id"] = valores[:implementador_id] if valores[:implementador_id] && valores[:implementador_id] != "todos"
    # Devuelve las condiciones a aplicar
    return condiciones
  end
  
  # Igual que el metodo anterior pero en vez de con "simbol" con "cadenas" para la busqueda de valores
  # def self.condiciones valores={}
  #   agente_rol = valores["agente_rol"]||"financiador"
  #   condiciones = {}
  #   condiciones["fecha"] = valores["fecha_inicio"]..valores["fecha_fin"] if valores["fecha_inicio"] && valores["fecha_fin"]
  #   condiciones["proyecto_id"] = valores["proyecto"] if valores["proyecto"]
  #   condiciones["moneda_id"] = valores["moneda"] unless valores["moneda"].nil? || valores["moneda"] == "todas"
  #   condiciones[agente_rol + "_id"] = valores["agente"] unless valores["agente"].nil? || valores["agente"] == "todos"
  #   condiciones["partida_id"] = valores["partida"] if valores["partida"]
  #   condiciones["partida_proyecto_id"] = valores["partida_proyecto"] if valores["partida_proyecto"]
  #   condiciones["subpartida_id"] = valores["subpartida"] if valores["subpartida"]
  #   condiciones["subpartida_id"] = nil if valores["subpartida"] == "isnull"
  #   condiciones["pais_id"] = valores["pais"] unless valores["pais"].nil? || valores["pais"] == "todos"
  #   condiciones["pais_id"] = nil if valores["pais"] == "regional"
  #   return condiciones
  # end

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
