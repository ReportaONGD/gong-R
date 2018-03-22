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
# Controlador encargado de los resumenes de proyecto. Este controlador es utilizado desde las secciones:
# * Sección proyectos: se utiliza para presentar un resumen de proyecto según diversos parámetros

class ResumenProyectoController < ApplicationController

  before_filter :verificar_etapa
  before_filter :criterios_gasto, :only => [:gasto]
  before_filter :criterios_presupuesto, :only => [:presupuesto]
  before_filter :verificar_tasas_cambio, :except => [:seguimiento_tecnico, :transferencia]



  def verificar_etapa
    if @proyecto.etapa.empty?
      msg_error _("Tiene que definir por lo menos una etapa para acceder a los informes")
      redirect_to :menu => :configuracion, :controller => :datos_proyecto, :action => :etapas
    end
  end

  def criterios_gasto
    if params[:financiador_implementador] == "" 
      msg_error _("Debe seleccionar agente. Para ello primero seleccione tipo implementador o financiador.")
      redirect_to :action => "gasto", :sin_layout =>  (params[:sin_layout] ? true : false)
    end
  end

  def criterios_presupuesto
    if params[:selector] and (params[:selector][:etapa].nil? or params[:selector][:etapa]=="" )
      msg_error _("Debe seleccionar etapa. Si no existe ninguna debe dar de alta para este proyecto.")
      redirect_to :action => "presupuesto", :sin_layout =>  (params[:sin_layout] ? true : false)
    end
  end

  # Verifica que haya tasas de cambio para todas las monedas en todas las etapas
  def verificar_tasas_cambio
    if (params[:moneda] == "todas" || params[:tasa_cambio] == "1")
      mensaje = []
      tasas_ppto_posibles = @proyecto.etapa.count * @proyecto.moneda.count
      tasas_ppto_definidas = TasaCambio.where(etapa_id: @proyecto.etapa, objeto: "presupuesto").count
      if @proyecto.convenio?
        tasas_gasto_posibles = @proyecto.pacs.sum{ |p| p.etapa.count * p.moneda.count}
        tasas_gasto_definidas = @proyecto.pacs.sum{ |p| TasaCambio.where(etapa_id: p.etapa, objeto: "gasto").select("moneda_id, etapa_id").uniq.count }
      else
        tasas_gasto_posibles = tasas_ppto_posibles
        tasas_gasto_definidas = TasaCambio.where(etapa_id: @proyecto.etapa, objeto: "gasto").select("moneda_id, etapa_id").uniq.count
      end
      mensaje.push _("No se han definido todas las tasas de cambio de presupuesto posibles.") unless tasas_ppto_definidas == tasas_ppto_posibles
      mensaje.push _("No se han definido todas las tasas de cambio de gasto posibles.") unless tasas_gasto_definidas == tasas_gasto_posibles
      mensaje.push _("El resumen puede ser incorrecto.") unless mensaje.empty?
      msg_error mensaje.join(" ") unless mensaje.empty? 
    end 
  end


  def index
    redirect_to :action => 'presupuesto'
  end
  
        # en proyectos: selecciona la moneda y llama a estado_presupuesto si ya hay moneda y actividad/partida
  def presupuesto
    @listado_moneda = [[_("Todas las monedas (con tasa aplicada)"), "todas"]] + @proyecto.moneda.collect{|e| [e.nombre, e.id]}
    @listado_pais = [[_("Todos los países"), "todos"]] + (@proyecto.pais.count > 1 ? [[_("Región"), "regional"]] : [] ) + @proyecto.pais_gasto.collect{|p| [p.nombre, p.id.to_s]} 
    @listado_etapa =[[_("Todas"), "todas"]] +  @proyecto.etapa.collect{|e| [e.nombre, e.id]}

    unless params[:selector]
      params[:selector] = {:tasa_cambio => "0", :fichero => "0"}
      params[:selector][:moneda] = "todas"
      params[:selector][:pais] = "todos"
      params[:selector][:partida_actividad] = "partida_proyecto"
      params[:selector][:financiador_implementador] = "financiador"
      params[:selector][:etapa] = @proyecto.etapa.last.id.to_s if @proyecto.etapa.last
    end

    # Hacemos la busqueda si se seleccionan los criterios
    if params[:selector] and params[:selector][:moneda] != '' and params[:selector][:partida_actividad] != '' and params[:selector][:etapa] != '' and params[:selector][:etapa]
      estado_presupuesto 
      respond_to do |format|
        format.html do 
          render :action => 'presupuesto' , :layout => (params[:sin_layout] ? false : true)
        end
        format.xls do
          @nombre = _("Resumen Presupuesto")
          #render 'comunes_xls/resumen_tabla', :layout => false
          nom_fich = "resumen_presupuesto_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
        end
      end
    else
      render :action => 'presupuesto' , :layout => (params[:sin_layout] ? false : true)
    end
  end

  def estado_presupuesto
    filtros = { proyecto: @proyecto.id, etapa: params[:selector][:etapa], moneda: params[:selector][:moneda], tasa_cambio: params[:selector][:tasa_cambio] }
    filtros[:agente_rol] = params[:selector][:financiador_implementador]
    filtros[:pais] = params[:selector][:pais]

    agrupados = params[:selector][:financiador_implementador]=="financiadores_agrupados"

    columnas = case params[:selector][:financiador_implementador]
      when "implementador" then @proyecto.implementador.collect{|i| {"id" => i.id, "nombre" => i.nombre}}
      when "financiador" then @proyecto.financiador.collect{|i| {"id" => i.id, "nombre" => i.nombre}}
      when "financiadores_agrupados" then VPresupuesto.columnas_financiador_agrupado(@proyecto)
    end
    
    estilo_tabla = { :columna_suma => true, :fila_suma => true, :ancho_fila => ((columnas.count + 2) * 105 + 200), :fila_porcentaje => true , :columna_porcentaje => true}
    
    case params[:selector][:partida_actividad]
      when "partida" then
        nom_fila = _("Partidas")
        filas = Partida.find(:all, :order => "tipo, codigo").collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre, "tipo" => i.tipo}}
        datos = agrupados ? VPresupuesto.partida_x_grupos(filtros) : VPresupuesto.sum_partida(filtros) 
        estilo_tabla[:fila_suma_columnas_tipo] = true
      when "partida_proyecto" then
        nom_fila = _("Partidas del proyecto")
        filas = @proyecto.partida_financiacion.order("tipo, codigo").collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre, "tipo" => i.tipo }}
        datos = agrupados ? VPresupuesto.partida_proyecto_x_grupos(filtros) : VPresupuesto.sum_partida_proyecto(filtros)
        estilo_tabla[:fila_suma_columnas_tipo] = true
      when "actividad" then
        nom_fila = _("Actividades")
        filas = @proyecto.actividad.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}} 
        datos = agrupados ? VPresupuesto.actividad_x_grupos(filtros) : VPresupuesto.sum_actividad(filtros)
      when "resultado" then
        nom_fila = _("Resultados")
        filas = @proyecto.resultado.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}} + [{"id" => 0, "nombre" => _("Actividades Globales")}]
        datos = agrupados ? VPresupuesto.resultado_x_grupos(filtros) : VPresupuesto.agrupa_sum_resultado(filtros)
      when "oe" then
        nom_fila = _("Objetivos Específicos")
        filas = @proyecto.objetivo_especifico.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}} + [{"id" => 0, "nombre" => _("Actividades Globales")}] 
        datos = agrupados ? VPresupuesto.oe_x_grupos(filtros) : VPresupuesto.agrupa_sum_oe(filtros)
    end 

    titulo =[ _("Resumen de presupuesto."),
              _("Moneda") + ": " + (params[:selector][:moneda] == 'todas' ? _('Todas las monedas') : Moneda.find(params[:selector][:moneda]).abreviatura) ,
              _("Tasa Cambio") + ": " + ( (params[:selector][:tasa_cambio] == '1' or params[:selector][:moneda] == 'todas') ? _('Aplicada'): _('No aplicada') ) + " (" +
                _("importes en %{moneda}") % {:moneda => Moneda.find_by_id( (params[:selector][:tasa_cambio] == '1' or params[:selector][:moneda] == 'todas') ? @proyecto.moneda_id : params[:selector][:moneda]).abreviatura } + ").",
              _("Etapa") + ": " + (params[:selector][:etapa] == 'todas' ? _('Todas las etapas') : Etapa.find(params[:selector][:etapa]).nombre),
              _("País") + ": " + (params[:selector][:pais]=="todos" ? _("Todos los países") : (params[:selector][:pais] == "regional" ? _("Región") : Pais.find(params[:selector][:pais]).nombre)),
              _("Filas") + ": " +  nom_fila,
	      _("Columnas") + ": " + _(params[:selector][:financiador_implementador].humanize.capitalize) ]
    
    @tablas = [{:titulo => titulo ,:filas => filas, :columnas => columnas, :datos => datos, :otros => estilo_tabla } ]
    @resumen = [ :tabla => {:titulo => titulo ,:filas => filas, :columnas => columnas, :datos => datos, :otros => { :columna_suma => true, :fila_suma => true, :ancho_fila => ((columnas.count + 2) * 105 + 200), :fila_porcentaje => true , :columna_porcentaje => true} } ]

    nombre_subpartidas = _("Subpartidas por partida")

    @titulo, @titulo[0] = titulo[0..4], nombre_subpartidas 

    # Buscamos las subpartidas para segunda tabla si estamos en un resumen por partidas o por partidas de proyecto.
    @subpartidas = Array.new
    if params[:selector][:partida_actividad] == "partida"
      for partida in Partida.all
        filtros_partida = filtros.merge(partida: partida.id)
        importe_partida = VPresupuesto.sum_total(filtros_partida).first[:importe]
        @subpartidas.push(:cabecera => [[ partida.codigo_nombre , "2" ], [importe_partida ,"1_2_td"]])
        ([["isnull", _("Sin subpartida")]] + Subpartida.where(proyecto_id: @proyecto.id, partida_id: partida.id).order(:nombre).collect{|s| [s.id,s.nombre] }).each do |s|
          importe = VPresupuesto.sum_total(filtros_partida.merge(subpartida: s[0])).first[:importe]
          @subpartidas.push(:contenido => [s[1], importe]) if importe
        end
      end
    elsif  params[:selector][:partida_actividad] == "partida_proyecto"
      for partida_proyecto in @proyecto.partida_financiacion
        if partida_proyecto.padre
          hijas = @proyecto.partida_financiacion.where(partida_financiacion_id: partida_proyecto.id).collect{|p| p.id}
          filtros_partida = filtros.merge(partida_proyecto: hijas)
          importe_partida = VPresupuesto.sum_total(filtros_partida).first[:importe]
          @subpartidas.push(:cabecera => [[ _("TOTAL") + " " + partida_proyecto.codigo_nombre , "2" ], [importe_partida ,"1_2_td"]])
        else
          filtros_partida = filtros.merge(partida_proyecto: partida_proyecto.id)
          importe_partida = VPresupuesto.sum_total(filtros_partida).first[:importe]
          @subpartidas.push(:cabecera => [[ partida_proyecto.codigo_nombre , "2" ], [importe_partida ,"1_2_td"]])
          ([["isnull", _("Sin subpartida")]] + partida_proyecto.subpartida_proyecto(@proyecto.id).collect{|s| [s.id,s.nombre] }).each do |s|
            importe = VPresupuesto.sum_total(filtros_partida.merge(subpartida: s[0])).first[:importe]
            @subpartidas.push(:contenido => [s[1], importe]) if importe
          end
        end
      end
    end

    @resumen.push( :listado => {:nombre => nombre_subpartidas, :titulo => @titulo, :lineas => @subpartidas} ) if @subpartidas
  end

  # En proyectos: selecciona opciones para el resumen de previsión de gastos
  def presupuesto_detallado
    @listado_etapa = @proyecto.etapa.collect{|e| [e.nombre, e.id]}
    titulo_res = @proyecto.convenio_accion == "resultado" ? _("Acciones") : _("Resultados")
    titulo_oes = @proyecto.convenio_accion == "objetivo_especifico" ? _("Acciones") : _("Objetivos Específicos")
    @listado_tipos = [ [_("Partidas"), "partida"],
                       [_("Partidas del proyecto"), "partida_proyecto"],
                       [_("Actividades"), "actividad"],
                       [titulo_res, "resultado"],
                       [titulo_oes, "oes"] ]
    params[:partida_actividad] ||= "actividad"
    estado_presupuesto_detallado if params[:etapa] && @proyecto.etapa.find_by_id(params[:etapa])
    
    respond_to do |format|
      format.xls do
        @nombre = "Resumen Previsión Gastos '#{@proyecto.nombre}'"
        @resumen = @tablas.collect{|t| {tabla: t} }
        nom_fich = "prevision_gastos" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
      end
      format.html
    end
  end

  # Calculos del resumen de presupuesto detallado (previsión de gastos)
  def estado_presupuesto_detallado
    etapa = @proyecto.etapa.find_by_id(params[:etapa])
    @fecha_de_inicio = etapa.fecha_inicio
    @fecha_de_fin = etapa.fecha_fin
    tipo = params[:partida_actividad]

    datos_ppto = []
    cols_ppto = []
    rows_ppto = case params[:partida_actividad]
      when "partida" then Partida.find(:all, :order => "tipo, codigo").collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre, "tipo" => i.tipo}}
      when "partida_proyecto" then @proyecto.partida_financiacion.order("tipo, codigo").collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre, "tipo" => i.tipo}}
      when "actividad" then @proyecto.actividad.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}}
      when "resultado" then @proyecto.resultado.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}} + [{"id" => 0, "nombre" => _("Actividades Globales")}]
      when "oes" then @proyecto.objetivo_especifico.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}} + [{"id" => 0, "nombre" => _("Actividades Globales")}]
    end
    rows_ppto.uniq!

    condiciones = {proyecto: @proyecto.id, moneda: "todas", tasa_cambio: "0",
                   financiador_implementador: "implementador", agente: "todos"}
    subtotal_dif_acu = 0.0
    for mes in (1..etapa.periodos)
      condiciones[:fecha_inicio] = @fecha_de_inicio.beginning_of_month + (mes-1).month
      condiciones[:fecha_fin] = condiciones[:fecha_inicio] + 1.month - 1.day
      condiciones[:columna_id] = mes
      # Definimos la cabecera de la columna
      fecha_crono = I18n.l(condiciones[:fecha_inicio], format: "%b %Y")
      cols_ppto.push({"id" => mes, "nombre" => fecha_crono})
      # Averiguamos el ppto segun lo buscado
      presupuestos = case tipo
        when "partida"
          VPresupuestoDetallado.agrupa_sum_partida(condiciones)
        when "partida_proyecto"
          VPresupuestoDetallado.agrupa_sum_partida_proyecto(condiciones)
        when "oes"
          VPresupuestoDetallado.agrupa_sum_oe(condiciones)
        when "resultado"
          VPresupuestoDetallado.agrupa_sum_resultado(condiciones)
        # Por defecto, actividad
        else
          VPresupuestoDetallado.agrupa_sum_actividad(condiciones) 
      end
      datos_ppto += presupuestos
      # Calculos de subtotales y acumulados
      subtotal_ppto = presupuestos.inject(0){|sum,p| sum + p["importe"]} 
      datos_ppto += [{"fila_id" => "total_ppto", "columna_id" => mes, "importe" => subtotal_ppto}]
      subtotal_gsto = VGasto.sum_total(condiciones).first[:importe]
      datos_ppto += [{"fila_id" => "total_gsto", "columna_id" => mes, "importe" => subtotal_gsto}]
      subtotal_dif_mes = subtotal_ppto - (subtotal_gsto||0.0)
      datos_ppto += [{"fila_id" => "dif_mensual", "columna_id" => mes, "importe" => subtotal_dif_mes}]
      subtotal_dif_acu += subtotal_dif_mes
      datos_ppto += [{"fila_id" => "dif_acumula", "columna_id" => mes, "importe" => subtotal_dif_acu}]
    end

    rows_ppto += [{"id" => "total_ppto", "nombre" => _("TOTAL Presupuestado"), "clase" => "texto_resaltado"},
                  {"id" => "total_gsto", "nombre" => _("TOTAL Ejecutado"), "clase" => "texto_gris"},
                  {"id" => "dif_mensual", "nombre" => _("DIFERENCIA Mensual"), "clase" => "texto_gris"},
                  {"id" => "dif_acumula", "nombre" => _("DIFERENCIA Acumulada"), "clase" => "texto_gris"} ]

    #unless msg_tc.empty?
    #  msg_error _("Los resultados del resumen pueden no ser correctos") + ":<br>" + msg_tc.collect{|k,v| v}.join("<br>")
    #end

    titulo_fechas = [_("Fecha inicio") + ": " + I18n.l(@fecha_de_inicio, format: "%b %Y"),
                     _("Fecha fin") + ": " + I18n.l(@fecha_de_fin, format: "%b %Y"),
                     _("Moneda") + ": " + @proyecto.moneda_principal.nombre,]
    tipo_seleccionado = @listado_tipos.select{|l| l[1] == params[:partida_actividad]}.first
    titulo_fechas.push(_("Filas") + ": " + tipo_seleccionado[0]) if tipo_seleccionado
    titulo_resumen_ppto = [_("Cronograma de gastos previstos")] + titulo_fechas 
    otros = { sin_fila_vacia: true, columna_suma: true, ancho_fila: ((cols_ppto.count + 2) * 105 + 200) }
    tabla_ppto = { titulo: titulo_resumen_ppto, filas: rows_ppto, columnas: cols_ppto, datos: datos_ppto, otros: otros }
    @tablas = [tabla_ppto]
  end

  # en proyectos: selecciona la moneda, los agentes
  # y llama a busqueda_presupuesto
  def gasto
    @listado_moneda = [[_("Todas las monedas (con tasa aplicada)"), "todas"]] + @proyecto.moneda.collect{|e| [e.nombre, e.id]}
    @listado_pais = [[_("Todos los países"), "todos"]] + (@proyecto.pais.count > 1 ? [[_("Región"), "regional"]] : [] ) + @proyecto.pais_gasto.collect{|p| [p.nombre, p.id.to_s]}
    @listado_agente = [[_("Todos los agentes"), "todos"]] + @proyecto.implementador.collect{|e| [e.nombre, e.id]}
    @listado_pac = [ [_("Acumulado (todos los PACs)"), @proyecto.id] ] + @proyecto.pacs.collect{|e| [e.nombre, e.id]} if @proyecto.convenio?
    # Hacemos la busqueda si se seleccionan los criterios

    params[:moneda] ||= "todas"
    params[:pais] ||= "todos"
    params[:partida_actividad] ||= "partida_proyecto"
    params[:financiador_implementador] ||= "financiador"
    params[:agente] ||= @proyecto.agente.id
    params[:pac] ||= @proyecto.pacs.first.id if @proyecto.convenio?
    @fecha_de_inicio = @proyecto.etapa.first.fecha_inicio unless params["fecha_inicio"] 
    #@fecha_de_fin = DateTime.now.to_date unless params["fecha_fin"]
    @fecha_de_fin = @proyecto.fecha_de_fin unless params["fecha_fin"]
    
    unless params[:moneda].nil? or params[:partida_actividad].nil? or params[:financiador_implementador].nil? 
      estado_gasto
      respond_to do |format|
        format.html do 
          render :action => "gasto", :layout => (params[:sin_layout] ? false : true)
        end
        format.xls do
          @nombre = _("Seguimiento Gasto")
          nom_fich = "seguimiento_gasto_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
        end
      end
    else
      render :action => "gasto", :layout => (params[:sin_layout] ? false : true)
    end
  end

  def agentes
    render :partial => "agentes"
  end


  def estado_gasto
    @fecha_de_inicio ||= fecha params["fecha_inicio"]
    @fecha_de_fin ||= fecha params["fecha_fin"]
    #@fecha_de_fin = (@fecha_de_fin >> 1) - 1 # Para que incluya el mes en elegido
    proyecto = Proyecto.find_by_id(params[:pac]) if @proyecto.convenio?
    proyecto = @proyecto unless @proyecto.convenio?
    filas = case params[:partida_actividad]
      when "partida" then Partida.find(:all, :order => "tipo, codigo").collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre, "tipo" => i.tipo}}
      when "partida_proyecto" then proyecto.partida_financiacion.order("tipo, codigo").collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre, "tipo" => i.tipo}}
      when "actividad" then proyecto.actividad.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}}
      when "resultado" then proyecto.resultado.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}} + [{"id" => 0, "nombre" => _("Actividades Globales")}]
      when "oe" then proyecto.objetivo_especifico.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}} + [{"id" => 0, "nombre" => _("Actividades Globales")}]
    end
    columnas = [{"id" => "1", "nombre" => _("Presupuesto")}, {"id" => "2", "nombre" => _("Gastos")}] unless params[:agente] == "todos_agrupados"
    columnas = VPresupuesto.columnas_financiador_agrupado(@proyecto) if params[:agente] == "todos_agrupados"

    # Definimos los filtros para los resumenes
    filtros = { agente_rol: params[:financiador_implementador], proyecto: proyecto.id, moneda: params[:moneda], tasa_cambio: params[:tasa_cambio],
                fecha_inicio: @fecha_de_inicio, fecha_fin: @fecha_de_fin, pais: params[:pais] }

    # Si hemos puesto un filtro y estamos sacando un agrupado por actividad, resultado o objetivos, establecemos el filtro
    if (params[:partida_actividad] == "actividad" || params[:partida_actividad] != "resultado" || params[:partida_actividad] != "oe") && params[:filtro_partida]
      # En el caso de que exista la partida de financiacion 
      if partida_financiacion = PartidaFinanciacion.find_by_id( params[:filtro_partida] )
        # Si es una partida madre
        if partida_financiacion.padre
          filtros[:partida] = []
          partida_financiacion.partida_financiacion_hija.each{|par| filtros[:partida].push(par.partida.collect{|p| p.id})}
        else
          filtros[:partida] = partida_financiacion.partida.collect{|p| p.id}
        end
      end
    end

    case  [params[:partida_actividad],  params[:financiador_implementador]]
      when ["partida", "implementador"] then
         filtros[:agente] = params[:agente]
         presupuestos = VPresupuestoDetallado.agrupa_sum_partida filtros
         gastos = VGasto.agrupa_sum_partida filtros

      when ["partida", "financiador"] then
        # Si queremos el resumen agrupado...
        if params[:agente] == "todos_agrupados"
          presupuestos = []
          gastos = VGasto.partida_x_grupos filtros
        # Para resumen por agente...
        else
          # Para los agentes del sistema, seleccionamos la agrupacion...
          agt = Agente.find_by_id params[:agente]
          if agt && agt.sistema
            if agt.publico
              filtros[:agente] = agt.local ? @proyecto.financiador_local_publico : @proyecto.financiador_externo_publico
            else
              filtros[:agente] = agt.local ? @proyecto.financiador_local_privado : @proyecto.financiador_externo_privado
            end 
          end
          filtros[:agente] ||= params[:agente]
          # Y calculamos presupuesto y gasto
          presupuestos = VPresupuestoDetallado.agrupa_sum_partida filtros
          gastos = VGasto.agrupa_sum_partida filtros
        end


      when ["actividad", "implementador"] then
         filtros[:agente] = params[:agente]
         presupuestos = VPresupuestoDetallado.agrupa_sum_actividad filtros
         gastos = VGasto.agrupa_sum_actividad filtros

      when ["resultado", "implementador"] then
         filtros[:agente] = params[:agente]
         presupuestos = VPresupuestoDetallado.agrupa_sum_resultado filtros
         gastos = VGasto.agrupa_sum_resultado filtros

      when ["oe", "implementador"] then
         filtros[:agente] = params[:agente]
         presupuestos = VPresupuestoDetallado.agrupa_sum_oe filtros
         gastos = VGasto.agrupa_sum_oe filtros


      when ["actividad", "financiador"] then
        # Si queremos el resumen agrupado...
        if params[:agente] == "todos_agrupados"
          presupuestos = []
          gastos = VGasto.actividad_x_grupos filtros
        # Para resumen por agente...
        else
          # Para los agentes del sistema, seleccionamos la agrupacion...
          agt = Agente.find_by_id params[:agente]
          if agt && agt.sistema
            if agt.publico  
              filtros[:agente] = agt.local ? @proyecto.financiador_local_publico : @proyecto.financiador_externo_publico
            else
              filtros[:agente] = agt.local ? @proyecto.financiador_local_privado : @proyecto.financiador_externo_privado
            end 
          end
          filtros[:agente] ||= params[:agente]
          
          # Y calculamos presupuesto y gasto
          presupuestos = VPresupuestoDetallado.agrupa_sum_actividad filtros
          gastos = VGasto.agrupa_sum_actividad filtros
        end

      when ["resultado", "financiador"] then
        # Si queremos el resumen agrupado...
        if params[:agente] == "todos_agrupados"
          presupuestos = []
          gastos = VGasto.resultado_x_grupos filtros
        # Para resumen por agente...
        else
          # Para los agentes del sistema, seleccionamos la agrupacion...
          agt = Agente.find_by_id params[:agente]
          if agt && agt.sistema
            if agt.publico
              filtros[:agente] = agt.local ? @proyecto.financiador_local_publico : @proyecto.financiador_externo_publico
            else
              filtros[:agente] = agt.local ? @proyecto.financiador_local_privado : @proyecto.financiador_externo_privado
            end
          end
          filtros[:agente] ||= params[:agente]
          # Y calculamos presupuesto y gasto
          presupuestos = VPresupuestoDetallado.agrupa_sum_resultado filtros
          gastos = VGasto.agrupa_sum_resultado filtros
        end

      when ["oe", "financiador"] then
        # Si queremos el resumen agrupado...
        if params[:agente] == "todos_agrupados"
          presupuestos = []
          gastos = VGasto.oe_x_grupos filtros
        # Para resumen por agente...
        else
          # Para los agentes del sistema, seleccionamos la agrupacion...
          agt = Agente.find_by_id params[:agente]
          if agt && agt.sistema
            if agt.publico
              filtros[:agente] = agt.local ? @proyecto.financiador_local_publico : @proyecto.financiador_externo_publico
            else
              filtros[:agente] = agt.local ? @proyecto.financiador_local_privado : @proyecto.financiador_externo_privado
            end
          end
          filtros[:agente] ||= params[:agente]
          # Y calculamos presupuesto y gasto
          presupuestos = VPresupuestoDetallado.agrupa_sum_oe filtros
          gastos = VGasto.agrupa_sum_oe filtros
        end


      when ["partida_proyecto", "implementador"] then
    
         filtros[:agente] = params[:agente]
         presupuestos = VPresupuestoDetallado.agrupa_sum_partida_proyecto filtros
         gastos = VGasto.agrupa_sum_partida_proyecto filtros

      when ["partida_proyecto", "financiador"] then
        # Si queremos el resumen agrupado...
        if params[:agente] == "todos_agrupados"
          presupuestos = []
          gastos = VGasto.partida_proyecto_x_grupos filtros
        # Para resumen por agente...
        else  
          # Para los agentes del sistema, seleccionamos la agrupacion...
          agt = Agente.find_by_id params[:agente]
          if agt && agt.sistema
            if agt.publico
              filtros[:agente] = agt.local ? @proyecto.financiador_local_publico : @proyecto.financiador_externo_publico
            else
              filtros[:agente] = agt.local ? @proyecto.financiador_local_privado : @proyecto.financiador_externo_privado
            end
          end
          filtros[:agente] ||= params[:agente]
          # Y calculamos presupuesto y gasto
          presupuestos = VPresupuestoDetallado.agrupa_sum_partida_proyecto filtros
          gastos = VGasto.agrupa_sum_partida_proyecto filtros
        end
    end 

    datos = presupuestos + gastos 
    titulo =[ _("Resumen de gasto") + " " + proyecto.nombre + ".",
              _("Filas") + ": " + (@proyecto.convenio_accion == params[:partida_actividad] ? _("Acción") : params[:partida_actividad].humanize),
              _("Moneda") + ": " + ( params[:moneda] == 'todas' ?  _('Todas las monedas') : Moneda.find(params[:moneda]).nombre),
              _("Tasa Cambio") + ": " + ( (params[:tasa_cambio] == '1' or params[:moneda] == 'todas') ? _('Aplicada') : _('No aplicada') ) + " (" +
                _("importes en %{moneda}") % {:moneda => Moneda.find_by_id( (params[:tasa_cambio] == '1' or params[:moneda] == 'todas') ? @proyecto.moneda_id : params[:moneda]).abreviatura } + ").",
              _("Fechas") + ": " + @fecha_de_inicio.to_time.to_s + ' - ' + @fecha_de_fin.to_time.to_s,
	      _("Agente") + ": " + (params[:agente] == "todos" || params[:agente] == "todos_agrupados" ? _("Todos los agentes") : Agente.find(params[:agente]).nombre),
              _("Rol del agente") + ": " + params[:financiador_implementador],
              _("País") + ": " + (params[:pais]=="todos" ? _("Todos los países") : (params[:pais] == "regional" ? _("Región") : Pais.find(params[:pais]).nombre)),
              _("Mostrar filas sin valores") + ": " + (params[:sin_fila_vacia] == "1" ? _("No") : _("Si")) ]

    # Ponemos el estilo de tabla que se va a mostrar en funcion de que agentes agrupados o no 
    if  params[:agente] == "todos_agrupados"
      estilo_tabla = {  :columna_suma => true, :fila_suma => true, :ancho_fila => (9 * 105 + 200),:clases => ["","1","1_2_td"] }
    else
      estilo_tabla = {  :columna_resta => _("Pendiente"), :fila_suma => true, :columna_pctparcial => _("% Ejecutado"), :clases => ["","2","1_2_td"] }
    end
    # Añadimos una fila de suma parcial de tipos de partida (directo o indirecto) en los casos que las filas sean partidas
    estilo_tabla[:fila_suma_columnas_tipo] = true  if params[:partida_actividad] =~ /partida|partida_proyecto/
    # Si se selecciona 'sin_fila_vacia' pasamos el parametro para que no se dibujen en la tabla
    estilo_tabla[:sin_fila_vacia] = true if params["sin_fila_vacia"] == "1"

    @tablas = [{:titulo => titulo ,:filas => filas, :columnas => columnas, :datos => datos, :otros => estilo_tabla  }]
    @resumen = [ :tabla => {:titulo => titulo ,:filas => filas, :columnas => columnas, :datos => datos, :otros => estilo_tabla } ]

    nombre_subpartidas = _("Subpartidas por partida")

    # Buscamos las subpartidas para segunda tabla si estamos en un resumen por partidas o por partidas de proyecto.
    @titulo, @titulo[0], @titulo[4] = titulo[0..3], nombre_subpartidas, titulo[8]
    @subpartidas = [{:cabecera => [ [_("Partida/Subpartida"),"2"], [_("Presupuesto"),"1_2_td"], [_("Gasto"),"1_2_td"], [_("Pendiente"),"1_2_td"], [_("% Ejecutado"),"1_2_td"] ] } ]
    if params[:partida_actividad] == "partida"
      for partida in Partida.all
        presupuesto = presupuestos.detect{|v| v["fila_id"] == partida.id }
        importe_pspto = presupuesto ? presupuesto["importe"] : 0
        gasto = gastos.detect{|v| v["fila_id"] == partida.id }
        importe_gasto = gasto ? gasto["importe"] : 0
        pct_gasto = importe_pspto && importe_pspto != 0 ? 100*(importe_gasto||0)/importe_pspto : "-"
        unless importe_pspto == 0 and importe_gasto == 0
          @subpartidas.push(:cabecera => [[ partida.codigo_nombre , "2" ], [importe_pspto ,"1_2_td"], [importe_gasto ,"1_2_td"],
                                           [((importe_pspto || 0)  - (importe_gasto || 0 ))  ,"1_2_td"], [pct_gasto,"1_2_td"]])
        end
        ([["isnull", _("Sin subpartida")]] + Subpartida.where(proyecto_id: @proyecto.id, partida_id: partida.id).order(:nombre).collect{|s| [s.id,s.nombre] }).each do |s|
          filtros_subpartida = filtros.merge(partida: partida.id, subpartida: s[0])
          importe_pspto = VPresupuestoDetallado.sum_total(filtros_subpartida).first[:importe]
          importe_gasto = VGasto.sum_total(filtros_subpartida).first[:importe]
          pct_gasto = importe_pspto && importe_pspto != 0 ? 100*(importe_gasto||0)/importe_pspto : "-"
          # Añadimos detalle a cada de eleme3nto del listado para poder listarlo posteriormente
          update = "gasto_partida_" + partida.id.to_s + "_subpartida_" + s[0].to_s 
          mas_detalle = { url: {action: :detalle_gasto_subpartida, update: update, filtro: filtros_subpartida } }  
          @subpartidas.push(:contenido => [s[1], importe_pspto, importe_gasto, ((importe_pspto || 0)  - (importe_gasto || 0 )),pct_gasto], :objeto_desplegado => mas_detalle)  if importe_pspto or importe_gasto
        end
      end
    elsif  params[:partida_actividad] == "partida_proyecto"
      for partida_proyecto in proyecto.partida_financiacion
        # Cuando es una partida padre, tiene que obtener la suma de los hijos
        if partida_proyecto.padre
          hijas = proyecto.partida_financiacion.where(partida_financiacion_id: partida_proyecto.id).collect{|p| p.id}
          importe_pspto = presupuestos.select{|v| hijas.include? v["fila_id"] }.inject(0) {|sum,p| sum + (p["importe"]||0) }
          importe_gasto = gastos.select{|v| hijas.include? v["fila_id"] }.inject(0) {|sum,p| sum + (p["importe"]||0) }
          pct_gasto = importe_pspto && importe_pspto != 0 ? 100*(importe_gasto||0)/importe_pspto : "-"
          @subpartidas.push(:cabecera => [[ _("TOTAL") + " " + partida_proyecto.codigo_nombre , "2" ], [importe_pspto ,"1_2_td"], [importe_gasto ,"1_2_td"] ,
                                          [((importe_pspto || 0)  - (importe_gasto || 0 ))  ,"1_2_td"], [pct_gasto,"1_2_td"]])
        # Si no es una partida padre, desglosa por subpartidas
        else
          presupuesto = presupuestos.detect{|v| v["fila_id"] == partida_proyecto.id } 
          importe_pspto = presupuesto ? presupuesto["importe"] : 0
          gasto = gastos.detect{|v| v["fila_id"] == partida_proyecto.id }
          importe_gasto = gasto ? gasto["importe"] : 0
          pct_gasto = importe_pspto && importe_pspto != 0 ? 100*(importe_gasto||0)/importe_pspto : "-"
          unless importe_pspto == 0 and importe_gasto == 0
            @subpartidas.push(:cabecera => [[ partida_proyecto.codigo_nombre , "2" ], [importe_pspto ,"1_2_td"], [importe_gasto ,"1_2_td"] , 
                                          [((importe_pspto || 0)  - (importe_gasto || 0 ))  ,"1_2_td"], [pct_gasto,"1_2_td"]])
          end
          ([["isnull", _("Sin subpartida")]] + partida_proyecto.subpartida_proyecto(proyecto.id).collect{|s| [s.id,s.nombre] }).each do |s|
            filtros_subpartida = filtros.merge(partida_proyecto: partida_proyecto.id, subpartida: s[0])
            importe_pspto = VPresupuestoDetallado.sum_total(filtros_subpartida).first[:importe]
            importe_gasto = VGasto.sum_total(filtros_subpartida).first[:importe]
            pct_gasto = importe_pspto && importe_pspto != 0 ? 100*(importe_gasto||0)/importe_pspto : "-"
            # Añadimos detalle a cada de eleme3nto del listado para poder listarlo posteriormente
            update = "gasto_partida_" + partida_proyecto.id.to_s + "_subpartida_" + s[0].to_s 
            mas_detalle = { url: {action: :detalle_gasto_subpartida, update: update, filtro: filtros_subpartida } }  
            @subpartidas.push(:contenido => [s[1], importe_pspto, importe_gasto, ((importe_pspto || 0)  - (importe_gasto || 0 )),pct_gasto], :objeto_desplegado => mas_detalle )  if importe_pspto or importe_gasto
          end
        end
      end
    end

    @resumen.push(:listado => {:nombre => nombre_subpartidas, :titulo => @titulo, :lineas => @subpartidas} ) if @subpartidas
  end
  
	# en agentes: desglosa las lineas de gasto para una determinada subpartida
  def detalle_gasto_subpartida
    # Por si a alguien le da por toquetear los filtros, usamos el id de agente saneado por application_controller
    params[:filtro][:proyecto] = @proyecto.id if params[:filtro]
    listado_gastos_vista = VGasto.listado_gastos params[:filtro]
    listado_gastos = Gasto.find(listado_gastos_vista.collect{|g| g.gasto_id})
    listado_gastos.each do |g|
      g.importe_x_financiador = (listado_gastos_vista.find{|gv| gv.gasto_id == g.id }).importe
      # ponemos la moneda que le corresponde segun el tipo de listado que estemos mostrando.
      g.moneda_id =  @proyecto.moneda_principal.id if params[:filtro][:moneda] == "todas" or  params[:filtro][:tasa_cambio] == "1"

    end
    @formato_xls = 1 
    respond_to do |format|
      format.html do
        render(:update) { |page|  page.replace_html(params[:update], :partial => "detalle_gasto_subpartida", :locals => {:listado_gastos => listado_gastos}) }
      end
      format.xls do
        if params[:filtro][:agente_rol] == "financiador" and params[:filtro][:agente] != "todos"
      	  @tipo = "gasto_x_financiador" 
        else
          @tipo = "gasto"
        end
        @objetos = listado_gastos
        nom_fich = "Gastos_de_subpartida_" + (@proyecto).nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end




	# en proyectos: selecciona la caja para sacar el informe de arqueo
  def arqueo_caja
    @listado_libros = eval( "@" + singularizar_seccion ).libro.select{|l| @usuario_identificado.libro.include? l}.collect {|a|[a.nombre, a.id]}
    @listado_etapa = [[_("Todas"), "todas"]] + @proyecto.etapa.collect{|e| [e.nombre, e.id]} unless @proyecto.convenio?
    @listado_pac = [[_("Todos"), "todos"]] + @proyecto.pacs.collect{|p| [p.nombre, p.id]} if @proyecto.convenio?
    # Si el proyecto tiene visibilidad limitada y no somos admins
    # mostramos solo los libros o agentes asignados
    if @proyecto.ocultar_gastos_otras_delegaciones && !@proyecto.usuario_admin?(@usuario_identificado)
      agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado) 
    else
      agentes_permitidos = @proyecto.implementador
    end
    @listado_agentes = agentes_permitidos.collect{|e| [e.nombre, e.id]}
    @listado_monedas = @proyecto.moneda.collect{|e| [e.nombre, e.id]}
    # Si hemos especificado un libro para ver el informe
    if params[:selector] && (params[:selector][:tipo] == "agente" || params[:selector][:tipo] == "cuenta")
      @libro = Libro.where(agente_id: agentes_permitidos).find_by_id(params[:selector][:libro]) if params[:selector][:tipo] == "cuenta"
      @agente = agentes_permitidos.find_by_id(params[:selector][:agente]) if params[:selector][:tipo] == "agente"
      @moneda = Moneda.find_by_id(params[:selector][:moneda]) if params[:selector][:tipo] == "agente"
      @moneda = @libro.moneda if @libro 

      # Proyectos de los que obtener informacion
      if @proyecto.convenio?
        @pac = Proyecto.find_by_id(params[:selector][:pac])
        proyectos = @pac ? [ @pac ] : @proyecto.pacs
      else
        @etapa = Etapa.find_by_id(params[:selector][:etapa])
        proyectos = [ @proyecto ]
      end

      fecha_inicio = @etapa ? @etapa.fecha_inicio : nil
      fecha_fin = @etapa ? @etapa.fecha_fin : nil
      # Si es arqueo de un solo libro, lo invocamos tal cual
      if @libro
        arqueo = @libro.arqueo( proyectos, fecha_inicio, fecha_fin )
      # Si es arqueo de un agente, recorremos todos sus libros en la moneda indicada
      elsif @agente && @moneda
        arqueo = { :filas => [], :totales => {}, :entrante => 0, :saliente => 0 }
        @agente.libro.all(:conditions => {:moneda_id => @moneda.id}).each do |libro|
          arqueo_libro = libro.arqueo( proyectos, fecha_inicio, fecha_fin )
          arqueo[:filas] += arqueo_libro[:filas]
          #arqueo[:totales] = arqueo_libro[:totales]
          arqueo[:entrante] += arqueo_libro[:entrante]
          arqueo[:saliente] += arqueo_libro[:saliente]
          # Sumamos los totales por conceptos
          arqueo_libro[:totales].each do |tipo,parcial|
            arqueo[:totales][tipo] ||= {}
            parcial.each do |dir,valor|
              arqueo[:totales][tipo][dir] ||= 0
              arqueo[:totales][tipo][dir] += valor
            end
          end
        end
        # Ordenamos por fecha las filas
        arqueo[:filas].sort! { |x,y| x[:contenido][0] <=> y[:contenido][0] }
      else
        arqueo = { :filas => [], :totales => {}, :entrante => 0, :saliente => 0 }
      end

      # Incluye los saldos linea a linea
      saldo = 0.0
      arqueo[:filas].each do |fila|
        saldo += fila[:contenido][3].to_f - fila[:contenido][4].to_f
        fila[:contenido].push saldo
      end

      # Prepara la salida de datos
      lineas = Array.new
      lineas.push( :cabecera => [ [_("Fecha"),"1_2"], [_("Tipo"),"1_2"], [_("Concepto"),"3_2"], [_("Entradas"),"1_2_td"], [_("Salidas"),"1_2_td"], [_("Saldo"),"1_2_td"] ])
      lineas += arqueo[:filas]
      lineas.push( :contenido => [ '','','','','' ] )
      lineas.push( :cabecera => [ [_("Totales"),"1_2"], ["","1_2"], ["","3_2"], [arqueo[:entrante],"1_2_td"], [arqueo[:saliente],"1_2_td"], [arqueo[:entrante] - arqueo[:saliente],"1_2_td"] ])
      arqueo[:totales].each do |k,v|
        lineas.push( :contenido => [ '',_(k),'',v["Entrante"]||'',v["Saliente"]||'','' ] )
      end

      @resumen = Array.new
      nombre = "arqueo_caja"
      titulo = @proyecto.nombre + " / " + _("Arqueo") + " "
      titulo += _("Cuenta/Caja %{nombre_cuenta}")%{nombre_cuenta: @libro.nombre} if @libro
      titulo += _("Cuentas/Cajas de %{nombre_agente} (%{mon})")%{nombre_agente: @agente.nombre, mon: @moneda.nombre} if @libro.nil? && @agente && @moneda
      titulo += " / " 
      if @proyecto.convenio?
        titulo += _("PAC") + ": " + (@pac ? @pac.nombre : _("Todas") )
      else
	titulo += _("Etapa") + ": " + (@etapa ? @etapa.nombre + " " + _("(desde %{fecha_inicio} hasta %{fecha_fin})") % {:fecha_inicio => @etapa.fecha_inicio.strftime('%d/%m/%Y'), :fecha_fin => @etapa.fecha_fin.strftime('%d/%m/%Y')} : _("Todas") )
      end
      @resumen.push(:listado => {:nombre => nombre, :titulo => titulo, :lineas => lineas})

      respond_to do |format|
        format.html do
          render :template => 'comunes/arqueo_caja', :layout => (params[:sin_layout] ? false : true)
        end
        format.xls do
          nom_fich = "arqueo_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
        end
      end
    else
      render :template => "comunes/arqueo_caja", :layout => (params[:sin_layout] ? false : true)
    end
  end

	# en proyectos, vista resumen de transferencias (segun la hoja X.A.1 del informe AECID)
  def transferencia
    @listado_etapa = [[_("Todas"), "todas"]] + @proyecto.etapa.collect{|e| [e.nombre, e.id]} unless @proyecto.convenio?
    @listado_pac = [[_("Todos"), "todos"]] + @proyecto.pacs.collect{|p| [p.nombre, p.id]} if @proyecto.convenio?


      @etapa = params[:selector] && params[:selector][:etapa] ? @proyecto.etapa.find_by_id(params[:selector][:etapa]) : nil
      @pac = params[:selector] && params[:selector][:pac] ? @proyecto.pacs.find_by_id(params[:selector][:pac]) : nil

      lineas = Array.new

      # Estas van a ser condiciones generales
      moneda_principal = @proyecto.moneda_principal
      moneda_intermedia = @proyecto.moneda_intermedia
      condiciones_base = Hash.new
      if @proyecto.convenio?
        condiciones_base[:proyecto_id] = @pac ? [@pac.id] : @proyecto.pacs.collect{|p| p.id}
        condiciones_base[:remanente] = false unless @pac 
      else
        condiciones_base[:proyecto_id] = [@proyecto.id]
        condiciones_base[:fecha_recibido] = @etapa.fecha_inicio..@etapa.fecha_fin if @etapa
      end

      # Si tenemos visibilidad limitada en el proyecto, aplicamos solo a los agentes permitidos
      if @proyecto.ocultar_gastos_otras_delegaciones && !@proyecto.usuario_admin?(@usuario_identificado)
        agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado)
      else
        agentes_permitidos = @proyecto.implementador
      end
      condiciones_base["libro.agente_id"] = agentes_permitidos

      # Subvenciones Recibidas (de todos los financiadores?)
      condiciones = condiciones_base.clone
      condiciones["libro.moneda_id"] = moneda_principal.id
      condiciones[:tipo] = "subvencion"
      transferencias_principal = Transferencia.all(:order => "fecha_recibido", :include => ["libro_destino"], :conditions => condiciones)
      tot_recibidos = 0
      tot_gastos = 0 
      lineas_tmp = Array.new
      transferencias_principal.each do |t|
        gasto_transferencia = t.gasto.inject(0) {|sum,g| sum+g.importe }
        tot_gastos += gasto_transferencia 
        # Desglosa las subvenciones segun el financiador (ajustando los porcentajes de gasto)
        t.transferencia_x_agente.each do |txf|
          porcentaje = txf.importe / t.importe_cambiado
          lineas_tmp.push( :contenido => [t.fecha_recibido, txf.importe, gasto_transferencia * porcentaje, "", txf.agente.nombre, t.libro_destino.nombre])
          tot_recibidos += txf.importe
        end
        # Si no hay financiadores definidos, lo pone tambien
        if t.transferencia_x_agente.empty?
          lineas_tmp.push( :contenido => [t.fecha_recibido, t.importe_cambiado, gasto_transferencia, "", "", t.libro_destino.nombre])
          tot_recibidos += t.importe_cambiado
        end
      end
      unless lineas_tmp.empty?
        lineas.push( :cabecera => [["0", "1_3"], [_("Subvenciones Recibidas"), "4"] ] )
        lineas.push( :cabecera => [	[_("Fecha"), "1_3"],    [_("%{moneda} recibidos") % {:moneda => moneda_principal.abreviatura}, "1_2_td"],
					[_("Gastos"), "1_2_td"], ["", "1_4"], [_("Financiador"), "1"], [_("Cuenta"), "1"]      ])
        lineas += lineas_tmp
        lineas.push( :contenido => [_("TOTALES"), tot_recibidos, tot_gastos] )
        lineas.push( :contenido => [] )
      end

      # A partir de este punto, solo se tienen en cuenta movimientos sobre el financiador principal
      #condiciones_base["transferencia_x_agente.agente_id"] = @proyecto.agente.id

      # Transferencias a la moneda principal para cuentas sin pais dentro de los del proyecto
      condiciones = condiciones_base.clone
      condiciones["libro.moneda_id"] = moneda_principal.id
      condiciones["libro_destinos_transferencia.moneda_id"] = moneda_principal.id
      condiciones["libro_destinos_transferencia.agente_id"] = agentes_permitidos
      condiciones["transferencia_x_agente.agente_id"] = @proyecto.agente.id
      transferencias_principal = Transferencia.all(:order => "fecha_recibido", :include => ["transferencia_x_agente", "libro_origen", "libro_destino"], :conditions => condiciones)
      lineas_sp = Array.new
      lineas_tmp = Array.new
      tot_sp_transferidos = 0
      tot_sp_recibidos = 0
      tot_sp_gastos = 0
      tot_recibidos = 0

      transferencias_principal.each do |t|
        # Coge por un lado los remanentes
        if t.tipo == "remanente" && @proyecto.libro_id == t.libro_destino_id
          lineas_tmp.push( :contenido => [t.fecha_recibido, t.importe_cambiado, "", t.nombres_financiadores, t.libro_destino.nombre])
          tot_recibidos += t.importe_cambiado
        # Y por otro el resto de transferencias a la moneda principal que no estuvieran incluidas
        elsif @proyecto.pais.find_by_id(t.libro_destino.pais_id).nil?
          gasto_transferencia = t.gasto.inject(0) {|sum,g| sum+g.importe }
          lineas_sp.push( :contenido => [t.fecha_recibido, t.importe_enviado, t.importe_cambiado, gasto_transferencia, "", (t.tipo == "remanente" ? "(R) " : "") + t.libro_destino.nombre, t.libro_origen.nombre])
          tot_sp_transferidos += t.importe_enviado if t.importe_enviado 
          tot_sp_recibidos += t.importe_cambiado
          tot_sp_gastos += gasto_transferencia
        end
      end
      # Pinta los remanentes
      unless lineas_tmp.empty?
        lineas.push( :cabecera => [["0", "1_3"], [_("Remanentes"), "4"] ] )
        lineas.push( :cabecera => [	[_("Fecha"), "1_3"],
                                        [_("%{moneda} recibidos") % {:moneda => moneda_principal.abreviatura}, "1_2_td"],
					["", "1_4"], [_("Financiador"), "1"], [_("Cuenta"), "1"]      ])
        lineas += lineas_tmp
        lineas.push( :contenido => [_("TOTALES"), tot_recibidos] )
        lineas.push( :contenido => [] )
      end
      # Y despues de los paises, las que no tienen

      # Transferencias a la moneda principal por paises para el financiador principal
      @proyecto.pais.each do |p|
        condiciones = condiciones_base.clone
        condiciones["libro.moneda_id"] = moneda_principal.id
        condiciones["libro_destinos_transferencia.moneda_id"] = moneda_principal.id
        condiciones["libro_destinos_transferencia.agente_id"] = agentes_permitidos
        condiciones["libro_destinos_transferencia.pais_id"] = p.id
        transferencias_principal = Transferencia.all(:order => "fecha_recibido", :include => ["libro_origen", "libro_destino"], :conditions => condiciones)

        lineas_tmp = Array.new
        tot_transferidos = 0
        tot_recibidos = 0
        tot_gastos = 0

        transferencias_principal.each do |t|
          # No lo incluye si es un remanente y estamos con consolidado del convenio
          gasto_transferencia = t.gasto.inject(0) {|sum,g| sum+g.importe }
          lineas_tmp.push( :contenido => [t.fecha_recibido, t.importe_enviado, t.importe_cambiado, gasto_transferencia, "", (t.tipo == "remanente" ? "(R) " : "") + t.libro_origen.nombre, t.libro_destino.nombre])
          tot_transferidos += t.importe_enviado if t.importe_enviado
          tot_recibidos += t.importe_cambiado
	  tot_gastos += gasto_transferencia
        end
        unless lineas_tmp.empty?
          lineas.push( :cabecera => [["1A", "1_3"], [_("Transferencias %{agente} a cuentas %{moneda} en %{pais}") % {:agente => @proyecto.agente.nombre, :moneda => moneda_principal.abreviatura, :pais => p.nombre}, "4"]] )
          lineas.push( :cabecera => [ [_("Fecha"), "1_3"],
                                    [_("%{moneda} transferidos") % {:moneda => moneda_principal.abreviatura}, "1_2_td"],
                                    [_("%{moneda} recibidos") % {:moneda => moneda_principal.abreviatura}, "1_2_td"],
                                    [_("Gastos"), "1_2_td"], ["", "1_4"],
                                    [_("Cuenta Origen"), "1"], [_("Cuenta Destino"), "1"]      ])
          lineas += lineas_tmp
          lineas.push( :contenido => [_("TOTALES"), tot_transferidos, tot_recibidos, tot_gastos] )
          lineas.push( :contenido => [] )
        end
      end

      # Pinta las transferencias a la moneda principal para no pais
      unless lineas_sp.empty?
        lineas.push( :cabecera => [["1A", "1_3"], [_("Transferencias") + " " + @proyecto.agente.nombre + _(" a otras cuentas ") + moneda_principal.abreviatura, "4"] ] )
        lineas.push( :cabecera => [	[_("Fecha"), "1_3"],
                                        [_("%{moneda} transferidos") % {:moneda => moneda_principal.abreviatura}, "1_2_td"],
                                        [_("%{moneda} recibidos") % {:moneda => moneda_principal.abreviatura}, "1_2_td"],
                                        [_("Gastos"), "1_2_td"], ["", "1_4"],
					[_("Cuenta Origen"), "1"], [_("Cuenta Destino"), "1"]      ])
        lineas += lineas_sp
        lineas.push( :contenido => [_("TOTALES"), tot_sp_transferidos, tot_sp_recibidos, tot_sp_gastos] )
        lineas.push( :contenido => [] )
      end

      # Transferencias a la divisa (si la hay) desde la principal por paises y financiadores
      condiciones = condiciones_base.clone
      condiciones["libro.moneda_id"] = moneda_principal.id
      condiciones["libro_destinos_transferencia.moneda_id"] = moneda_intermedia.id if moneda_intermedia
      condiciones["libro_destinos_transferencia.agente_id"] = agentes_permitidos

      @proyecto.financiador.each do |f|
        condiciones["transferencia_x_agente.agente_id"] = f.id
        @proyecto.pais.each do |p|
          condiciones["libro_destinos_transferencia.pais_id"] = p.id
          transferencias_divisa = Transferencia.all(:order => "fecha_recibido", :include => ["transferencia_x_agente","libro_origen", "libro_destino"], :conditions => condiciones)

          lineas_tmp = Array.new
          tot_transferidos = 0
          tot_recibidos = 0
          tot_cambiados = 0
          tot_gastos = 0

          # Recoge las transferencias a divisas 
          transferencias_divisa.each do |t|
            gasto_transferencia = t.gasto.inject(0) {|sum,g| sum+g.importe }
            lineas_tmp.push( :contenido => [t.fecha_recibido, t.importe_enviado, t.importe_recibido, t.importe_cambiado, t.tasa_cambio, gasto_transferencia, "", (t.tipo == "remanente" ? "(R) " : "") + t.libro_origen.nombre, t.libro_destino.nombre])
            tot_transferidos += t.importe_enviado if t.importe_enviado
            tot_recibidos += t.importe_recibido if t.importe_recibido
            tot_cambiados += t.importe_cambiado if t.importe_cambiado
            tot_gastos += gasto_transferencia
          end
          unless lineas_tmp.empty?
            tc_total = tot_cambiados != 0 ? format("%.5f",tot_recibidos / tot_cambiados) : "" 
            lineas.push( :cabecera => [ ["1B", "1_3"],
                                        [_("Transferencias %{agente} a cuentas %{moneda} en %{pais}") % {:agente => f.nombre, :moneda => moneda_intermedia.abreviatura, :pais => p.nombre}, "4"]
                                      ] )
            lineas.push( :cabecera => [ [_("Fecha"), "1_3"],
                                        [_("%{moneda} enviados") % {:moneda => moneda_principal.abreviatura}, "1_2_td"],
                                        [_("%{moneda} recibidos y cambiados") % {:moneda => moneda_principal.abreviatura}, "1_2_td"],
                                        [_("%{moneda} recibidos") % {:moneda => moneda_intermedia.abreviatura}, "1_2_td"],
                                        [_("Tasa de Cambio") + " " + moneda_intermedia.abreviatura + "/" + moneda_principal.abreviatura, "1_2_td_g"],
                                        [_("Gastos") + " (" + moneda_intermedia.abreviatura + ")", "1_2_td"],
                                        ["", "1_4"], [_("Cuenta Origen"), "1"], [_("Cuenta Destino"), "1"]     ])
            lineas += lineas_tmp
            lineas.push( :contenido => [_("TOTALES"), tot_transferidos, tot_recibidos, tot_cambiados, tc_total, tot_gastos] )
            lineas.push( :contenido => [] )
          end
        end
      end if @proyecto.moneda_intermedia


      # Transferencias a las monedas locales por países
      condiciones = condiciones_base.clone
      @proyecto.pais.each do |p|
        condiciones["libro.pais_id"] = p.id
        p.moneda.each do |m|
          #condiciones.delete(:tipo)
          condiciones["libro.moneda_id"] = m.id
          transferencias_locales = Transferencia.all(:order => "fecha_recibido", :include => ["libro_destino"], :conditions => condiciones)

          lineas_tmp = Array.new
          tot_transferidos_princ = 0
          tot_transferidos_sec = 0
          tot_recibidos_princ = 0
          tot_recibidos_sec = 0
          tot_cambiados_princ = 0
          tot_cambiados_sec = 0
          tot_gastos = 0

          transferencias_locales.each do |t|
            if	t.libro_origen && (t.libro_origen.moneda_id == moneda_principal.id || (moneda_intermedia && t.libro_origen.moneda_id == moneda_intermedia.id))
              gasto_transferencia = t.gasto.inject(0) {|sum,g| sum+g.importe }

              # Separamos si existe o no existe moneda intermedia pues el formato final sera distinto
              if moneda_intermedia
                # Si la transferencia es desde moneda principal
                lineas_tmp.push( :contenido => [t.fecha_recibido, t.importe_enviado, "", t.importe_recibido, "", t.importe_cambiado, t.tasa_cambio, "", gasto_transferencia, "", t.nombres_financiadores, t.libro_destino.agente.nombre, (t.tipo == "remanente" ? "(R) " : "") + t.libro_origen.nombre, t.libro_destino.nombre]) if t.libro_origen.moneda == moneda_principal
                # Si la transferencia es desde la moneda intermedia
                lineas_tmp.push( :contenido => [t.fecha_recibido, "", t.importe_enviado, "", t.importe_recibido, t.importe_cambiado, "", t.tasa_cambio, gasto_transferencia, "", t.nombres_financiadores, t.libro_destino.agente.nombre, (t.tipo == "remanente" ? "(R) " : "") + t.libro_origen.nombre, t.libro_destino.nombre]) if t.libro_origen.moneda == moneda_intermedia
              else
                # Cuando no existe la moneda intermedia, eliminamos sus campos
                lineas_tmp.push( :contenido => [t.fecha_recibido, t.importe_enviado, t.importe_recibido, t.importe_cambiado, t.tasa_cambio, gasto_transferencia, "", t.nombres_financiadores, t.libro_destino.agente.nombre, (t.tipo == "remanente" ? "(R) " : "") + t.libro_origen.nombre, t.libro_destino.nombre])
              end

              tot_transferidos_princ += t.importe_enviado if t.importe_enviado && t.libro_origen.moneda == moneda_principal
              tot_transferidos_sec += t.importe_enviado if t.importe_enviado && moneda_intermedia && t.libro_origen.moneda == moneda_intermedia
              tot_recibidos_princ += t.importe_recibido if t.importe_recibido && t.libro_origen.moneda == moneda_principal
              tot_recibidos_sec += t.importe_recibido if t.importe_recibido && moneda_intermedia && t.libro_origen.moneda == moneda_intermedia
              tot_cambiados_princ += t.importe_cambiado if t.importe_cambiado && t.libro_origen.moneda == moneda_principal
              tot_cambiados_sec += t.importe_cambiado if t.importe_cambiado && moneda_intermedia && t.libro_origen.moneda == moneda_intermedia 
              tot_gastos += gasto_transferencia
            end
          end
          unless lineas_tmp.empty?
            tc_total_princ = tot_cambiados_princ != 0 ? format("%.5f",tot_recibidos_princ / tot_cambiados_princ) : ""
            tc_total_sec = tot_cambiados_sec != 0 ? format("%.5f",tot_recibidos_sec / tot_cambiados_sec) : ""
            lineas.push( :cabecera => [["2", "1_3"], [p.nombre + " (" + m.nombre + ")", "4"] ] )
            cabecera  = [ [_("Fecha"), "1_3"], [_("%{moneda} enviados") % {:moneda => moneda_principal.abreviatura}, "1_2_td"]]
            cabecera += [ [_("%{moneda} enviados") % {:moneda => moneda_intermedia.abreviatura}, "1_2_td"] ] if moneda_intermedia
            cabecera += [ [_("%{moneda} recibidos y cambiados") % {:moneda => moneda_principal.abreviatura}, "1_2_td"] ]
            cabecera += [ [_("%{moneda} recibidos y cambiados") % {:moneda => moneda_intermedia.abreviatura}, "1_2_td"] ] if moneda_intermedia
            cabecera += [ [_("%{moneda} recibidos") % {:moneda => m.abreviatura}, "1_2_td"] ]
            cabecera += [ [_("Tasa de Cambio") + " " + m.abreviatura + "/" + moneda_principal.abreviatura, "1_2_td_g"] ]
            cabecera += [ [_("Tasa de Cambio") + " " + m.abreviatura + "/" + moneda_intermedia.abreviatura, "1_2_td_g"] ] if moneda_intermedia
            cabecera += [ [_("Gastos") + " (" + m.abreviatura + ")", "1_2_td"],
                          ["", "1_4"], [_("Financiador"), "3_4"], [_("Destinatario"), "3_4"], [_("Cuenta Origen"), "1"], [_("Cuenta Destino"), "1"]     ]
            lineas.push( :cabecera => cabecera )
            lineas += lineas_tmp
            lineas.push( :contenido => [_("TOTALES"), tot_transferidos_princ, tot_transferidos_sec, tot_recibidos_princ, tot_recibidos_sec, tot_cambiados_princ + tot_cambiados_sec, tc_total_princ, tc_total_sec, tot_gastos] ) if moneda_intermedia
            lineas.push( :contenido => [_("TOTALES"), tot_transferidos_princ, tot_recibidos_princ, tot_cambiados_princ, tc_total_princ, tot_gastos] ) unless moneda_intermedia
            lineas.push( :contenido => [] )
          end
        end
      end 

      @resumen = Array.new
      nombre = "transferencias"
      titulo = _("Resumen Transferencias ") + @proyecto.nombre + " / "
      if @proyecto.convenio?
        titulo += _("PAC") + ": " + (@pac ? @pac.nombre : "Todos")
      else
        titulo += _("Etapa") + ": " + (@etapa ? @etapa.nombre + " " + _("(desde %{fecha_inicio} hasta %{fecha_fin})") % {:fecha_inicio => @etapa.fecha_inicio.strftime('%d/%m/%Y'), :fecha_fin => @etapa.fecha_fin.strftime('%d/%m/%Y')} : _("Todas") )
      end
      resumen_error = @proyecto.pais.size == 0 ? 
	_("No existe ningún país definido para el proyecto.<br/>Configure los paises de actuación en las Relaciones del Menú de Configuración del proyecto.") : nil
      @resumen.push(:listado => {:nombre => nombre, :titulo => titulo, :lineas => lineas, :resumen_error => resumen_error})


      respond_to do |format|
        format.html do
          render :layout => (params[:sin_layout] ? false : true)
        end
        format.xls do
          nom_fich = "resumen_transferencias_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
        end
      end
  end

	# En proyectos, vista resumen de estado de tesoreria (segun la hoja X.A.2 del informe AECID)
  def estado_tesoreria
    @listado_etapa = [[_("Todas"), "todas"]] + @proyecto.etapa.collect{|e| [e.nombre, e.id]} unless @proyecto.convenio?
    @listado_pac = @proyecto.pacs.collect{|e| [e.nombre, e.id]} if @proyecto.convenio?
    @listado_agente = @proyecto.financiador.collect{|e| [e.nombre, e.id]} + [ [_("Todos"), "todos"] ]

    unless params[:selector]
      params[:selector] = {:agente => @proyecto.agente.id}
    end

    if @proyecto.convenio?
      @etapa = nil
      proyecto = @proyecto.pacs.find_by_id(params[:selector][:pac]) || @proyecto.pacs.first || @proyecto
    else
      @etapa = @proyecto.etapa.find_by_id(params[:selector][:etapa])
      proyecto = @proyecto
    end
    @agente = @proyecto.financiador.find_by_id(params[:selector][:agente])

    lineas = []
    (cab_col, cab_fila, filas) = proyecto.tesoreria(@agente, @etapa, params[:selector][:remanente] == "principal")

    cabecera = [ [_("Ingresos y Transferencias"),"1"] ]
    cab_col.each do |cab|
      p = Pais.find_by_id(cab[:pais_id])
      m = Moneda.find_by_id(cab[:moneda_id])
      cabecera.push( [ m.nombre + ( p ? " " + p.nombre : ""), "1_2_td"] )
    end

    lineas.push( :cabecera => cabecera )
    cab_fila.zip(filas).each do |cab, fila|
      estilo = [ ['',"1"] ]
      estilo += fila.collect{ ['','1_2_td' ] } unless cab == _("Tipo de cambio aplicable")
      estilo += fila.collect{ ['','1_2_td_g' ] }   if cab == _("Tipo de cambio aplicable")
      lineas.push( :estilo => estilo, :contenido => [ cab ] + fila )
    end

    @resumen = Array.new
    nombre = "tesoreria"
    titulo = _("Resumen Tesoreria") + " " + @proyecto.nombre + " / " 
    titulo += _("Etapa") + ": " + (@etapa ? @etapa.nombre + " " + _("(desde %{fecha_inicio} hasta %{fecha_fin})") % {:fecha_inicio => @etapa.fecha_inicio.strftime('%d/%m/%Y'), :fecha_fin => @etapa.fecha_fin.strftime('%d/%m/%Y')} : _("Todas") ) unless @proyecto.convenio?
    titulo += _("PAC") + ": " + proyecto.nombre if @proyecto.convenio?
    @resumen.push(:listado => {:nombre => nombre, :titulo => titulo, :lineas => lineas})

    respond_to do |format|
      format.html do
        render :layout => (params[:sin_layout] ? false : true)
      end
      format.xls do
        nom_fich = "resumen_tesoreria_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
      end
    end
  end

	# En proyectos, vista resumen de la matriz por etapa y pais
  def matriz
    @listado_etapa = [[_("Todas"), "todas"]] + @proyecto.etapa.collect{|e| [e.nombre, e.id]}
    @listado_pais =  [[_("Todos"), "todos"]] + @proyecto.pais.collect{ |p| [p.nombre, p.id] }.sort{ |a, b| a[0] <=> b[0]}

      @pais = params[:selector] && params[:selector][:pais] ? Pais.find_by_id(params[:selector][:pais]) : nil 
      @etapa = params[:selector] && params[:selector][:etapa] ? Etapa.find_by_id(params[:selector][:etapa]) : nil 
      seguimiento = params[:selector] && params[:selector][:tipo] == "seguimiento"
      ocultar_comentarios = params[:selector] && params[:selector][:ocultar_comentarios] == "1"
      #@columnas_nombre = [_("descripcion"), _("indicadores"), _("fuentes de verificacion"), _("hipótesis")] unless seguimiento
      #@columnas_nombre = [_("descripcion"), _("indicadores"), _("% realizado"), _("comentarios"), _("fuentes de verificacion"), _("hipótesis")] if seguimiento
      lineas = Array.new
      condiciones = { "proyecto_id" =>  @proyecto.id}
      condiciones["actividad_x_pais.pais_id"] = @pais.id if @pais 
      condiciones["actividad_x_etapa.etapa_id"] = @etapa.id if @etapa 
      filas_objetivos = Array.new
      filas_resultados = Array.new
      filas_actividades = Array.new 

      nivel_acciones = @proyecto.convenio ? @proyecto.convenio.convenio_accion : @proyecto.convenio_accion

      # Recorre desde objetivos especificos hacia abajo
      @proyecto.objetivo_especifico.all.each do |objetivo|
        existen_actividades = false
        cabecera_actividades = true if nivel_acciones == "objetivo_especifico"
        objetivo.resultado.all.each do |resultado|
          existen_actividades = false
          cabecera_actividades = true if nivel_acciones.nil? || nivel_acciones == "resultado"
          actividades = resultado.actividad.all(:order => "codigo", :include => [:actividad_x_pais, :actividad_x_etapa], :conditions => condiciones )
          actividades_resultado = []
          actividades.each do |actividad|
            nuevas_actividades = desglosa_actividades(actividad,@etapa,seguimiento,ocultar_comentarios)
            actividades_resultado += nuevas_actividades 
            existen_actividades = true if nuevas_actividades.length > 0 
          end
          if cabecera_actividades && actividades_resultado.length > 0
            objeto_padre = _("Resultado") + " " + resultado.codigo if nivel_acciones.nil?
            objeto_padre = _("Acción") + " " + (nivel_acciones == "resultado" ? resultado.codigo : objetivo.codigo) unless nivel_acciones.nil?
            filas_actividades.push(:cabecera => [ [_("Actividades") + " " + objeto_padre,"3_2"], [_("Recursos"),"1_td"], [_("Costes"),"1_td"] ]) unless seguimiento
            filas_actividades.push(:cabecera => [ [_("Actividades") + " " + objeto_padre,"3_2"], ["% " + _("Actividad"), "3_4"], [_("Recursos"),"1_td"], [_("Costes"),"1_2_td"], [_("Gastos"), "1_2_td"] ]) if seguimiento
            cabecera_actividades = false
          end
          filas_actividades += actividades_resultado if actividades_resultado.length > 0 
          filas_resultados += desglosa_fuentes(resultado, seguimiento, ocultar_comentarios) if existen_actividades
        end
        filas_objetivos += desglosa_fuentes(objetivo, seguimiento, ocultar_comentarios) if existen_actividades 
      end

      # Y le incluye las actividades globales (sin resultado asociado)
      condiciones[:resultado_id] = nil
      filas_actividades_comunes = [] 
      @proyecto.actividad.all(:order => "codigo", :include => [:actividad_x_pais, :actividad_x_etapa], :conditions => condiciones).each do |actividad|
        filas_actividades_comunes += desglosa_actividades(actividad,@etapa,seguimiento,ocultar_comentarios)
      end

      # Va rellenando las lineas
      #  primero el objetivo general
      if (@proyecto.objetivo_general && @proyecto.objetivo_general.descripcion != "")
        lineas.push(:cabecera => [ [_("Objetivo General"), "4"] ])
        lineas.push(:contenido => [ @proyecto.objetivo_general.descripcion ])
      end
      #  y continua con el objetivo especifico
      lineas.push(:cabecera => [ [(nivel_acciones == "objetivo_especifico" ? _("Acciones") : _("Descripción")),"3_2"], [_("Indicadores"),"1"], [_("Fuentes de verificación"),"1"], [_("Hipótesis"),"1"] ]) unless seguimiento
      lineas.push(:cabecera => [ [(nivel_acciones == "objetivo_especifico" ? _("Acciones") : _("Descripción")),"3_2"], [_("Indicadores"),"1"], ["% " + _("Indicador"),"1"], [_("Fuentes de verificación"),"1"] ]) if seguimiento
      lineas += filas_objetivos
      lineas.push(:cabecera => [ [(nivel_acciones == "resultado" ? _("Acciones") : _("Resultados")),"3_2"], ["","1"], ["","1"], ["","1"] ]) unless seguimiento
      lineas.push(:cabecera => [ [(nivel_acciones == "resultado" ? _("Acciones") : _("Resultados")),"3_2"], ["","1"], ["","1"], ["","1"] ]) if seguimiento 
      lineas += filas_resultados 
      lineas += filas_actividades
      if filas_actividades_comunes.length > 0
        lineas.push(:cabecera => [ [_("Actividades Globales"),"3_2"], [_("Recursos"),"1_td"], [_("Costes"),"1_td"] ]) unless seguimiento
        lineas.push(:cabecera => [ [_("Actividades Globales"),"3_2"], ["% " + _("Actividad"), "3_4"], [_("Recursos"),"1_td"], [_("Costes"),"1_2_td"], [_("Gastos"), "1_2_td"] ]) if seguimiento
        lineas += filas_actividades_comunes
      end

      @resumen = Array.new
      nombre = "matriz"
      titulo  = ( params[:selector] && params[:selector][:tipo] == "seguimiento" ? _("Matriz de Seguimiento") : _("Matriz de Formulación") ) + " "
      titulo += @proyecto.nombre + " / " + _("País") + ": " + (@pais ? @pais.nombre : _("Todos")) + " / "
      titulo += _("Etapa") + ": " + (@etapa ? @etapa.nombre + " " + _("(desde %{fecha_inicio} hasta %{fecha_fin})") % {:fecha_inicio => @etapa.fecha_inicio.strftime('%d/%m/%Y'), :fecha_fin => @etapa.fecha_fin.strftime('%d/%m/%Y')} : _("Todas") ) 
      @resumen.push(:listado => {:nombre => nombre, :titulo => titulo, :lineas => lineas})

      respond_to do |format|
        format.html do
          render :action => "matriz", :layout => (params[:sin_layout] ? false : true)
        end
        format.xls do
          nom_fich = "resumen_matriz_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
        end
      end

  end

        # Para un objetivo especifico o un resultado, saca hipotesis, indicadores y fuentes de verificacion
  def desglosa_fuentes(objeto, seguimiento=false, ocultar_comentarios=false)
    filas = Array.new
    titulo_objeto = objeto.codigo + ": " + objeto.descripcion
    comentarios = objeto.comentario
    titulo_objeto += "\n\n* ".html_safe + comentarios.collect{|c| c.texto}.join("\n* ".html_safe) unless !seguimiento || ocultar_comentarios || comentarios.empty?
    hipotesis = objeto.hipotesis
    indicadores = objeto.indicador
    objeto_repetido = nil
    # Si no hay indicadores al menos muestra el codigo del objeto
    filas.push( :contenido => [ titulo_objeto, "", "", "" ] ) if indicadores.length == 0
    # Si hay indicadores se los recorre para rellenar las filas
    indicadores.each do |indicador|
      indicador_repetido = nil
      titulo_indicador = indicador.codigo + ": " + indicador.descripcion
      comentarios = indicador.comentario
      #titulo_indicador += "\n\n* ".html_safe + comentarios.collect{|c| c.texto}.join("\n* ".html_safe) unless !seguimiento || ocultar_comentarios || comentarios.empty?
      fuentes = indicador.fuente_verificacion
      # Si no hay fuentes de verificacion al menos pone el indicador...
      # ... para formulacion
      filas.push( :contenido => [       objeto_repetido ? "" : titulo_objeto,
                                        titulo_indicador,
                                        "",
                                        (hipotesis.length>0 ? hipotesis.shift.descripcion : "") ]) if fuentes.length == 0 && !seguimiento
      # ... y para seguimiento
      filas.push( :contenido => [       objeto_repetido ? "" : titulo_objeto,
                                        titulo_indicador,
                                        (indicador.porcentaje_actual * 100).to_i.to_s + "%" + (indicador.comentario_porcentaje_actual != "" && !ocultar_comentarios ? " - " + indicador.comentario_porcentaje_actual : ""),
                                        "" ]) if fuentes.length == 0 && seguimiento
      # Si hay fuentes de verificacion las recorre para rellenar las filas
      fuentes.each do |fuente|
        # ... para formulacion
        filas.push( :contenido => [     objeto_repetido ? "" : titulo_objeto,
                                        indicador_repetido ? "" : titulo_indicador,
                                        fuente.codigo + ": " + fuente.descripcion,
                                        (hipotesis.length>0 ? hipotesis.shift.descripcion : "") ]) unless seguimiento
        # ... y para seguimiento
        filas.push( :contenido => [     objeto_repetido ? "" : titulo_objeto,
                                        indicador_repetido ? "" : titulo_indicador,
                                        indicador_repetido ? "" : (indicador.porcentaje_actual * 100).to_i.to_s + "%" + (indicador.comentario_porcentaje_actual != "" && !ocultar_comentarios ? " - " + indicador.comentario_porcentaje_actual : ""),
                                        (fuente.completada ? "(" + _("Completada") + ") " : "") +
                                          fuente.codigo + ": " + fuente.descripcion ]) if seguimiento
        objeto_repetido = true
        indicador_repetido = true
      end
      objeto_repetido = true
    end
    # Si queda alguna hipotesis la mete
    hipotesis.each do |hip|
      filas.push( :contenido => [       "", "", "", hip.descripcion ])
    end unless seguimiento
    return filas
  end

        # Para una actividad, saca partidas de financiador e importes totales
  def desglosa_actividades(objeto,etapa, seguimiento=false, ocultar_comentarios=false)
    hash = Hash.new 
    filas = Array.new
    importe_total = 0
    gasto_total = 0
    # Se recorre todos los presupuestos por actividad
    objeto.presupuesto_x_actividad.each do |pxa|
      # Y en el caso de que el presupuesto sea de la etapa relacionada y tenga asignada una partida lo mete
      if pxa.presupuesto && pxa.presupuesto.partida && (etapa.nil? || pxa.presupuesto.etapa_id == etapa.id)
        partida_asociada=pxa.presupuesto.partida.partida_asociada(@proyecto.id) if pxa.presupuesto && pxa.presupuesto.partida
        if partida_asociada
          # aplica la tasa de cambio
          importe = pxa.importe * pxa.presupuesto.tasa_cambio
          hash[partida_asociada.nombre] = Hash.new unless hash[partida_asociada.nombre]
          hash[partida_asociada.nombre][:presupuesto] += importe if hash[partida_asociada.nombre][:presupuesto]
          hash[partida_asociada.nombre][:presupuesto] = importe unless hash[partida_asociada.nombre][:presupuesto]
          importe_total += importe
        end
      end
    end
    # Se recorre todos los gastos por actividad
    objeto.gasto_x_actividad.each do |gxa|
      # Y en el caso de que el presupuesto sea de la etapa relacionada y tenga asignada una partida lo mete
      if gxa.gasto && gxa.gasto.partida && (etapa.nil? || (gxa.gasto.fecha >= etapa.fecha_inicio && gxa.gasto.fecha <= etapa.fecha_fin))
        partida_asociada = gxa.gasto.partida.partida_asociada(@proyecto.id)
        if partida_asociada
          # obtiene y aplica la tasa de cambio
          tc = gxa.gasto.tasa_cambio_proyecto(@proyecto.id)
          if tc
            importe = gxa.importe * tc.tasa_cambio
            hash[partida_asociada.nombre] = Hash.new unless hash[partida_asociada.nombre]
            hash[partida_asociada.nombre][:gasto] += importe if hash[partida_asociada.nombre][:gasto]
            hash[partida_asociada.nombre][:gasto] = importe unless hash[partida_asociada.nombre][:gasto]
            gasto_total += importe
          end
        end
      end
    end if seguimiento
    titulo_objeto = objeto.codigo + ": " + objeto.descripcion
    estado_actual = objeto.estado_actual(etapa) if seguimiento
    comentario_actividad = (estado_actual ? (estado_actual.porcentaje * 100).to_i.to_s + "%" + ((estado_actual.comentario && estado_actual.comentario != "" && !ocultar_comentarios ) ? " - " + estado_actual.comentario : "") : "") if seguimiento 

    # Si no tenemos informacion de costes o gastos, presentamos solo el titulo
    if hash.length == 0
      filas.push( :contenido => [         titulo_objeto, "", ""]) unless seguimiento
      filas.push( :contenido => [         titulo_objeto, comentario_actividad, "", ""]) if seguimiento
    # Si tenemos informacion de costes o gastos, presentamos el total
    else
      filas.push( :contenido => [       titulo_objeto, _("Total"), importe_total]) unless seguimiento
      filas.push( :contenido => [       titulo_objeto, comentario_actividad, _("Total"), importe_total, gasto_total]) if seguimiento
    end

    hash.each do |k,v|
      filas.push( :contenido => [       "", k, v[:presupuesto] ]) unless seguimiento
      filas.push( :contenido => [       "", "", k, v[:presupuesto], v[:gasto] ]) if seguimiento
    end
    return filas
  end


