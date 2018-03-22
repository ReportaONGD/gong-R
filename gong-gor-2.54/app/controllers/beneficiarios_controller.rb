# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2017 Free Software's Seed, CENATIC y IEPALA
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
# Controlador encargado de la gestión de los datos de proyecto.
# Este controlador es utilizado desde las secciones:
# * Sección proyectos: se utiliza para establecer los beneficiarios
#



class BeneficiariosController < ApplicationController

  before_filter :verificar_estado_proyecto, only: [ :modificar_crear, :eliminar]
  before_filter :datos_proyecto, only: [:editar_nuevo, :modificar_crear, :eliminar]

  # en proyectos: se redirecciona por defecto a identificación
  def index
    redirect_to action: :listado
  end

  # en proyectos:  lista los datos de beneficiarios
  def listado 
    rotulos_campos
    @beneficiarios = @proyecto.datos_proyecto.includes(:pais).order("pais.nombre")
  end

  # en proyectos: prepara el formulario de edición o creación de beneficiarios
  def editar_nuevo 
    rotulos_campos
    datos_formulario
    render partial: "formulario_beneficiarios"
  end

  # en proyectos: modifica o crea beneficiarios
  def modificar_crear
    @datos_proyecto.update_attributes params[:datos_proyecto]
    msg @datos_proyecto
    redirect_to action: :listado
  end

  # en proyectos: elimina la linea de beneficiarios
  def eliminar
    @datos_proyecto.destroy if @datos_proyecto.id
    msg_eliminar @datos_proyecto
    redirect_to action: :listado
  end

 private
  # Se asegura de que estemos en un estado que permita cambiar la informacion
  def verificar_estado_proyecto
    unless (@proyecto.estado_actual && @proyecto.estado_actual.definicion_estado.formulacion) || @proyecto.usuario_admin?(@usuario_identificado)
      msg_error _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar los datos del proyecto.")    if @proyecto.estado_actual.nil?
      msg_error _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se pueden modificar los datos del proyecto.") + " " + _("No ha sido definido como 'estado de formulación' por su administrador.")    unless @proyecto.estado_actual.nil?
      redirect_to action: "listado"
    end     
  end

  # Obtiene los beneficiarios desde parametros
  def datos_proyecto
    @datos_proyecto = @proyecto.datos_proyecto.find_by_id(params[:id]) ||
                      DatosProyecto.new(proyecto_id: @proyecto.id)
  end

  # Devuelve los datos del formulario
  def datos_formulario
    # Obtiene todos los paises ya asignados...
    asignados = @proyecto.datos_proyecto.collect{|dp| [dp.pais ? dp.pais.nombre : "N/A", dp.pais_id]}
    # ... menos los del propio dato
    asignados -= [ [@datos_proyecto.pais.nombre, @datos_proyecto.pais_id] ] if @datos_proyecto.pais
    # Escoge todos los paises posibles...
    @paises = @proyecto.pais.order("pais.nombre").collect{|p| [p.nombre, p.id]}
    # ... y les quita los que ya estan asignados
    @paises -= asignados 
  end

  # Devuelve los rotulos de totales para el listado
  def rotulos_campos
    @campos = [{rotulo: _("Beneficiarios directos hombres"), campo: "beneficiarios_directos_hombres"},
               {rotulo: _("Beneficiarios directos mujeres"), campo: "beneficiarios_directos_mujeres"},
               {rotulo: _("Beneficiarios directos sin especificar"), campo: "beneficiarios_directos_sin_especificar"},
               {rotulo: _("Beneficiarios indirectos hombres"), campo: "beneficiarios_indirectos_hombres"},
               {rotulo: _("Beneficiarios indirectos mujeres"), campo: "beneficiarios_indirectos_mujeres"},
               {rotulo: _("Beneficiarios indirectos sin especificar"), campo: "beneficiarios_indirectos_sin_especificar"},
               {rotulo: _("Población total de la zona"), campo: "poblacion_total_de_la_zona"} ]
  end
end
