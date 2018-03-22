# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2015 Free Software's Seed
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


class IngresoController < ApplicationController

  def index
    redirect_to :action => :listado 
  end

  # en agentes: establece los parametros de ordenación
  def ordenado
    session[:ingreso_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    session[:ingreso_orden] = params[:orden] ? params[:orden] : "fecha"
    redirect_to :action => :listado
  end

  # en agentes: establece los parametros de filtro
  def filtrado
    session[:ingreso_filtro_etapa] = params[:filtro][:etapa] if params[:filtro][:etapa]
    session[:ingreso_filtro_partida] = params[:filtro][:partida] if params[:filtro][:partida]
    session[:ingreso_filtro_proyecto] = params[:filtro][:proyecto] if params[:filtro][:proyecto]
    session[:ingreso_filtro_marcado] = params[:filtro][:marcado] if params[:filtro][:marcado]
    session[:ingreso_filtro_ref_contable] = params[:filtro][:ref_contable] if params[:filtro][:ref_contable]
    session[:ingreso_filtro_aplicar_fecha] = params[:filtro][:aplicar_fecha] == "1" ? true : false
    if session[:ingreso_filtro_aplicar_fecha]
      session[:ingreso_filtro_inicio]= Date.new params[:filtro]["inicio(1i)"].to_i ,params[:filtro]["inicio(2i)"].to_i ,params[:filtro]["inicio(3i)"].to_i
      session[:ingreso_filtro_final]= Date.new params[:filtro]["final(1i)"].to_i ,params[:filtro]["final(2i)"].to_i ,params[:filtro]["final(3i)"].to_i
    else
      session[:ingreso_filtro_inicio], session[:ingreso_filtro_final] = nil, nil
    end
    redirect_to :action => :listado
  end

  def elementos_filtrado
    session[:ingreso_asc_desc] ||= "ASC"
    session[:ingreso_orden] ||= "fecha"
    session[:ingreso_filtro_partida] ||= "todas"
    session[:ingreso_filtro_proyecto] ||= "todos"
    session[:ingreso_filtro_etapa] ||= "todas"
    session[:ingreso_filtro_marcado] ||= "todos"
    session[:ingreso_filtro_ref_contable] ||= ""
    session[:ingreso_filtro_inicio] ||= nil
    session[:ingreso_filtro_final] ||= nil
    session[:ingreso_filtro_aplicar_fecha] ||= false

    @etapa = @agente.etapa.find_by_id( session[:ingreso_filtro_etapa] )
    @partida = PartidaIngreso.find_by_id( session[:ingreso_filtro_partida] )
    marcado = Marcado.find_by_id( session[:ingreso_filtro_marcado] )

    texto_proyectos = if session[:ingreso_filtro_proyecto] == "todos"
                        _("Todos los proyectos")
                      elsif session[:ingreso_filtro_proyecto] == "no vinculado"
                        _("No vinculado a proyectos")
                      else
                        Proyecto.find_by_id(session[:ingreso_filtro_proyecto]).nombre
                      end

    datos_formulario
    filtro_etapa = [[_("Todas"), "todas"]] + @agente.etapa.order(:fecha_inicio).collect{|p| [p.nombre, p.id]} 
    filtro_partida = [[_("Todas"), "todas"]] + PartidaIngreso.order(:nombre).collect{|t| [t.nombre, t.id]}
    filtro_proyecto = [[_("Todos"), "todos"],[_("No vinculado a proyectos"), "ninguno"]] + @agente.proyecto_implementador.collect{ |e| [e.nombre, e.id.to_s]}
    filtro_marcado = [[_("Todos"), "todos"]] + Marcado.all(:order => "nombre").collect{ |e| [e.nombre, e.id.to_s] }
    
    @opciones_filtrado = [ {rotulo: _("Seleccione etapa"), nombre: "etapa", opciones: filtro_etapa},
                           {rotulo: _("Seleccione partida"), nombre: "partida", opciones: filtro_partida},
                           {rotulo: _("Seleccione proyecto"), nombre: "proyecto", opciones: filtro_proyecto},
                           {rotulo: _("Seleccione marcado"), nombre: "marcado", opciones: filtro_marcado},
                           {rotulo: _("Seleccione ref.contable"), nombre: "ref_contable", tipo: "texto"} ]
    @opciones_filtrado += [ {:rotulo =>  _("Fecha inicio"), :nombre => "inicio", :tipo => "calendario"},
                            {:rotulo =>  _("Fecha fin"), :nombre => "final", :tipo => "calendario"},
                            {:rotulo =>  _("Aplicar filtro fecha") + ": ", :nombre => "aplicar_fecha", :tipo => "checkbox"} ]
    @accion_filtrado = {:action => :filtrado, :listado => :listado}
    @estado_filtrado = [  (@etapa ? @etapa.nombre : _("Todas las etapas")),
                          (@partida ? @partida.nombre : _("Todas las partidas de ingreso")),
                          (marcado ? marcado.nombre : _("Sin filtro de marcado")),
                          texto_proyectos, 
                       ]
  end


	# en agentes: lista los ingresos
  def listado
    elementos_filtrado
    (condiciones, condiciones_ref_contable) = condiciones_listado

    @ingresos = @paginado = @agente.ingreso.where(condiciones_ref_contable).
                                            where(condiciones).
                                            order(session[:ingreso_orden] + " " + session[:ingreso_asc_desc]).
                                            paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                                     per_page: (params[:format_xls_count] || session[:por_pagina]))

    @formato_xls = @ingresos.total_entries
    @listado_mas_info = {:action => 'suma_total_listado'}

    respond_to do |format|
      format.html
      format.xls do
        @tipo = "ingreso"
        @objetos = @ingresos
        nom_fich = "ingresos_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

  # prepara el popup con informacion del importe total de los ingresos mostrados
  def suma_total_listado
    elementos_filtrado
    (condiciones, condiciones_ref_contable) = condiciones_listado
    ingresos = @agente.ingreso.where(condiciones_ref_contable).where(condiciones)
    numero_elementos = ingresos.count
    suma_total = ingresos.joins(:tasa_cambio).sum("importe*tasa_cambio")
    suma_total_formateada = float_a_moneda(suma_total)
    render :update do |page|
      texto_mensaje = _("%{num} ingresos con un importe total (aplicando tasas de cambio) de %{val} %{mon}")%{:num => numero_elementos, :val => suma_total_formateada, :mon => @agente.moneda_principal.abreviatura}
      page.insert_html :after, "cabecera",:inline => mensaje_advertencia(:identificador => "info_listado", :texto => texto_mensaje)
      page.call('Element.show("info_listado_borrado")')
    end
  end

	# en convocatorias: prepara el formulario de crear o editar
  def editar_nuevo
    @ingreso = @agente.ingreso.find_by_id(params[:id]) || Ingreso.new(agente_id: @agente.id)
    datos_formulario
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

	# en agentes: modifica o crea un proveedor
  def modificar_crear
    @ingreso = @agente.ingreso.find_by_id(params[:id]) || Ingreso.new(agente_id: @agente.id)
    @ingreso.update_attributes params[:ingreso]
    if @ingreso.errors.empty?
      # Si es uno ya existente, modifica la linea
      render(:update) { |page|   page.modificar :update => params[:update], :partial => "ingreso" , :mensaje => { :errors => @ingreso.errors } } if params[:id]
      # Si es uno nuevo lo incluye en la parte superior del listado
      render :update do |page|
        page.show "nuevos_ingresos"
        page.modificar :update => "ingreso_nuevo_" + params[:i], :partial => "nuevo_ingreso", :mensaje => { :errors => @ingreso.errors }
        page.replace "formulario_anadir_anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>" unless params[:id]
      end unless params[:id] 
    else
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @ingreso.errors} }
    end 
  end

	# en agentes: elimina un proveedor
  def eliminar
    @ingreso = @agente.ingreso.find_by_id(params[:id])
    @ingreso.destroy if @ingreso
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @ingreso.errors, :eliminar => true}}
  end

 private

  # Obtiene los filtros a implementar en el listado
  def condiciones_listado
    condiciones = {}
    if session[:ingreso_filtro_aplicar_fecha] && (session[:ingreso_filtro_inicio] <= session[:ingreso_filtro_final])
      condiciones[:fecha] = session[:ingreso_filtro_inicio]..session[:ingreso_filtro_final]
    elsif @etapa
      condiciones[:fecha] = @etapa.fecha_inicio..@etapa.fecha_fin
    end
    condiciones[:partida_ingreso_id] = @partida.id if @partida
    condiciones[:proyecto_id] = session[:ingreso_filtro_proyecto] unless session[:ingreso_filtro_proyecto] == "todos" || session[:ingreso_filtro_proyecto] == "ninguno"
    condiciones[:proyecto_id] = nil if session[:ingreso_filtro_proyecto] == "ninguno"
    condiciones[:marcado_id] = session[:ingreso_filtro_marcado] unless session[:ingreso_filtro_marcado] == "todos"
    condiciones_ref_contable = nil if session[:ingreso_filtro_ref_contable].blank?
    condiciones_ref_contable = ["ref_contable LIKE ?", session[:ingreso_filtro_ref_contable]] unless session[:ingreso_filtro_ref_contable].blank?

    return condiciones, condiciones_ref_contable
  end

  # Datos necesarios para los formularios
  def datos_formulario
    @partidas = PartidaIngreso.order("nombre").collect{|p| [p.nombre, p.id.to_s]}
    @monedas = @agente.moneda.collect {|a| [a.abreviatura, a.id]}
    @financiadores = Agente.where(financiador: true).order("nombre").collect{|f| [f.nombre, f.id.to_s]}
    @proyectos = @agente.proyecto_implementador.collect{|f| [f.nombre, f.id.to_s]}
  end

end

