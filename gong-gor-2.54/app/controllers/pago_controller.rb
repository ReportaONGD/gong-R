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
# Controlador encargado de la gestión de los pagos.
# Este controlador es utilizado desde las secciones:
# * Sección proyectos: se utiliza para listar, asignar y desasignar pagos a gastos 
# * Sección agentes: se utiliza para listar, asignar y desasignar pagos a gastos 
class PagoController < ApplicationController

  before_filter :verifica_cuenta_usuario, :only => [ :modificar_crear_pago, :eliminar_pago]

  
  def verifica_cuenta_usuario
    if params[:id]
      cuenta = Pago.find_by_id(params[:id]).libro
    else
      cuenta = Libro.find_by_id params[:pago][:libro_id]
    end
    unless @usuario_identificado.libro.include? cuenta
      mensaje = _("Su usuario no tiene permisos para gestionar pagos asociados a esta cuenta") if cuenta
      mensaje = _("Un pago debe estar asociado a una cuenta") unless cuenta
      render (:update) {|page|  page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"} 
    end
  end
  

  def pagos
    @pagos = Gasto.find_by_id(params[:gasto_id]).pago
    render :update do |page|
      page.replace_html params[:update], :partial => "listado", :locals =>  {:update_listado => params[:update], :update_gasto => params[:update_gasto]}
    end
  end

  def anadir_pago
    @pago =  Pago.find_by_id(params[:id]) || Pago.new
    gasto = Gasto.find_by_id(params[:gasto_id])
    @pago.gasto_id = gasto.id
    # Permite solo los libros que son del mismo agente y moneda que el gasto y ademas
    # son manejables por el usuario identificado
    @libros = (@proyecto||@agente).libro.all(:order => "nombre").select{|l| l.agente_id == gasto.agente.id && l.moneda_id == gasto.moneda_id && @usuario_identificado.reload.libro.include?(l)}
    #puts "----------------------> " + @usuario_identificado.reload.libro.inspect
    #puts "----------------------> " + @libros.inspect
    @pago.importe = (gasto.importe - gasto.importe_pagado) if @pago.id.nil?
    @pago.fecha ||= Time.now.to_s
    render(:update){ |page| page.formulario :partial => "formulario", :update => params[:update] }
  end

  # Averigua si el libro seleccionado es banco o caja chica y muestra/oculta las opciones de pago
  def cambia_libro
    libro = Libro.find_by_id params[:id]
    render :update do |page|
      page.show 'forma_pago' if libro && libro.tipo == "banco"
      page.hide 'forma_pago' unless libro.nil? || libro.tipo == "banco"
    end
  end

  def modificar_crear_pago
    @pago = params[:id] ? Pago.find(params[:id]) : Pago.new
    @pago.update_attributes params[:pago]
    @gasto = @pago.gasto
    @gasto.marcado_errores
    @pagos = @pago.gasto.pago
    if @pago.errors.empty?
      render (:update) do |page|
        # Primero actualizamos la linea de gasto
        page.modificar :update => params[:update_gasto], :partial => "gasto_proyectos/gasto", :mensaje => { :errors => @pago.errors }, :locals => {:update => params[:update_gasto]} if @proyecto
        page.modificar :update => params[:update_gasto], :partial => "gasto_agentes/gasto", :mensaje => { :errors => @pago.errors }, :locals => {:update => params[:update_gasto]} unless @proyecto
        # Y luego actualizamos el listado de pagos
        page.replace_html params[:update_listado], :partial => "listado", :locals => {:update_listado => params[:update_listado]}
      end
    else
      @libros = (@proyecto||@agente).libro.all(:order => "nombre").select{|l| l.agente_id == @gasto.agente.id && l.moneda_id == @gasto.moneda_id && @usuario_identificado.reload.libro.include?(l)}

      render(:update) { |page| page.recargar_formulario :partial => "formulario", :update => params[:update], :mensaje => {:errors => @pago.errors}, :locals => {:update => params[:update]} }
    end
  end

  def eliminar_pago
    @pago = Pago.find(params[:id])
    @pago.destroy
    @gasto = @pago.gasto
    @gasto.marcado_errores
    @pagos = @pago.gasto.pago
    render (:update) do |page|
      # Primero actualizamos la linea de gasto
      page.actualizar :update => params[:update_gasto], :partial => "gasto_proyectos/gasto", :mensaje => { :errors => @pago.errors, :eliminar => true }, :locals => {:update => params[:update_gasto]} if @proyecto
      page.actualizar :update => params[:update_gasto], :partial => "gasto_agentes/gasto", :mensaje => { :errors => @pago.errors, :eliminar => true }, :locals => {:update => params[:update_gasto]} unless @proyecto
      # Y luego actualizamos el listado de pagos
      page.replace_html params[:update_listado], :partial => "listado", :locals => {:update_listado => params[:update_listado]}
    end 
  end

end
