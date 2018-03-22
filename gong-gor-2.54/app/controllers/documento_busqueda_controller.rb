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
# Controlador encargado de la gestión de los documentos.
# Este controlador es utilizado desde las secciones:
# * Sección proyectos: se utiliza para listar, comentar, subir y descargar documentos
# * Sección financiaciones: se utiliza para listar, comentar, subir y descargar documentos
class DocumentoBusquedaController < ApplicationController


	# en proyectos y en financiación: se redirecciona por defecto a ordenado
  def index
    #session[:documento_filtro] = etiqueta_todos 
    redirect_to :action => "ordenado"
  end

#--
# FILTRADO DE DOCUMENTOS
#++

  # Hace un filtrado segun las etiquetas que tengamos seleccionadas
  def filtrado
    # Primero vaciamos la variable del filtros (hay una por seccion)
    session[("filtro_etiquetas_" + params[:seccion]).to_sym] = []
    # Incluimos el valor del selector si hay algo seleccionado 
    session[("filtro_etiquetas_" + params[:seccion]).to_sym] << params[:selector][:etiqueta_nueva] if params[:selector][:etiqueta_nueva].to_i != 0
    # Vamos incluyendo las etiquetas seleccionadas previamente
    if params[:filtro_etiqueta]
      params[:filtro_etiqueta].each_value do |id|
        session[("filtro_etiquetas_" + params[:seccion]).to_sym] << id if id != "" && id.to_i > 0
      end 
    end
    redirect_to :action => :listado
  end

  # Incluye la etiqueta seleccionada para poder filtrar
  def anadir_filtro
    etiquetas_filtrado
    render :update do |page|
      page.replace_html params[:update], :partial => "elemento_filtrado", :locals => { :indice => params[:indice].to_i, :valor => params[:selector][:etiqueta_nueva], :ultimo => true }
    end
  end

  # Elimina la etiqueta seleccionada de las elegidas para filtrar
  def quitar_filtro
    render :update do |page|
      page.replace_html params[:update], :inline => ''
    end
  end

	# en proyectos y agentes: filtrado de documentos relacionados (transferencias, gastos)
  def filtrado_relacionados
    session[:documento_busqueda_filtro_etapa_relacionada] = params[:filtro][:etapa_relacionada]
    session[:documento_busqueda_filtro_aplicar_fecha] = params[:filtro][:aplicar_fecha]
    if session[:documento_busqueda_filtro_aplicar_fecha]
      session[:documento_busqueda_filtro_inicio]= Date.new params[:filtro]["inicio(1i)"].to_i ,params[:filtro]["inicio(2i)"].to_i ,params[:filtro]["inicio(3i)"].to_i
      session[:documento_busqueda_filtro_final]= Date.new params[:filtro]["final(1i)"].to_i ,params[:filtro]["final(2i)"].to_i ,params[:filtro]["final(3i)"].to_i
    else
      session[:documento_busqueda_filtro_inicio], session[:documento_busqueda_filtro_final] = nil, nil
    end

    redirect_to :action => params[:listado]
  end

	# en proyectos y en financiación: establece los parametros de ordenación
  def ordenado
    session[:documento_busqueda_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC" 
    session[:documento_busqueda_orden] = params[:orden] ? params[:orden] : "adjunto_file_name" 
    redirect_to :action => "listado"
  end


#--
# LISTADOS DE DOCUMENTOS
#++

	# en proyectos y en financiación: lista los documentos disponibles
  def listado
   # Establece las condiciones para la busqueda de documentos segun sea de proyecto o global
    condiciones_proyecto = ( @proyecto ? "documento.proyecto_id = " + @proyecto.id.to_s : "" )
   # Si tiene pacs (es un convenio) incluye en la busqueda los documentos de estos
    @proyecto.pacs.each do |pac|
      condiciones_proyecto += " OR documento.proyecto_id = " + pac.id.to_s
    end if @proyecto
    condiciones_proyecto = "( " + condiciones_proyecto + " )" if condiciones_proyecto
    # Hace la busqueda de documentos segun tengamos filtros o no
    if session[("filtro_etiquetas_" + params[:seccion]).to_sym] and session[("filtro_etiquetas_" + params[:seccion]).to_sym].length > 0
      condicion_filtros = (params[:seccion] == "proyectos" ? condiciones_proyecto + " AND " : "") + "etiqueta_x_documento.etiqueta_id IN (?)", session[("filtro_etiquetas_" + params[:seccion]).to_sym]
      @documentos = Documento.joins(:etiqueta_x_documento).
                              joins(:usuario).
                              where(condicion_filtros).
                              order(session[:documento_busqueda_orden] + " " + session[:documento_busqueda_asc_desc]).
                              paginate(page: params[:page], per_page: (session[:por_pagina] or 20))
    else
      condicion_filtros = condiciones_proyecto if params[:seccion] == "proyectos"
      #condicion_filtros = "etiqueta.nombre LIKE ?", _("Exportacion") + " %" if params[:seccion] == "administracion"
      condicion_filtros = nil if condicion_filtros == "(  )" # Chapucilla por un error cuando las condiciones estan vacias

      @documentos = Documento.includes(["etiqueta_x_documento"]).
                              joins(:usuario).
                              where(condicion_filtros).
                              order(session[:documento_busqueda_orden] + " " + session[:documento_busqueda_asc_desc] ).
                              paginate(page: params[:page], per_page: session[:por_pagina])
    end
    etiquetas_filtrado
  end

	# Listado de documentos vinculados a gastos
  def listado_gastos
    session[:documento_busqueda_filtro_etapa_relacionada] ||= "todas"

    joins =  "LEFT JOIN gasto_x_documento  ON gasto_x_documento.documento_id = documento.id LEFT 
              JOIN gasto ON gasto.id = gasto_x_documento.gasto_id LEFT JOIN gasto_x_proyecto ON gasto_x_proyecto.gasto_id = gasto.id "
    # Ponemos las condiciiones en funcion de estar en la seccion de agentes o proyectos.
    condiciones =  params[:seccion] == "proyectos" ? {"gasto_x_proyecto.proyecto_id" => @proyecto.id} : {"gasto.agente_id" => @agente.id}

    if session[:documento_busqueda_filtro_aplicar_fecha] and  (session[:documento_busqueda_filtro_inicio] < session[:documento_busqueda_filtro_final])
      condiciones["gasto.fecha"] = session[:documento_busqueda_filtro_inicio]..session[:documento_busqueda_filtro_final]
    elsif  session[:documento_busqueda_filtro_etapa_relacionada] != "todas"
      @etapa_relacionada = Etapa.find( session[:documentos_relacionados_filtro_etapa] )
      condiciones["gasto.fecha"] = @etapa_relacionada.fecha_inicio..@etapa_relacionada.fecha_fin
    end

    # Ojo, hay errores en los logs del tipo:
    # NoMethodError (undefined method `+' for nil:NilClass):
    #   app/controllers/documento_busqueda_controller.rb:137:in `listado_gastos' 
    @documentos = @paginado = Documento.joins(joins).
                                        includes(:gasto).
                                        where(condiciones).
                                        order("adjunto_file_name").
                                        paginate(page: params[:page], per_page: session[:por_pagina])

    @accion_filtrado = {:action => :filtrado_relacionados, :listado => :listado_gastos}
    filtro_etapa = [["Todas","todas"]] +   eval( "@" + singularizar_seccion ).etapa.sort{ |a, b| a.fecha_inicio <=> b.fecha_inicio }.collect{ |e| [e.nombre, e.id] }
    @opciones_filtrado = [	{:rotulo =>  _("Seleccione etapa") + ": ", :nombre => "etapa_relacionada", :opciones => filtro_etapa},
				{:rotulo =>  _("Fecha inicio") + ": ", :nombre => "inicio", :tipo => "calendario"},
				{:rotulo =>  _("Fecha fin") + ": ", :nombre => "final", :tipo => "calendario"},
				{:rotulo =>  _("Aplicar filtro fecha") + ": ", :nombre => "aplicar_fecha", :tipo => "checkbox"}]

    render :action => "listado_relacionados" 
  end

	# Listado de documentos vinculados a transferencias
  def listado_transferencias
    session[:documento_busqueda_filtro_etapa_relacionada] ||= "todas"

    # Ponemos las condiciones en funcion de estar en la seccion de agentes o proyectos.
    condiciones = "transferencia_x_documento.transferencia_id IN (" + (@proyecto||@agente).transferencia.inject([]){|a,t| a.push(t.id)}.join(",") + ")" unless (@proyecto||@agente).transferencia.empty?
    condiciones = "FALSE" if (@proyecto||@agente).transferencia.empty?

    if session[:documento_busqueda_filtro_aplicar_fecha] and  (session[:documento_busqueda_filtro_inicio] < session[:documento_busqueda_filtro_final])
      condiciones += " AND ( (transferencia.fecha_enviado >= '" + session[:documento_busqueda_filtro_inicio].to_s + 
			"' AND transferencia.fecha_enviado <= '" + session[:documento_busqueda_filtro_final].to_s + "')" +
                     "   OR  (transferencia.fecha_recibido >= '" + session[:documento_busqueda_filtro_final].to_s + 
			"' AND transferencia.fecha_recibido <= '" + session[:documento_busqueda_filtro_final].to_s + "') )"
    elsif  session[:documento_busqueda_filtro_etapa_relacionada] != "todas"
      @etapa_relacionada = Etapa.find( session[:documento_busqueda_filtro_etapa_relacionada] )
      condiciones += " AND ( (transferencia.fecha_enviado >= '" + @etapa_relacionada.fecha_inicio.to_s + 
			"' AND transferencia.fecha_enviado <= '" + @etapa_relacionada.fecha_fin.to_s + "')" +
                     "   OR  (transferencia.fecha_recibido >= '" + @etapa_relacionada.fecha_inicio.to_s +
			"' AND transferencia.fecha_recibido <= '" + @etapa_relacionada.fecha_fin.to_s + "') )"
    end

    @documentos = @paginado = Documento.includes([:transferencia_x_documento, :transferencia]).
                                        where(condiciones).
                                        order("adjunto_file_name").
                                        paginate(page: params[:page], per_page: session[:por_pagina])

    @accion_filtrado = {:action => :filtrado_relacionados, :listado => :listado_transferencias}
    filtro_etapa = [["Todas","todas"]] +   eval( "@" + singularizar_seccion ).etapa.sort{ |a, b| a.fecha_inicio <=> b.fecha_inicio }.collect{ |e| [e.nombre, e.id] }
    @opciones_filtrado = [      {:rotulo =>  _("Seleccione etapa") + ": ", :nombre => "etapa_relacionada", :opciones => filtro_etapa},
                                {:rotulo =>  _("Fecha inicio") + ": ", :nombre => "inicio", :tipo => "calendario"},
                                {:rotulo =>  _("Fecha fin") + ": ", :nombre => "final", :tipo => "calendario"},
                                {:rotulo =>  _("Aplicar filtro fecha") + ": ", :nombre => "aplicar_fecha", :tipo => "checkbox"}]

    render :action => "listado_relacionados" 
  end


#--
# ETIQUETAS PARA FILTRADO
#++


    # Devuelve el conjunto de etiquetas valido para la seccion en la que estamos
    def etiquetas_filtrado
      condiciones_etiqueta = ""
      condiciones_etiqueta = "etiqueta.nombre LIKE ?", _("Exportación") + " %" if params[:seccion] == "administracion"
      condiciones_etiqueta = "etiqueta.tipo = 'proyecto'" if params[:seccion] == "proyectos"
      @etiquetas = Etiqueta.find( :all, :conditions => condiciones_etiqueta ).collect{ |e| [e.nombre, e.id] }.sort{ |a, b| a[0] <=> b[0]}
    end




end
