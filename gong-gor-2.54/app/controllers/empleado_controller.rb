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
# * Sección agente: se utiliza para listar, crear, modificar, inactivar un empleado
class EmpleadoController < ApplicationController
  # --
  ########## gestión de empleados ##########
  # ++

	# en agente: se redirecciona por defecto a ordenado
  def index
    redirect_to :action => :listado 
  end

	# en agente: lista los empleados del agente
  def listado
    session[:empleado_asc_desc] ||= "ASC"
    session[:empleado_orden] ||= "nombre"
    @empleados = @paginado =  Empleado.where(agente_id: @agente.id).order(session[:empleado_orden] + " " + session[:empleado_asc_desc]).
                                       paginate(page: params[:page], per_page: (session[:por_pagina] or 20))
  end

	# en agente: establece los parametros de ordenación
  def ordenado
    session[:empleado_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC" 
    session[:empleado_orden] = params[:orden] ? params[:orden].gsub(".capitalize","") : "nombre" 
    redirect_to :action => "listado"
  end
  
	# en agente: prepara el formulario de edición o creación
  def editar_nuevo
    @empleado = params[:id] ?  Empleado.find_by_id(params[:id]) : Empleado.new
    render :partial => "formulario"
  end

	# en agente:  modifica o crea
  def modificar_crear
    @empleado = Empleado.find_by_id(params[:id]) || Empleado.new
    params[:empleado][:agente_id] = @agente.id
    @empleado.update_attributes params[:empleado]
    msg @empleado
    redirect_to :action => "listado"
  end    

	# en agente: eliminar el empleado
  def eliminar
    @empleado = Empleado.find_by_id params[:id]
    @empleado.destroy
    msg_eliminar @empleado
    redirect_to :action => 'listado'
  end

  def empleado_salarios
    @salarios = Empleado.find_by_id(params[:empleado_id]).empleado_salario_hora
    render(:update) do |page| 
      page.replace_html params[:update], :partial => "empleado_salarios_hora", :locals => {:update_listado => params[:update]  }
    end
  end

  def nuevo_editar_empleado_salario
    @empleado_salario_hora = params[:id] ? EmpleadoSalarioHora.find_by_id(params[:id]) : EmpleadoSalarioHora.new 
    render(:update) { |page| page.formulario :partial => "formulario_empleado_salario", :update => params[:update]  }
  end

  def crear_modificar_empleado_salario
    @empleado_salario_hora = params[:id] ? EmpleadoSalarioHora.find(params[:id]) : EmpleadoSalarioHora.new
    @empleado_salario_hora.update_attributes params[:empleado_salario_hora]
    @salarios = Empleado.find_by_id(params[:empleado_id]).empleado_salario_hora
    if @empleado_salario_hora.id
      render(:update) { |page|  page.modificar :update_listado => params[:update_listado], :partial => "empleado_salarios_hora", 
                                               :locals => {:update_listado => params[:update_listado]  }, :mensaje => { :errors => @empleado_salario_hora.errors}, 
                                               :tipo_update => "sublistado" }
    else
      render(:update){ |page|  page.recargar_formulario :partial => "formulario_empleado_salario", :mensaje => { :errors => @empleado_salario_hora.errors } }
    end
  end

  def eliminar_empleado_salario
    @salario= EmpleadoSalarioHora.find(params[:id])
    @salario.destroy
    @salarios = Empleado.find_by_id(params[:empleado_id]).empleado_salario_hora
    render(:update) { |page|  page.eliminar(:update => params[:update], :mensaje => { :errors => @salario.errors, :eliminar => true }) }
  end
end
