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


class ProveedorController < ApplicationController

  def index
    redirect_to :action => :listado 
  end

  # en agentes: establece los parametros de ordenación
  def ordenado
    session[:proveedor_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    session[:proveedor_orden] = params[:orden] ? params[:orden] : "nombre"
    redirect_to :action => :listado
  end

  # Establece los parametros del filtro
  def filtrado
    if params[:filtro]
      session[:proveedor_filtro_pais] = params[:filtro][:pais]
      session[:proveedor_filtro_nombre] = params[:filtro][:nombre]
      session[:proveedor_filtro_nif] = params[:filtro][:nif]
    end
    redirect_to action: :listado
  end
 
  def elementos_filtrado
    session[:proveedor_asc_desc] ||= "ASC"
    session[:proveedor_orden] ||= "nombre"
    session[:proveedor_filtro_pais] ||= "todos"
    session[:proveedor_filtro_nombre] ||= ""
    session[:proveedor_filtro_nif] ||= ""

    @pais = Pais.find_by_id( session[:proveedor_filtro_pais] ) unless session[:proveedor_filtro_pais] == "todos"

    datos_formulario
    filtro_pais = [[_("Todos"),"todos"]] + Pais.order(:nombre).collect{|p| [p.nombre, p.id]} 
    
    @opciones_filtrado = [ {:rotulo => _("Seleccione Nombre"), :nombre => "nombre", :tipo => "texto"},
                           {:rotulo => _("Seleccione NIF"), :nombre => "nif", :tipo => "texto"},
                           {:rotulo => _("Seleccione país"), :nombre => "pais", :opciones => filtro_pais} ]
    @accion_filtrado = {:action => :filtrado, :listado => :listado}
    @estado_filtrado = [ (@pais ? @pais.nombre : _("Todos los paises")) ]
  end


	# en agentes: lista los proveedores
  def listado
    elementos_filtrado 
    condiciones = {} 
    condiciones[:pais_id] = @pais.id if @pais
    condiciones[:agente_id] = @agente.id if @agente
    condiciones_likes = []
    condiciones_likes.push "nombre LIKE %s"%[ActiveRecord::Base.connection.quote(session[:proveedor_filtro_nombre])] unless session[:proveedor_filtro_nombre].blank?
    condiciones_likes.push "nif LIKE %s"%[ActiveRecord::Base.connection.quote(session[:proveedor_filtro_nif])] unless session[:proveedor_filtro_nif].blank?

    @proveedores = @paginado = Proveedor.where(condiciones_likes.join(" AND ")).
                                         where(condiciones).
                                         order(session[:proveedor_orden] + " " + session[:proveedor_asc_desc]).
		                         paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                                  per_page: (params[:format_xls_count] || session[:por_pagina]))

    @formato_xls = @proveedores.total_entries
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "proveedor"
        @objetos = @proveedores
        nom_fich = "proveedores_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

	# en convocatorias: prepara el formulario de crear o editar
  def editar_nuevo
    @proveedor = @agente.proveedor.find_by_id(params[:id]) || Proveedor.new(agente_id: @agente.id)
    datos_formulario
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

	# en agentes: modifica o crea un proveedor
  def modificar_crear
    @proveedor = @agente.proveedor.find_by_id(params[:id]) || Proveedor.new(agente_id: @agente.id)
    @proveedor.update_attributes params[:proveedor]
    if @proveedor.errors.empty?
      # Si es uno ya existente, modifica la linea
      render(:update) { |page|   page.modificar :update => params[:update], :partial => "proveedor" , :mensaje => { :errors => @proveedor.errors } } if params[:id]
      # Si es uno nuevo lo incluye en la parte superior del listado
      render :update do |page|
        page.show "nuevos_proveedores"
        page.modificar :update => "proveedor_nuevo_" + params[:i], :partial => "nuevo_proveedor", :mensaje => { :errors => @proveedor.errors }
        page.replace "formulario_anadir_anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>" unless params[:id]
      end unless params[:id] 
    else
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @proveedor.errors} }
    end 
  end

	# en agentes: elimina un proveedor
  def eliminar
    @proveedor = @agente.proveedor.find_by_id(params[:id])
    @proveedor.destroy if @proveedor
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @proveedor.errors, :eliminar => true}}
  end

 private
  def datos_formulario
    @paises = Pais.order("nombre").collect{|p| [p.nombre, p.id]}
  end

end

