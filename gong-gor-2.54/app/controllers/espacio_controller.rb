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
# Controlador encargado de la gestión del workflow

class EspacioController < ApplicationController
  # en administracion: se redirecciona por defecto a ordenado
  def index
    redirect_to :action => 'ordenado'
  end

  # en administracion o en definicion_estados: establece los parametros de ordenación
  def ordenado
    session[:espacio_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"   
    session[:espacio_orden] = params[:orden] ? params[:orden] : "nombre" 
    session[:espacio_orden] = "espacio_padre_id" if params[:orden] == "ruta"
    redirect_to :action => "listado" 
  end

  def seleccionar_espacio
    session[:espacio_seleccionado_admin] = params[:id] 
    session[:espacio_seleccionado_tipo] = params[:id] ? params[:tipo] : nil
    redirect_to :action =>  :listado
  end

  # en administracion: lista las definicion_estados que hay en el sistema
  def listado
    #puts "------------> E id: " + session[:espacio_seleccionado_admin].to_s if session[:espacio_seleccionado_admin]
    #puts "------------> E tipo: " + session[:espacio_seleccionado_tipo].to_s if session[:espacio_seleccionado_tipo]
    #session[:espacio_seleccionado_admin] = nil
    #session[:espacio_seleccionado_tipo] = nil
    @espacios = Hash.new
    if session[:espacio_seleccionado_admin]
      @espacio = Espacio.find session[:espacio_seleccionado_admin]
      @espacios[session[:espacio_seleccionado_tipo]] = @espacio.espacio_hijo
    else
      #condiciones = "(definicion_espacio_proyecto != 1 OR definicion_espacio_proyecto is NULL) AND (definicion_espacio_agente != 1 OR definicion_espacio_agente is NULL) AND definicion_espacio_proyecto_id is NULL AND definicion_espacio_agente_id is NULL AND espacio.proyecto_id is NULL AND espacio.agente_id is NULL AND espacio.nombre <> 'Proyectos' and espacio.nombre <> 'Agentes' and espacio.nombre <> 'Plantillas Exportación' AND (espacio_padre_id is NULL OR espacio_padre_id = 0)"
      condiciones = "(definicion_espacio_proyecto != 1 OR definicion_espacio_proyecto is NULL) AND (definicion_espacio_pais != 1 OR definicion_espacio_pais IS NULL) AND (definicion_espacio_agente != 1 OR definicion_espacio_agente is NULL) AND (definicion_espacio_socia != 1 OR definicion_espacio_socia is NULL) AND (definicion_espacio_financiador!=1 OR definicion_espacio_financiador IS NULL) AND definicion_espacio_proyecto_id is NULL AND definicion_espacio_agente_id is NULL AND espacio.proyecto_id is NULL AND espacio.agente_id is NULL AND espacio.modificable AND (espacio_padre_id is NULL OR espacio_padre_id = 0)"
      orden = session[:espacio_orden] + " " + session[:espacio_asc_desc]
      @espacios['general'] =  Espacio.find(:all, :order => orden, :conditions => condiciones )
      @espacios['proyecto'] = Espacio.find :all, :order => orden, :conditions =>  {:definicion_espacio_proyecto => true, :espacio_padre_id => nil}
      @espacios['agente'] = Espacio.find :all, :order => orden, :conditions =>  {:definicion_espacio_agente => true, :espacio_padre_id => nil}
      @espacios['socia'] = Espacio.find :all, :order => orden, :conditions =>  {:definicion_espacio_socia => true, :espacio_padre_id => nil}
      @espacios['financiador'] = Espacio.find :all, :order => orden, :conditions =>  {:definicion_espacio_financiador => true, :espacio_padre_id => nil}
      @espacios['pais'] = Espacio.find :all, :order => orden, :conditions =>  {:definicion_espacio_pais => true, :espacio_padre_id => nil}
    end
  end
  
  # en administracion: prepara el formulario de edición o creación
  def editar_nuevo
    @espacio = params[:id] ?  Espacio.find(params[:id]) : Espacio.new
    @espacio_padre_id = session[:espacio_seleccionado_admin]
    render :partial => "formulario"
  end

  # en administracion: modifica o crea
  def modificar_crear
    #puts "-------> " + params[:espacio].inspect
    @espacio = params[:id] ?  Espacio.find(params[:id]) : Espacio.new
    #params[:espacio][:espacio_padre_id] = nil
    @espacio.update_attributes params[:espacio]
    @espacio.save 
    msg @espacio
    redirect_to :action => "listado"
  end

  # en administracion: elimina
  def eliminar
    @espacio = Espacio.find_by_id(params[:id])
    ActiveRecord::Base.transaction do
      @espacio.destroy
      raise ActiveRecord::Rollback unless @espacio.errors.empty? 
    end if @espacio
    session[:espacio_seleccionado] = nil
    msg_eliminar @espacio
    redirect_to :action => 'listado'
  end


end
