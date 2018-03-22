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
# Controlador encargado de la visibilizacion y calculo de remanentes para Convenios
#--

class RemanenteController < ApplicationController

  helper :resumen_proyecto

	# en proyectos: presenta el calculo de remanentes segun la opcion de moneda elegida 
  def index 
    @listado_moneda = [[@proyecto.moneda_principal.nombre.pluralize,"todas"],[_("Todas las monedas"),"locales"]]
    @listado_tipo = [[_("Tesoreria"),"tesoreria"],[_("Ejecución"), "ejecucion"]]
    @listado_tipo = [[_("Tesoreria"),"tesoreria"]]
    @listado_vista = [[_("Por Partidas"), "partida"], [_("Por Actividades"), "actividad"]]
    @resumen = []

    # Sólo si hay un PAC anterior
    unless @proyecto.pac_anterior.nil? 
      params[:moneda] ||= "todas"
      params[:partida_actividad] ||= "partida"
      params[:tipo] ||= "tesoreria"

      # Remanentes por tesoreria
      if params[:tipo] == "tesoreria"
        (cab_col, cab_fila, filas) = @proyecto.pac_anterior.tesoreria(@proyecto.agente, nil, params[:moneda] == "todas")

        cabecera = [ [_("Remanentes de %{nombre}") % {:nombre => @proyecto.pac_anterior.nombre},"1"] ]
        cab_col.each do |cab|
          p = Pais.find_by_id(cab[:pais_id])
          m = Moneda.find_by_id(cab[:moneda_id])
          cabecera.push( [ m.nombre + ( p ? " " + p.nombre : ""), "1_2_td"] )
        end

        lineas = []
        lineas.push( :cabecera => cabecera )
        for i in (0..3)
          estilo = [ ['',"1"] ]
          estilo += filas[i-4].collect{ ['','1_2_td' + (i==1 ? '_g' : '')] }
          lineas.push( :estilo => estilo, :contenido => [ cab_fila[i-4] ] + filas[i-4] )
        end
        nombre = _("Remanente de Tesorería") + " " + @proyecto.pac_anterior.nombre
        @resumen.push( :listado => {:nombre => nombre, :titulo => nombre, :lineas => lineas})

      # Remanentes por partida o actividad
      else
        estado_gasto
      end

      # Aplica los remanentes si asi se ha pedido
      if params[:commit] == _("Aplicar Remanentes")
        @proyecto.aplica_remanentes if @proyecto.pac_anterior
        msg _("Se han generado las transferencias correspondientes a los remanentes de '%{proyecto}'") % {:proyecto => @proyecto.pac_anterior.nombre} 
      end

      respond_to do |format|
        format.html do 
          render :action => "index", :layout => (params[:sin_layout] ? false : true)
        end
        format.xls do
          @nombre = _("Cálculo de Remanentes")
          nom_fich = "remanentes_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
        end
      end
    else
      render :action => "index", :layout => (params[:sin_layout] ? false : true)
    end
  end

	# en proyectos: obtiene el calculo de remanentes
  def estado_gasto
    # Inicializamos los datos necesarios
    fecha_de_inicio = @proyecto.pac_anterior.fecha_de_inicio
    fecha_de_fin = @proyecto.pac_anterior.fecha_de_fin
    fecha_de_fin = (fecha_de_fin >> 1) - 1 # Para que incluya el mes en elegido
    proyecto = @proyecto.pac_anterior

    # Las filas son partidas o actividades, segun se haya elegido
    filas = Partida.find(:all, :order => "codigo").collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}} if params[:partida_actividad] == "partida"
    filas = proyecto.actividad.collect{|i| {"id" => i.id, "nombre" => i.codigo_nombre}} if params[:partida_actividad] == "actividad"

    # Selecciona el tipo de calculo de remanentes (convertidas a moneda principal o por cada moneda)
    monedas = ["todas"] if params[:moneda] == "todas"
    monedas = @proyecto.moneda.collect{|m| m.id} unless params[:moneda] == "todas"
 
    filtro = { proyecto: proyecto.id, moneda: moneda, agente_rol: "implementador", fecha_inicio: fecha_de_inicio, fecha_fin: fecha_de_fin, tasa_cambio: "0" }
 
    # Construye una tabla por cada moneda 
    monedas.each do |moneda|
      datos = []
      columnas = []

      # Va recorriendo todos los implementadores para meterlos en cada columna
      columna = 1
      filtro[:moneda] = moneda
      proyecto.implementador.each do |agente|
        filtro[:agente] = agente.id
        # Si queremos ver remanentes por partidas
        if params[:partida_actividad] == "partida"
          presupuesto = VPresupuestoDetallado.sum_partida filtro 
          gasto = VGasto.sum_partida filtro
        # Si queremos ver remanentes por actividades
        else
          presupuesto = VPresupuestoDetallado.sum_actividad filtro
          gasto = VGasto.sum_actividad(filtro)
        end
        # Mete en cada fila la diferencia entre presupuesto y gasto
        for fila in filas do
          p = presupuesto ? presupuesto.detect {|v| v["fila_id"] == fila["id"].to_s} : nil
          g = gasto ? gasto.detect {|v| v["fila_id"] == fila["id"].to_s} : nil
          datos.push( {"columna_id" => columna.to_s, "fila_id" => fila["id"].to_s, "importe" => (p ? p["importe"] : 0.0) - (g ? g["importe"] : 0.0) } )
        end
        columnas.push({"id" => columna.to_s, "nombre" => agente.nombre})
        columna += 1 
      end

      # Incluye la tabla de la moneda
      titulo =[	_("Remanentes de %{nombre}") % {:nombre => proyecto.nombre},
		(moneda == "todas" ? _("Cálculo en %{moneda}") % {:moneda => proyecto.moneda_principal.nombre.pluralize} : _("Remanentes de %{moneda} por %{actividad}") % {:moneda => Moneda.find_by_id(moneda.to_i).nombre, :actividad => params[:partida_actividad].capitalize}) +
		_("Fechas") + ": " + fecha_de_inicio.to_s + '/' +  fecha_de_fin.to_s  ]

      @resumen.push(:tabla => {:titulo => titulo ,:filas => filas, :columnas => columnas, :datos => datos, :otros => {  :columna_resta => false, :columna_suma => true, :fila_suma => true, :columna_desviacion => false, :clases => ["","3_2","1_2_td"] } })
    end
  end

end
