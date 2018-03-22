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
# Controlador encargado de la gestion de la entidad presupuesto. Este controlador es utilizado desde las secciones:
# * Sección agentes: se utiliza para la gestión del presupuesto de empleado
#
class PresupuestoEmpleadoAgentesController < ApplicationController

  def index
    # unless session[:presupuesto_empleado_etapa]
    #   etapa_actual = Etapa.where(agente_id: @agente.id).where("fecha_inicio >= ? AND fecha_fin <= ?", Time.now.year.to_s + "-01-01", Time.now.year.to_s + "-12-31")
    #   session[:presupuesto_empleado_etapa] = etapa_actual.id
    # end
    redirect_to :action => :listado
  end


  def filtrado
    session[:presupuesto_empleado_etapa] = params[:etapa_id]
    redirect_to :action => params[:listado]
  end

  # en proyectos: listado de presupuestos del proyecto cargado en la sessión
  def listado
    @empleados = Empleado.where(agente_id: @agente.id)
  end

  # en agentes: modifica o crea un presupuesto
  def modificar_crear
    @empleado = Empleado.find_by_id(params[:presupuesto][:empleado_id])
    @etapa = Etapa.find(params[:etapa_id])
    modificar_crear_presupuesto    
    if @presupuesto.errors.empty?
      render :update do |page|
        # Si el presupuesto ya existía
        if params[:id]
          page.modificar :update => params[:update], :partial => "presupuesto", :locals => { :presupuesto => @presupuesto, :empleado => @empleado}, :mensaje => { :errors => @presupuesto.errors }  
        # Si es un nuevo presupuesto
        else
          nueva = params[:update_listado] +"_"+ (rand 1000000).to_s
          page.nueva_fila :update => params[:update_listado] + "_nuevo", :partial => "presupuesto", :nueva_fila => nueva, :locals => { :presupuesto => @presupuesto, :empleado => @empleado }, :mensaje => { :errors => @presupuesto.errors } 
        end
        page.replace "suma_" + params[:empleado_id], :partial => "suma", :locals => {:empleado => @empleado }
        page.replace "caja_suma_total_fin", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_fin"}
      end
    else
    # Si hay fallo grabando el presupuesto (y es un nuevo presupuesto) mostramos el formulario con el mensaje de error 
      datos_formulario
      @proyectos = @presupuesto.presupuesto_x_proyecto
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @presupuesto.errors} }
    end
  end

  # Metodo que llama modificar_crear y crear_presupuesto_anual
  def modificar_crear_presupuesto
    @presupuesto = @agente.presupuesto.find_by_id(params[:id]) || Presupuesto.new(agente_id: @agente.id)
    etapa_anterior_id =  @presupuesto.etapa_id
    params[:presupuesto][:etapa_id] = @etapa.id
    params[:presupuesto][:moneda_id] = @agente.moneda_principal.id
    mes = params[:presupuesto][:presupuesto_detallado][:mes].to_i
    fecha_inicio = @etapa.fecha_inicio >> (mes - 1)
    fecha_fin = fecha_inicio.next_month.prev_day

    # Se asegura de que el importe sea el calculo de numero_unidades y coste_unitario
    if params[:presupuesto] && params[:presupuesto][:coste_unitario_convertido]
      params[:presupuesto][:numero_unidades] = 1
      coste_unitario = moneda_a_float params[:presupuesto][:coste_unitario_convertido]
      importe = params[:presupuesto][:coste_unitario_convertido]
      params[:presupuesto][:importe] = coste_unitario
    end

    # Guarda cambios
    params[:presupuesto].delete(:presupuesto_detallado)
    @presupuesto.attributes = params[:presupuesto]
    Presupuesto.skip_callback(:create, :after, :dividir_por_mes)
    @presupuesto.save
    Presupuesto.set_callback(:create, :after, :dividir_por_mes)
    if @presupuesto.errors.empty?
      presupuesto_detallado = PresupuestoDetallado.find_or_create_by_presupuesto_id(@presupuesto.id)
      presupuesto_detallado.update_attributes(importe: importe, fecha_inicio: fecha_inicio, fecha_fin: fecha_fin, nombre: params[:presupuesto][:concepto], mes: mes)
      @presupuesto.reload if params[:id] 
      params["proyectos"]["0"]["importe"] = @presupuesto.importe unless params["proyectos_detallado"]
      @presupuesto.actualizar_presupuesto_x_proyectos params["proyectos"]
    end
  end

  #-- 
  # METODOS AJAX PARA MANEJAR PRESUPUESTO DETALLES
  # ++

  # en agentes: elimina un presupuesto
  def eliminar
    @objeto = Presupuesto.find(params[:id])
    @objeto.destroy
    empleado = Empleado.find_by_id(params[:empleado_id])
    render(:update) do |page|
      page.eliminar :update => params[:update], :mensaje =>  {:errors => @objeto.errors, :eliminar => true}
      page.replace "suma_" + params[:empleado_id], :partial => "suma", :locals => {:empleado => empleado }
      page.replace "caja_suma_total_fin", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_fin"}
    end
  end


  # en agentes: prepara el formulario de edición o creación de presupuesto
  def editar_nuevo
    @empleado = Empleado.find(params[:empleado_id])
    @presupuesto = @objeto = Presupuesto.find_by_id(params[:id]) || Presupuesto.new(agente_id: @agente.id)
    @proyectos = @presupuesto.presupuesto_x_proyecto
    datos_formulario
    render (:update) {|page| page.formulario :partial => "formulario", :update => params[:update]}
  end


  # en agentes: muestra el detalle de la linea de presupuesto 
  def detallar_presupuestos
    etapa_id = session[:presupuesto_empleado_etapa]
    @empleado = Empleado.find params[:empleado_id]
    @presupuestos = @empleado.presupuesto.where(etapa_id: etapa_id)
    render :update do |page|
      page.replace_html params[:update_listado], :partial => "presupuestos", :update => params[:update_listado]
    end
  end
  
  def detallar_proyectos
    @presupuesto = @objeto = params[:id] ?  Presupuesto.find(params[:id]) : Presupuesto.new
    @proyectos = @presupuesto.presupuesto_x_proyecto
    @proyectos_seleccionables = proyectos_seleccionables
    render :update do |page|
      page.replace "proyectos_detalle", :partial => "proyectos_detalle"
    end
  end

  def anadir_proyecto
    @proyectos_seleccionables = proyectos_seleccionables
    render :template => "presupuesto_empleado_agentes/anadir_proyecto"
  end

  def auto_complete_for_presupuesto_subpartida_nombre
    if params[:presupuesto] && params[:presupuesto][:partida_id]
      condiciones = ['nombre like ? and agente_id = ? and partida_id = ?', "%#{params[:search]}%", params[:agente_id].to_s, params[:presupuesto][:partida_id].to_s ]
    else
      condiciones = ['nombre like ? and agente_id = ?', "%#{params[:search]}%", params[:agente_id].to_s]
    end
    @subpartidas = Subpartida.find(:all, :conditions => condiciones)
    render :inline => "<%= auto_complete_result_3 @subpartidas, :nombre %>"
  end

	# En los formularios de edicion de presupuesto, calcula precios segun lo que haya metido
  def calcula_importe
    numero_unidades = moneda_a_float params[:presupuesto][:numero_unidades] 
    coste_unitario = moneda_a_float params[:presupuesto][:coste_unitario_convertido] 
    @importe_formateado = ('%.2f' % (numero_unidades * coste_unitario)).to_s.sub(".",",")
    render :update do |page|
      page.replace_html "presupuesto_importe_convertido", :inline => _("Importe") + " <br><b><%= @importe_formateado %><br>"
      page[:presupuesto_importe].value = numero_unidades * coste_unitario if numero_unidades && coste_unitario
    end
  end

	# En presupuesto por partidas, prepara el formulario de importe estimado para la partida
  def nuevo_presupuesto_anual
    @empleado = Empleado.find_by_id params[:id]
    @presupuesto = Presupuesto.new(agente_id: @agente.id)
    @proyectos = []
    datos_formulario
    render (:update) {|page| page.formulario :partial => "formulario_anual", :update => params[:update]}
  end


  def crear_presupuesto_anual
    #@empleado = Empleado.find_by_id params[:id]
    @empleado = Empleado.find_by_id(params[:presupuesto][:empleado_id])
    @etapa = Etapa.find(params[:etapa_id]) #No deberia estar en la sesion la etapa ?
    concepto = params[:presupuesto][:concepto]
    params[:mes].each do |valores|
      if valores[1] == "1"
        fecha_mes = @etapa.fecha_inicio >> (valores[0].to_i - 1)
        params[:presupuesto][:concepto] = concepto + " ( " + I18n.l(fecha_mes, :format => "%B %y") + " ) "
        params[:presupuesto][:presupuesto_detallado] = {}
        params[:presupuesto][:presupuesto_detallado][:mes] = valores[0]
        modificar_crear_presupuesto    
        break unless @presupuesto.errors.empty?
      end
    end
    if @presupuesto.errors.empty?
      @presupuestos = @empleado.presupuesto.where(etapa_id: session[:presupuesto_empleado_etapa])
      render(:update) do |page|
        page.modificar :update_listado => params[:update_listado], :partial => "presupuestos"
        page.replace "suma_" + @empleado.id.to_s, :partial => "suma", :locals => {:empleado => @empleado }
        page.replace "caja_suma_total_fin", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_fin"}
      end
    else
      datos_formulario
      @proyectos = @presupuesto.presupuesto_x_proyecto
      render(:update) do |page| 
        page.recargar_formulario :partial => "formulario_anual", :mensaje => {:errors => @presupuesto.errors} 
      end
    end
  end
  
  def eliminar_presupuestos_empleado
    @empleado = Empleado.find_by_id(params[:empleado_id])
    @empleado.presupuesto.destroy_all
    @presupuestos = @empleado.presupuesto
    render(:update) do |page|
      #page.eliminar :update => params[:update_listado], :mensaje =>  {:errors => @empleado.errors, :eliminar => true}
      page.visual_effect(:fade, params[:update_listado] + "_borrado" )
      page.visual_effect(:fade, params[:update_listado] + "_borradofondo" )
      page.replace_html params[:update_listado], :partial => "presupuestos", :update => params[:update_listado]
      page.mensaje_informacion params[:update_listado], _("Se han eliminado correctamente todas las lineas de presupuesto del empleado ") + @empleado.nombre      
      page.replace "suma_" + @empleado.id.to_s, :partial => "suma", :locals => {:empleado => @empleado }
      page.replace "caja_suma_total_fin", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_fin"}
    end    
  end

  def gastos_marcados_empleado
    tipo_marcado = Marcado.find_by_nombre "Error dato empleado"
    etapa = Etapa.find_by_id session[:presupuesto_empleado_etapa]			
    rango_fechas = etapa.fecha_inicio..etapa.fecha_fin 
    condiciones = {"empleado_id" => params[:empleado_id], "fecha" => rango_fechas, "marcado_id" => tipo_marcado.id}
    @gastos = Gasto.where(condiciones)
    render(:update) do |page|
      page.replace_html params[:update], :partial => "gastos_empleado",:locals =>{ :update_listado => params[:update]}
    end
  end

  def gastos_relacionados_presupuesto
    presupuesto = Presupuesto.find_by_id params[:presupuesto_id]
    fechas = presupuesto.presupuesto_detallado.first
    rango_fechas = fechas.fecha_inicio..fechas.fecha_fin 
    condiciones = {"empleado_id" => presupuesto.empleado_id, "fecha" => rango_fechas, "partida_id" => presupuesto.partida_id,
                   "subpartida_agente_id" => presupuesto.subpartida_id }
    @gastos = Gasto.where(condiciones)
    render(:update) do |page|
      page.replace_html params[:update], :partial => "gastos_empleado",:locals =>{ :update_listado => params[:update]}
    end
  end

  private
  def datos_formulario
    @etapa = Etapa.find_by_id(session[:presupuesto_empleado_etapa])
    @moneda = @agente.moneda_principal
    @meses = []
    # Ponemos todos los meses de la etapa
    fecha_mes = @etapa.fecha_inicio
    for mes in 1..@etapa.periodos
      @meses.push [ I18n.l(fecha_mes, :format => "%B %y") , mes]
      fecha_mes = fecha_mes >> 1
    end
    @partidas = Partida.where(ocultar_agente: false, tipo_empleado: true).order(:codigo).collect {|a| [a.codigo_nombre, a.id]}
    @agente_imputado = [@agente[:nombre], @agente[:id]]
    @proyectos_seleccionables = proyectos_seleccionables
  end

  def proyectos_seleccionables
    proyectos_seleccionables = @agente.proyectos_vinculados(Etapa.find_by_id(session[:presupuesto_empleado_etapa]))
    return proyectos_seleccionables ? ([["Imputado al agente", nil]] + proyectos_seleccionables.collect {|a|[a.nombre, a.id]}) : [["Imputado al agente", nil]]
  end

end