#+++
# Resumen de Actividades
#---

	# en proyectos: genera el informe de seguimiento tecnico 
  def seguimiento_tecnico 
    @listado_pac = [[_("Todas"),nil]] + @proyecto.pacs.collect{|e| [e.nombre, e.id]} if @proyecto.convenio?
    @fecha_de_fin = DateTime.now.to_date unless params["fecha_fin"]
    @fecha_de_fin = Date.strptime(params["fecha_fin"]["(3i)"] + '-' + params["fecha_fin"]["(2i)"] + '-' + params["fecha_fin"]["(1i)"], '%d-%m-%Y') if params["fecha_fin"]

    if params[:selector] && params[:selector][:pdf] == "1"
      begin
        url = url_for(:only_path => false, :action => :seguimiento_tecnico_render, :id => params[:pac], :fecha_de_fin => @fecha_de_fin.to_time.to_i.to_s)
        kit = Shrimp::Phantom.new( url, {}, {"_session_id" => cookies[:_session_id]})
        send_file(kit.to_pdf, :filename => @proyecto.nombre + "_" + _("seguimiento_tecnico") + '.pdf', :type => 'application/pdf', :disposition => 'inline')
      rescue => ex
        logger.error ex.message
        logger.error ex.backtrace
        msg_error _("Se produjo un error en el módulo de exportación a PDF.")
        seguimiento_tecnico_render
      end
    else
      seguimiento_tecnico_render
    end
  end
	# renderiza el informe de seguimiento tecnico (es necesario hacerlo asi para poder generar pdfs)
  def seguimiento_tecnico_render
    @fecha_de_fin ||= Time.at(params[:fecha_de_fin].to_i).to_date if params[:fecha_de_fin]
    params[:pac] = params[:id] if params[:id]
    params[:pac] ||= @proyecto.pacs.first.id if @proyecto.convenio?

    if @proyecto.convenio?
      pac = Proyecto.find_by_id(params[:pac])
      @proyectos = pac || @proyecto.pacs
    else
      @proyectos = [@proyecto] unless @proyecto.convenio?
    end
    unless @fecha_de_fin.nil?
      estado_seguimiento_tecnico
      @activs = @proyecto.actividad.sort_by(&:codigo).group_by(&:resultado)
    end
    render :action => "seguimiento_tecnico", :layout => (params[:fecha_de_fin] ? false : true)
  end

  def estado_seguimiento_tecnico
    # Seleccionamos actividades y resultados y objetivos activos en etapas dentro de las fechas
    #@actividades = @proyecto.actividad.all(:include => ["etapa"], :conditions => ["etapa.fecha_inicio <= ?", @fecha_de_fin])
    #@resultados = @proyecto.resultado.all(:include => ["actividad"], :conditions => {"actividad.id" => @actividades})
    #@oe = @proyecto.objetivo_especifico.all(:include => ["resultado"], :conditions => {"resultado.id" => @resultados})
    @actividades = Actividad.all(:order => "actividad.codigo", :include => ["etapa"], :conditions => ["etapa.fecha_inicio <= ? AND actividad.proyecto_id IN (?)", @fecha_de_fin, @proyectos])
    @resultados = Resultado.all(:order => "resultado.codigo", :include => ["actividad"], :conditions => {"actividad.id" => @actividades, "resultado.proyecto_id" => @proyectos})
    @oe = ObjetivoEspecifico.all(:order => "objetivo_especifico.codigo", :include => ["resultado"], :conditions => {"resultado.id" => @resultados, "objetivo_especifico.proyecto_id" => @proyectos})
  end


  # en proyectos: genera el informe de resumen ejecutivo
  def resumen_ejecutivo 
    @listado_pac = [[_("Todas"),nil]] + @proyecto.pacs.collect{|e| [e.nombre, e.id]} if @proyecto.convenio?
    if params[:selector] && params[:selector][:fichero] == "1" && params[:selector][:tipo] == "pdf"
      begin
        url = url_for(:only_path => false, :action => :resumen_ejecutivo_render, :id => 34, :to_pdf => true)
        kit = Shrimp::Phantom.new( url, { :format => "37cm*42cm" }, {"_session_id" => cookies[:_session_id]})
        send_file(kit.to_pdf, :filename => _("Resumen_ejecutivo_") + @proyecto.nombre + '.pdf', :type => 'application/pdf', :disposition => 'attachment')
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
    
    #carga los datos básicos del proyecto comunes para varios resumenes
    lineas = datos_basicos

    lineas.push(:cabecera => [ [_("3. FECHAS Y VIGENCIA"), "1"], ["","13_4"] ])
    @proyecto.etapa.each do |et|
      lineas.push(:contenido => [ et.nombre.upcase, "" ])
      lineas.push(:contenido => [  _("Fecha de inicio:"), I18n.l(et.fecha_inicio)])
      lineas.push(:contenido => [  _("Fecha de finalización:"), I18n.l(et.fecha_fin)])
      lineas.push(:contenido => [  _("Periodo total de ejecución:"), et.meses.to_s + " meses"])
    end if @proyecto.etapa.count > 0
    @proyecto.etapa.each do |et|
      lineas.push(:contenido => [  _("Fecha de inicio:"),""])
      lineas.push(:contenido => [  _("Fecha de finalización:"),""])
      lineas.push(:contenido => [  _("Periodo total de ejecución:"), ""])
    end unless @proyecto.etapa.count > 0

    lineas.push(:contenido => [  _("% de tiempo transcurrido:"),porcentaje_tiempo])
    @proyecto.periodo.joins(:tipo_periodo).where("tipo_periodo.grupo_tipo_periodo" => "final").each do |pe|
      lineas.push(contenido: [ _("Fecha fin %{nombre_periodo}:")%{nombre_periodo: pe.tipo_periodo.nombre}, I18n.l(pe.fecha_fin)])
    end

    lineas.push(:cabecera => [[_("4. FINANCIACIÓN Y SEGUIMIENTO ECONOMICO (en la moneda de justificación)"), "4"] ])
    lineas.push(:cabecera => [ [_("Descripción"),"3_2"], [_("Presupuesto aprobado"),"1"], [_("Presupuesto ejecutado"),"1"], [_("% de Ejecución presupuestaria"),"1"] ]) if bool_xls
    lineas.push(:cabecera => [ [_("Descripción"),"3_2"], [_("Presupuesto aprobado"),"1_td"], [_("Presupuesto ejecutado"),"1_td"], [_("% de Ejecución presupuestaria"),"1_td"] ]) unless bool_xls
    
    
    p_total = @proyecto.presupuesto_total || 0
    g_total = @proyecto.gasto_total_sin_financiador || 0
    cad_total_pres = view_context.float_a_moneda(p_total) + " " + @proyecto.moneda_principal.abreviatura
    cad_total_gasto = view_context.float_a_moneda(g_total) + " " + @proyecto.moneda_principal.abreviatura
    cad_total_porcentaje_ejec = (p_total > 0 ? (100 * g_total / p_total).round : 0).to_s + " %"
    lineas.push(:contenido => [ _("Presupuesto total del Proyecto:"),cad_total_pres,cad_total_gasto, cad_total_porcentaje_ejec])

    p_finan = @proyecto.agente ? @proyecto.presupuesto_total_con_financiador(@proyecto.agente) : 0
    g_finan = @proyecto.agente ? @proyecto.gasto_total_con_financiador(@proyecto.agente) : 0
    cad_fin_pres = view_context.float_a_moneda(p_finan) + " " + @proyecto.moneda_principal.abreviatura
    cad_fin_gasto = view_context.float_a_moneda(g_finan) + " " + @proyecto.moneda_principal.abreviatura
    cad_fin_porcentaje_ejec = ( p_finan > 0 ? (100 * g_finan / p_finan).round : 0).to_s + " %"
    lineas.push(:contenido => [ _("Aportación Financiador Principal:"),cad_fin_pres,cad_fin_gasto,cad_fin_porcentaje_ejec])

    p_otros = p_total - p_finan
    g_otros = g_total - g_finan
    cad_otros_pres = view_context.float_a_moneda(p_otros) + " " + @proyecto.moneda_principal.abreviatura
    cad_otros_gasto = view_context.float_a_moneda(g_otros) + " " + @proyecto.moneda_principal.abreviatura
    cad_otros_porcentaje_ejec = ( p_otros > 0 ? (100 * g_otros / p_otros).round : 0).to_s + " %"
    lineas.push(:contenido => [ _("Aportación otros financiadores:"),cad_otros_pres,cad_otros_gasto,cad_otros_porcentaje_ejec])
    
    lineas.push(:cabecera => [[_("5. SEGUIMIENTO  TECNICO"), "4"] ])
    lineas.push(:cabecera => [ [_("Descripción"),"3_2"], [_("Seguimiento"),"3_2"], [_("% cumplimiento"),"1"] ]) if bool_xls
    lineas.push(:cabecera => [ [_("Descripción"),"3_2"], [_("Seguimiento"),"3_2"], [_("% cumplimiento"),"1_td"] ]) unless bool_xls

    activ_total = @proyecto.actividad.count
    activ_valor_porc = @proyecto.actividad.sum do |a|
      vixa = ValorIntermedioXActividad.joins(:actividad_x_etapa).
                                       where("actividad_x_etapa.actividad_id" => a.id).
                                       order("valor_intermedio_x_actividad.fecha").last
      vixa ? vixa.porcentaje||0.0 : 0.0
    end 
    activ_valor = ActividadXEtapa.count(:include => [:actividad,:valor_intermedio_x_actividad], :conditions => ["actividad.proyecto_id = ? AND realizada = TRUE",@proyecto.id])
    lineas.push(:contenido => [ _("Actividades:"),activ_valor.to_s + " de " + activ_total.to_s + " Actividades realizadas",(activ_valor_porc * 100/(activ_total > 0 ? activ_total : 1)).round.to_s + " %"])
    
    ind_total = Indicador.count(:include => ["objetivo_especifico", "resultado"], :conditions => ["objetivo_especifico.proyecto_id = ? OR resultado.proyecto_id = ?", @proyecto.id, @proyecto.id])
    ind_valor_porc = Indicador.includes(:resultado, :objetivo_especifico).
                               where(["objetivo_especifico.proyecto_id = ? OR resultado.proyecto_id = ?", @proyecto.id, @proyecto.id]).
                               inject(0){|sum,i| sum + i.porcentaje_actual }
    ind_valor = Indicador.count(:include => ["valor_intermedio_x_indicador", "objetivo_especifico", "resultado"], :conditions => ["porcentaje = 1 AND (objetivo_especifico.proyecto_id = ? OR resultado.proyecto_id = ?)", @proyecto.id, @proyecto.id])   
    lineas.push(:contenido => [ _("Indicadores:"),ind_valor.to_s + " de " + ind_total.to_s + " Indicadores realizados",(ind_valor_porc * 100/(ind_total > 0 ? ind_total : 1)).round.to_s + " %"])
    
    fv_total = FuenteVerificacion.count(:include => ["objetivo_especifico", "resultado"], :conditions => ["objetivo_especifico.proyecto_id = ? OR resultado.proyecto_id = ?", @proyecto.id, @proyecto.id])
    fv_valor = FuenteVerificacion.count(:include => ["objetivo_especifico", "resultado"], :conditions => ["completada AND (objetivo_especifico.proyecto_id = ? OR resultado.proyecto_id = ?)", @proyecto.id, @proyecto.id])
    lineas.push(:contenido => [ _("Fuentes Verificación:"),fv_valor.to_s + " de " + fv_total.to_s + " Fuentes de Verificación justificadas",(fv_valor * 100/(fv_total > 0 ? fv_total : 1)).round.to_s + " %"])


    @resumen = Array.new
    nombre = "resumen ejecutivo"
    titulo  = "Resumen Ejecutivo" + " "
    titulo += @proyecto.nombre + " / " + _("País") + ": " + (@pais ? @pais.nombre : _("Todos")) + " / "
    titulo += _("Etapa") + ": " + (@etapa ? @etapa.nombre + " " + _("(desde %{fecha_inicio} hasta %{fecha_fin})") % {:fecha_inicio => I18n.l(@etapa.fecha_inicio), :fecha_fin => I18n.l(@etapa.fecha_fin)} : _("Todas") ) 
    @resumen.push(:listado => {:nombre => nombre, :titulo => titulo, :lineas => lineas})

    respond_to do |format|
        format.html do
          render :action => "resumen_ejecutivo", :layout => (params[:fecha_de_fin] ? false : true)
        end
        format.xls do
          nom_fich = "Resumen_ejecutivo_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
        end
    end
  end

  #lo usan resumen_ejecutivo, documento_formulacion
  def datos_basicos
    lineas = Array.new
    lineas.push(:cabecera => [ [_("1. DATOS BASICOS DEL PROYECTO"), "1"], ["","13_4"]])
    lineas.push(:contenido => [  _("Nombre corto del proyecto:"),@proyecto.nombre])
    lineas.push(:contenido => [  _("Título del Proyecto:"),@proyecto.titulo])

    lineas += usuarios_por_rol_en_proyecto

    list_paises = Array.new
    @proyecto.pais.each do |pa|
      list_paises.push(pa.nombre)
    end
    lineas.push(:contenido => [  _("País/es - Área geográfica:"), list_paises.join(', ')])

    list_sectores_pobl = Array.new
    @proyecto.sector_poblacion.each do |se|
      list_sectores_pobl.push(se.nombre)
    end
    lineas.push(:contenido => [  _("Sector/es de población:"), list_sectores_pobl.join(', ')])

    lineas.push(:contenido => [  _("Estado:"),@proyecto.definicion_estado ? @proyecto.definicion_estado.nombre : ""])

    list_sectores_inter = Array.new
    @proyecto.sector_intervencion.each do |se|
      list_sectores_inter.push(se.nombre)
    end
    lineas.push(:contenido => [  _("Sector/es de intervención:"), list_sectores_inter.join(', ')])

    list_areas = Array.new
    @proyecto.area_actuacion.each do |ar|
      list_areas.push(ar.nombre)
    end
    lineas.push(:contenido => [  _("Área/s de Actuación:"), list_areas.join(', ')])

    lineas.push(:contenido => [  _("Financiador Principal:"),@proyecto.convocatoria.agente.nombre + " (" + ( @proyecto.convocatoria.agente.nombre_completo||"" ) + ")"])

    list_financiadores = Array.new
    @proyecto.financiador.each do |fi|
      list_financiadores.push(fi.nombre + ( fi.nombre_completo ? " (" + fi.nombre_completo + ")" : "")) unless fi.id == @proyecto.convocatoria.agente.id || fi.sistema
    end
    lineas.push(:contenido => [  _("Otros financiadores:"), list_financiadores.join(', ')])

    @list_implementadores = Array.new
    @proyecto.implementador.each do |im|
      @list_implementadores.push(im.nombre)
    end
    lineas.push(:contenido => [  _("Implementador/es:"), @list_implementadores.join(', ')])

    lineas.push(:cabecera => [ [_("2.1 OBJETIVO GENERAL DEL PROYECTO"), "4"]])
    lineas.push(:contenido => [  @proyecto.objetivo_general ? @proyecto.objetivo_general.descripcion : ""])

    lineas.push(:cabecera => [ [_("2.2 OBJETIVO ESPECIFICO DEL PROYECTO"), "4"]])
    @proyecto.objetivo_especifico.each do |ob|
      lineas.push(:contenido => [  ob.codigo + " - " + ob.descripcion])
    end

    return lineas
  end

  #usado por resumen_ejecutivo_render
  def porcentaje_tiempo
    resul = ""
    if @proyecto.etapa.count > 0
      inicio = @proyecto.etapa.sort{ |a,b| a.fecha_inicio <=> b.fecha_inicio }.first.fecha_inicio
      fin = @proyecto.etapa.sort{ |a,b| a.fecha_fin <=> b.fecha_fin }.last.fecha_fin
      if @proyecto.estado_actual && @proyecto.estado_actual.definicion_estado.cerrado
        ultimo_estado = @proyecto.estado.where(estado_actual: false).includes(:definicion_estado).where("definicion_estado.cerrado" => false).order("estado.updated_at").last
        ultima = ultimo_estado.fecha_fin
        ultima = Date.today unless ultimo_estado
      else
        ultima = Date.today
      end
      texto_tiempo = ultima < inicio ? (_("Faltan %{num} días para comenzar") % {:num => (inicio - ultima).to_i}) : ( ultima > fin ? _("%{num} días de retraso") % {:num => (ultima - fin).to_i} : _("%{num} días restantes") % {:num => (fin - ultima).to_i})
      texto_porcentaje = ((ultima - inicio)* 100 / (fin - inicio) ).round.to_s
      resul = texto_porcentaje + " % - " + texto_tiempo
    end unless @proyecto.estado_actual && @proyecto.estado_actual.definicion_estado.cerrado
    resul
  end

  # formatea el número con el punto y la coma
  def format_number(number, delimiter = '.', separator = ',')
    parts = number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
    parts.join(separator)  
  end

