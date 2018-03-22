# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2016 Free Software's Seed, CENATIC y IEPALA
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
# Controlador encargado de las vistas resumen financieras para una agente implementador. Este controlador es utilizado desde las secciones agentes.

class ResumenProyectosAgenteController < ApplicationController

  helper :resumen_proyecto

  before_filter :verificar_etapa

  def verificar_etapa
    if @agente.nil? || @agente.etapa.empty?
      msg_error _("Tiene que definir por lo menos una etapa para acceder a los informes")
      redirect_to :menu => :configuracion_agente, :controller => :datos_agente, :action => :etapas
    end
  end

  
  # en agente: se redirecciona por defecto a presupuesto
  def index
    redirect_to :action => :presupuesto
  end

  def transferencia
    @listado_moneda = @agente.moneda.collect{|e| [e.nombre, e.id.to_s]}
    @listado_etapa = @agente.etapa.collect{|e| [e.nombre, e.id]}

    # Hacemos la busqueda si se seleccionan los criterios
    estado_transferencia if params[:moneda]

    respond_to do |format|
      format.xls do
        nom_fich = "transferencias_proyectos_" + @agente.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
      end
      format.html
    end
  end

  def estado_transferencia
    @fecha_de_inicio = fecha params["fecha_inicio"]
    @fecha_de_fin = fecha params["fecha_fin"]
    if params[:seleccion_fecha] == "etapa" && params[:etapa] && etapa = Etapa.find_by_id(params[:etapa])
      @fecha_de_inicio = etapa.fecha_inicio
      @fecha_de_fin = etapa.fecha_fin
    end
    @moneda = Moneda.find_by_id params[:moneda]

    aplica_tasa_cambio = @moneda.nil? || params[:tasa_cambio] == "1"
    abreviatura_moneda = aplica_tasa_cambio ? (@proyecto || @agente).moneda_principal.abreviatura : @moneda.abreviatura

    condiciones = {"fecha_enviado" => @fecha_de_inicio..@fecha_de_fin}
    condiciones["libro.agente_id"] = @agente.id
    condiciones["libro.moneda_id"] = @moneda.id if @moneda
    transferencias=Transferencia.joins(:libro_origen,:libro_destino).where(condiciones).where("!(libro.agente_id = ? AND NOT proyecto_id)",@agente.id).group(["proyecto_id","libro_destinos_transferencia.agente_id","libro.moneda_id"]).sum(:importe_enviado)

    # Prepara la salida de datos
    lineas = Array.new
    lineas.push( :cabecera => [ [_("Proyecto"),"1"], [_("Implementador"),"1"], [_("Transferido"),"1_2_td"], ["","1_3"], [_("Gastado"),"1_2_td"], ["","1_3"] ])
    i = 0
    transferencias.each do |key,value|
      moneda = Moneda.find_by_id key[2]
      agente = Agente.find_by_id key[1]
      proyecto = Proyecto.find_by_id key[0]
      if proyecto
        nombre_proyecto = proyecto.nombre
        moneda_proyecto = aplica_tasa_cambio ? proyecto.moneda_principal.abreviatura : moneda.abreviatura
        condiciones_gasto = { "gasto_x_proyecto.proyecto_id" => proyecto.id, "gasto.agente_id" => agente.id }
        condiciones_gasto["gasto.moneda_id"] = @moneda.id if @moneda 
        gastado = GastoXProyecto.joins(:gasto).joins(:tasa_cambio_proyecto).where(condiciones_gasto).sum("gasto_x_proyecto.importe * tasa_cambio.tasa_cambio") if aplica_tasa_cambio
        gastado = GastoXProyecto.joins(:gasto).joins(:tasa_cambio_proyecto).where(condiciones_gasto).sum("gasto_x_proyecto.importe") unless aplica_tasa_cambio
      else
        nombre_proyecto = _("Sin Proyecto")
        moneda_proyecto = "" 
        gastado = "" 
      end
      lineas.push( :contenido => [ nombre_proyecto, agente.nombre, value, moneda.abreviatura, gastado, moneda_proyecto ] )
    end

    # Preparamos la tabla para mostrar el detalle del seguimiento por subpartidas del agente
    titulo_datos =[ _("Moneda") + ": " + (@moneda ? @moneda.abreviatura :  _('Todas las monedas')) ,
               _("Tasa cambio") + ": " + (aplica_tasa_cambio ? _('Aplicada'): _('No aplicada')),
               _("Fechas") + ": " + @fecha_de_inicio.to_time.to_s + ' - ' + @fecha_de_fin.to_time.to_s ]

    titulo = [_("Resumen de Transferencias a Proyectos.")] + titulo_datos

    # Recogemos todo en una tabla común
    @resumen = [ :listado => { :nombre => _("Resumen de Transferencias a Proyectos."), :titulo => titulo, :lineas => lineas } ]
  end

  def proyectos
    @estados = [[_("En ejecución"), "ejecucion"], [_("Todos los activos"),"activos"]] +
               DefinicionEstado.all(:order => "orden").collect {|p| [p.nombre_completo, p.id.to_s]}
    params[:estado] ||= "ejecucion"
    condiciones_estado = case params[:estado]
      when "ejecucion" then
        { "definicion_estado.aprobado" => true, "definicion_estado.cerrado" => false }
      when "activos" then
        { "definicion_estado.cerrado" => false }
      else
        { "definicion_estado.id" => params[:estado] }
    end

    @proyectos = @agente.proyecto_implementador.includes("definicion_estado").where(condiciones_estado).where("convenio_id" => nil)
    @formato_xls = @proyectos.count

    respond_to do |format|
      format.html
      format.xls do
        # Ojo con este tipo!!!
        @tipo = "proyecto_ampliado"
        @objetos = @proyectos
        nom_fich = "resumen_proyectos" + @agente.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

  def cronograma_proyectos
    @listado_etapa = @agente.etapa.collect{|e| [e.nombre, e.id]}
    estado_cronograma_proyectos if params[:etapa] && Etapa.find_by_id(params[:etapa])

    respond_to do |format|
      format.xls do
        @nombre = "Resumen Presupuesto Proyectos " + @agente.nombre
        @resumen = @tablas.collect{|t| {tabla: t} }
        nom_fich = "resumen_presupuesto_proyectos" + @agente.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
      end
      format.html
    end
  end

  def estado_cronograma_proyectos
    etapa = Etapa.find_by_id(params[:etapa])
    tasas_cambio = TasaCambio.where(etapa_id: params[:etapa], objeto: "presupuesto")
    @fecha_de_inicio = etapa.fecha_inicio
    @fecha_de_fin = etapa.fecha_fin

    msg_tc = {} 
    columnas = []
    filas_ppto = []
    datos_ppto = []
    datos_gasto = []

    condiciones = {agente: @agente.id, agente_rol: "implementador"}
    condiciones[:proyecto_aprobado] = true unless params[:solo_aprobados] == "0"
    # Recorremos todos los periodos mensuales (incluye meses no enteros)
    for mes in (1..etapa.periodos)
      condiciones[:fecha_inicio] = @fecha_de_inicio + (mes-1).month
      condiciones[:fecha_fin] = condiciones[:fecha_inicio] + 1.month  - 1.day
      condiciones[:columna_id] =  mes
      # Definimos la cabecera de la columna
      fecha_crono = I18n.l(condiciones[:fecha_inicio], :format => "%B %Y")
      columnas.push({"id" => mes, "nombre" => fecha_crono})
      # Averiguamos el presupuesto y el gasto para el periodo
      # El gasto lo tomamos del gasto con TC para el agente
      datos_gasto += VGastoAgente.sum_proyecto(condiciones.merge(proyecto:"isnotnull"))
      # El presupuesto de proyectos debemos ajustarlo para aplicar la tasa de cambio del agente si la moneda no coincide
      VPresupuestoDetallado.sum_proyecto(condiciones).each do |p|
        proy = Proyecto.find_by_id(p.fila_id)
        if proy.moneda_id == @agente.moneda_id
          importe = p.importe
        else
          tc = tasas_cambio.find_by_moneda_id(proy.moneda_id)
          importe = tc ? tc.tasa_cambio * p.importe : 0
          msg_tc[proy.moneda_id] = _("No se ha definido ninguna tasa de cambio de presupuesto para '%{mon}' en la etapa seleccionada.")%{mon: proy.moneda_principal.abreviatura} unless tc
        end
        filas_ppto.push({"id" => p.fila_id, "nombre" => proy.nombre})
        datos_ppto.push({"fila_id" => p.fila_id, "importe" => importe, "columna_id" => mes })
      end
    end

    unless msg_tc.empty?
      msg_error _("Los resultados del resumen pueden no ser correctos") + ":<br>" + msg_tc.collect{|k,v| v}.join("<br>")
    end

    filas_ppto = filas_ppto.uniq
    filas_gasto = datos_gasto.collect{|p| p.fila_id}.uniq.collect{|id| {"id" => id, "nombre" => Proyecto.find_by_id(id).nombre} } 

    titulo_fechas = [_("Fecha inicio") + ": " + @fecha_de_inicio.to_time.to_s, _("Fecha fin") + ": " + @fecha_de_fin.to_time.to_s]
    titulo_resumen_ppto = [_("Cronograma de gastos previstos por proyecto")] + titulo_fechas 
    titulo_resumen_gasto = [_("Cronograma de gastos realizados por proyecto")] + titulo_fechas
    otros = { :fila_suma => true, :columna_suma => true, :ancho_fila => ((columnas.count + 2) * 105 + 200) }
    tabla_ppto = { :titulo => titulo_resumen_ppto, :filas => filas_ppto, :columnas => columnas, :datos => datos_ppto, :otros => otros }
    tabla_gasto = { :titulo => titulo_resumen_gasto, :filas => filas_gasto, :columnas => columnas, :datos => datos_gasto, :otros => otros }
    @tablas = [tabla_ppto, tabla_gasto]
  end

  # en agentes: genera el informe de resumen ejecutivo
  def resumen_ejecutivo 
    @monedas = @agente.moneda.collect{|m| [m.abreviatura,m.id]}
    moneda_agente = Moneda.find_by_id(@agente.moneda_id)
    divisa_agente = Moneda.find_by_id(@agente.moneda_intermedia_id)
    @monedas.push([moneda_agente.abreviatura,moneda_agente.id]) if moneda_agente
    @monedas.push([divisa_agente.abreviatura,divisa_agente.id]) if divisa_agente
    @monedas.uniq!
    
    if params[:selector] && params[:selector][:fichero] == "1" && params[:selector][:tipo] == "pdf"
      begin
        url = url_for(:only_path => false, :action => :resumen_ejecutivo_render, :id => 35, :to_pdf => true)
        kit = Shrimp::Phantom.new( url, { :format => "37cm*42cm" }, {"_session_id" => cookies[:_session_id]})
        send_file(kit.to_pdf, :filename => _("Resumen_ejecutivo_") + @agente.nombre + '.pdf', :type => 'application/pdf', :disposition => 'attachment')
      rescue => ex
        logger.error ex.message
        logger.error ex.backtrace
        msg_error _("Se produjo un error en el módulo de exportación a PDF.")
        resumen_ejecutivo_render
      end
    else
      resumen_ejecutivo_render
    end
  end

  def resumen_ejecutivo_render
    bool_xls = params[:selector] && params[:selector][:fichero] == "1" && params[:selector][:tipo] == "xls"
    @moneda = Moneda.find_by_id(params[:selector][:moneda_id]) if params[:selector] && params[:selector][:moneda_id]
    @moneda ||= @agente.moneda_principal || Moneda.first
    # Condiciones para tipo gestor o implementador
    condiciones = (params[:selector] && params[:selector][:tipo_resumen] == "gestor") ? {} : {implementador: @agente.id}

    # Cabeceras de las secciones del resumen
    lineas1 = Array.new
    lineas1.push(cabecera:  [ [_("1. DATOS BÁSICOS"), "3_2"], ["","5_2"]])

    lineas2 = Array.new
    lineas2.push(cabecera: [ [_("2. DATOS ECONÓMICOS DE PROYECTOS ABIERTOS"), "4"] ])
    lineas2.push(cabecera: [ [_("Número de proyectos"),"1_3_td"], [_("Estado"),"3_2"],
                             [_("Suma de Presupuestos aprobados (%{mon})")%{mon: @moneda.abreviatura},"1_td"] ])

    lineas3 = Array.new
    lineas3.push(cabecera: [ [_("3. DATOS TÉCNICOS DE PROYECTOS ABIERTOS"), "4"] ])
    lineas3.push(cabecera: [ [_("Número de proyectos"),"1_3_td"], [_("Área de Actuación"),"2"],
                             [_("Suma de Presupuestos aprobados (%{mon})")%{mon: @moneda.abreviatura},"1_2_td"],
                             [_("Titulares derecho directos hombres"),"1_2_td"],
                             [_("Titulares derecho directos mujeres"),"1_2_td"],
                             [_("Titulares derecho directos sin especificar"), "1_2_td"] ])

    lineas4 = Array.new
    lineas4.push(cabecera: [ [_("4. RELACIÓN DE PROYECTOS ABIERTOS"), "4"] ])
    cabecera_proyectos  = [ [_("Nombre del proyecto"),"3_4"] ]
    cabecera_proyectos += [ [_("Título"), "1"] ] if bool_xls
    cabecera_proyectos += [ [_("Estado"),"1_2"], [_("Financiador"),"1_2"], [_("Tipo"),"1_2"],
                            [_("Fecha inicio"),"1_3"], [_("Fecha fin"),"1_3"],
                            [_("Presupuesto Total (%{mon})")%{mon: @moneda.abreviatura},"1_2_td"],
                            [_("% ejec. tiempo"),"1_4_td"],
                            [_("% ejec. ppto."),"1_4_td"], [_("% ejec. Actividades"),"1_4_td"] ]
    lineas4.push(cabecera: cabecera_proyectos)

    # Recogida de datos
    estados_activos = DefinicionEstado.where(cerrado: false).order("orden")
    num_proyectos = 0
    total_presupuesto = 0.0
    areas_actuacion = Hash.new
    # Recorre los estados no cerrados
    estados_activos.each do |estado|
      total_presupuesto_estado = 0.0
      # Obtenemos todos los proyectos del agente para ese estado (evitando los PACs)
      # Si no hay condiciones particulares, es para todos los proyectos en los que es gestor,
      # si hay condiciones particulares es porque se trata de implementador
      proyectos_estado = (condiciones.blank? ? @agente.proyecto_gestor : @agente.proyecto_implementador).
                            joins(:definicion_estado).
                            where(:convenio_id => nil, "definicion_estado.id" => estado.id)
      num_proyectos_estado = proyectos_estado.count
      proyectos_estado.each do |proyecto|
        mas_info = { url: {seccion: 'proyectos', menu: 'resumen', controller: 'info', action: 'listado_proyecto_detalle', proyecto_id: proyecto.id, update: "mas_info_proyecto_#{proyecto.id}"} }
        # Informacion economica
        presupuesto_proyecto = self.presupuesto_proyecto_moneda proyecto, @moneda, condiciones
        total_presupuesto_estado += presupuesto_proyecto
        contenido_proyectos  = [ proyecto.nombre ]
        contenido_proyectos += [ proyecto.titulo ] if bool_xls
        contenido_proyectos += [ estado.nombre, proyecto.convocatoria.agente.nombre, (proyecto.convocatoria.tipo_convocatoria ? proyecto.convocatoria.tipo_convocatoria.nombre : "") ] 
        if proyecto.etapa.empty?
          lineas4.push(contenido: contenido_proyectos + [ "", "", "", "", "", ""],
                       mas_info: mas_info)
        else
          cad_porcentaje_tiempo = self.porcentaje_tiempo proyecto
          pe_p_total = proyecto.presupuesto_total_con_tc(condiciones)
          pe_g_total = proyecto.gasto_total_con_tc(condiciones).to_f
          cad_total_porcentaje_ejec = (pe_p_total > 0 ? (pe_g_total * 100/pe_p_total) : 0).round.to_s + " %"
          activ_total = proyecto.actividad.count
          #activ_valor = proyecto.actividad.sum{|a| a.estado_actual ? a.estado_actual.porcentaje||0.0 : 0.0}
          activ_valor = proyecto.actividad.sum do |a|
            vixa = ValorIntermedioXActividad.joins(:actividad_x_etapa).
                                             where("actividad_x_etapa.actividad_id" => a.id).
                                             order("valor_intermedio_x_actividad.fecha").last
            vixa ? vixa.porcentaje||0.0 : 0.0
          end
          cad_activ_valor_porc = (activ_valor * 100/(activ_total > 0 ? activ_total : 1)).round.to_s + " %"
          etapa_inicio = proyecto.etapa.reorder(:fecha_inicio).first
          etapa_fin = proyecto.etapa.reorder(:fecha_fin).last
          lineas4.push(contenido: contenido_proyectos + [ etapa_inicio.fecha_inicio, etapa_fin.fecha_fin,
                                                          presupuesto_proyecto, cad_porcentaje_tiempo,
                                                          cad_total_porcentaje_ejec, cad_activ_valor_porc],
                       mas_info: mas_info)
        end
        # Informacion tecnica
        pxas = proyecto.proyecto_x_area_actuacion
        pxas.each do |pxa|
          areas_actuacion[pxa.area_actuacion.nombre] ||= {num: 0, pct: 0.0, importe: 0.0, tddh: 0.0, tddm: 0.0, tdse: 0.0}
          areas_actuacion[pxa.area_actuacion.nombre][:importe] += presupuesto_proyecto * pxa.porcentaje
          areas_actuacion[pxa.area_actuacion.nombre][:num] += 1
          areas_actuacion[pxa.area_actuacion.nombre][:pct] += pxa.porcentaje
          datos_proyecto = proyecto.datos_proyecto
          unless datos_proyecto.empty?
            areas_actuacion[pxa.area_actuacion.nombre][:tddh] += datos_proyecto.sum(:beneficiarios_directos_hombres) * pxa.porcentaje
            areas_actuacion[pxa.area_actuacion.nombre][:tddm] += datos_proyecto.sum(:beneficiarios_directos_mujeres) * pxa.porcentaje
            areas_actuacion[pxa.area_actuacion.nombre][:tdse] += datos_proyecto.sum(:beneficiarios_directos_sin_especificar) * pxa.porcentaje
          end
        end
        # Si el proyecto no tiene areas de actuacion asignadas...
        if pxas.empty?
          nombre_sin_area = _("Sin especificar 'Area de Actuacion'")
          areas_actuacion[nombre_sin_area] ||= {num: 0, pct: 0.0, importe: 0.0, tddh: 0.0, tddm: 0.0, tdse: 0.0}
          areas_actuacion[nombre_sin_area][:importe] += presupuesto_proyecto
          areas_actuacion[nombre_sin_area][:num] += 1
          areas_actuacion[nombre_sin_area][:pct] += 1
          datos_proyecto = proyecto.datos_proyecto
          unless datos_proyecto.empty?
            areas_actuacion[nombre_sin_area][:tddh] += datos_proyecto.sum(:beneficiarios_directos_hombres)
            areas_actuacion[nombre_sin_area][:tddm] += datos_proyecto.sum(:beneficiarios_directos_mujeres)
            areas_actuacion[nombre_sin_area][:tdse] += datos_proyecto.sum(:beneficiarios_directos_sin_especificar)
          end
        end
      end
      lineas2.push(contenido: [ num_proyectos_estado, estado.nombre, total_presupuesto_estado ])
      num_proyectos += num_proyectos_estado
      total_presupuesto += total_presupuesto_estado
    end

    # Consolidamos informacion de areas de actuacion
    total_areas = {pct: 0.0, importe: 0.0, tddh: 0.0, tddm: 0.0, tdse: 0.0}
    areas_actuacion.sort.map do |nombre_area, datos_area|
      total_areas[:pct] += datos_area[:pct]
      total_areas[:importe] += datos_area[:importe]
      total_areas[:tddh] += datos_area[:tddh]
      total_areas[:tddm] += datos_area[:tddm]
      total_areas[:tdse] += datos_area[:tdse]
      lineas3.push(contenido: [datos_area[:num],nombre_area,datos_area[:importe],datos_area[:tddh], datos_area[:tddm], datos_area[:tdse]])
    end

    # Totales por grupo
    lineas1.push(contenido: [ _("Oficina/Delegación:") , @agente.nombre])
    lineas2.push(contenido: [ _("Total: %{num} proyectos")%{num: num_proyectos}, "----", total_presupuesto ])
    lineas3.push(contenido: [ _("Total: %{num} proyectos")%{num: total_areas[:pct]}, "----", total_areas[:importe], total_areas[:tddh], total_areas[:tddm], total_areas[:tdse] ])
    lineas4.push(contenido: [ _("Total: %{num} proyectos")%{num: num_proyectos}, "----", "----", "----", "----", "----", total_presupuesto, "----", "----", "----"])

    # Renderiza el resultado
    @resumen = Array.new
    nombre = "resumen ejecutivo"
    titulo  = "Resumen Ejecutivo" + " "
    titulo += @agente.nombre + " / "
    @resumen.push(:listado => {nombre: nombre, titulo: titulo, lineas: (lineas1 + lineas2 + lineas3 + lineas4)})

    respond_to do |format|
      format.html do
        render action: "resumen_ejecutivo", layout: (params[:fecha_de_fin] ? false : true)
      end
      format.xls do
        nom_fich = "Resumen_ejecutivo_" + @agente.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/resumen', xls: nom_fich, layout: false
      end
    end
  end

  # Devuelve el presupuesto de un proyecto en una moneda concreta
  def presupuesto_proyecto_moneda proyecto, moneda, condiciones_agente={}
    presupuesto = proyecto.presupuesto_total_con_tc condiciones_agente
    if moneda.id == proyecto.moneda_id
      presupuesto_moneda = presupuesto
    else
      # Averigua la TC desde la moneda del proyecto a la moneda de justificacion
      tc = TasaCambio.where(etapa_id: proyecto.etapa.first, objeto: "presupuesto", moneda_id: moneda.id).first
      presupuesto_moneda = tc ? (presupuesto / tc.tasa_cambio).round(2) : 0.0
    end
    return presupuesto_moneda
  end

  # Devuelve el porcentaje de tiempo de ejecucion
  def porcentaje_tiempo proyecto
    unless proyecto.etapa.empty?
      inicio = proyecto.fecha_de_inicio
      fin = proyecto.fecha_de_fin
      porcentaje = ((Date.today - inicio)* 100 / (fin - inicio) ).round.to_s + " %"
    end
    return porcentaje
  end
end
