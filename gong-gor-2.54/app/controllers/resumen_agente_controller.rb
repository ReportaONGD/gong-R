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
# Controlador encargado de las vistas resumen financieras para una agente implementador. Este controlador es utilizado desde las secciones agentes.

class ResumenAgenteController < ApplicationController

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

  def gasto
    @listado_moneda = @agente.moneda.collect{|e| [e.nombre, e.id.to_s]} + [["Todas las monedas (con tasa aplicada)","todas"]]
    @listado_etapa = @agente.etapa.collect{|e| [e.nombre, e.id]}
    # Hacemos la busqueda si se seleccionan los criterios
    estado_gasto if params[:moneda]
  end

  # Obtiene un resumen de gastos
  # Esto hay que simplificarlo... (invocamos las mismas vistas varias veces)
  def estado_gasto
    @fecha_de_inicio = fecha params["fecha_inicio"]
    @fecha_de_fin = fecha params["fecha_fin"] 
    if params[:seleccion_fecha] == "etapa" && params[:etapa] && etapa = Etapa.find_by_id(params[:etapa])
      @fecha_de_inicio = etapa.fecha_inicio
      @fecha_de_fin = etapa.fecha_fin 
    end
    filtro_gasto = { agente: @agente.id, fecha_inicio: @fecha_de_inicio, fecha_fin: @fecha_de_fin, 
                     moneda: params[:moneda], tasa_cambio: params[:tasa_cambio] }

    # Recogemos la tabla de resumen general
    condiciones = {"ocultar_agente" => false} unless params[:mostrar_partidas_ocultas] == "1"
    partidas = Partida.find(:all, :conditions => condiciones, :order => "codigo")
    filas = partidas.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}}
    columnas = [{"id" => "1", "nombre" => _("Presupuesto")}, {"id" => "2", "nombre" => _("Gastos")}]
    # buscamos el presupuesto por partidas para las fechas y criterios seleccionadas
    presupuestos = VPresupuestoAgenteDetallado.partida(@agente.id, @fecha_de_inicio, @fecha_de_fin , params[:moneda],  params[:tasa_cambio], nil)
    presupuestos = presupuestos.collect {|p| {"columna_id" => "1", "importe" => p.importe , "fila_id" => p.partida_id.to_s }}
    # Buscamos el gasto por partidas del agente para las fechas y criterios seleccionados
    gastos = VGastoAgente.sum_partida(filtro_gasto.merge( columna_id: 2 ) )
    # preparamos la tabla para su presentación visual
    titulo_datos =[ _("Moneda") + ": #{ params[:moneda] == 'todas' ?  _('Todas las monedas') : Moneda.find(params[:moneda]).abreviatura} " ,
               _("Tasa cambio") + ": " + ((params[:tasa_cambio] == '1' or params[:moneda] == 'todas') ? _('Aplicada'): _('No aplicada')),
               _("Fechas") + ": " + @fecha_de_inicio.to_time.to_s + ' - ' + @fecha_de_fin.to_time.to_s ]

    # Comprobamos que no hay partidas ocultas con datos de agente para comunicarlo al usuario
    # Simplificar esto usando el bucle de mas abajo (duplica los select a bbdd)
    presupuestos.each do |p|
      msg_error(_("Existen partidas ocultas que contienen presupuestos.") + " " + _("Seleccione mostrar partidas ocultas para verlas"), :now => true)  if (filas.select{|f| f["id"].to_s == p["fila_id"].to_s}).empty?
    end
    gastos.each do |p|
      msg_error(_("Existen partidas ocultas que contienen gastos.") + " " + _("Seleccione mostrar partidas ocultas para verlas"), :now => true)  if (filas.select{|f| f["id"].to_s == p["fila_id"].to_s}).empty?
    end

    # Preparamos la tabla para mostrar el detalle del seguimiento por subpartidas del agente
    @titulo_partida = [_("Resumen de gasto comparado con el presupuesto.")] + titulo_datos
    @titulo_subpartida = [_("Detalle del presupuesto frente al gasto del agente por subpartidas y el gasto imputado a delegacion frente al gasto imputado a proyectos")] + titulo_datos
    @partidas = [:cabecera => [[_("Partida"), "1"], [_("Presupuesto"),"1_2_td"], [ _("Gasto") ,"1_2_td"], [_("Diferencia") ,"1_2_td"],  [_("Desviación") + " %" ,"1_2_td"],  [_("Imputado a delegación") ,"1_2_td"],  [_("Imputado a proyecto") ,"1_2_td"]] ]
    @subpartidas =  [:cabecera => [[_("Partida/Subpartida") , "1" ], [_("Presupuesto"),"1_2_td"], [ _("Gasto") ,"1_2_td"], [_("Diferencia") ,"1_2_td"],  [_("Desviación") + " %" ,"1_2_td"],  [_("Imputado a delegación") ,"1_2_td"],  [_("Imputado a proyecto") ,"1_2_td"]] ]
    # Preparamos la tabla para mostrar el detalle de seguimiento de sbupartidas por proyectos
    @titulo_subpartidas_proyectos = [_("Detalle del gasto imputado a proyectos mostrado por subpartida y proyecto")] + titulo_datos
    @subpartidas_proyectos = [:cabecera => [[ _("Partida/Subpartida") , "2" ], [_("Proyecto") ,"3_2"], [ _("Gasto imputado proyectos")  ,"1_2_td"],  [_("Gasto total partida")  ,"1_2_td"]]]



    # Tablas de gasto por subpartida y por proyecto
    tp = tg = tid = tip = 0
    # Recorre todas las partidas
    for partida in partidas
      filtro_partida = filtro_gasto.merge( partida: partida.id )
      # Buscamos para cada partida el presupuesto para las fechas y los criterios seleccionados
      importe_presupuesto = VPresupuestoAgenteDetallado.partida(@agente.id, @fecha_de_inicio, @fecha_de_fin, params[:moneda] , params[:tasa_cambio], partida.id.to_s ).first
      # Buscamos para cada partida el gasto total para las fechas y los criterios seleccionados
      importe_gasto = VGastoAgente.sum_total( filtro_partida ).first
      # Buscamos para cada partida el gasto imputado a delegacion para las fechas y los criterios seleccionados
      importe_gasto_delegacion = VGastoAgente.sum_total( filtro_partida.merge( proyecto: "isnull" ) ).first
      # Buscamos para cada partida el gasto imputado a proyectos para las fechas y los criterios seleccionados
      importe_gasto_proyectos = VGastoAgente.sum_total( filtro_partida.merge( proyecto: "isnotnull" ) ).first

      gasto = (importe_gasto and importe_gasto[:importe]) ? importe_gasto[:importe] : 0
      gasto_delegacion = (importe_gasto_delegacion and importe_gasto_delegacion[:importe]) ? importe_gasto_delegacion[:importe] : 0
      gasto_proyectos = (importe_gasto_proyectos and importe_gasto_proyectos[:importe]) ? importe_gasto_proyectos[:importe] : 0
      presupuesto = (importe_presupuesto and importe_presupuesto[:importe]) ? importe_presupuesto[:importe] : 0

      # Mete los datos en las tablas
      @partidas.push(:contenido => [partida.codigo_nombre, presupuesto, gasto, (presupuesto - gasto), (presupuesto == 0 ? "-" : (presupuesto - gasto)/presupuesto * 100),
            gasto_delegacion, gasto_proyectos] )
      @subpartidas.push(:cabecera => [ [ partida.codigo_nombre , "1" ], [presupuesto ,"1_2_td"], [ gasto  ,"1_2_td"], [(presupuesto - gasto)  ,"1_2_td"],
            [ (presupuesto == 0 ? "-" : (presupuesto - gasto)/presupuesto * 100)  ,"1_2_td"], [gasto_delegacion  ,"1_2_td"], [gasto_proyectos  ,"1_2_td"]] ) 
      @subpartidas_proyectos.push(:cabecera => [[ partida.codigo_nombre , "2" ], ["" ,"3_2"], [ gasto_proyectos  ,"1_2_td"], [ gasto,"1_2_td"]])

      # Suma los totales
      tp += presupuesto
      tg += gasto
      tid += gasto_delegacion
      tip += gasto_proyectos

      # Hace los calculos para las subpartidas
      for subpartida in   Subpartida.find_all_by_agente_id_and_partida_id( @agente.id, partida.id)
        filtro_subpartida = filtro_partida.merge( subpartida: subpartida.id )
        pres = VPresupuestoAgenteDetallado.subpartida(@agente.id, @fecha_de_inicio, @fecha_de_fin ,params[:moneda], params[:tasa_cambio], partida.id.to_s, subpartida.id.to_s, nil)
        importe_gasto = VGastoAgente.sum_total(filtro_subpartida).first
        importe_gasto_delegacion = VGastoAgente.sum_total(filtro_subpartida.merge( proyecto: "isnull" )).first
        importe_gasto_proyectos = VGastoAgente.sum_total(filtro_subpartida.merge( proyecto: "isnotnull" )).first
        gasto = importe_gasto ? importe_gasto.importe||0 : 0
        gasto_delegacion = importe_gasto_delegacion ? importe_gasto_delegacion.importe||0 : 0
        gasto_proyectos = importe_gasto_proyectos ? importe_gasto_proyectos.importe||0 : 0
        presupuesto = (pres.empty? ? 0 : pres.first[:importe]) || 0
        # Añadimos detalle a cada de eleme3nto del listado para poder listarlo posteriormente
        update = "gasto_partida_" + partida.id.to_s + "_subpartida_" + subpartida.id.to_s 
        mas_detalle = { url: {action: :detalle_gasto_subpartida, update: update, filtro: filtro_subpartida } }
        @subpartidas.push(:contenido => [subpartida.nombre, presupuesto, gasto, (presupuesto - gasto), (presupuesto == 0 ? "-" : (presupuesto - gasto)/presupuesto * 100), gasto_delegacion, gasto_proyectos], :objeto_desplegado => mas_detalle)  
        # Ahora ponemos los datos para rellenar la tabla de proyectos por partidas
        proyecto_subpartida = VGastoAgente.sum_subpartida_proyecto(filtro_subpartida.merge(proyecto: "isnotnull"))
        for fila in proyecto_subpartida
          @subpartidas_proyectos.push(:contenido => [(fila.subpartida_nombre || _("Sin subpartida")), (fila.proyecto_nombre|| _("Imputado a delegación")), (fila.importe || "0")])
        end
      end

      # Y completa con los que no tienen subpartida definida
      filtro_subpartida = filtro_partida.merge( subpartida: "isnull" )
      importe_pre = VPresupuestoAgenteDetallado.subpartida(@agente.id, @fecha_de_inicio, @fecha_de_fin ,params[:moneda], params[:tasa_cambio], partida.id.to_s, nil, true)
      importe_gasto = VGastoAgente.sum_total(filtro_subpartida).first
      importe_gasto_delegacion = VGastoAgente.sum_total(filtro_subpartida.merge( proyecto: "isnull" )).first
      importe_gasto_proyectos = VGastoAgente.sum_total(filtro_subpartida.merge( proyecto: "isnotnull" )).first
      gasto = importe_gasto ? importe_gasto.importe||0 : 0
      gasto_delegacion = importe_gasto_delegacion ? importe_gasto_delegacion.importe||0 : 0
      gasto_proyectos = importe_gasto_proyectos ? importe_gasto_proyectos.importe||0 : 0
      pres = (importe_pre.empty? or importe_pre.first[:importe].nil?) ? 0 : importe_pre.first[:importe]
      @subpartidas.push(:contenido => [_("Sin subpartida"), pres, gasto, (pres - gasto), (pres == 0 ? "-" : (pres - gasto)/pres * 100), gasto_delegacion, gasto_proyectos])  unless gasto == 0 and pres == 0
      proyecto_subpartida = VGastoAgente.sum_subpartida_proyecto(filtro_subpartida.merge(proyecto: "isnotnull"))
      for fila in proyecto_subpartida
        @subpartidas_proyectos.push(:contenido => [(fila.subpartida_nombre || "Sin subpartida"), (fila.proyecto_nombre || ""), (fila.importe || "0")])
      end
    end

    # Mete los totales por columna para las partidas
    @partidas.push(:contenido => [_("TOTALES"), tp, tg, (tp - tg), (tp == 0 ? "-" : (tp - tg)/tp * 100), tid, tip])


    # Recogemos todo en una tabla común
    respond_to do |format|
      format.xls do
        #@resumen = [ :tabla => tabla_resumen ]
        @resumen = []
        @resumen.push(  :listado => {   :nombre => _("Resumen por partidas"),
                                        :titulo => @titulo_partida,
                                        :lineas => @partidas })
        @resumen.push(	:listado => {	:nombre => _("Resumen por subpartidas"),
					:titulo => @titulo_subpartida,
					:lineas => @subpartidas }) 
        @resumen.push(	:listado => {	:nombre => _("Resumen por subpartidas y proyectos"),
					:titulo => @titulo_subpartidas_proyectos,
					:lineas => @subpartidas_proyectos }) 
        nom_fich = "resumen_gasto_" + @agente.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
      end
      format.html
    end
  end
  
  # Muesrta e3kl detalle de los gastos de una subpartida para el resumen de gasto. Peticion via AJAX
  def detalle_gasto_subpartida
    #Por si a alguien le da por toquetear los filtros, usamos el id de agente saneado por application_controller
    #params[:filtro][:proyecto] = @royecto.id if params[:filtro]
    listado_gastos_vista = VGastoAgente.listado_gastos params[:filtro]
    listado_gastos = Gasto.find(listado_gastos_vista.collect{|g| g.gasto_id})
    # listado_gastos.each do |g|
    #   g.importe_x_financiador = (listado_gastos_vista.find{|gv| gv.gasto_id == g.id }).importe
    # end
    @formato_xls = 1
    respond_to do |format|
      format.html do
        render(:update) { |page|  page.replace_html(params[:update], :partial => "resumen_proyecto/detalle_gasto_subpartida", :locals => {:listado_gastos => listado_gastos}) }
      end
      format.xls do
        # if params[:filtro][:agente_rol] == "financiador" and params[:filtro][:agente] != "todos"
        #   @tipo = "gasto_x_financiador"
        # else
          @tipo = "gasto_agentes"
        # end
        @objetos = listado_gastos
        nom_fich = "Gastos_de_subpartida_" + (@agente).nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
    # render(:update) do |page|
    #    page.replace_html(params[:update], :inline => "HOLA")
    # end
  end
  

  def presupuesto
    @listado_moneda = (@agente.moneda.collect{|e| [e.nombre, e.id]}) + [["Todas las monedas (T.Cambio aplicada)", "todas"]]
    @listado_etapas = @agente.etapa.collect{|e| [e.nombre, e.id]}
    estado_presupuesto if params[:moneda] 
  end

  def estado_presupuesto
   condiciones = {"ocultar_agente" => false} unless params[:mostrar_partidas_ocultas] == "1"
   partidas = Partida.find(:all, :conditions => condiciones, :order => "codigo")
   # Recogemos los datos de la tabla primera resumen del presupuesto de agente frente al presupuesto de proyecto
   filas =  partidas.collect {|i| {"id" => i.id, "nombre" => i.codigo_nombre} }  # if params[:detallado] == "1"       
   columnas = [{"id" => "2", "nombre" => "Pto. Proyectos"}, {"id" => "1", "nombre" => "Pto. Agente"}]
   etapa = Etapa.find params[:etapa]

   filtros = { moneda: params[:moneda], agente_rol: "implementador", agente: @agente.id, fecha_inicio: etapa.fecha_inicio, fecha_fin: etapa.fecha_fin, tasa_cambio: params[:tasa_cambio], proyecto_aprobado: true }
   presupuestos_proyectos = VPresupuestoDetallado.sum_partida_sin_proyecto(filtros).collect {|p| {"columna_id" => "2", "importe" => p.importe , "fila_id" => p.fila_id }} 
   presupuestos_delegacion = VPresupuestoAgente.partida_implementador(@agente.id, etapa.id, params[:moneda], params[:tasa_cambio], nil).collect {|p| {"columna_id" => "1", "importe" => p.importe , "fila_id" => p.fila_id }}
   datos = presupuestos_proyectos + presupuestos_delegacion
   titulo =[ "Moneda: #{ params[:moneda] == 'todas' ?  'Todas las monedas' : Moneda.find(params[:moneda]).abreviatura} " ,
             "Tasa cambio: #{(params[:tasa_cambio] == '1' or params[:moneda] == 'todas') ? 'Aplicada': 'No aplicada'}" ,
             "Etapa: #{ etapa.nombre + ' (' + etapa.fecha_inicio.to_time.to_s + ' - ' + etapa.fecha_fin.to_time.to_s + ")" } " ]
   titulo_resumen = ["Resumen del presupuesto de proyectos (ingresos) y de agente (gastos)"] + titulo
   tabla = { :titulo => titulo_resumen, :filas => filas, :columnas => columnas, :datos => datos, :otros => { :fila_suma => true, :columna_resta => true } }

   # Comprobamos que no hay partidas ocultas con datos de agente
   aviso_p_agente = false
   aviso_p_proyecto = false 
   presupuestos_proyectos.each { |p| aviso_p_proyecto = true if (filas.select{|f| f["id"].to_s == p["fila_id"].to_s}).empty? }
   presupuestos_delegacion.each { |p| aviso_p_agente = true if (filas.select{|f| f["id"].to_s == p["fila_id"].to_s}).empty? }
   msg_error(_("Existen partidas ocultas que contienen presupuestos de proyecto.") + " " + _("Seleccione mostrar partidas ocultas para verlas"), :now => true)  if aviso_p_proyecto
   msg_error(_("Existen partidas ocultas que contienen presupuestos de agente.") + " " + _("Seleccione mostrar partidas ocultas para verlas"), :now => true)  if aviso_p_agente

   #Recogemos la tabla del detalle del presupuesto del agente por subpartidas y la de detalle de presupuesto por proyectos   
   @subpartidas = Array.new
   @presupuesto_proyectos = Array.new
   for partida in partidas
      filtros_partida = filtros.merge(partida: partida.id)
      #Buscamos el valor por partidas del presupuesto por agente
      importe_partida = VPresupuestoAgente.partida_implementador(@agente.id, etapa.id, params[:moneda], params[:tasa_cambio], partida.id).first
      @subpartidas.push(:cabecera => [[ partida.codigo_nombre , "2" ], [(importe_partida ? importe_partida[:importe] : 0) ,"1_2_td"]])
    
      for subpartida in  Subpartida.find_all_by_agente_id_and_partida_id( @agente.id, partida.id)
        valor = VPresupuestoAgente.subpartida_partida(@agente.id, params[:etapa], params[:moneda], params[:tasa_cambio], partida.id.to_s, (subpartida ? subpartida.id.to_s : nil))
        @subpartidas.push(:contenido => [(subpartida ? subpartida.nombre : "sin subpartida"), valor.first[:importe]]) unless valor.nil? or valor.empty?
      end
      #buscamos el valor por partidas del presupuesto por proyecto
      partida_proyectos = VPresupuestoDetallado.sum_total(filtros_partida).first
      @presupuesto_proyectos.push(:cabecera => [[ partida.codigo_nombre , "2" ], ["","2"], [(partida_proyectos  ? partida_proyectos[:importe] : 0) ,"1_2_td"]]) 
      detalle_partida_proyecto = VPresupuestoDetallado.sum_partida filtros_partida
      for detalle in detalle_partida_proyecto
         # Incluimos la lista con posibilidad de desplegar mas detalle
         update = "presupuesto_partida_" + detalle.fila_id.to_s + "_proyecto_" + detalle.proyecto_id.to_s
         mas_detalle = { url: {action: :detalle_presupuestos_proyecto, update: update, filtro: filtros_partida.merge(proyecto: detalle.proyecto_id)} }
         @presupuesto_proyectos.push(:contenido => [detalle.proyecto_nombre, "", (detalle.importe || 0) ], :objeto_desplegado => mas_detalle)
      end
    end
     @titulo_presupuesto_subpartida = ["Detalle del presupuesto del agente (gastos) por subpartidas"] + titulo   
     @titulo_presupuesto_proyectos = ["Detalle del presupuesto por proyectos (ingresos)"] + titulo
     # Recogemos todo en una tabla común
     @tablas = [tabla]
     respond_to do |format|
        format.xls do
          @nombre = "Resumen Presupuesto" + @agente.nombre
          @resumen = [  :tabla => tabla ]
          @resumen.push( :listado => {  :tipo => "v_presupuesto_subpartida",
                                        :nombre => _("Resumen por subpartidas"),
                                        :titulo => @titulo_presupuesto_subpartida,
                                        :lineas => @subpartidas })
          @resumen.push( :listado => {	:tipo => "v_presupuesto_proyecto",
					:nombre => _("Resumen por proyectos"),
					:titulo => @titulo_presupuesto_proyectos,
					:lineas => @presupuesto_proyectos })

          nom_fich = "resumen_presupuesto_" + @agente.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
        end
        format.html
      end
  end

	# en agentes: desglosa las lineas de presupuesto para una partida y un proyecto en un rango de fechas concreto
  def detalle_presupuestos_proyecto
    # Por si a alguien le da por toquetear los filtros, usamos el id de agente saneado por application_controller
    params[:filtro][:agente] = @agente.id if params[:filtro]
    presupuestos = VPresupuestoDetallado.sum_presupuesto params[:filtro]

    @formato_xls = 1 
    respond_to do |format|
      format.html do
        render(:update) { |page|  page.replace_html(params[:update], :partial => "detalle_presupuestos_proyecto", :locals => {:presupuestos => presupuestos}) }
      end
      format.xls do
        @tipo = "detalle_presupuestos_proyecto"
        @objetos = presupuestos 
        nom_fich = "presupuestos_" + (@agente).nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

	# en agentes: selecciona la caja para sacar el informe de arqueo
  def arqueo_caja
    @listado_libros = eval( "@" + singularizar_seccion ).libro.select{|l| @usuario_identificado.libro.include? l}.collect {|a|[a.nombre, a.id]}
    @listado_etapa = @agente.etapa.collect{|e| [e.nombre, e.id]}

    # Si hemos especificado un libro para ver el informe
    if params[:selector] and params[:selector][:libro] != ''
      @libro = Libro.find(params[:selector][:libro])
      @moneda = @libro.moneda
      @etapa = Etapa.find_by_id(params[:selector][:etapa])

      fecha_inicio = @etapa ? @etapa.fecha_inicio : nil
      fecha_fin = @etapa ? @etapa.fecha_fin : nil

      arqueo = @libro.arqueo [], fecha_inicio, fecha_fin

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
      lineas.push( :contenido => [ '','','','','','' ] )
      lineas.push( :cabecera => [ [_("Totales"),"1_2"], ["","1_2"], ["","3_2"], [arqueo[:entrante],"1_2_td"], [arqueo[:saliente],"1_2_td"], [arqueo[:entrante] - arqueo[:saliente],"1_2_td"] ])
      arqueo[:totales].each do |k,v|
        lineas.push( :contenido => [ '',_(k),'',v["Entrante"]||'',v["Saliente"]||'','' ] )
      end

      @resumen = Array.new
      nombre = "arqueo_caja"
      titulo = _("Arqueo Cuenta/Caja") + " " + @libro.nombre + " " + @libro.cuenta + " (" + @libro.moneda.nombre + ") / " + _("Etapa") + ": " +
		( @etapa ? @etapa.nombre + " (" + _("desde") + " " + @etapa.fecha_inicio.strftime('%d/%m/%Y') + " " + _("hasta") + " " + @etapa.fecha_fin.strftime('%d/%m/%Y') + ")" : _("Todas"))
      @resumen.push(:listado => {:nombre => nombre, :titulo => titulo, :lineas => lineas})

      respond_to do |format|
        format.html do
          render :template => 'comunes/arqueo_caja', :layout => (params[:sin_layout] ? false : true)
        end
        format.xls do
          nom_fich = "arqueo_" + @agente.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
        end
      end
    else
      render :template => "comunes/arqueo_caja", :layout => (params[:sin_layout] ? false : true)
    end
 
  end

end