# en proyectos: genera el informe de resumen formulación
  def documento_formulacion
    @listado_pac = [[_("Todas"),nil]] + @proyecto.pacs.collect{|e| [e.nombre, e.id]} if @proyecto.convenio?
    if params[:selector] && params[:selector][:fichero] == "1" && params[:selector][:tipo] == "pdf"
      begin
        url = url_for(:only_path => false, :action => :documento_formulacion_render, :id => 35, :to_pdf => true)
        #kit = Shrimp::Phantom.new( url, { :format => "37cm*42cm" }, {"_session_id" => cookies[:_session_id]})
        kit = Shrimp::Phantom.new( url, { :margin => "0.5cm"}, {"_session_id" => cookies[:_session_id]})
        send_file(kit.to_pdf, :filename => _("Documento_formulación_") + @proyecto.nombre + '.pdf', :type => 'application/pdf', :disposition => 'attachment')
      rescue => ex
        logger.error "======> Error exportando PDF: " + ex.message.inspect
        logger.error ex.backtrace
        msg_error _("Se produjo un error en el módulo de exportación a PDF.")
        documento_formulacion_render
      end
    else
      documento_formulacion_render
    end
  end

  def documento_formulacion_render   
    #RESUMEN EJECUTIVO 
    #carga los datos básicos del proyecto que son comunes para varios resumenes
    lineas = datos_basicos

    lineas.push(:cabecera => [ [_("3. FECHAS Y VIGENCIA"), "1"], ["","13_4"] ])
    @proyecto.etapa.each do |et|
      lineas.push(:contenido => [ et.nombre.upcase, "" ])
      lineas.push(:contenido => [  _("Fecha de inicio:"),et.fecha_inicio.strftime('%d/%m/%Y')])
      lineas.push(:contenido => [  _("Fecha de finalización:"),et.fecha_fin.strftime('%d/%m/%Y')])
      lineas.push(:contenido => [  _("Periodo total de ejecución:"), et.meses.to_s + " meses"])
    end if @proyecto.etapa.count > 0
    @proyecto.etapa.each do |et|
      lineas.push(:contenido => [  _("Fecha de inicio:"),""])
      lineas.push(:contenido => [  _("Fecha de finalización:"),""])
      lineas.push(:contenido => [  _("Periodo total de ejecución:"), ""])
    end unless @proyecto.etapa.count > 0

    lineas.push(:cabecera => [[_("4. FINANCIACIÓN (en la moneda de justificación)"), "4"] ])
    lineas.push(:cabecera => [ [_("Descripción"),"3_2"], [_("Presupuesto aprobado"),"1_td"], [" % ","1_td"] ]) 
    
    
    cad_total_pres = (@proyecto.presupuesto_total > 0 ? format_number(format("%.2f",@proyecto.presupuesto_total.round(2))) + " " + @proyecto.moneda_principal.abreviatura : "0,00 " + @proyecto.moneda_principal.abreviatura)
    lineas.push(:contenido => [ _("Presupuesto total del Proyecto:"),cad_total_pres,"100,00 %"])

    cad_fin_pres = (@proyecto.agente ? format_number(format("%.2f",@proyecto.presupuesto_total_con_financiador(@proyecto.agente).round(2))) + " " + @proyecto.moneda_principal.abreviatura : "0,00 " + @proyecto.moneda_principal.abreviatura )
    lineas.push(:contenido => [ _("Aportación Financiador Principal:"),cad_fin_pres, format_number(format("%.2f",@proyecto.presupuesto_total_con_financiador(@proyecto.agente).round(2) * 100 / @proyecto.presupuesto_total.round(2))) + " %"])

    cad_otros_pres = (@proyecto.presupuesto_total > 0 && @proyecto.agente ? format_number(format("%.2f",@proyecto.presupuesto_total.round(2) - @proyecto.presupuesto_total_con_financiador(@proyecto.agente).round(2))) + " " + @proyecto.moneda_principal.abreviatura : "0,00 " + @proyecto.moneda_principal.abreviatura )
    lineas.push(:contenido => [ _("Aportación otros financiadores:"),cad_otros_pres,format_number(format("%.2f",(@proyecto.presupuesto_total.round(2) - @proyecto.presupuesto_total_con_financiador(@proyecto.agente).round(2)) * 100 / @proyecto.presupuesto_total.round(2))) + " %"])
    

    @resumen_ejecutivo = Array.new
    nombre = "resumen ejecutivo"
    titulo  = "Resumen Ejecutivo" + " "
    titulo += @proyecto.nombre + " / " + _("País") + ": " + (@pais ? @pais.nombre : _("Todos")) + " / "
    titulo += _("Etapa") + ": " + (@etapa ? @etapa.nombre + " " + _("(desde %{fecha_inicio} hasta %{fecha_fin})") % {:fecha_inicio => @etapa.fecha_inicio.strftime('%d/%m/%Y'), :fecha_fin => @etapa.fecha_fin.strftime('%d/%m/%Y')} : _("Todas") ) 
    @resumen_ejecutivo.push(:listado => {:nombre => nombre, :titulo => titulo, :lineas => lineas})

    # DATOS DE INFORMACION DE PROYECTO
    @grupos_datos = GrupoDatoDinamico.where(:seguimiento => 0).all(:order => "rango")

    #MATRIZ
    lineas = matriz_informes true
    @resumen_matriz = Array.new
    nombre = "matriz"
    titulo  = _("Matriz de Formulación ") +  @proyecto.nombre
    @resumen_matriz.push(:listado => {:nombre => nombre, :titulo => titulo, :lineas => lineas})

    #CRONOGRAMA
    @etapa = @proyecto.etapa.first
    @actividades = @etapa.actividad if @etapa

    #PRESUPUESTO PARTIDAS
    filtros = { proyecto: @proyecto.id, etapa: "todas", moneda: "todas", tasa_cambio: "0", agente_rol: "financiador", pais: "todos" }
    filas = Partida.find(:all, :order => "codigo").collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}}
    datos = VPresupuesto.sum_partida(filtros) 
    columnas = @proyecto.financiador.collect{|i| {"id" => i.id, "nombre" => i.nombre}}
    titulo =[ _("RESUMEN DE PRESUPUESTO POR PARTIDAS"),
                  _("Moneda") + ": " + _('Todas las monedas') ,
                  _("Tasa Cambio") + ": " + _('Aplicada') + " (" +
                    _("importes en %{moneda}") % {:moneda => Moneda.find_by_id(@proyecto.moneda_id).abreviatura } + ")",
                  _("Etapa") + ": " + _('Todas las etapas'),
                  _("País") + ": " + _("Todos los países"),
                  _("Filas") + ": " +  _("Partidas"),
            _("Columnas") + ": " + _("financiador".humanize.capitalize) ]

    @tablas = [{:titulo => titulo ,:filas => filas, :columnas => columnas, :datos => datos, :otros => { :columna_suma => true, :fila_suma => true, :ancho_fila => ((columnas.count + 2) * 145 + 200), :fila_porcentaje => true , :columna_porcentaje => true} } ]
    @resumen = [ :tabla => {:titulo => titulo ,:filas => filas, :columnas => columnas, :datos => datos, :otros => { :columna_suma => true, :fila_suma => true, :ancho_fila => ((columnas.count + 2) * 105 + 200), :fila_porcentaje => true , :columna_porcentaje => true} } ]

    @titulo = titulo[0..4]

    #PRESUPUESTO ACTIVIDADES
    filtros = { proyecto: @proyecto.id, etapa: "todas", moneda: "todas", tasa_cambio: "0", agente_rol: "financiador", pais: "todos" }
    filas = @proyecto.actividad.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}} 
    datos = VPresupuesto.sum_actividad(filtros)
    columnas = @proyecto.financiador.collect{|i| {"id" => i.id, "nombre" => i.nombre}}
    titulo =[ _("RESUMEN DE PRESUPUESTO POR  ACTIVIDADES"),
                  _("Moneda") + ": " + _('Todas las monedas') ,
                  _("Tasa Cambio") + ": " + _('Aplicada') + " (" +
                    _("importes en %{moneda}") % {:moneda => Moneda.find_by_id(@proyecto.moneda_id).abreviatura } + ")",
                  _("Etapa") + ": " + _('Todas las etapas'),
                  _("País") + ": " + _("Todos los países"),
                  _("Filas") + ": " +  _("Actividades"),
            _("Columnas") + ": " + _("financiador".humanize.capitalize) ]

    @tablas_activ = [{:titulo => titulo ,:filas => filas, :columnas => columnas, :datos => datos, :otros => { :columna_suma => true, :fila_suma => true, :ancho_fila => ((columnas.count + 2) * 145 + 200), :fila_porcentaje => true , :columna_porcentaje => true} } ]
    @resumen_activ = [ :tabla => {:titulo => titulo ,:filas => filas, :columnas => columnas, :datos => datos, :otros => { :columna_suma => true, :fila_suma => true, :ancho_fila => ((columnas.count + 2) * 105 + 200), :fila_porcentaje => true , :columna_porcentaje => true} } ]

    @titulo_activ = titulo[0..4]

    respond_to do |format|
        format.html do
          render :action => "documento_formulacion", :layout => (params[:fecha_de_fin] ? false : true)
        end
        format.xls do
          nom_fich = "Documento_formulacion_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
        end
    end

  end

  #usado en documento_formulacion e informe_final
  def matriz_informes seguimiento, ocultar_comentarios=true
    lineas = Array.new
    condiciones = { "proyecto_id" =>  @proyecto.id}
    filas_objetivos = Array.new
    filas_resultados = Array.new
    filas_actividades = Array.new 

    nivel_acciones = @proyecto.convenio ? @proyecto.convenio.convenio_accion : @proyecto.convenio_accion

    # Recorre desde objetivos especificos hacia abajo
    @proyecto.objetivo_especifico.all.each do |objetivo|
      existen_actividades = false
      cabecera_actividades = true if nivel_acciones == "objetivo_especifico"
      objetivo.resultado.all.each do |resultado|
        existen_actividades = false
        cabecera_actividades = true if nivel_acciones.nil? || nivel_acciones == "resultado"
        actividades = resultado.actividad.all(:order => "codigo", :include => [:actividad_x_pais, :actividad_x_etapa], :conditions => condiciones )
        actividades_resultado = []
        actividades.each do |actividad|
          nuevas_actividades = desglosa_actividades(actividad,@etapa,seguimiento,ocultar_comentarios)
          actividades_resultado += nuevas_actividades 
          existen_actividades = true if nuevas_actividades.length > 0 
        end
        if cabecera_actividades && actividades_resultado.length > 0
          objeto_padre = _("Resultado") + " " + resultado.codigo if nivel_acciones.nil?
          objeto_padre = _("Acción") + " " + (nivel_acciones == "resultado" ? resultado.codigo : objetivo.codigo) unless nivel_acciones.nil?
          filas_actividades.push(:cabecera => [ [_("Actividades") + " " + objeto_padre,"3_2"], [_("Recursos"),"1_td"], [_("Costes"),"1_td"] ]) unless seguimiento
          filas_actividades.push(:cabecera => [ [_("Actividades") + " " + objeto_padre,"3_2"], ["% " + _("Actividad"), "3_4"], [_("Recursos"),"1_td"], [_("Costes"),"1_2_td"], [_("Gastos"), "1_2_td"] ]) if seguimiento
          cabecera_actividades = false
        end
        filas_actividades += actividades_resultado if actividades_resultado.length > 0 
        filas_resultados += desglosa_fuentes(resultado, seguimiento, ocultar_comentarios) if existen_actividades
      end
      filas_objetivos += desglosa_fuentes(objetivo, seguimiento, ocultar_comentarios) if existen_actividades 
    end

    # Y le incluye las actividades globales (sin resultado asociado)
    condiciones[:resultado_id] = nil
    filas_actividades_comunes = [] 
    @proyecto.actividad.all(:order => "codigo", :include => [:actividad_x_pais, :actividad_x_etapa], :conditions => condiciones).each do |actividad|
      filas_actividades_comunes += desglosa_actividades(actividad,@etapa,seguimiento,ocultar_comentarios)
    end

    # Va rellenando las lineas
    #  primero el objetivo general
    if (@proyecto.objetivo_general && @proyecto.objetivo_general.descripcion != "")
      lineas.push(:cabecera => [ [_("Objetivo General"), "4"] ])
      lineas.push(:contenido => [ @proyecto.objetivo_general.descripcion ])
    end
    #  y continua con el objetivo especifico
    lineas.push(:cabecera => [ [(nivel_acciones == "objetivo_especifico" ? _("Acciones") : _("Descripción")),"3_2"], [_("Indicadores"),"1"], [_("Fuentes de verificación"),"1"], [_("Hipótesis"),"1"] ]) unless seguimiento
    lineas.push(:cabecera => [ [(nivel_acciones == "objetivo_especifico" ? _("Acciones") : _("Descripción")),"3_2"], [_("Indicadores"),"1"], ["% " + _("Indicador"),"1"], [_("Fuentes de verificación"),"1"] ]) if seguimiento
    lineas += filas_objetivos
    lineas.push(:cabecera => [ [(nivel_acciones == "resultado" ? _("Acciones") : _("Resultados")),"3_2"], ["","1"], ["","1"], ["","1"] ]) unless seguimiento
    lineas.push(:cabecera => [ [(nivel_acciones == "resultado" ? _("Acciones") : _("Resultados")),"3_2"], ["","1"], ["","1"], ["","1"] ]) if seguimiento 
    lineas += filas_resultados 
    lineas += filas_actividades
    if filas_actividades_comunes.length > 0
      lineas.push(:cabecera => [ [_("Actividades Globales"),"3_2"], [_("Recursos"),"1_td"], [_("Costes"),"1_td"] ]) unless seguimiento
      lineas.push(:cabecera => [ [_("Actividades Globales"),"3_2"], ["% " + _("Actividad"), "3_4"], [_("Recursos"),"1_td"], [_("Costes"),"1_2_td"], [_("Gastos"), "1_2_td"] ]) if seguimiento
      lineas += filas_actividades_comunes
    end

    return lineas
  end

  # en proyectos: genera el informe de inicio de actividades
  def inicio_actividades
    @listado_pac = [[_("Todas"),nil]] + @proyecto.pacs.collect{|e| [e.nombre, e.id]} if @proyecto.convenio?
    if params[:selector] && params[:selector][:fichero] == "1" && params[:selector][:tipo] == "pdf"
      begin
        url = url_for(:only_path => false, :action => :inicio_actividades_render, :id => 35, :to_pdf => true)
        kit = Shrimp::Phantom.new( url, { :margin => "0.5cm"}, {"_session_id" => cookies[:_session_id]})
        send_file(kit.to_pdf, :filename => _("Inicio_Actividades_") + @proyecto.nombre + '.pdf', :type => 'application/pdf', :disposition => 'attachment')
      rescue => ex
        logger.error ex.message
        logger.error ex.backtrace
        msg_error _("Se produjo un error en el módulo de exportación a PDF.")
        inicio_actividades_render
      end
    else
      inicio_actividades_render
    end
  end


  def inicio_actividades_render   
    lineas = Array.new
    lineas.push(:cabecera => [ [_("1. DATOS IDENTIFICATIVOS DEL PROYECTO"), "2"],["","2"]]) 
    lineas.push(:estilo => [ ["", "1"], ["","1"], ["","1"], ["","1"] ] ) 
    @list_implementadores = Array.new
    @proyecto.implementador.each do |im|
      @list_implementadores.push(im.nombre)
    end
    lineas.push(:contenido => [  _("Agente/Delegación Implementador/a: "), @list_implementadores.join(', '), _("Agente/Delegación Gestor/a: "), @proyecto.gestor.nombre])

    lineas.push(:estilo => [ ["", "1"],["", "13_4"]] )
    lineas.push(:contenido => [  _("Nombre corto del proyecto: "), @proyecto.nombre ])
    lineas.push(:contenido => [  _("Título del Proyecto: "), @proyecto.titulo])

    cc_proy = CuentaContable.select(:codigo).uniq.where(:elemento_contable_id => @proyecto.id, :elemento_contable_type => "Proyecto")
    lineas.push(:contenido => [ _("Centros de coste del Proyecto: "), cc_proy.collect{|cc| cc.codigo}.join(", ") ]) unless cc_proy.empty?

    lineas += usuarios_por_rol_en_proyecto(solo_admins: true)

    lineas.push(:cabecera => [ [_("2. DATOS PRESUPUESTARIOS DEL PROYECTO"), "3"],["","1"]]) 
    lineas.push(:estilo => [ ["", "1"],["", "2"],["", "1_td"]] ) 
    cad_total_pres = (@proyecto.presupuesto_total > 0 ? format_number(format("%.2f",@proyecto.presupuesto_total.round(2))) + " " + @proyecto.moneda_principal.abreviatura : "0,00 " + @proyecto.moneda_principal.abreviatura)
    lineas.push(:contenido => [ _("Presupuesto total del Proyecto:"),"",cad_total_pres])
    cad_fin_pres = (@proyecto.agente ? format_number(format("%.2f",@proyecto.presupuesto_total_con_financiador(@proyecto.agente).round(2))) + " " + @proyecto.moneda_principal.abreviatura : "0,00 " + @proyecto.moneda_principal.abreviatura )
    lineas.push(:contenido => [ _("Aportación Financiador Principal: "), @proyecto.convocatoria.agente.nombre + " (" + (@proyecto.convocatoria.agente.nombre_completo||"") + ")", cad_fin_pres])

    #cad_financiadores = ""
    @proyecto.financiador.reorder("sistema, nombre").each do |fi|
      if (fi.id != @proyecto.convocatoria.agente.id)
        importe_otro = @proyecto.presupuesto_total_con_financiador(fi)
        lineas.push(:contenido => [ _("Aportación Otro Financiador: "), fi.nombre + (fi.nombre_completo.blank? ? "" : " (#{fi.nombre_completo})"),
                                    view_context.float_a_moneda(importe_otro) + " " + @proyecto.moneda_principal.abreviatura ]) if importe_otro != 0.0
      end
    end

    lineas.push(:cabecera => [ [_("3. DATOS REFERENTES AL INICIO DEL PROYECTO"), "3"],["","1"]]) 
    lineas.push(:estilo => [ ["", "1"],["", "2"],["", "1_2_td"],["", "1_td"]] ) 
    lineas.push(:contenido => [  _("RECEPCIÓN DE FONDOS: "), "","", ""])
    @proyecto.transferencia.each do |trans|
      if (["ingreso", "adelanto", "subvencion"].include?(trans.tipo))
        lineas.push(:contenido => [  trans.tipo.capitalize, trans.observaciones.capitalize, trans.fecha_recibido, trans.importe_recibido ? format_number(format("%.2f",trans.importe_recibido.round(2))) + " " + Moneda.find(Libro.find(trans.libro_destino_id).moneda_id).abreviatura : format_number(format("%.2f",trans.importe_cambiado.round(2))) + " " + Moneda.find(Libro.find(trans.libro_destino_id).moneda_id).abreviatura ])
      end
    end
    lineas.push(:estilo => [ ["", "2"],["", "1"],["", "3_4"],["", "3_4"]] ) 
    lineas.push(:contenido => [  _("Duración prevista del Proyecto: "), @proyecto.duracion_meses.to_s + " meses", "", "" ])
    lineas.push(:contenido => [  _("Fecha Real de Inicio del Proyecto: "), @proyecto.etapa.first.fecha_inicio.strftime('%d/%m/%Y'), "", "" ])
    lineas.push(:contenido => [  _("Fecha Prevista de Finalización del Proyecto: "), @proyecto.etapa.last.fecha_fin.strftime('%d/%m/%Y'), "", ""])
    lineas.push(:contenido => [  _("PERIODOS DE JUSTIFICACIÓN Y PRORROGAS: "), "", "", ""])
    lineas.push(:estilo => [ ["", "1"],["", "2"],["", "3_4"],["", "3_4"]] ) 
    @proyecto.periodo.each do |per|
      lineas.push(:contenido => [  per.tipo_periodo.nombre, per.descripcion, _("Fecha inicio: ") + per.fecha_inicio.strftime('%d/%m/%Y') , _("Fecha fin: ") + per.fecha_fin.strftime('%d/%m/%Y')])
    end

    lineas.push(:cabecera => [ [_("4. DATOS TÉCNICOS DEL PROYECTO"), "3"],["","1"]]) 
    lineas.push(:estilo => [ ["", "1"],["", "13_4"]] ) 
    lineas.push(:contenido => [ _("Objetivo General: "), @proyecto.objetivo_general ? @proyecto.objetivo_general.descripcion : ""])
    @proyecto.objetivo_especifico.each do |ob|
       lineas.push(:contenido => [ _("Objetivo Específico: "), ob.codigo + " - " + ob.descripcion])
    end
    list_sectores_pobl = Array.new
    @proyecto.sector_poblacion.each do |se|
      list_sectores_pobl.push(se.nombre)
    end
    lineas.push(:contenido => [  _("Sector/es de población:"),list_sectores_pobl.join(', ')])

    list_sectores_inter = Array.new
    @proyecto.sector_intervencion.each do |se|
      list_sectores_inter.push(se.nombre)
    end
    lineas.push(:contenido => [  _("Sector/es de intervención:"),list_sectores_inter.join(', ')])

    list_areas = Array.new
    @proyecto.area_actuacion.each do |ar|
      list_areas.push(ar.nombre)
    end
    lineas.push(:contenido => [  _("Área/s de Actuación:"),list_areas.join(', ')])


    @inicio_actividades = Array.new
    nombre = "inicio actividades"
    titulo  = "Inicio Actividades" + " "
    titulo += @proyecto.nombre + " / " + _("País") + ": " + (@pais ? @pais.nombre : _("Todos")) + " / "
    titulo += _("Etapa") + ": " + (@etapa ? @etapa.nombre + " " + _("(desde %{fecha_inicio} hasta %{fecha_fin})") % {:fecha_inicio => @etapa.fecha_inicio.strftime('%d/%m/%Y'), :fecha_fin => @etapa.fecha_fin.strftime('%d/%m/%Y')} : _("Todas") ) 
    @inicio_actividades.push(:listado => {:nombre => nombre, :titulo => titulo, :lineas => lineas})


    respond_to do |format|
        format.html do
          render :action => "inicio_actividades", :layout => (params[:fecha_de_fin] ? false : true)
        end
    end

  end

 # en proyectos: genera el informe final 
  def informe_final
    @listado_pac = [[_("Todas"),nil]] + @proyecto.pacs.collect{|e| [e.nombre, e.id]} if @proyecto.convenio?
    if params[:selector] && params[:selector][:fichero] == "1" && params[:selector][:tipo] == "pdf"
      begin
        url = url_for(:only_path => false, :action => :informe_final_render, :id => 35, :to_pdf => true)
        #kit = Shrimp::Phantom.new( url, { :format => "37cm*42cm" }, {"_session_id" => cookies[:_session_id]})
        kit = Shrimp::Phantom.new( url, { :margin => "0.5cm"}, {"_session_id" => cookies[:_session_id]})
        send_file(kit.to_pdf, :filename => _("Informe_Técnico_Final_") + @proyecto.nombre + '.pdf', :type => 'application/pdf', :disposition => 'attachment')
      rescue => ex
        logger.error ex.message
        logger.error ex.backtrace
        msg_error _("Se produjo un error en el módulo de exportación a PDF.")
        informe_final_render
      end
    else
      informe_final_render
    end
  end

  def informe_final_render      
    #LOGO FINANCIADOR
    #la descripcion del logo del financiador debe ser logo
    @documento = Documento.where(:agente_id => @proyecto.agente.id, :descripcion => "logo").first 

    #RESUMEN EJECUTIVO 
    lineas = datos_basicos

    lineas.push(:cabecera => [ [_("3. FECHAS Y VIGENCIA"), "1"], ["","13_4"] ])
    @proyecto.etapa.each do |et|
      lineas.push(:contenido => [ et.nombre.upcase, "" ])
      lineas.push(:contenido => [  _("Fecha de inicio:"),et.fecha_inicio.strftime('%d/%m/%Y')])
      lineas.push(:contenido => [  _("Fecha de finalización:"),et.fecha_fin.strftime('%d/%m/%Y')])
      lineas.push(:contenido => [  _("Periodo total de ejecución:"), et.meses.to_s + " meses"])
    end if @proyecto.etapa.count > 0
    @proyecto.etapa.each do |et|
      lineas.push(:contenido => [  _("Fecha de inicio:"),""])
      lineas.push(:contenido => [  _("Fecha de finalización:"),""])
      lineas.push(:contenido => [  _("Periodo total de ejecución:"), ""])
    end unless @proyecto.etapa.count > 0

    lineas.push(:cabecera => [[_("4. FINANCIACIÓN Y SEGUIMIENTO ECONOMICO (en la moneda de justificación)"), "4"] ])
    lineas.push(:cabecera => [ [_("Descripción"),"3_2"], [_("Presupuesto aprobado"),"1_td"], [_("Presupuesto ejecutado"),"1_td"], [_("% de Ejecución presupuestaria"),"1_td"] ]) 
          
    cad_total_pres = (@proyecto.presupuesto_total > 0 ? format_number(format("%.2f",@proyecto.presupuesto_total.round(2))) + " " + @proyecto.moneda_principal.abreviatura : "0,00 " + @proyecto.moneda_principal.abreviatura)
    cad_total_gasto = (@proyecto.gasto_total_sin_financiador > 0 ? format_number(format("%.2f",@proyecto.gasto_total_sin_financiador.round(2))) + " " + @proyecto.moneda_principal.abreviatura : "0,00 " + @proyecto.moneda_principal.abreviatura)
    cad_total_porcentaje_ejec = (@proyecto.presupuesto_total > 0 && @proyecto.gasto_total_sin_financiador > 0 ? (@proyecto.gasto_total_sin_financiador * 100/@proyecto.presupuesto_total).round.to_s + " %" : "0 %")
    lineas.push(:contenido => [ _("Presupuesto total del Proyecto:"),cad_total_pres,cad_total_gasto, cad_total_porcentaje_ejec])

    cad_fin_pres = (@proyecto.agente ? format_number(format("%.2f",@proyecto.presupuesto_total_con_financiador(@proyecto.agente).round(2))) + " " + @proyecto.moneda_principal.abreviatura : "0,00 " + @proyecto.moneda_principal.abreviatura )
    cad_fin_gasto = (@proyecto.agente ? format_number(format("%.2f",@proyecto.gasto_total_con_financiador(@proyecto.agente).round(2))) + " " + @proyecto.moneda_principal.abreviatura : "0,00 " + @proyecto.moneda_principal.abreviatura )
    cad_fin_porcentaje_ejec = (@proyecto.presupuesto_total > 0 && @proyecto.gasto_total_sin_financiador > 0 ? (@proyecto.gasto_total_con_financiador(@proyecto.agente) * 100/@proyecto.presupuesto_total_con_financiador(@proyecto.agente)).round.to_s + " %" : "0 %")
    lineas.push(:contenido => [ _("Aportación Financiador Principal:"),cad_fin_pres,cad_fin_gasto,cad_fin_porcentaje_ejec])

    cad_otros_pres = (@proyecto.presupuesto_total > 0 && @proyecto.agente ? format_number(format("%.2f",@proyecto.presupuesto_total.round(2) - @proyecto.presupuesto_total_con_financiador(@proyecto.agente).round(2))) + " " + @proyecto.moneda_principal.abreviatura : "0,00 " + @proyecto.moneda_principal.abreviatura )
    cad_otros_gasto = (@proyecto.gasto_total_sin_financiador > 0 && @proyecto.agente ? format_number(format("%.2f",(@proyecto.gasto_total_sin_financiador.round(2) - @proyecto.gasto_total_con_financiador(@proyecto.agente).round(2)).round(2))) + " " + @proyecto.moneda_principal.abreviatura : "0,00 " + @proyecto.moneda_principal.abreviatura )
    cad_otros_porcentaje_ejec = (@proyecto.presupuesto_total > 0 && @proyecto.gasto_total_sin_financiador && (@proyecto.presupuesto_total - @proyecto.presupuesto_total_con_financiador(@proyecto.agente)) > 0 ? ((@proyecto.gasto_total_sin_financiador - @proyecto.gasto_total_con_financiador(@proyecto.agente).round(2)) * 100/(@proyecto.presupuesto_total - @proyecto.presupuesto_total_con_financiador(@proyecto.agente)) ).round.to_s + " %" : "0 %")
    #cad_otros_porcentaje_ejec = 0
    lineas.push(:contenido => [ _("Aportación otros financiadores:"),cad_otros_pres,cad_otros_gasto,cad_otros_porcentaje_ejec])
      
    lineas.push(:cabecera => [[_("5. SEGUIMIENTO  TECNICO"), "4"] ])
    lineas.push(:cabecera => [ [_("Descripción"),"3_2"], [_("Seguimiento"),"3_2"], [_("% cumplimiento"),"1_td"] ]) 

    activ_total = @proyecto.actividad.count
    activ_valor_porc = @proyecto.actividad.sum{|a| a.estado_actual ? a.estado_actual.porcentaje||0.0 : 0.0}
    activ_valor = ActividadXEtapa.count(:include => [:actividad,:valor_intermedio_x_actividad], :conditions => ["actividad.proyecto_id = ? AND realizada = TRUE",@proyecto.id])
    lineas.push(:contenido => [ _("Actividades:"),activ_valor.to_s + " de " + activ_total.to_s + " Actividades realizadas",(activ_valor_porc * 100/(activ_total > 0 ? activ_total : 1)).round.to_s + " %"])
      
    ind_total = Indicador.count(:include => ["objetivo_especifico", "resultado"], :conditions => ["objetivo_especifico.proyecto_id = ? OR resultado.proyecto_id = ?", @proyecto.id, @proyecto.id])
    ind_valor = Indicador.count(:include => ["valor_intermedio_x_indicador", "objetivo_especifico", "resultado"], :conditions => ["porcentaje = 1 AND (objetivo_especifico.proyecto_id = ? OR resultado.proyecto_id = ?)", @proyecto.id, @proyecto.id])   
    lineas.push(:contenido => [ _("Indicadores:"),ind_valor.to_s + " de " + ind_total.to_s + " Indicadores realizados",(ind_valor * 100/(ind_total > 0 ? ind_total : 1)).round.to_s + " %"])
      
    fv_total = FuenteVerificacion.count(:include => ["objetivo_especifico", "resultado"], :conditions => ["objetivo_especifico.proyecto_id = ? OR resultado.proyecto_id = ?", @proyecto.id, @proyecto.id])
    fv_valor = FuenteVerificacion.count(:include => ["objetivo_especifico", "resultado"], :conditions => ["completada AND (objetivo_especifico.proyecto_id = ? OR resultado.proyecto_id = ?)", @proyecto.id, @proyecto.id])
    lineas.push(:contenido => [ _("Fuentes Verificación:"),fv_valor.to_s + " de " + fv_total.to_s + " Fuentes de Verificación justificadas",(fv_valor * 100/(fv_total > 0 ? fv_total : 1)).round.to_s + " %"])

    @resumen_ejecutivo = Array.new
    nombre = "resumen ejecutivo"
    titulo  = "Resumen Ejecutivo" + " "
    titulo += @proyecto.nombre + " / " + _("País") + ": " + (@pais ? @pais.nombre : _("Todos")) + " / "
    titulo += _("Etapa") + ": " + (@etapa ? @etapa.nombre + " " + _("(desde %{fecha_inicio} hasta %{fecha_fin})") % {:fecha_inicio => @etapa.fecha_inicio.strftime('%d/%m/%Y'), :fecha_fin => @etapa.fecha_fin.strftime('%d/%m/%Y')} : _("Todas") ) 
    @resumen_ejecutivo.push(:listado => {:nombre => nombre, :titulo => titulo, :lineas => lineas})

    # DATOS DE INFORMACION DE PROYECTO
    #@grupos_datos = GrupoDatoDinamico.where(:seguimiento => 1, :cierre => 1).all(:order => "rango")
    @grupos_datos = GrupoDatoDinamico.where(:seguimiento => 1, :cierre => 1).all(:order => "rango")

    #MATRIZ
    lineas = matriz_informes true
    @resumen_matriz = Array.new
    nombre = "matriz"
    titulo  = _("Matriz de Formulación ") +  @proyecto.nombre
    @resumen_matriz.push(:listado => {:nombre => nombre, :titulo => titulo, :lineas => lineas})

    #SEGUIMIENTO TECNICO
    @fecha_de_fin = DateTime.now.to_date
    params[:pac] = params[:id] if params[:id]
    params[:pac] ||= @proyecto.pacs.first.id if @proyecto.convenio?

    if @proyecto.convenio?
      pac = Proyecto.find_by_id(params[:pac])
      @proyectos = pac || @proyecto.pacs
    else
      @proyectos = [@proyecto] unless @proyecto.convenio?
    end
    unless @fecha_de_fin.nil?
      estado_seguimiento_tecnico
      @activs = @proyecto.actividad.sort_by(&:codigo).group_by(&:resultado)
    end


    #CRONOGRAMA
    seguimiento=true
    @etapa = @proyecto.etapa.first
    @actividades = @etapa.actividad if @etapa

    #GASTO POR PARTIDAS TODOS LOS FINANCIADORES
    @tablas_partidas_todos = resumen_gasto true, "todos"

    #GASTO POR PARTIDAS FINANCIADOR PRINCIPAL
    @tablas_partidas = resumen_gasto true, @proyecto.agente

    #GASTO POR PARTIDAS OTROS FINANCIADORES
    @tablas_partidas_otros = Array.new
    @proyecto.financiador.each do |finan|
      if finan.id != @proyecto.agente.id
        @tablas_partidas_otros.push(resumen_gasto true, finan)
      end
    end

    #GASTO POR ACTIVIDADES TODOS LOS FINANCIADORES FINANCIADOR
    @tablas_actividades_todos = resumen_gasto false, "todos"

    #GASTO POR ACTIVIDADES FINANCIADOR PRINCIPAL
    @tablas_actividades = resumen_gasto false, @proyecto.agente

    #GASTO POR ACTIVIDADES OTROS FINANCIADORES
    @tablas_actividades_otros = Array.new
    @proyecto.financiador.each do |finan|
      if finan.id != @proyecto.agente.id
        @tablas_actividades_otros.push(resumen_gasto false, finan)
      end
    end


    respond_to do |format|
        format.html do
          render :action => "informe_final", :layout => (params[:fecha_de_fin] ? false : true)
        end
        format.xls do
          nom_fich = "Informe_Técnico_Final_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
        end
    end

  end

  #lo utiliza informe_final
  def resumen_gasto partidas, financiador
    filtros = { proyecto: @proyecto.id, etapa: "todas", moneda: "todas", tasa_cambio: "0", agente_rol: "financiador", pais: "todos" }
    filas = (partidas ? Partida.find(:all, :order => "codigo").collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}} : @proyecto.actividad.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}})

    filtros[:agente] = financiador
    # Y calculamos presupuesto y gasto
    presupuestos = partidas ? VPresupuestoDetallado.agrupa_sum_partida(filtros) : VPresupuestoDetallado.agrupa_sum_actividad(filtros)
    gastos = partidas ? VGasto.agrupa_sum_partida(filtros) : VGasto.agrupa_sum_actividad(filtros)

    datos = presupuestos + gastos
    columnas = [{"id" => "1", "nombre" => _("Presupuesto")}, {"id" => "2", "nombre" => _("Gastos")}] if partidas
    columnas = [{"id" => "1", "nombre" => _("Presupuesto")}, {"id" => "2", "nombre" => _("Gastos")}] unless partidas
    if partidas
      if financiador == "todos"
        titulo = [  _("RESUMEN DE GASTO POR PARTIDAS DE TODOS LOS FINANCIADORES"),
                   _("Agente") + ": todos" ] 
      elsif financiador.id == @proyecto.agente.id
        titulo = [  _("RESUMEN DE GASTO POR PARTIDAS DEL FINANCIADOR PRINCIPAL"),
                    _("Agente: ") + financiador.nombre ] 
      else
        titulo = [  _("RESUMEN DE GASTO POR PARTIDAS DE OTRO FINANCIADOR"),
                    _("Agente: ") + financiador.nombre] 
      end
    else
      if financiador == "todos"
        titulo = [ _("RESUMEN DE GASTO POR ACTIVIDADES DE TODOS LOS FINANCIADORES"),
                   _("Agente") + ": todos" ] 
      elsif financiador.id == @proyecto.agente.id
        titulo = [ _("RESUMEN DE GASTO POR ACTIVIDADES DEL FINANCIADOR PRINCIPAL"),
                      _("Agente: ") + financiador.nombre ] 
      else
        titulo = [ _("RESUMEN DE GASTO POR ACTIVIDADES DE OTRO FINANCIADOR"),
                    _("Agente: ") + financiador.nombre] 
      end
    end
    titulo +=[  _("Moneda") + ": " + _('Todas las monedas') ,
                _("Tasa Cambio") + ": " + _('Aplicada') + " (" +
                _("importes en %{moneda}") % {:moneda => Moneda.find_by_id(@proyecto.moneda_id).abreviatura } + ")",
                #_("Etapa") + ": " + _('Todas las etapas'),
                #_("País") + ": " + _("Todos los países"),
                #_("Filas: ") + ( partidas ?  _("Partidas") : _("Actividades"))
              ]
               
    return [{:titulo => titulo ,:filas => filas, :columnas => columnas, :datos => datos, :otros => {  :columna_resta => _("Pendiente"), :fila_suma => true, :columna_pctparcial => _("% Ejecutado") } }]

  end

 private

  # Devuelve un array de usuarios por rol en el proyecto
  def usuarios_por_rol_en_proyecto opciones={}
    lineas = []
    condiciones_rol = {seccion: "proyectos"}
    condiciones_rol[:admin] = true if opciones[:solo_admins]
    condicion_ocultos = opciones[:mostrar_ocultos] ? "" : "grupo_usuario_id IS NULL OR grupo_usuario.ocultar_proyecto IS NOT TRUE"
    Rol.where(condiciones_rol).each do |rol|
      usuarios = UsuarioXProyecto.where(rol_id: rol.id, proyecto_id: @proyecto.id).
                                  includes(:grupo_usuario, :usuario).
                                  where(condicion_ocultos).
                                  uniq("usuario_id").order("usuario.nombre_completo").
                                  collect{|uxp| uxp.usuario.nombre_completo}.join(", ")

      lineas.push(:contenido => [ rol.nombre, usuarios ]) unless usuarios.blank?
    end
    return lineas
  end
end

