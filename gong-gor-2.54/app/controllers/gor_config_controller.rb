# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2016 Free Software's Seed
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
# Controlador encargado de la gestión de los tipos de agentes 
class GorConfigController < ApplicationController
  before_filter :solo_administracion

  def index
    redirect_to :action => "listado"
  end

  def listado
    @config = @paginado = GorConfig.order(:name).paginate(:page => params[:page], :per_page => (session[:por_pagina] or 20) )
  end

  def editar_nuevo
    @parameter = GorConfig.find_by_id(params[:id])
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

  def modificar_crear
    @parameter = GorConfig.find_by_id(params[:id])
    @parameter.update_attributes(value: params[:parameter][:value])
    if @parameter.errors.empty?
      render(:update) { |page| page.modificar update: params[:update], partial: "parameter" , mensaje: { errors: @parameter.errors } }
    else
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @parameter.errors} }
    end
  end

 private

  # Se asegura de que estemos en administracion y podamos hacer esto
  def solo_administracion
    return params[:seccion] == "administracion" && @usuario_identificado && @usuario_identificado.administracion
  end
end
