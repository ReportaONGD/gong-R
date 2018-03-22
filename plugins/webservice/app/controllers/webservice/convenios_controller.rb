# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2014 Red.es 
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
#  Agreements Webservice controller
#
# All webservices are available on /webservice/convenios route
#
# Autorization for all WS are done by GONG OAUTH provider
#
# Returned data is in xml or json format depending the extension of the invoked webservice (ex.):
# * XML Format: /webservice/convenios/datos_generales.xml
# * JSON Format: /webservice/convenios/datos_generales.json
#
# After "get_pacs_from_period_param" filter, all methods has following accesible objects:
#  * @proyecto => Requested agreement "Proyecto" object
#  * @periodo  => Report period "Periodo" object if seguimiento_periodo_id param is used
#  * @pacs     => Array of "Proyecto" objects for annuals of agreement (all annuals if no seguimiento_periodo_id param is sent)
#  * @pac      => "Proyecto" object with last annual period for current report period (last annual if no seguimiento_periodo_id param is sent)
#
# Controlador encargado de los webservices de convenios.

class Webservice::ConveniosController < Webservice::ApplicationController
  include Webservice::Swagger::ConveniosApi

  skip_before_filter :autorizar, :sesion_timeout, :xls_request, :por_pagina, :autorizar_rol
  doorkeeper_for :all

  respond_to :json, :xml

  # Agreement is in correct state and has pac defined and is owned by user
  before_filter :validate_project, :except => [:index]
  # Get pacs from period param and validate it
  before_filter :get_pacs_from_period_param, :except => [:index]

  # Correct content type header
  after_filter :correct_content_type

  # Convenios existentes en estado de "informe" (dejamos esto de momento, pero deberia eliminarse cuando terminen la integracion con oauth)
  # Existing proyects in "report" status
  #   Path: /webservice/convenios
  #   MAY param:
  #     financiador_nombre: Name of the main financier
  def index
    # Seleccionamos solo los proyectos cuyo estado esta relacionado con una definición de estado que permite "reporte""
    # Habria que añadir la condicion de que sean proyectos vinculados al usuario. Esperamos a autenticación
    # El id del usuario que posee el token es doorkeeper_token[:resource_owner_id]
    @proyectos = Proyecto.where(:convenio_id => nil).select {|p| p.estado_actual and p.estado_actual.definicion_estado.reporte  }
    # Se puede pasar como parametro :financiador_nombre para filtrar el listado
    if params[:financiador_nombre]
      @proyectos = @proyectos.select {|p| p.convocatoria.agente.nombre == params[:financiador_nombre] }
    end
    render "webservice/proyectos/index"
  end

  # Datos generales del convenio
  # "I.Gral" sheet
  # Global information about PROJECT_ID agreement/program and PAC related to seguimiento_periodo_id justification period
  #  Path: /webservice/convenios/PROJECT_ID
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def datos_generales
    @otros_financiadores = (@proyecto.financiador.where(:sistema => false) - @proyecto.implementador - [@proyecto.agente, @proyecto.gestor])
  end

  # Matriz planificada del PAC
  # "III.1 Matriz PAC"
  #
  #  Path: /webservice/convenios/PROJECT_ID/matriz_formulacion_pac
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def matriz_formulacion_pac
    @elemento = @pac
    # Indicamos que solo queremos la formulacion y no el seguimiento
    @solo_formulacion = true
    render "webservice/proyectos/matriz"
  end

  # Matriz ejecutada del PAC
  # "III.2 Ejec"
  #
  #  Path: /webservice/convenios/PROJECT_ID/matriz_seguimiento_pac
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def matriz_seguimiento_pac
    @elemento = @pac
    @fecha_fin = @pac.fecha_de_fin
    render "webservice/proyectos/matriz"
  end

  # Matriz acumulada del Convenio 
  # "III.3 Acu"
  #
  #  Path: /webservice/convenios/PROJECT_ID/matriz_seguimiento_acumulada
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def matriz_seguimiento_acumulada
    @elemento = @proyecto
    @fecha_fin = @pac.fecha_de_fin
    render "webservice/proyectos/matriz"
  end

  # Cronograma de seguimiento del PAC
  # "IV. Crng"
  # Shedule tracking activities
  #  Path: /webservice/convenios/PROJECT_ID/cronograma_seguimiento
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def cronograma_seguimiento
    @elemento = @pac
    render "webservice/proyectos/cronograma_seguimiento"
  end

  # Resumen presupuestario del PAC por Acciones
  # "V.1. $Acc" sheet
  # Budget summary by actions
  #  Path: /webservice/convenios/PROJECT_ID/resumen_presupuestario_acciones
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def resumen_presupuestario_acciones
    financiadores = { AECID: @pac.agente, ongd: @pac.financiador_externo_ong, otros: (@pac.financiador - [@proyecto.agente] - @pac.financiador_externo_ong) }
    pptos = {}
    gastos = {}
    financiadores.each do |key,value|
      pptos[key] = { acciones: [] } 
      gastos[key] = { acciones: [] } 
      # Usamos columna_id para evitar que el presupuesto este delgosado para cada uno de los agentes
      filtros = { proyecto: @pac.id, agente: value, columna_id: 0 }
      if @proyecto.convenio_accion == "resultado"
        VPresupuesto.agrupa_sum_resultado(filtros).each do |ppto|
          elem = Resultado.find_by_id ppto["fila_id"]
          pptos[key][:acciones].push({ codigo: (elem ? elem.codigo : "GENERAL"), importe: ppto["importe"] })
        end
        VGasto.agrupa_sum_resultado(filtros).each do |gasto|
          elem = Resultado.find_by_id gasto["fila_id"]
          gastos[key][:acciones].push({ codigo: (elem ? elem.codigo : "GENERAL"), importe: gasto["importe"] })
        end
      else
        VPresupuesto.agrupa_sum_oe(filtros).each do |ppto|
          elem = ObjetivoEspecifico.find_by_id ppto["fila_id"]
          pptos[key][:acciones].push({ codigo: (elem ? elem.codigo : "GENERAL"), importe: ppto["importe"] })
        end
        VGasto.agrupa_sum_oe(filtros).each do |gasto|
          elem = ObjetivoEspecifico.find_by_id gasto["fila_id"]
          gastos[key][:acciones].push({ codigo: (elem ? elem.codigo : "GENERAL"), importe: gasto["importe"] })
        end
      end
    end
    @periodo = {:presupuestado => pptos, :ejecutado => gastos}

    render "balance_presupuestario"
  end

  # Resumen presupuestario del PAC por Países
  # "V.2. $G" sheet
  # Budget summary by countries
  #  Path: /webservice/convenios/PROJECT_ID/resumen_presupuestario_paises
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def resumen_presupuestario_paises
    financiadores = { AECID: @pac.agente, otros: @pac.financiador - [@pac.agente] }
    partidas = {
      sensibilizacion: Partida.joins(:partida_financiacion).where("partida_financiacion.proyecto_id" => @pac.id, "partida_financiacion.codigo" => ["A.XIII.1","A.XIII.2"]),
      otros: Partida.joins(:partida_financiacion).where("partida_financiacion.proyecto_id" => @pac.id, "partida_financiacion.codigo" =>
                       ["A.I","A.II","A.III","A.VII.1","A.VII.2","A.VII.3"]),
      ongd_esp: Partida.joins(:partida_financiacion).where("partida_financiacion.proyecto_id" => @pac.id, "partida_financiacion.codigo" => "B.1"),
      ongd_local: Partida.joins(:partida_financiacion).where("partida_financiacion.proyecto_id" => @pac.id, "partida_financiacion.codigo" => "B.2")
    }
    paises = (@proyecto.pais + [Pais.new(:nombre => "Regional")])
    p_resto = Partida.all - partidas[:ongd_esp] - partidas[:ongd_local] - partidas[:sensibilizacion] - partidas[:otros]

    # Gasto en el pac
    @periodo = {}
    # Gasto desde el principio del convenio
    @acumulado = {}
    # Presupuesto planificado desde el principio del proyecto
    @total = {}
    financiadores.each do |f_key,f_value|
      @periodo[f_key] = { pais: [] }
      @acumulado[f_key] = { pais: [] }  
      @total[f_key] = { pais: [] }
      # Hace los calculos para las filas por partidas (indirectos, sensibilizacion y otros)
      partidas.each do |p_key, p_value|
        # Gastos en el PAC
        @periodo[f_key][p_key] = Gasto.joins(:gasto_x_agente).includes(:gasto_x_proyecto).where("gasto_x_proyecto.proyecto_id" => @pac.id, "gasto_x_agente.agente_id" => f_value, :partida_id => p_value).joins(:gasto_x_proyecto => :tasa_cambio_proyecto).sum("gasto_x_agente.importe*tasa_cambio").to_f
        # Gastos acumulados
        @acumulado[f_key][p_key] = Gasto.joins(:gasto_x_agente).includes(:gasto_x_proyecto).where("gasto_x_proyecto.proyecto_id" => @pacs.collect{|p| p.id}, "gasto_x_agente.agente_id" => f_value, :partida_id => p_value).joins(:gasto_x_proyecto => :tasa_cambio_proyecto).sum("gasto_x_agente.importe*tasa_cambio").to_f
        # Presupuestado total
        @total[f_key][p_key] = Presupuesto.joins(:tasa_cambio).where("presupuesto.proyecto_id" => @proyecto.id,"presupuesto.partida_id" => p_value).includes(:presupuesto_x_agente).where("presupuesto_x_agente.agente_id" => f_value).sum("presupuesto_x_agente.importe * tasa_cambio").to_f
      end
      # Para el resto de partidas lo calculamos agrupado por paises (incluyendo los regionales)
      paises.each do |pais|
        filtros = { pais: pais.id||"regional", agente: f_value, partida: p_resto, etapa: @etapas }
        # Gastos del pais en el PAC
        gastos_pais = VGasto.sum_total( filtros.merge( proyecto: @pac.id ) ).first[:importe]
        # Gastos del pais acumulados
        acumulado_pais = VGasto.sum_total( filtros.merge( proyecto:  @pacs.collect{|p| p.id} ) ).first[:importe] 
        # PPto total por paises (llegamos a el a traves de las actividades)
        ppto_pais = VPresupuesto.sum_total( filtros.merge( proyecto: @proyecto.id ) ).first[:importe]

        @periodo[f_key][:pais].push :nombre => pais.nombre, :importe => (gastos_pais||0.0).to_f
        @acumulado[f_key][:pais].push :nombre => pais.nombre, :importe => (acumulado_pais||0.0).to_f
        @total[f_key][:pais].push :nombre => pais.nombre, :importe => (ppto_pais||0.0).to_f
      end
    end

    render "balance_presupuestario"
  end

  # Resumen presupuestario del PAC para Otros Financiadores
  # "V.3. $O" sheet
  # Budget status by founders 
  #  Path: /webservice/convenios/PROJECT_ID/resumen_presupuestario_otros_financiadores
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def resumen_presupuestario_otros_financiadores
    @otros_financiadores = (@proyecto.financiador.where(:sistema => false) - [@proyecto.agente] - @pac.financiador_externo_ong)
  end

  # Gasto en el PAC por partidas y financiadores
  # "EI.1 $año" sheet
  # Annual expenses by item and funders for PROJECT_ID agreement/program and PAC related to seguimiento_periodo_id justification period
  #  Path: /webservice/convenios/PROJECT_ID/gasto_pac_partidas_y_financiadores
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def gasto_pac_partidas_y_financiadores
    casos = {
       :AECID => @pac.agente.id,
       :exteriores_publicas => @pac.financiador_externo_publico, :exteriores_ongd => @pac.financiador_externo_ong, :exteriores_privadas => @pac.financiador_externo_privado,
       :locales_ongd => @pac.financiador_local_ong, :locales_publico => @pac.financiador_local_publico, :locales_privado => @pac.financiador_local_privado
    }
    @ejecutado = {}
    casos.each do |k,v|
      @ejecutado[k] = {partidas: []}
      g = VGasto.sum_partida_proyecto(proyecto: @pac.id, agente: v, fecha_inicio: @pac.fecha_de_inicio, fecha_fin: @pac.fecha_de_fin)
      g.each do |p|
        pf = PartidaFinanciacion.find_by_id p.fila_id
        @ejecutado[k][:partidas].push( { partida_id: p.fila_id, nombre: pf.nombre, codigo: pf.codigo, importe: p.importe }) if pf
      end
    end
    render "gasto_partidas_y_financiadores"
  end

  # Gasto acumulado en el Convenio por partidas y financiadores
  # "EI.2 $acu" sheet
  # Accumulated expenses by item and funders for PROJECT_ID agreement/program until (and including) PAC related to seguimiento_periodo_id justification period
  #  Path: /webservice/convenios/PROJECT_ID/gasto_acumulado_partidas_y_financiadores
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def gasto_acumulado_partidas_y_financiadores
    casos = {
       :AECID => @pac.agente.id,
       :exteriores_publicas => @pac.financiador_externo_publico, :exteriores_ongd => @pac.financiador_externo_ong, :exteriores_privadas => @pac.financiador_externo_privado,
       :locales_ongd => @pac.financiador_local_ong, :locales_publico => @pac.financiador_local_publico, :locales_privado => @pac.financiador_local_privado
    }
    @ejecutado = {}
    casos.each do |k,v|
      g = VGasto.sum_partida_proyecto(proyecto: @pacs.collect{|p| p.id}, agente: v, fecha_inicio: @proyecto.fecha_de_inicio, fecha_fin: @proyecto.fecha_de_fin)
      gastos = []
      g.each do |p|
        # Hacemos el mapeo del mapeo de partidas (pasamos todas a la referencia del convenios)
        pf = PartidaFinanciacion.find_by_id(p.fila_id)
        pc = @proyecto.partida_financiacion.find_by_codigo(pf.codigo) if pf
        gastos = sum_array( gastos, { partida_id: pc.id, nombre: pc.nombre, codigo: pc.codigo, importe: p.importe }, :partida_id ) if pc
      end
      @ejecutado[k] = {partidas: gastos}
    end
    render "gasto_partidas_y_financiadores"
  end

  # Seguimiento del presupuesto ejecutado por partidas
  # "EII.1 B" sheet
  # Budget execution by items for PROJECT_ID agreement/program until (and including) PAC related to seguimiento_periodo_id justification period
  #  Path: /webservice/convenios/PROJECT_ID/balance_presupuestario_partidas
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def balance_presupuestario_partidas
    @periodo = {}
    @periodo[:presupuestado] = {:partidas => @pac.presupuesto_total_x_partidas_proyecto(:financiador => @pac.agente)}
    @periodo[:ejecutado] = {:partidas => @pac.gasto_total_x_partidas_proyecto(:financiador => @pac.agente, :fecha_inicio => @pac.fecha_de_inicio, :fecha_fin => @pac.fecha_de_fin)}

    presupuestos = []
    gastos = []
    @pacs.each do |mypac|
      p=mypac.presupuesto_total_x_partidas_proyecto(:financiador => mypac.agente)
      g=mypac.gasto_total_x_partidas_proyecto(:financiador => mypac.agente, :fecha_inicio => mypac.fecha_de_inicio, :fecha_fin => mypac.fecha_de_fin)
      # Recorremos todos los resultados porque tenemos que ajustar los ids de las partidas
      p.each do |presup|
        pf = PartidaFinanciacion.find_by_id(presup[:partida_id])
        pc = @proyecto.partida_financiacion.find_by_codigo(pf.codigo) if pf
        presupuestos = sum_array( presupuestos, { partida_id: pc.id, nombre: pc.nombre, codigo: pc.codigo, importe: presup[:importe] }, :partida_id ) if pc
      end
      g.each do |gasto|
        pf = PartidaFinanciacion.find_by_id(gasto[:partida_id])
        pc = @proyecto.partida_financiacion.find_by_codigo(pf.codigo) if pf
        gastos = sum_array( gastos, { partida_id: pc.id, nombre: pc.nombre, codigo: pc.codigo, importe: gasto[:importe] }, :partida_id ) if pc
      end
    end
    @acumulado = {:presupuestado => {:partidas => presupuestos}, :ejecutado => {:partidas => gastos}}

    render "balance_presupuestario"
  end

  # Seguimiento del presupuesto ejecutado por acciones
  # "EII.2 B A" sheet
  # Budget execution by actions for PROJECT_ID agreement/program until (and including) PAC related to seguimiento_periodo_id justification period
  #  Path: /webservice/convenios/PROJECT_ID/balance_presupuestario_acciones
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def balance_presupuestario_acciones

    # Valores para el periodo seleccionado (presupuesto y gasto del pac)
    pptos = []
    gastos = []
    filtros = { proyecto: @pac.id, agente: @pac.agente, fecha_inicio: @pac.fecha_de_inicio, fecha_fin: @pac.fecha_de_fin }
    if @proyecto.convenio_accion == "resultado"
      VPresupuesto.agrupa_sum_resultado(filtros).each do |ppto|
        elem = Resultado.find_by_id ppto["fila_id"]
        pptos.push({ codigo: (elem ? elem.codigo : "GENERAL"), importe: ppto["importe"] })
      end
      VGasto.agrupa_sum_resultado(filtros).each do |gasto|
        elem = Resultado.find_by_id gasto["fila_id"]
        gastos.push({ codigo: (elem ? elem.codigo : "GENERAL"), importe: gasto["importe"] })
      end 
    else
      VPresupuesto.agrupa_sum_oe(filtros).each do |ppto|
        elem = ObjetivoEspecifico.find_by_id ppto["fila_id"]
        pptos.push({ codigo: (elem ? elem.codigo : "GENERAL"), importe: ppto["importe"] })
      end
      VGasto.agrupa_sum_oe(filtros).each do |gasto|
        elem = ObjetivoEspecifico.find_by_id gasto["fila_id"]
        gastos.push({ codigo: (elem ? elem.codigo : "GENERAL"), importe: gasto["importe"] })
      end
    end
    @periodo = {:presupuestado => {:acciones => pptos}, :ejecutado => {:acciones => gastos}}

    # Acumulados de todo el convenio (presupuesto general y gasto acumulado hasta el pac informado)
    pptos = []
    gastos = []
    filtros = { agente: @pac.agente, fecha_inicio: @proyecto.fecha_de_inicio, fecha_fin: @pac.fecha_de_fin }
    # Las etapas para el presupuesto seran las anteriores (incluidas) al pac indicado
    if @proyecto.convenio_accion == "resultado"
      # Para el presupuesto, se calcula solo la suma del presupuesto general de las etapas del convenio
      VPresupuesto.agrupa_sum_resultado(filtros.merge(proyecto:@proyecto, etapa: @etapas)).each do |ppto|
        elem = Resultado.find_by_id ppto["fila_id"]
        pptos.push({ codigo: (elem ? elem.codigo : "GENERAL"), importe: ppto["importe"] })
      end
      VGasto.agrupa_sum_resultado(filtros.merge(proyecto:@pacs)).each do |gasto|
        elem = Resultado.find_by_id gasto["fila_id"]
        gastos.push({ codigo: (elem ? elem.codigo : "GENERAL"), importe: gasto["importe"] })
      end
    else
      VPresupuesto.agrupa_sum_oe(filtros.merge(proyecto:@proyecto, etapa: @etapas)).each do |ppto|
        elem = ObjetivoEspecifico.find_by_id ppto["fila_id"]
        pptos.push({ codigo: (elem ? elem.codigo : "GENERAL"), importe: ppto["importe"] })
      end
      VGasto.agrupa_sum_oe(filtros.merge(proyecto:@pacs)).each do |gasto|
        elem = Resultado.find_by_id gasto["fila_id"]
        gastos.push({ codigo: (elem ? elem.codigo : "GENERAL"), importe: gasto["importe"] })
      end
    end
    @acumulado = {:presupuestado => {:acciones => pptos}, :ejecutado => {:acciones => gastos}}

    render "balance_presupuestario"
  end

  # Cuentas Bancarias
  # "EIII.1 T" sheet
  # Bank accounts 
  #  Path: /webservice/convenios/PROJECT_ID/personal
  #  PROJECT_ID: ID of the agreetment as shown in proyecto webservice
  def cuentas_bancarias
  end

  # Tesoreria
  # "EIII.2 T" sheet
  # Project Cash
  #  Path: /webservice/convenios/PROJECT_ID/tesoreria
  #  PROJECT_ID: ID of the agreetment as shown in proyecto webservice
  def tesoreria
    tesoreria = @pac.tesoreria @pac.agente, @pac.etapa.first, false
    columnas = tesoreria[0].collect{|t| Moneda.find_by_id(t[:moneda_id]).abreviatura + (t[:pais_id] ? " " + Pais.find_by_id(t[:pais_id]).nombre : "")}
    @periodo = {:nombre_filas => tesoreria[1], :nombre_columnas => columnas, :fila_datos => tesoreria[2]}
    render "balance_presupuestario"
  end

  # Relacion de Personal
  # "EIV.1 P" sheet
  # Staff
  #  Path: /webservice/convenios/PROJECT_ID/personal
  #  PROJECT_ID: ID of the agreetment as shown in proyecto webservice
  def personal
    render "webservice/proyectos/personal"
  end

  # Transferencias desde la cuenta principal del convenio 
  # "EV.1 Tr"
  # Transfers to agreetment accounts by donors and countries
  #  Path: /webservice/convenios/PROJECT_ID/transferencias_convenio
  #  PROJECT_ID: ID of the agreetment as shown in proyecto webservice
  def transferencias_convenio
    # Recoge toda transferencia de euros a divisas
    @periodos = []
    libros_origen = @proyecto.libro.where(:moneda_id => @proyecto.moneda_principal.id)
    libros_destino = @proyecto.libro.where(:moneda_id => @proyecto.moneda_intermedia.id) if @proyecto.moneda_intermedia
    # Elimina los libros en divisa que son moneda local en el pais
    libros_divisa = libros_destino.select{|l| !l.pais.moneda.include?(@proyecto.moneda_intermedia) } if libros_destino

    @pacs.each do |pac|
      TasaCambio.joins(:etapa).where("etapa.id" => pac.etapa, :objeto => "gasto", :moneda_id => @proyecto.moneda_intermedia.id).each do |tc|
        cond = {:libro_origen_id => libros_origen, :libro_destino_id => libros_divisa, "fecha_recibido" => tc.fecha_inicio..tc.fecha_fin}
        transf = pac.transferencia.where(cond).where("transferencia.tipo != 'remanente'")
        @periodos.push({:fecha_inicio => tc.fecha_inicio, :fecha_fin => tc.fecha_fin, :transferencias => formatea_transferencias(transf)})
      end
    end if @proyecto.moneda_intermedia
    render "transferencias"
  end

  # Resto de transferencias y operaciones de cambio 
  # "EV.2 TxP" sheet
  # Transfers from agreetment accounts by donors and countries
  #  Path: /webservice/convenios/PROJECT_ID/transferencias_paises
  #  PROJECT_ID: ID of the agreetment as shown in proyecto webservice
  def transferencias_paises
    # Recoge todas las transferencias salvo las de la cuenta de subvencion hacia alguna cuenta nuestra ordenadas por paises
    libros_origen = @proyecto.libro.where(:moneda_id => [@proyecto.moneda_principal.id, @proyecto.moneda_intermedia.id])

    # Recoge toda transferencia enviada desde la cuenta de subvencion ordenadas por paises destino
    # Primero agrupamos por paises
    @paises = []
    @proyecto.pais.collect do |pais|
      # Para cada pais, sus monedas
      monedas = []
      pais.moneda.each do |moneda|
        # Obtenemos los periodos para el calculo de TC iterando los pacs
        periodos = []
        @pacs.each do |pac|
          TasaCambio.joins(:etapa).where("etapa.id" => pac.etapa, :objeto => "gasto", :moneda_id => moneda.id).each do |tc|
            cond = {"libro.pais_id" => pais.id, "libro.moneda_id" => moneda.id, "fecha_recibido" => tc.fecha_inicio..tc.fecha_fin}
            transf = pac.transferencia.where(:libro_origen_id => libros_origen).includes(:libro_destino).where(cond)
            periodos.push :fecha_inicio => tc.fecha_inicio, :fecha_fin => tc.fecha_fin, :transferencias => formatea_transferencias(transf) 
          end
        end
        monedas.push :nombre => moneda.nombre, :abreviatura => moneda.abreviatura, :periodos => periodos
      end
      @paises.push :nombre => pais.nombre, :monedas => monedas
    end
    render "transferencias"
  end

  # Listado de comprobantes
  # "EVI. C" sheet
  # Invoices list 
  #  Path: /webservice/convenios/PROJECT_ID/comprobantes
  #  PROJECT_ID: ID of the project as shown in proyecto webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def comprobantes
    @elemento = @pac
    @gastos = Gasto.joins(:gasto_x_proyecto).where("gasto_x_proyecto.proyecto_id" => @elemento.id).
                order("gasto_x_proyecto.orden_factura")
    render "webservice/proyectos/comprobantes"
  end

  # Listado de documentos de fuentes de verificación
  # List of verification documents for PAC related to seguimiento_periodo_id justification period
  #  Path: /webservice/convenios/PROJECT_ID/documentos_fuentes_verificacion
  #  PROJECT_ID: ID of the agreement as shown in proyectos webservice
  def documentos_fuentes_verificacion
    @fuentes_verificacion = []
    @pac.objetivo_especifico.each {|oe| @fuentes_verificacion += oe.fuente_verificacion }
    @pac.resultado.each {|r| @fuentes_verificacion += r.fuente_verificacion }
    render "webservice/proyectos/documentos_fuentes_verificacion"
  end


  # Bienes Adquiridos
  # Goods acquired 
  #  Path: /webservice/convenios/PROJECT_ID/bienes_adquiridos
  #  PROJECT_ID: ID of the project as shown in proyecto webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def bienes_adquiridos 
    @elemento = @pac
    # Recogemos todos los gastos correspondientes a las partidas de Costes Directos de Inversion
    partidas_financiador_bienes = @pac.partida_financiacion.where(:codigo => ["A.IV.1","A.V","A.VI"])
    partidas_bienes = Partida.joins(:partida_x_partida_financiacion).where("partida_x_partida_financiacion.partida_financiacion_id" => partidas_financiador_bienes)
    @fecha_fin ||= @pac.fecha_de_fin
    @gastos = Gasto.joins(:gasto_x_proyecto).where("gasto_x_proyecto.proyecto_id" => @pac.id).
                where(:partida_id => partidas_bienes).
                where(["fecha < ? OR fecha_informe < ?",@fecha_fin, @fecha_fin]).
                order("fecha")
    render "webservice/proyectos/bienes_adquiridos"
  end


