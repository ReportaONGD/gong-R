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

class ResumenEmpleadosProyectoController < ApplicationController
  helper :resumen_proyecto

  before_filter :verificar_etapa

  def verificar_etapa
    if @proyecto.nil? || @proyecto.etapa.empty?
      msg_error _("Tiene que definir por lo menos una etapa para acceder a los informes")
      redirect_to :menu => :configuracion_proyectp, :controller => :datos_proyectos, :action => :etapas
    end
  end
  
  # en agente: se redirecciona por defecto a empleados
  def index
    redirect_to :action => :resumen_empleados
  end
  
  # OJO: El siguiente resumen de presupuesto de empleado, al igual que el resto de funcionalidades relacionadas con empleados no contemplan el tema de TASAS DE CAMBIO por que de momento se entiende que el presupuesto se hace en la moneda base de agente.
  def resumen_empleados
    estado_empleados
    
    respond_to do |format|
      format.xls do
        @nombre = "Resumen de horas de Personal para el proyecto " + @proyecto.nombre
        @resumen = @tablas.collect{|t| {tabla: t} }
        nom_fich = "resumen_#{params[:tipo]}_personal_proyectos" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
      end
      format.html
    end
  end

  def estado_empleados
    @fecha_de_inicio = @proyecto.fecha_de_inicio
    @fecha_de_fin = @proyecto.fecha_de_fin
    @filas_empleados = []
    cond1 = { "fecha" =>  [@fecha_de_inicio..@fecha_de_fin], "gasto_x_proyecto.proyecto_id" => @proyecto.id}
    cond2 = "gasto.empleado_id IS NOT NULL"
    @gastos_con_empleado = Gasto.joins(:gasto_x_proyecto).where(cond1).where(cond2).group("gasto.empleado_id").select("gasto.empleado_id")
    @gastos_con_empleado.each do |gce|
      @filas_empleados.push "id" => gce.empleado_id, "nombre" => Empleado.find_by_id(gce.empleado_id).nombre
    end
    @titulo_fechas = [_("Fecha inicio") + ": " + @fecha_de_inicio.to_time.to_s, _("Fecha fin") + ": " + @fecha_de_fin.to_time.to_s]
    @tablas = [tabla_meses]
  end

  def tabla_meses
    datos = []
    columnas = []
    condiciones = {proyecto: @proyecto.id}

    # Recorremos todos los periodos mensuales (incluye meses no enteros)

    meses_totales = (@fecha_de_fin.year * 12 + @fecha_de_fin.month) - (@fecha_de_inicio.year * 12 + @fecha_de_inicio.month)
    for mes in 1..meses_totales 
      condiciones[:fecha_inicio] = @fecha_de_inicio + (mes-1).month
      condiciones[:fecha_fin] = condiciones[:fecha_inicio] + 1.month  - 1.day
      condiciones[:columna_id] =  mes
      # Definimos la cabecera de la columna
      fecha_crono = I18n.l(condiciones[:fecha_inicio], :format => "%B %Y")
      columnas.push({"id" => mes, "nombre" => fecha_crono})
      datos += estado_meses(condiciones, mes)
    end

        
    titulo_resumen = [_("HORAS de personal por MESES")] + @titulo_fechas 
    
    otros = { :fila_suma => true, :ancho_fila => ((columnas.count + 2) * 105 + 50), :marcar_valores_negativos => true, :columna_suma => true}
    tabla = { :titulo => titulo_resumen, :filas => @filas_empleados, :columnas => columnas, :datos => datos, :otros => otros }
    
    return tabla
  end
  
  def estado_meses condiciones, mes
    datos = []
    VGastoAgente.empleados_horas(condiciones).each do |vp|
      datos.push "columna_id" => mes, "fila_id" => vp.empleado_id, "importe" => vp.horas
    end
    return datos
  end

end
