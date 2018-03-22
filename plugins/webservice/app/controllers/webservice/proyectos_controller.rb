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
# Projects Webservice controller
#
# All webservices are available on /webservice/proyectos route
#
# Autorization for all WS are done by GONG OAUTH provider
#
# Returned data is in xml or json format depending the extension of the invoked webservice (ex.):
# * XML Format: /webservice/proyectos/datos_generales.xml
# * JSON Format: /webservice/proyectos/datos_generales.json
#
# Controlador encargado de los webservices.

class Webservice::ProyectosController < Webservice::ApplicationController
  include Webservice::Swagger::ProyectosApi
  skip_before_filter :autorizar, :sesion_timeout, :xls_request, :por_pagina, :autorizar_rol
  #doorkeeper_for :all

  respond_to :json, :xml

  # Get project report period and validate it
  before_filter :get_dates_from_period_param, :except => [:index]
  # Project is in correct state and is owned by user
  before_filter :validate_project, :except => [:index]

  # Correct content type header
  after_filter :correct_content_type

  # Proyectos existentes en estado de "informe"
  # Existing proyects in "report" status
  #   Path: /webservice/proyectos
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
  end
 
  # Datos generales del proyecto
  # Global information about PROJECT_ID project (Sheet 'I. Datos Generales' of AECID Project's Monitoring and Final Report)
  #  Path: /webservice/proyectos/PROJECT_ID
  #  PROJECT_ID: ID of the project as shown in proyectos webservice
  def datos_generales 
    # Los condicionales en el rabl con child funcionan algo raro con lo que pongo esta condicion en el controlador
    # Name could be translated to another language so it should be filtered by "sistema" attribute instead
    @otros_financiadores = (@proyecto.financiador.where(:sistema => false) - @proyecto.implementador - [@proyecto.agente, @proyecto.gestor]) 
  end

  # Información de seguimiento de la Matriz del Marco Lógico del proyecto 
  # LFM monitoring information from PROJECT_ID project
  #  Path: /webservice/proyectos/PROJECT_ID/matriz_seguimiento
  #  PROJECT_ID: ID of the project as shown in proyectos webservice
  #  MAY param: fecha_fin . Ending date for indicator and activity status
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def matriz_seguimiento
    @elemento = @proyecto
    @fecha_fin ||= @elemento.fecha_de_fin
    render "matriz" 
  end

  # Cronograma de seguimiento de Actividades del proyecto 
  # Shedule tracking activities from PROJECT_ID project
  #  Path: /webservice/proyectos/PROJECT_ID/cronograma_seguimiento
  #  PROJECT_ID: ID of the project as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def cronograma_seguimiento
    @elemento = @proyecto
  end

  # Listado de documentos de fuentes de verificación
  # List of verification documents
  #  Path: /webservice/proyectos/PROJECT_ID/documentos_fuentes_verificacion
  #  PROJECT_ID: ID of the project as shown in proyectos webservice
  def documentos_fuentes_verificacion
    @fuentes_verificacion = []
    @proyecto.objetivo_especifico.each {|oe| @fuentes_verificacion += oe.fuente_verificacion }
    @proyecto.resultado.each {|r| @fuentes_verificacion += r.fuente_verificacion }
  end

  # Resumen financiero del proyecto
  # Financial summary of PROJECT_ID project
  #  Path: /webservice/proyectos/PROJECT_ID/resumen_financiero
  #  PROJECT_ID: ID of the project as shown in proyectos webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def resumen_financiero
    @previsto = {:subvencion => @proyecto.presupuesto_total_con_tc(:financiador => @proyecto.agente)}
    @previsto[:rendimientos] = nil
    @previsto[:exteriores_ongd] = @proyecto.presupuesto_total_con_tc(:financiador => @proyecto.financiador_externo_ong)
    @previsto[:exteriores_publicas] = @proyecto.presupuesto_total_con_tc(:financiador => @proyecto.financiador_externo_publico)
    @previsto[:exteriores_privadas] = @proyecto.presupuesto_total_con_tc(:financiador => @proyecto.financiador_externo_privado)
    @previsto[:locales_ongd] = @proyecto.presupuesto_total_con_tc(:financiador => @proyecto.financiador_local_ong)
    @previsto[:locales_publicas] = @proyecto.presupuesto_total_con_tc(:financiador => @proyecto.financiador_local_publico)
    @previsto[:locales_privadas] = @proyecto.presupuesto_total_con_tc(:financiador => @proyecto.financiador_local_privado)

    @ejecutado = {:periodos => []}
    if @periodo
      # Inicialmente, la fecha de inicio es la fecha de comienzo del proyecto
      fecha_inicio = @proyecto.fecha_de_inicio
      # Obtenemos todos los periodos anteriores ordenados por fecha ascendente
      @proyecto.periodo.where("fecha_inicio <= ?",@periodo.fecha_inicio).order("fecha_inicio asc").each do |periodo|
        # La fecha de fin sera la del dia anterior al comienzo del informe
        fecha_fin = periodo.fecha_inicio - 1.days
        datos_periodo = {:seguimiento_periodo_id => periodo.id, :fecha_fin => fecha_fin}
        datos_periodo[:subvencion] = @proyecto.gasto_total_con_tc(:financiador => @proyecto.agente, :fecha_fin => fecha_fin)
        datos_periodo[:rendimientos] = @proyecto.suma_intereses_con_tc(:financiador => @proyecto.agente, :fecha_fin => fecha_fin) 
        datos_periodo[:exteriores_ongd] = @proyecto.gasto_total_con_tc(:financiador => @proyecto.financiador_externo_ong, :fecha_fin => fecha_fin)
        datos_periodo[:exteriores_publicas] = @proyecto.gasto_total_con_tc(:financiador => @proyecto.financiador_externo_publico, :fecha_fin => fecha_fin)
        datos_periodo[:exteriores_privadas] = @proyecto.gasto_total_con_tc(:financiador => @proyecto.financiador_externo_privado, :fecha_fin => fecha_fin)
        datos_periodo[:locales_ongd] = @proyecto.gasto_total_con_tc(:financiador => @proyecto.financiador_local_ong, :fecha_fin => fecha_fin)
        datos_periodo[:locales_publicas] = @proyecto.gasto_total_con_tc(:financiador => @proyecto.financiador_local_publico, :fecha_fin => fecha_fin)
        datos_periodo[:locales_privadas] = @proyecto.gasto_total_con_tc(:financiador => @proyecto.financiador_local_privado, :fecha_fin => fecha_fin)
        @ejecutado[:periodos].push datos_periodo
      end
    end
  end

  # Balance presupuestario del proyecto
  # Project Budget Balance
  #  Path: /webservice/proyectos/PROJECT_ID/balance_presupuestario
  #  PROJECT_ID: ID of the project as shown in proyecto webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def balance_presupuestario
    # las agrupaciones son por financiador principal y el resto, asi que seleccionamos a "Otros"
    otros_financiadores = @proyecto.financiador - [@proyecto.agente]
    # El calculo presupuesto es directo
    @presupuestado = {}
    @presupuestado[@proyecto.agente.nombre.upcase] = {:partidas => @proyecto.presupuesto_total_x_partidas_proyecto(:financiador => @proyecto.agente)}
    @presupuestado[:Otros] = {:partidas => @proyecto.presupuesto_total_x_partidas_proyecto(:financiador => otros_financiadores)}
    # En el calculo del gasto volcamos todos los periodos, pues la hoja muestra un acumulado final y es necesario calcular solo el gasto por periodos
    # (desde el inicio de uno hasta el inicio del siguiente)
    @ejecutado = {:periodos => []}
    if @periodo
      # Inicialmente, la fecha de inicio es la fecha de comienzo del proyecto
      fecha_inicio = @proyecto.fecha_de_inicio
      # Obtenemos todos los periodos anteriores ordenados por fecha ascendente
      @proyecto.periodo.where("fecha_inicio <= ?",@periodo.fecha_inicio).order("fecha_inicio asc").each do |periodo|
        # La fecha de fin sera la del dia anterior al comienzo del informe
        fecha_fin = periodo.fecha_inicio - 1.days
        datos_periodo = {:seguimiento_periodo_id => periodo.id, :fecha_inicio => fecha_inicio, :fecha_fin => fecha_fin}
        datos_periodo[@proyecto.agente.nombre.upcase] =
            {:partidas => @proyecto.gasto_total_x_partidas_proyecto(:financiador => @proyecto.agente, :fecha_inicio => fecha_inicio, :fecha_fin => fecha_fin)}
        datos_periodo[:Otros] =
            {:partidas => @proyecto.gasto_total_x_partidas_proyecto(:financiador => otros_financiadores, :fecha_inicio => fecha_inicio, :fecha_fin => fecha_fin)}
        @ejecutado[:periodos].push datos_periodo
        # Para el siguiente periodo, usamos como fecha de inicio la de comienzo del presente periodo
        fecha_inicio = periodo.fecha_inicio
      end
    end
  end

  # Estado de tesorería
  # Treasury status
  #  Path: /webservice/proyectos/PROJECT_ID/tesoreria
  #  PROJECT_ID: ID of the project as shown in proyecto webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def tesoreria
    @fecha_inicio ||= @proyecto.fecha_de_inicio
    @fecha_fin ||= @proyecto.fecha_de_fin
  end

  # Relacion de Personal
  # Staff
  #  Path: /webservice/proyectos/PROJECT_ID/personal
  #  PROJECT_ID: ID of the project as shown in proyecto webservice
  def personal
  end

  # Transferencias/Cambio
  # Transfers and currency exchanges
  #  Path: /webservice/proyectos/PROJECT_ID/transferencias
  #  PROJECT_ID: ID of the project as shown in proyecto webservice
  def transferencias
    @fecha_fin ||= @proyecto.fecha_de_fin
    @transferencias = {:monedas => [], :divisa => nil}

    # Obtenemos periodos y transferencias desde moneda principal a divisa
    if @proyecto.moneda_intermedia
      # Primero trabajamos con la divisa
      moneda = {:abreviatura => @proyecto.moneda_intermedia.abreviatura, :periodos => []}
      # Recorre todos los periodos definidos para obtener las transferencias
      TasaCambio.joins(:etapa).where("etapa.id" => @proyecto.etapa, :objeto => "gasto", :moneda_id => @proyecto.moneda_intermedia).where(["tasa_cambio.fecha_inicio <= ?",@fecha_fin]).order("tasa_cambio.fecha_inicio").each do |tc|
        fecha_inicio = tc.fecha_inicio
        fecha_fin = tc.fecha_fin < @fecha_fin ? tc.fecha_fin : @fecha_fin
        transf = @proyecto.transferencia.includes(:libro_origen,:libro_destino).where(
                   :fecha_recibido => fecha_inicio..fecha_fin,
                   "libro.moneda_id" => @proyecto.moneda_principal, "libro_destinos_transferencia.moneda_id" => @proyecto.moneda_intermedia
                 ).order("fecha_recibido asc")
        moneda[:periodos].push({:fecha_inicio => fecha_inicio, :fecha_fin => fecha_fin, :tasa_cambio => tc.tasa_cambio,
                                :transferencias => transf.collect{|t| {:fecha => t.fecha_recibido, :enviado => t.importe_enviado, :recibido => t.importe_cambiado, :tasa_cambio => t.tasa_cambio, :financiadores => t.nombres_financiadores} } })
      end
      @transferencias[:divisa] = moneda
    end

    # Obtenemos periodos y transferencias por monedas locales
    (@proyecto.moneda - [@proyecto.moneda_principal,@proyecto.moneda_intermedia]).each do |m|
      moneda = {:abreviatura => m.abreviatura, :periodos => []}
      # Recorre todos los periodos definidos para la moneda local
      TasaCambio.joins(:etapa).where("etapa.id" => @proyecto.etapa, :objeto => "gasto", :moneda_id => m).where(["tasa_cambio.fecha_inicio <= ?",@fecha_fin]).order("tasa_cambio.fecha_inicio").each do |tc|
        fecha_inicio = tc.fecha_inicio
        fecha_fin = tc.fecha_fin < @fecha_fin ? tc.fecha_fin : @fecha_fin
        transf = @proyecto.transferencia.includes(:libro_origen,:libro_destino).where(
                   :fecha_recibido => fecha_inicio..fecha_fin,
                   "libro.moneda_id" => [@proyecto.moneda_principal,@proyecto.moneda_intermedia], "libro_destinos_transferencia.moneda_id" => m
                 ).order("libro.moneda_id asc, fecha_recibido asc")
        moneda[:periodos].push({:fecha_inicio => fecha_inicio, :fecha_fin => fecha_fin,
                                :tasa_cambio => tc.tasa_cambio, :tasa_cambio_divisa => tc.tasa_cambio_divisa,
                                :transferencias => transf.collect{|t| {:fecha => t.fecha_recibido, :enviado => t.importe_enviado, :recibido => t.importe_cambiado, :moneda_enviada => t.moneda_enviada.abreviatura, :tasa_cambio => t.tasa_cambio, :financiadores => t.nombres_financiadores} } })
      end
      @transferencias[:monedas].push(moneda)
    end
  end

  # Bienes Adquiridos
  # Goods acquired 
  #  Path: /webservice/proyectos/PROJECT_ID/bienes_adquiridos
  #  PROJECT_ID: ID of the project as shown in proyecto webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def bienes_adquiridos 
    @elemento = @proyecto
    # Recogemos todos los gastos correspondientes a las partidas de Costes Directos de Inversion
    partidas_financiador_bienes = @proyecto.partida_financiacion.where(:codigo => ["A.II.1.","A.II.2.1.","A.II.2.2.","A.II.3."])
    partidas_bienes = Partida.joins(:partida_x_partida_financiacion).where("partida_x_partida_financiacion.partida_financiacion_id" => partidas_financiador_bienes)
    @fecha_fin ||= @proyecto.fecha_de_fin
    @gastos = Gasto.joins(:gasto_x_proyecto).where("gasto_x_proyecto.proyecto_id" => @proyecto.id).
                where(:partida_id => partidas_bienes).
                where(["fecha < ? OR fecha_informe < ?",@fecha_fin, @fecha_fin]).
                order("fecha")
  end

  # Listado de comprobantes 
  # Invoices list 
  #  Path: /webservice/proyectos/PROJECT_ID/comprobantes
  #  PROJECT_ID: ID of the project as shown in proyecto webservice
  #  MAY param: seguimiento_periodo_id . ID of monitoring period as defined in /webservice/proyectos WS
  def comprobantes
    @elemento = @proyecto
    @fecha_fin ||= @proyecto.fecha_de_fin
    @gastos = Gasto.joins(:gasto_x_proyecto).where("gasto_x_proyecto.proyecto_id" => @proyecto.id).
                where(["fecha < ? OR fecha_informe < ?",@fecha_fin, @fecha_fin]).
                order("gasto_x_proyecto.orden_factura")
  end

  def documentos
    @documentos = @proyecto.documento
  end

  def documento
    doc = @Proyecto.documento.find
    send_data doc.adjunto.path,
              filename: doc.adjunto_file_name,
              type: doc.adjunto_content_type
  end


  private

  # Needed to send correct content type header
  def correct_content_type
    headers['Content-Type'] = request.format.to_s + "; charset=" + ( response.charset.nil? ? "utf-8" : response.charset.to_s)
  end

  def get_dates_from_period_param
    @periodo = @proyecto.periodo.find_by_id params[:seguimiento_periodo_id]
    @fecha_fin = (@periodo.fecha_inicio - 1.days) if @periodo
    head :not_found if params[:seguimiento_periodo_id] && @periodo.nil?
  end

  def validate_project
    if @proyecto.nil? || @proyecto.convenio_id || @proyecto.convenio_accion || @proyecto.estado_actual.nil? || @proyecto.estado_actual.definicion_estado.nil? || !@proyecto.estado_actual.definicion_estado.reporte
      head :forbidden
    end
  end
  
end