private

  # Needed to send correct content type header
  def correct_content_type
    headers['Content-Type'] = request.format.to_s + "; charset=" + ( response.charset.nil? ? "utf-8" : response.charset.to_s)
  end

  # Get all PACs before begining report date
  def get_pacs_from_period_param
    @periodo = @proyecto.periodo.find_by_id params[:seguimiento_periodo_id]
    fecha_limite = @periodo ? @periodo.fecha_inicio : @proyecto.fecha_de_fin + 1.days
    @pacs = Proyecto.where(:convenio_id => @proyecto.id).includes("etapa").where("etapa.fecha_fin < ?",fecha_limite).order("etapa.fecha_fin")
    # Etapas del convenio
    @etapas = @proyecto.etapa.where("fecha_fin < ?", fecha_limite)
    @pac = @pacs.last
    head :not_found if (params[:seguimiento_periodo_id] && @periodo.nil?) || @pac.nil?
  end

  def validate_project
    if @proyecto.nil? || @proyecto.convenio_accion.nil? || @proyecto.estado_actual.nil? || @proyecto.estado_actual.definicion_estado.nil? || !@proyecto.estado_actual.definicion_estado.reporte
      head :forbidden
    end
  end

  # Para sumar arrays de partidas de diferentes proyectos
  def sum_array total, element, key=:partida_id
    found = false
    total.each do |el|
      if el[key] == element[key]
        el[:importe] += element[:importe]
        found = true
      end
    end
    total.push element unless found
    return total
  end  

  # Formatea las transferencias para salida
  def formatea_transferencias transf=[]
    transf.collect do |t|
      {:fecha_enviado => t.fecha_enviado, :enviado => t.importe_enviado, :moneda_enviada => t.libro_origen.moneda.abreviatura, :fecha_recibido => t.fecha_recibido, :recibido => t.importe_recibido, :moneda_recibida => t.libro_origen.moneda.abreviatura, :obtenido => t.importe_cambiado, :moneda_obtenida => t.libro_destino.moneda.abreviatura, :tasa_cambio => t.tasa_cambio, :destinatario => t.libro_destino.agente.nombre, :financiador => t.nombres_financiadores, :cuenta_origen => t.libro_origen.nombre, :cuenta_destino => t.libro_destino.nombre, :observaciones => t.observaciones }
    end
  end
end
