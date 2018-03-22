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
# Controlador encargado de la gestión de las fuentes de verificación.

class FuenteVerificacionController < ApplicationController

  def listado_fuentes_verificacion
    @fuentes_verificacion = []
    @proyecto.objetivo_especifico.each  do |oe|
      @fuentes_verificacion += oe.fuente_verificacion
    end
    @proyecto.resultado.each  do |r|
      @fuentes_verificacion += r.fuente_verificacion
    end
  end

  def fuente_verificacion_editar_completada
    @fuente_verificacion = FuenteVerificacion.find_by_id(params[:id])
    render :partial => "formulario_fuente_verificacion_completada"
  end

  def fuente_verificacion_completada
    fuente_verificacion = FuenteVerificacion.find_by_id(params[:id])
    fuente_verificacion.update_attribute :completada, params[:fuente_verificacion][:completada]
    render :update do |page|
      page.call("Modalbox.hide")
      page.replace params[:update], :partial => "fuente_verificacion", :locals => { :fuente_verificacion => fuente_verificacion, :i =>  params[:i], :update => params[:update] }
      page.visual_effect :highlight, params[:update] , :duration => 6
    end
  end

  def fuente_verificacion_vincular_o_nuevo
    #render :partial => "formulario_fuente_verificacion_vincular_o_nuevo"
    render(:update) { |page| page.formulario :partial => "formulario_fuente_verificacion_vincular_o_nuevo", :update => params[:update] }
  end

  def fuente_verificacion_editar_vincular_documento
    @documentos = @proyecto.documento.collect {|d| [d.adjunto_file_name, d.id]}
    #render :partial => "formulario_fuente_verificacion_vincular"
    render(:update) { |page| page.replace 'formulariocontenedor', :partial => "formulario_fuente_verificacion_vincular", :locals => { :update => params[:update] } }
  end


  def fuente_verificacion_vincular_documento
    objeto = FuenteVerificacion.find_by_id params[:objeto_id]
    @relacion = FuenteVerificacionXDocumento.create :documento_id => params[:documento][:id], :fuente_verificacion_id => params[:objeto_id]
    if objeto && @relacion.errors.empty?
      render(:update){ |page|  page.modificar(:update_listado => params[:update_listado], :locals => {:update => params[:update_listado], :objeto_id => params[:objeto_id], :documentos => objeto.documento}, :partial => "listado_documentos", :mensaje => { :errors => @relacion.errors}) }
    else
      # Si hay datos que fallan se vuelve al formulario
      @documentos = @proyecto.documento.collect {|d| [d.adjunto_file_name, d.id]}
      render(:update){ |page|  page.recargar_formulario :partial => "formulario_fuente_verificacion_vincular", :mensaje => { :errors => @relacion.errors } }
    end
    #redirect_to :action => "listado_fuentes_verificacion"
  end

  def fuente_verificacion_eliminar_documento
    objeto = FuenteVerificacion.find_by_id params[:objeto_id]
    @relacion = FuenteVerificacionXDocumento.find(:first, :conditions => {:documento_id => params[:id], :fuente_verificacion_id => params[:objeto_id]})
    @relacion.destroy if @relacion
    render(:update) { |page|  page.eliminar(:update => params[:update_listado], :mensaje => { :errors => @relacion.errors, :eliminar => true }) }
  end

end
