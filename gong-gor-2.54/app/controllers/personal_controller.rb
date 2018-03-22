# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2014 Free Software's Seed
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


class PersonalController < ApplicationController

  before_filter :verificar_estado_no_cerrado_ajax, :only => [   :editar_nuevo, :modificar_crear, :eliminar ]

  def index
    redirect_to :action => :filtrado_ordenado_iniciales 
  end

  # en proyectos y en agente: inicializa los defectos para ordenado y filtro y redirecciona a listado
  def filtrado_ordenado_iniciales
    session[:personal_asc_desc] ||= "ASC"
    session[:personal_orden] = "nombre"
    session[:personal_filtro_tipo] ||= "todos"
    redirect_to :action => :listado
  end

  # en proyectos y agentes: establece los parametros de ordenación
  def ordenado
    session[:personal_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    if params[:orden]
      session[:personal_orden] = ( params[:orden].match(/^tipo_personal.codigo_nombre/) ? "tipo_personal.codigo" : params[:orden] ) 
    else
      session[:personal_orden] = "nombre"
    end
    redirect_to :action => "listado"
  end

  # en proyectos y agentes: establece los parametros de filtro
  def filtrado
    session[:personal_filtro_tipo] = params[:filtro][:tipo]
    redirect_to :action => :listado
  end

  def elementos_filtrado
    tipos_personal
    @tipo = TipoPersonal.find_by_id( session[:personal_filtro_tipo] ) unless session[:personal_filtro_tipo] == "todos"
    
    filtro_tipo = [[_("Todos"),"todos"]] + @tipos_personal
    
    @opciones_filtrado = [{:rotulo =>  _("Tipo de Personal"), :nombre => "tipo", :opciones => filtro_tipo} ]
    @accion_filtrado = {:action => :filtrado, :listado => :listado}
    @estado_filtrado = [ (@tipo ? @tipo.codigo_nombre : _("Cualquier tipo de personal")) ]
  end


	# en proyectos y agentes: lista las partidas y subpartidas relacionadas
  def listado 
    elementos_filtrado
   
    condiciones = {} 
    condiciones[:tipo_personal_id] = @tipo.id if @tipo

    @personal = @paginado = @proyecto.personal.includes(["tipo_personal"]).
                                      where(condiciones).
                                      order(session[:personal_orden] + " " + session[:personal_asc_desc]).
                                      paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                               per_page: (params[:format_xls_count] || session[:por_pagina]))

    @formato_xls = @personal.total_entries
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "personal"
        @objetos = @personal
        nom_fich = "personal_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

	# en proyectos y agentes: crea o edita una nueva subpartida
  def editar_nuevo
    @persona = @proyecto.personal.find_by_id(params[:id]) || Personal.new
    tipos_personal 
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

	# en proyectos y agentes: modifica o crea una subpartida 
  def modificar_crear
    @persona = @proyecto.personal.find_by_id(params[:id]) || Personal.new(:proyecto_id => @proyecto.id)
    @persona.update_attributes params[:persona]
    if @persona.errors.empty?
      render(:update) { |page|   page.modificar :update => params[:update], :partial => "persona" , :mensaje => { :errors => @persona.errors } } if params[:id]
      # Si es una nueva persona 
        render :update do |page|
          page.show "nuevas_personas"
          page.modificar :update => "persona_nueva_" + params[:i], :partial => "nueva_persona", :mensaje => { :errors => @persona.errors }
          page.replace "formulario_anadir_anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>" unless params[:id]
        end unless params[:id] 
    else
      tipos_personal 
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @persona.errors} }
    end 
  end

	# en proyectos y agentes: elimina una subpartida
  def eliminar
    @persona = @proyecto.personal.find(params[:id]).destroy
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @persona.errors, :eliminar => true}}
  end

 private

  def tipos_personal 
    @tipos_personal = TipoPersonal.all(:order => "codigo").collect{|p| [p.codigo_nombre, p.id]}
  end

  # Comprueba que no este cerrado
  def verificar_estado_no_cerrado_ajax
    #unless @permitir_formulacion || @permitir_ejecucion
    unless @proyecto && @proyecto.estado_actual && @proyecto.estado_actual.definicion_estado && !@proyecto.estado_actual.definicion_estado.cerrado
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar los datos del proyecto.")  if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto no se encuentra en un estado adecuado para modificar los datos.") unless @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end

end

