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

class ResumenEmpleadosAgenteController < ApplicationController
  helper :resumen_proyecto

  before_filter :verificar_etapa

  def verificar_etapa
    if @agente.nil? || @agente.etapa.empty?
      msg_error _("Tiene que definir por lo menos una etapa para acceder a los informes")
      redirect_to :menu => :configuracion_agente, :controller => :datos_agente, :action => :etapas
    end
  end
  
  # en agente: se redirecciona por defecto a empleados
  def index
    redirect_to :action => :resumen_empleados
  end
  
  # OJO: El siguiente resumen de presupuesto de empleado, al igual que el resto de funcionalidades relacionadas con empleados no contemplan el tema de TASAS DE CAMBIO por que de momento se entiende que el presupuesto se hace en la moneda base de agente.
  def resumen_empleados
    @listado_etapa = @agente.etapa.collect{|e| [e.nombre, e.id]}
    estado_empleados if params[:etapa] and params[:tipo]
    
    respond_to do |format|
      format.xls do
        @nombre = "Resumen Presupuesto de Personal por Proyectos " + @agente.nombre
        @resumen = @tablas.collect{|t| {tabla: t} }
        nom_fich = "resumen_#{params[:tipo]}_personal_proyectos" + @agente.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
      end
      format.html
    end
  end
  
  def estado_empleados
    @etapa = Etapa.find_by_id(params[:etapa])
    @fecha_de_inicio = @etapa.fecha_inicio
    @fecha_de_fin = @etapa.fecha_fin
    @filas_empleados = []
    Empleado.where(agente_id: @agente.id).each do |e|
      @filas_empleados.push "id" => e.id, "nombre" => e.nombre
    end
    @titulo_moneda = ["Datos sobre la moneda del agente:  #{@agente.moneda_principal.abreviatura}"]
    @titulo_fechas = [_("Fecha inicio") + ": " + @fecha_de_inicio.to_time.to_s, _("Fecha fin") + ": " + @fecha_de_fin.to_time.to_s]
    @tablas = [tabla_agregado, tabla_proyectos, tabla_meses]
  end
  
  def tabla_agregado
    c_presupuesto = [{"id" => "1_p", "nombre" => _("Presupuesto al Agente")}, {"id" => "2_p", "nombre" => _("Presupuesto a Proyectos")}]
    c_gasto =  [{"id" => "1_g", "nombre" => _("Gasto al Agente")}, {"id" => "2_g", "nombre" => _("Gasto a Proyectos")}]
    c_horas =  [{"id" => "1_h", "nombre" => _("Horas al Agente")}, {"id" => "2_h", "nombre" => _("Horas a Proyectos")}]
    c_presupuesto_gasto = []
    c_presupuesto_gasto << c_presupuesto.first << c_gasto.first <<  {"id" => "1_d", "nombre" => _("Diferencia Agente")} <<
                           c_presupuesto.second << c_gasto.second << {"id" => "2_d", "nombre" => _("Diferencia Proyectos")} <<
                          {"id" => "p_t", "nombre" => _("Total Presupuesto")} << {"id" => "g_t", "nombre" => _("Total Gasto")} << 
                          {"id" => "t_d", "nombre" => _("Diferencia totales")}

    columnas = eval("c_#{params[:tipo]}")

    titulo = [_("#{params[:tipo].humanize.upcase} de personal AGREGADO")] + @titulo_fechas + @titulo_moneda 
    
    otros = { :fila_suma => true, :ancho_fila => ((columnas.count + 2) * 70 + 250), :sin_truncar => true,
              :clases => ["","3_4","1_3_td","1_2","1_2_td"], :marcar_valores_negativos => true  }

    unless params[:tipo] == "presupuesto_gasto"
      otros[:columna_suma] = true
      otros[:fila_porcentaje] = true
    end

    condiciones = {agente_id: @agente.id, fecha_inicio: @fecha_de_inicio.to_s, fecha_fin: @fecha_de_fin.to_s, moneda_id: @agente.moneda_principal.id}

    tabla = { :titulo => titulo, :filas => @filas_empleados, 
              :columnas => columnas, :datos => eval("estado_#{params[:tipo]}_agregado(condiciones)"), :otros => otros }
  end

  def estado_presupuesto_gasto_agregado condiciones = {}
    presupuestos = estado_presupuesto_agregado condiciones
    gastos = estado_gasto_agregado condiciones
    datos = presupuestos + gastos

    # Calculamos todas las columnas totales y diferencia
    for empleado in @filas_empleados
      pre_agen = presupuestos.find {|p| p["columna_id"] == "1_p" and p["fila_id"] == empleado["id"]}
      pre_agen = pre_agen ? pre_agen["importe"] : 0
      gas_agen = gastos.find {|g| g["columna_id"] == "1_g" and g["fila_id"] == empleado["id"]}
      gas_agen = gas_agen ? gas_agen["importe"] : 0
      pre_proy = presupuestos.find {|p| p["columna_id"] == "2_p" and p["fila_id"] == empleado["id"]}
      pre_proy = pre_proy ? pre_proy["importe"] : 0
      gas_proy = gastos.find {|g| g["columna_id"] == "2_g" and g["fila_id"] == empleado["id"]}
      gas_proy = gas_proy ? gas_proy["importe"] : 0
      # Diferencia entre el presupuesto y gastos de agente
      datos.push  "columna_id" => "1_d", "fila_id" => empleado["id"], "importe" => pre_agen - gas_agen
      # Diferencia entre el presupuesto y gastos de agente
      datos.push  "columna_id" => "2_d", "fila_id" => empleado["id"], "importe" => pre_proy - gas_proy
      # Diferencia entre el presupuesto y gastos de agente
      tot_pre = pre_agen + pre_proy
      tot_gas = gas_agen + gas_proy
      datos.push  "columna_id" => "p_t", "fila_id" => empleado["id"], "importe" => tot_pre
      # Diferencia entre el presupuesto y gastos de agente
      datos.push  "columna_id" => "g_t", "fila_id" => empleado["id"], "importe" => tot_gas
      # Diferencia entre el presupuesto y gastos de agente
      datos.push  "columna_id" => "t_d", "fila_id" => empleado["id"], "importe" => tot_pre - tot_gas
    end
    return datos
  end


  def estado_presupuesto_agregado condiciones 
    datos = []
    # Buscamos los presupuestos imputados al agente
    condiciones[:proyecto_imputado_id] = "isnull"
    VPresupuestoAgenteDetallado.empleados(condiciones).each do |vp|
      datos.push "columna_id" => "1_p", "fila_id" => vp.empleado_id, "importe" => vp.importe
    end
    # Buscamos los presupuestos imputados a proyectos
    condiciones[:proyecto_imputado_id] = "isnotnull"
    VPresupuestoAgenteDetallado.empleados(condiciones).each do |vp|
      datos.push "columna_id" => "2_p", "fila_id" => vp.empleado_id, "importe" => vp.importe
    end
    return datos
  end
  
  def estado_gasto_agregado condiciones
    datos = []
    # Buscamos los presupuestos imputados al agente
    condiciones[:proyecto] = "isnull"
    VGastoAgente.empleados(condiciones).each do |vp|
      datos.push "columna_id" => "1_g", "fila_id" => vp.empleado_id, "importe" => vp.importe
    end
    # Buscamos los presupuestos imputados a proyectos
    condiciones[:proyecto] = "isnotnull"
    VGastoAgente.empleados(condiciones).each do |vp|
      datos.push "columna_id" => "2_g", "fila_id" => vp.empleado_id, "importe" => vp.importe
    end
    return datos
  end

  def estado_horas_agregado condiciones
    datos = []
    # Buscamos los presupuestos imputados al agente
    condiciones[:proyecto] = "isnull"
    VGastoAgente.empleados_horas(condiciones).each do |vp|
      datos.push "columna_id" => "1_h", "fila_id" => vp.empleado_id, "importe" => vp.horas
    end
    # Buscamos los presupuestos imputados a proyectos
    condiciones[:proyecto] = "isnotnull"
    VGastoAgente.empleados_horas(condiciones).each do |vp|
      datos.push "columna_id" => "2_h", "fila_id" => vp.empleado_id, "importe" => vp.horas
    end
    return datos
  end

  ##################################################
  # METODOS RELACIONADOS CON EMPLEADOS X PROYECTOS #
  ##################################################

  def tabla_proyectos
    datos = []
    # Existe un formato de columnas diferente si exportamos a fichero
    if params[:fichero] == "1" and params[:tipo] == "presupuesto_gasto"
      @columnas_proyectos = [{"id" => "nil_p", "nombre" => "PRESUPUESTO. \n Imputado al agente "},
                             {"id" => "nil_g", "nombre" => "GASTO. \n Imputado al agente "}, 
                             {"id" => "nil_d", "nombre" => "DIFERENCIA. \n Imputado al agente "}]
    else
      @columnas_proyectos = [{"id" => nil, "nombre" => "Imputado al agente"}]
    end
    @proyectos = @agente.proyectos_vinculados(@etapa)
    @proyectos.each do |p|
      # Existe un formato de columnas diferente si exportamos a fichero
      if params[:fichero] == "1" and params[:tipo] == "presupuesto_gasto"
        @columnas_proyectos.push "id" => p.id.to_s + "_p", "nombre" => "PRESUPUESTOS. \n" + p.nombre
        @columnas_proyectos.push "id" => p.id.to_s + "_g", "nombre" => "GASTOS. \n" + p.nombre 
        @columnas_proyectos.push "id" => p.id.to_s + "_d", "nombre" => "DIFERENCIA. \n" + p.nombre 
      else
        @columnas_proyectos.push "id" => p.id, "nombre" => p.nombre
      end
    end

    condiciones = { agente_id: @agente.id, fecha_inicio: @fecha_de_inicio.to_s, fecha_fin: @fecha_de_fin.to_s, moneda_id: @agente.moneda_principal.id}
        
    titulo = [_("#{params[:tipo].humanize.upcase} de personal por PROYECTOS")] + @titulo_fechas + @titulo_moneda 
    otros = { :fila_suma => true, :ancho_fila => ((@columnas_proyectos.count + 2) * 105 + 50),
              :marcar_valores_negativos => true, :celdas_title => true }
    otros[:columna_suma] = true if params[:fichero] == "0" # and params[:tipo] == "presupuesto_gasto"
    tabla = { :titulo => titulo, :filas => @filas_empleados, :columnas => @columnas_proyectos , 
              :datos => eval("estado_#{params[:tipo]}_proyectos(condiciones)"), :otros => otros }
    
    return tabla
  end

  def estado_presupuesto_gasto_proyectos condiciones = {}
    presupuestos = estado_presupuesto_proyectos condiciones
    gastos = estado_gasto_proyectos condiciones
    datos = []
    for empleado in @filas_empleados
      for proyecto in @proyectos 
        pre = presupuestos.find {|p| p["columna_id"] == proyecto.id and p["fila_id"] == empleado["id"]}
        pre = pre ? pre["importe"] : 0
        gas = gastos.find {|g| g["columna_id"] == proyecto.id  and g["fila_id"] == empleado["id"]}
        gas = gas ? gas["importe"] : 0
        if params[:fichero] == "1" and params[:tipo] == "presupuesto_gasto"
          datos.push  "columna_id" => proyecto.id.to_s + "_p", "fila_id" => empleado["id"], "importe" => pre
          datos.push  "columna_id" => proyecto.id.to_s + "_g", "fila_id" => empleado["id"], "importe" => gas
          datos.push  "columna_id" => proyecto.id.to_s + "_d", "fila_id" => empleado["id"], "importe" => pre - gas
        else
          title = "Presupuesto: " + view_context.celda_formateada(pre) + " - " +   "Gasto: " + view_context.celda_formateada(gas) 
          datos.push  "columna_id" => proyecto.id, "fila_id" => empleado["id"], "importe" => pre - gas, "title" => title 
        end
      end
      # Falta el caso proyecto = nil, es decir el caso de asignado a Agente.
      pre = presupuestos.find {|p| p["columna_id"] == nil and p["fila_id"] == empleado["id"]}
      pre = pre ? pre["importe"] : 0
      gas = gastos.find {|g| g["columna_id"] == nil  and g["fila_id"] == empleado["id"]}
      gas = gas ? gas["importe"] : 0
      if params[:fichero] == "1" and params[:tipo] == "presupuesto_gasto"
        datos.push  "columna_id" => "nil_p", "fila_id" => empleado["id"], "importe" => pre
        datos.push  "columna_id" => "nil_g", "fila_id" => empleado["id"], "importe" => gas
        datos.push  "columna_id" => "nil_d", "fila_id" => empleado["id"], "importe" => pre - gas
      else
        title = "Presupuesto: " + view_context.celda_formateada(pre) + " - " +   "Gasto: " + view_context.celda_formateada(gas) 
        datos.push  "columna_id" => nil, "fila_id" => empleado["id"], "importe" => pre - gas, "title" => title 
      end
    end
    return datos
  end

  def estado_presupuesto_proyectos condiciones = {}
    datos = []
    VPresupuestoAgenteDetallado.empleados_proyectos(condiciones).each do |vp|
      datos.push "columna_id" => vp.proyecto_imputado_id, "fila_id" => vp.empleado_id, "importe" => vp.importe
    end
    return datos
  end
  
  def estado_gasto_proyectos condiciones = {}
    datos = []
    VGastoAgente.empleados_proyectos(condiciones).each do |g|
      datos.push "columna_id" => g.proyecto_id, "fila_id" => g.empleado_id, "importe" => g.importe
    end
    return datos
  end

  def estado_horas_proyectos condiciones = {}
    datos = []
    VGastoAgente.empleados_horas_proyectos(condiciones).each do |g|
      datos.push "columna_id" => g.proyecto_id, "fila_id" => g.empleado_id, "importe" => g.horas
    end
    return datos
  end

  ##############################################
  # METODOS RELACIONADOS CON EMPLEADOS X MESES #
  ##############################################

  def tabla_meses
    datos = []
    columnas = []
    condiciones = {agente_id: @agente.id, moneda_id: @agente.moneda_principal.id}

    # Recorremos todos los periodos mensuales (incluye meses no enteros)
    for mes in (1..@etapa.periodos)
      condiciones[:fecha_inicio] = @fecha_de_inicio + (mes-1).month
      condiciones[:fecha_fin] = condiciones[:fecha_inicio] + 1.month  - 1.day
      condiciones[:columna_id] =  mes
      # Definimos la cabecera de la columna
      fecha_crono = I18n.l(condiciones[:fecha_inicio], :format => "%B %Y")
      if params[:fichero] == "1" and params[:tipo] == "presupuesto_gasto"
        columnas.push({"id" => mes.to_s + "_p", "nombre" => "PRESUPUESTO. \n" + fecha_crono})
        columnas.push({"id" => mes.to_s + "_g", "nombre" => "GASTO. \n" + fecha_crono})
        columnas.push({"id" => mes.to_s + "_d", "nombre" => "DIFERENCIA. \n" +  fecha_crono})
      else
        columnas.push({"id" => mes, "nombre" => fecha_crono})
      end
      datos += eval("estado_#{params[:tipo]}_meses(condiciones, mes)")
    end

        
    titulo_resumen = [_("#{params[:tipo].humanize.upcase} de personal por MESES")] + @titulo_fechas + @titulo_moneda 
    
    otros = { :fila_suma => true, :ancho_fila => ((columnas.count + 2) * 105 + 50), :marcar_valores_negativos => true}
    otros[:columna_suma] = true if params[:fichero] == "0" # and params[:tipo] == "presupuesto_gasto"
    tabla = { :titulo => titulo_resumen, :filas => @filas_empleados, :columnas => columnas, :datos => datos, :otros => otros }
    
    return tabla
  end

  def estado_presupuesto_gasto_meses  condiciones, mes
    datos = []
    presupuestos = estado_presupuesto_meses(condiciones, mes)
    gastos = estado_gasto_meses(condiciones, mes)
    for empleado in @filas_empleados
      pre = presupuestos.find {|p| p["columna_id"] == mes and p["fila_id"] == empleado["id"]}
      pre = pre ? pre["importe"] : 0
      gas = gastos.find {|g| g["columna_id"] == mes  and g["fila_id"] == empleado["id"]}
      gas = gas ? gas["importe"] : 0
      if params[:fichero] == "1" and params[:tipo] == "presupuesto_gasto"
        datos.push  "columna_id" => mes.to_s + "_p", "fila_id" => empleado["id"], "importe" => pre
        datos.push  "columna_id" => mes.to_s + "_g", "fila_id" => empleado["id"], "importe" => gas
        datos.push  "columna_id" => mes.to_s + "_d", "fila_id" => empleado["id"], "importe" => pre - gas
      else
        title = "Presupuesto: " + view_context.celda_formateada(pre) + " - " +   "Gasto: " + view_context.celda_formateada(gas) 
        datos.push  "columna_id" => mes, "fila_id" => empleado["id"], "importe" => pre - gas, "title" => title 
      end
    end
    return datos 
  end

  def estado_presupuesto_meses condiciones, mes
    datos = []
    VPresupuestoAgenteDetallado.empleados(condiciones).each do |vp|
      datos.push "columna_id" => mes, "fila_id" => vp.empleado_id, "importe" => vp.importe
    end
    return datos
  end

  def estado_gasto_meses condiciones, mes
    datos = []
    VGastoAgente.empleados(condiciones).each do |vp|
      datos.push "columna_id" => mes, "fila_id" => vp.empleado_id, "importe" => vp.importe
    end
    return datos
  end

  def estado_horas_meses condiciones, mes
    datos = []
    VGastoAgente.empleados_horas(condiciones).each do |vp|
      datos.push "columna_id" => mes, "fila_id" => vp.empleado_id, "importe" => vp.horas
    end
    return datos
  end

end
