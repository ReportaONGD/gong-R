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
# Controlador encargado de las vistas resumen comunes a agentes y proyectos.

class ResumenController < ApplicationController

  helper :resumen_proyecto

  before_filter :verificar_etapa


  def verificar_etapa
    if @agente && @agente.etapa.empty?
      msg_error _("Tiene que definir por lo menos una etapa para acceder a los informes")
      redirect_to :menu => :configuracion_agente, :controller => :datos_agente, :action => :etapas
    end
    if @proyecto && @proyecto.etapa.empty?
      msg_error _("Tiene que definir por lo menos una etapa para acceder a los informes")
      redirect_to :menu => :configuracion, :controller => :datos_proyecto, :action => :etapas
    end
  end

  
  # en agente: se redirecciona por defecto a presupuesto
  def index
    redirect_to :action => :proveedor
  end

  def proveedor
    @listado_moneda = (@proyecto || @agente).moneda.collect{|e| [e.nombre, e.id.to_s]}
    @listado_etapa = (@proyecto || @agente).etapa.collect{|e| [e.nombre, e.id]}
    # Hacemos la busqueda si se seleccionan los criterios
    estado_proveedor if params[:moneda]

    respond_to do |format|
      format.xls do
        nom_fich = "resumen_proveedores_" + (@proyecto || @agente).nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
      end
      format.html do
        render :template => "comunes/resumen_proveedores", :layout => (params[:sin_layout] ? false : true)
      end
    end
  end

  def estado_proveedor
    @fecha_de_inicio = fecha params["fecha_inicio"]
    @fecha_de_fin = fecha params["fecha_fin"]
    if params[:seleccion_fecha] == "etapa" && params[:etapa] && etapa = Etapa.find_by_id(params[:etapa])
      @fecha_de_inicio = etapa.fecha_inicio
      @fecha_de_fin = etapa.fecha_fin
    end
    @moneda = Moneda.find_by_id params[:moneda]

    aplica_tasa_cambio = @moneda.nil? || params[:tasa_cambio] == "1"
    abreviatura_moneda = aplica_tasa_cambio ? (@proyecto || @agente).moneda_principal.abreviatura : @moneda.abreviatura

    condiciones = {"gasto.fecha" => @fecha_de_inicio..@fecha_de_fin}
    condiciones["gasto.moneda_id"] = @moneda.id if @moneda
    # Hay que ver como ordenar...
    if @proyecto
      condiciones["gasto_x_proyecto.proyecto_id"] = @proyecto.id
      # Si el proyecto tiene configurada visibilidad limitada, exportamos tan solo los gastos de implementadores
      # asociados al usuario a no ser que el usuario sea un admin
      if @proyecto.ocultar_gastos_otras_delegaciones && !@proyecto.usuario_admin?(@usuario_identificado)
        agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado)
        condiciones["gasto.agente_id"] = agentes_permitidos
      end
      gastos=Gasto.joins(:gasto_x_proyecto).where(condiciones).group(:proveedor_id).sum("gasto_x_proyecto.importe") unless aplica_tasa_cambio
      gastos=GastoXProyecto.joins(:gasto).joins(:tasa_cambio_proyecto).where(condiciones).group(:proveedor_id).sum("gasto_x_proyecto.importe * tasa_cambio.tasa_cambio") if aplica_tasa_cambio
    else
      condiciones[:agente_id] = @agente.id
      gastos=Gasto.where(condiciones).group(:proveedor_id).sum(:importe) unless aplica_tasa_cambio
      gastos=Gasto.joins(:tasa_cambio_agente).where(condiciones).group(:proveedor_id).sum("importe * tasa_cambio.tasa_cambio") if aplica_tasa_cambio
    end
    # Prepara la salida de datos
    lineas = Array.new
    lineas.push( :cabecera => [ [_("NIF"),"2_3"], [_("Emisor"),"2"], [_("Importe"),"1_2_td"], ["","1_3"] ])
    otros_proveedores = nil
    i = 0
    gastos.each do |key,value|
      proveedor = Proveedor.find_by_id key
      detalle_gastos = { :url => {:action => "detalle_gastos_proveedor", :fecha_inicio => @fecha_de_inicio, :fecha_fin => @fecha_de_fin, :moneda => @moneda ? @moneda.id : nil, :proveedor_id => key, :update => "gasto_proveedor_" + (i+=1).to_s } }
      if proveedor.nil?
        otros_proveedores = {:contenido => [ "", _("NO DEFINIDO"), value, abreviatura_moneda ], :objeto_desplegado => detalle_gastos }
      else
        lineas.push( :contenido => [ proveedor.nif, proveedor.nombre, value, abreviatura_moneda ], :objeto_desplegado => detalle_gastos )
      end
    end 
    lineas.push( otros_proveedores ) if otros_proveedores

    # Recogemos todo en una tabla común
    titulo_datos =[ _("Moneda") + ": " + (@moneda ? @moneda.abreviatura :  _('Todas las monedas')) ,
               _("Tasa cambio") + ": " + (aplica_tasa_cambio ? _('Aplicada'): _('No aplicada')),
               _("Fechas") + ": " + @fecha_de_inicio.to_time.to_s + ' - ' + @fecha_de_fin.to_time.to_s ]
    titulo = [_("Resumen de Proveedores.")] + titulo_datos
    @resumen = [ :listado => { :nombre => _("Resumen de proveedores"), :titulo => titulo, :lineas => lineas } ]
  end

  def detalle_gastos_proveedor
    condiciones = {"gasto.fecha" => params[:fecha_inicio]..params[:fecha_fin]}
    condiciones["moneda_id"] = params[:moneda] if params[:moneda] 
    condiciones["proveedor_id"] = params[:proveedor_id]
    # Si estamos desde proyecto hacemos una busqueda distinta...
    if @proyecto
      condiciones["gasto_x_proyecto.proyecto_id"] = @proyecto.id
      # Si el proyecto tiene configurada visibilidad limitada, exportamos tan solo los gastos de implementadores
      # asociados al usuario a no ser que el usuario sea un admin
      if @proyecto.ocultar_gastos_otras_delegaciones && !@proyecto.usuario_admin?(@usuario_identificado)
        agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado)
        condiciones["gasto.agente_id"] = agentes_permitidos
      end
      gastos=Gasto.joins(:gasto_x_proyecto).where(condiciones).uniq.order(:fecha).
                   paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                            per_page: (params[:format_xls_count] || session[:por_pagina]))
    # ... a cuando estamos desde agente...
    else
      condiciones[:agente_id] = @agente.id
      gastos=Gasto.where(condiciones).order(:fecha).
                   paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                            per_page: (params[:format_xls_count] || session[:por_pagina]))
    end

    @formato_xls = gastos.total_entries
    respond_to do |format|
      format.html do
        render(:update) { |page|  page.replace_html(params[:update], :partial => "comunes/resumen_gastos_proveedores", :locals => {:gastos => gastos}) }
      end
      format.xls do
        @tipo = @proyecto ? "gasto" : "gasto_agentes"
        @objetos = gastos
        nom_fich = "gastos_proveedor_" + (@proyecto||@agente).nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end
end
