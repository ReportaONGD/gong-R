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


class SubpartidaController < ApplicationController

 # --
 ########## SUBPARTIDAS ##########
 # ++

  def index
    redirect_to :action => :filtrado_ordenado_iniciales 
  end

  # en proyectos y en agente: inicializa los defectos para ordenado y filtro y redirecciona a listado
  def filtrado_ordenado_iniciales
    session[:subpartida_asc_desc] ||= "ASC"
    session[:subpartida_orden] = "nombre"
    session[:subpartida_filtro_partida] ||= "todas"
    redirect_to :action => :listado
  end

  # en proyectos y agentes: establece los parametros de ordenación
  def ordenado
    session[:subpartida_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    session[:subpartida_orden] = params[:orden] || "nombre"
    redirect_to :action => "listado"
  end

  # en proyectos y agentes: establece los parametros de filtro
  def filtrado
    session[:subpartida_filtro_partida] = params[:filtro][:partida]
    redirect_to :action => :listado
  end

  def elementos_filtrado
    partidas
    @partida = Partida.find_by_id( session[:subpartida_filtro_partida] ) unless session[:subpartida_filtro_partida] == "todas"

    filtro_partida = [[_("Todas"),"todas"]] + @partidas
    
    @opciones_filtrado = [{:rotulo =>  _("Seleccione partida"), :nombre => "partida", :opciones => filtro_partida} ]
    @accion_filtrado = {:action => :filtrado, :listado => :listado}
    @estado_filtrado = [ (@partida ? @partida.codigo_nombre : _("Cualquier partida")) ]
  end


	# en proyectos y agentes: lista las partidas y subpartidas relacionadas
  def listado 
    elementos_filtrado
   
    condiciones = {} 
    condiciones[:partida_id] = @partida.id if @partida

    @subpartidas = @paginado =  (@proyecto || @agente).subpartida.
                                                       includes(["partida"]).
                                                       where(condiciones).
                                                       order(session[:subpartida_orden] + " " + session[:subpartida_asc_desc]).
                                                       paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                                                per_page: (params[:format_xls_count] || session[:por_pagina]))
    
    @formato_xls = @subpartidas.total_entries
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "subpartida"
        @objetos = @subpartidas
        nom_fich = "subpartidas_" + (@proyecto||@agente).nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

	# en proyectos y agentes: crea o edita una nueva subpartida
  def editar_nuevo
    @subpartida = (@proyecto || @agente).subpartida.find_by_id(params[:id]) || Subpartida.new
    partidas
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

	# en proyectos y agentes: modifica o crea una subpartida 
  def modificar_crear
    @subpartida = (@proyecto || @agente).subpartida.find_by_id(params[:id]) || (@proyecto || @agente).subpartida.new()
    @subpartida.update_attributes params[:subpartida]
    if @subpartida.errors.empty?
      render(:update) { |page|   page.modificar :update => params[:update], :partial => "subpartida" , :mensaje => { :errors => @subpartida.errors } } if params[:id]
      # Si es una nueva subpartida
        render :update do |page|
          page.show "nuevas_subpartidas"
          page.modificar :update => "subpartida_nueva_" + params[:i], :partial => "nueva_subpartida", :mensaje => { :errors => @subpartida.errors }
          page.replace "formulario_anadir_anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>" unless params[:id]
        end unless params[:id] 
    else
      partidas
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @subpartida.errors} }
    end 
  end

	# en proyectos y agentes: elimina una subpartida
  def eliminar
    @subpartida = (@proyecto || @agente).subpartida.find(params[:id]).destroy
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @subpartida.errors, :eliminar => true}}
  end

private

  def partidas
    @partidas = Partida.all(:order => "codigo").collect{|p| [p.codigo_nombre(@proyecto), p.id]} if params[:seccion] == "proyectos"
    @partidas = Partida.all(:order => "codigo", :conditions => {:ocultar_agente => false}).collect{|p| [p.codigo_nombre, p.id]} unless params[:seccion] == "proyectos"
  end

end
#done

