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
# Controlador encargado de la gestion del presupuesto detallado de un presupuesto. Sus metodos se invocan via ajax al elaborar el presupuesto por proyecto o por agente.
#
class PresupuestoDetalladoController < ApplicationController

  before_filter :presupuesto_relacionado
  before_filter :verificar_etapa, :only => [ :guardar, :dividir_x_mes ]
  before_filter :verificar_estado_formulacion_ajax, :only => [ :guardar, :dividir_x_mes ]

  # en proyectos: prepara el formulario para los detalles del presupuesto
  def editar
    @presupuesto_detallados = @presupuesto.presupuesto_detallado
    @fecha_inicio = @presupuesto.etapa.fecha_inicio if @presupuesto.etapa
    @fecha_fin = @presupuesto.etapa.fecha_fin if @presupuesto.etapa
    render (:update) { |page| page.formulario :update => params[:update] , :partial => "presupuesto_detallado"}
  end

  # en proyectos:	guarda el detalle de presupuesto
  def guardar
    @presupuesto.actualizar_presupuesto_detallado params[:detalle]
    if params[:seccion] == "proyectos"
      if params[:actividad_id]
        @actividad = Actividad.find params[:actividad_id]
        @pxa = PresupuestoXActividad.find_by_presupuesto_id_and_actividad_id params[:id], params[:actividad_id]
        @presupuesto = Presupuesto.find( params[:id], :include => :presupuesto_x_actividad, :conditions => {"presupuesto_x_actividad.actividad_id" => params[:actividad_id]} ) # Esto parece algo absurdo pero lo recargamos para que al recargar la linea muestre la información de la actividad
        render(:update) { |page| page.modificar :update => @pxa.id.to_s, :partial => "presupuesto_actividad/presupuesto", :locals => { :presupuesto => @presupuesto, :actividad => @actividad}, :mensaje => { :errors => @presupuesto.errors } }
      else 
        partida = PartidaFinanciacion.find_by_id(params[:partida_id])
        #@partida = @presupuesto.partida_x_partida_financiacion.first.partida_financiacion 
        render(:update) { |page| page.modificar :update => params[:update], :partial => "presupuesto_proyectos/presupuesto", :locals => { :presupuesto => @presupuesto, :partida => partida}, :mensaje => { :errors => @presupuesto.errors } }
      end
    elsif params[:seccion] == "agentes"
      if params[:partida_ingreso_id]
        @partida = PartidaIngreso.find_by_id params[:partida_ingreso_id]
        vista = params[:vista] || "presupuesto_ingresos/presupuesto"
        render(:update) { |page| page.modificar update: params[:update], partial: vista, locals: {presupuesto: @presupuesto}, mensaje: {errors: @presupuesto.errors} }
      else
        vista = params[:vista] || "presupuesto_agentes/presupuesto"
        render(:update) { |page| page.modificar update: params[:update], partial: vista, locals: { presupuesto: @presupuesto }, mensaje: { errors: @presupuesto.errors } }
      end
    end
  end

  # en proyectos: divide el detalle de presupuesto por meses
  def dividir_x_mes
    @fecha_inicio = @presupuesto.etapa.fecha_inicio
    @fecha_fin = @presupuesto.etapa.fecha_fin
    @presupuesto.dividir_por_mes @fecha_inicio, @fecha_fin, params[:ocultar]
    @presupuesto_detallados = @presupuesto.presupuesto_detallado
    render (:update) do |page| 
      page.remove "formularioinline", "formulariofondo"
      page.mensaje_informacion params[:update], _(""), :tipo_mensaje => "mensajefallo" if @presupuesto.etapa && @presupuesto.etapa.cerrada
      page.formulario :update => params[:update] , :partial => "presupuesto_detallado"
    end
  end

 private

  # Obtiene el presupuesto relacionado
  def presupuesto_relacionado
    # Cuando tenemos partida de ingreso es que nos estamos refiriendo al ppto de ingresos
    @presupuesto = Presupuesto.find_by_id(params[:id]) unless params[:partida_ingreso_id]
    @presupuesto = PresupuestoIngreso.find_by_id(params[:id]) if params[:partida_ingreso_id]
    if @presupuesto.nil?
      render :update do |page|
        mensaje = _("El presupuesto relacionado no existe") + " " + _("No se puede modificar el presupuesto detallado.")
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
      return false
    end
  end

  # Se asegura de que la etapa no este cerrada
  def verificar_etapa
    if @presupuesto.etapa.cerrada && @presupuesto.proyecto.nil?
      render :update do |page|
        mensaje = _("La etapa esta cerrada.") + " " + _("No se puede modificar el presupuesto detallado.")
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
      return false
    end
  end

  def verificar_estado_formulacion_ajax
    #unless @permitir_formulacion
    # Dejamos que se pueda modificar el presupuesto en formulacion
    unless @agente || @proyecto.estado_actual
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("No se puede modificar el presupuesto detallado.")    if @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end


end
