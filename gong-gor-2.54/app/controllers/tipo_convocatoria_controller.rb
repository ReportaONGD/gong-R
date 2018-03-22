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
# Controlador encargado de la gestión de los tipos de convocatorias
class TipoConvocatoriaController < ApplicationController

  def index
    redirect_to :action => "listado"
  end

  def listado
    @tipos = @paginado =  TipoConvocatoria.order("nombre").paginate(:page => params[:page], :per_page => (session[:por_pagina] or 20) )
  end

  def editar_nuevo
    @tipo = TipoConvocatoria.find_by_id(params[:id]) || TipoConvocatoria.new
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

  def modificar_crear
    @tipo = TipoConvocatoria.find_by_id(params[:id]) || TipoConvocatoria.new
    @tipo.update_attributes params[:tipo]
    if @tipo.errors.empty?
      render(:update) { |page|   page.modificar :update => params[:update], :partial => "tipo_convocatoria" , :mensaje => { :errors => @tipo.errors } } if params[:id]
      # Si es un nuevo tipo de convocatoria
      render :update do |page|
        page.show "nuevos_tipos"
        page.modificar :update => "tipo_nuevo_" + params[:i], :partial => "nuevo_tipo", :mensaje => { :errors => @tipo.errors }
        page.replace "formulario_anadir_anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>"
      end unless params[:id]
    else
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @tipo.errors} }
    end
  end    

  def eliminar
    @tipo = TipoConvocatoria.find_by_id(params[:id]).destroy 
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @tipo.errors, :eliminar => true}}
  end
end
