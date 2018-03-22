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
# Controlador encargado de la gestión de agente. Este controlador es utilizado desde las secciones:
# * Sección administración: se utiliza para crear agentes y asignarles usuarios.
# * Sección agentes: se utiliza para seleccionar el agente

class AgenteController < ApplicationController
  # en administracion: se redirecciona por defecto a ordenado
  def index
    redirect_to :action => "listado" if params[:seccion] == "administracion"
    redirect_to :action => "listado_usuario" if params[:seccion] == "agentes"
  end

  # Condiciones para listados segun el filtro
  def filtrado_condiciones
    session[:agente_asc_desc] ||= "ASC"
    session[:agente_orden] ||= "nombre"
    session[:agente_filtro_pais] ||= []
    session[:agente_filtro_nombre] ||= ""
    session[:agente_filtro_tipo] ||= "todos"
    session[:agente_filtro_financiador] ||= "todos"
    session[:agente_filtro_implementador] ||= "todos"

    condiciones  = " NOT sistema"
    condiciones += " AND agente.pais_id IN (" + session[:agente_filtro_pais].join(",") + ")" unless session[:agente_filtro_pais].blank?
    # Ojo!... tenemos que sanear esto para evitar inyecciones sql. Hay alguna otra forma menos retorcida?
    condiciones += " AND agente.nombre LIKE " + ActiveRecord::Base.connection.quote(session[:agente_filtro_nombre]) unless session[:agente_filtro_nombre].blank?
    condiciones += " AND tipo_agente_id = " + session[:agente_filtro_tipo] unless session[:agente_filtro_tipo] == "todos"
    condiciones += " AND financiador IS TRUE" if session[:agente_filtro_financiador] == "true"
    condiciones += " AND financiador IS NOT TRUE" if session[:agente_filtro_financiador] == "false" 
    condiciones += " AND implementador IS TRUE" if session[:agente_filtro_implementador] == "true"
    condiciones += " AND implementador IS NOT TRUE" if session[:agente_filtro_implementador] == "false" 
    @condiciones = condiciones

    paises = Pais.order("nombre").collect {|p| [p.nombre, p.id.to_s]}
    tipos = [[_("Todos"), "todos"]] + TipoAgente.order("nombre").collect {|t| [t.nombre, t.id.to_s]}
    financiador = [["Todos", "todos"], [_("Sólo financiadores"), "true"], [_("Sólo NO financiadores"), "false"]]
    implementador = [["Todos", "todos"], [_("Sólo implementadores"), "true"], [_("Sólo NO implementadores"), "false"]]

    @opciones_filtrado  = [     {:rotulo => _("Seleccione Nombre"), :nombre => "nombre", :tipo => "texto"},
                                {:rotulo => _("Seleccione Países"), :nombre => "pais", :opciones =>  paises, :tipo => "multiple"},
                                {:rotulo => _("Seleccione Tipo"), :nombre => "tipo", :opciones => tipos},
                                {:rotulo => _("Financiador"), :nombre => "financiador", :opciones => financiador},
                          ]
    @opciones_filtrado += [     {:rotulo => _("Implementador"), :nombre => "implementador", :opciones => implementador}
                          ] if params[:seccion] == "administracion"

    @accion_filtrado = {:action => :filtrado }
  end

  # en administracion: lista las agentes que hay en el sistema
  def listado
    filtrado_condiciones
    @agentes = @paginado = Agente.where(@condiciones).
                                  order(session[:agente_orden] + " " + session[:agente_asc_desc]).
                                  paginate(:page => params[:page], :per_page => (session[:por_pagina]))
  end

  # en administracion o en agentes: establece los parametros de ordenación
  def ordenado
    session[:agente_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"   
    session[:agente_orden] = params[:orden] ? params[:orden] : "nombre" 
    redirect_to :action => "listado" if params[:seccion] == "administracion"
    redirect_to :action => "listado_usuario" if params[:seccion] == "agentes"
  end

  # Condiciones de filtrado del listado de agente
  def filtrado
    if params[:filtro]
      session[:agente_filtro_pais] = params[:filtro][:pais].reject!(&:blank?) if params[:filtro][:pais].class.name == "Array"
      session[:agente_filtro_nombre] = params[:filtro][:nombre]
      session[:agente_filtro_tipo] = params[:filtro][:tipo]
      session[:agente_filtro_financiador] = params[:filtro][:financiador]
      session[:agente_filtro_implementador] = params[:filtro][:implementador]
    end
    redirect_to :action => "listado" if params[:seccion] == "administracion"
    redirect_to :action => "listado_usuario" if params[:seccion] == "agentes"
  end
 
  # en administracion: prepara el formulario de edición o creación
  def editar_nuevo
    @agente = Agente.find_by_id params[:id]
    # Recogemos otros financiadores que tengan un mapeo contable hecho para poder copiarselo
    @otros_financiadores = Agente.where(financiador: true).joins(:partida_financiacion).where("partida_financiacion.proyecto_id IS NULL").uniq.order(:nombre)
    @otros_financiadores -= [@agente] if @agente && @agente.financiador
    @paises = Pais.order(:nombre).collect {|p| [p.nombre, p.id]}
    @monedas = Moneda.order(:nombre).collect {|p| [p.nombre, p.id]}
    @tipos_agente = TipoAgente.order(:nombre).collect {|t| [t.nombre, t.id]}
    render :partial => "formulario"
  end

  # en administracion: modifica o crea
  def modificar_crear
    @agente = Agente.find_by_id(params[:id]) || Agente.new 
    @agente.update_attributes params[:agente]
    if @agente.errors.empty? && @agente.implementador && params[:selector] && params[:selector][:generar_cuentas] == "1"
      @agente.generar_cuentas
    end
    if @agente.errors.empty? && @agente.financiador && params[:selector] && params[:selector][:copiar_mapeo] != ""
      agente_copiar = Agente.where(financiador: true).find_by_id params[:selector][:copiar_mapeo]
      @agente.copiar_mapeo_desde(agente_copiar) unless agente_copiar.nil? || agente_copiar.partida_financiacion.where(proyecto_id: nil).empty?
    end
    msg @agente
    redirect_to :action => "listado"
  end

  # en administracion: elimina
  def eliminar
    @agente = Agente.find_by_id(params[:id])
    @agente.destroy
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @agente.errors, :eliminar => true}}
  end

  # en agentes: lista los agentes asociados al usuario declarado en la sessión
  def listado_usuario
    filtrado_condiciones
    @agentes = @paginado = @usuario_identificado.agente.
                                   where(socia_local: false, implementador: true).
                                   where(@condiciones).
                                   order(session[:agente_orden] + " " + session[:agente_asc_desc] ).
                                   paginate(:page => params[:page], :per_page => (session[:por_pagina]))
  end

end
