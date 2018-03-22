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


class PluginController < ApplicationController

  before_filter :verificar_administrador, :only => [:index]
  before_filter :verificar_administrador_ajax, :except => [:index]

  def index
    Plugin.comprueba_plugins
    @plugins = Plugin.order(:codigo)
  end

	# en proyectos y agentes: crea o edita una nueva subpartida
  def editar_nuevo
    @plugin = Plugin.find_by_id(params[:id])
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

	# en proyectos y agentes: modifica o crea una subpartida 
  def modificar_crear
    @plugin = Plugin.find_by_id(params[:id])
    if @plugin && params[:plugin][:activo]
      @plugin.update_attributes activo: (params[:plugin][:activo] == "1")
      Plugin.recarga_rutas
      Plugin.search_external_auth
      render(:update) { |page|   page.modificar :update => params[:update], :partial => "plugin" , :mensaje => { :errors => @plugin.errors } }
    else
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @plugin.errors } }
    end 
  end

 private

  def verificar_administrador
    unless @usuario_identificado.administracion 
      msg_error _("No tiene permisos suficientes para realizar esta acción.")
      redirect_to main_app.entrada_path 
    end
  end

  def verificar_administrador_ajax
    unless @usuario_identificado.administracion
      render :update do |page|
        page.mensaje_informacion params[:update], _("No tiene permisos suficientes para realizar esta acción."), :tipo_mensaje => "mensajefallo"
      end
    end
  end

end

