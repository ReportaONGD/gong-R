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
# Controlador encargado de la gestion de la entidad partida Financiacion.
# Estas partidas son las partidas de las financiaciones que se mapean con las partidas generales del sistema
# Este controlador es utilizado desde las secciones:
# * Sección financiaciones: se utiliza para sacar los informes para los financiacores

class PartidaFinanciacionController < ApplicationController

  before_filter :verificar_estado_ajax, :only => [:modificar_crear, :eliminar, :crear_asociacion_partida, :eliminar_asociar_partida]

  # en financiaciones: se redirecciona por defecto a listado
  def index
    Partida.all.each do |partida|
        msg_error _("ATENCIÓN") + ": " + _("Todavía hay alguna partida del Sistema sin asignar a alguna de las Partidas del Proyecto") unless partida.ocultar_proyecto || partida.partida_asociada(@proyecto)
    end
    redirect_to :action => 'listado'
  end

  # --
  # METODOS DE GESTION DE Partidas
  # ++

  # en financiaciones: lista las partidas de la finaciación cargada en la sessión
  def listado
    @partidas_financiacion = @proyecto.partida_financiacion.all(:conditions => {:partida_financiacion_id => nil}, :order => 'codigo')
    @formato_xls = 0 
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "partida_financiacion"
        @objetos = @partidas_financiacion
        @subobjetos = [ "partida" ]
        nom_fich = "partidas_financiador_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

  # en administracion de agentes listado de partidas del financiador
  def listado_financiador
    agente = Agente.find_by_id params[:objeto_id]
    @partidas_financiacion = agente.partida_financiacion.all(:conditions => {:partida_financiacion_id => nil}, :order => 'codigo')
    render (:update) { |page| page.replace_html params[:update_listado], :partial => "partidas" }
  end

  # en financiaciones: prepara el formulario de edición o creación
  def editar_nuevo
    @partida_financiacion = params[:id] ?  PartidaFinanciacion.find(params[:id]) : PartidaFinanciacion.new
    @partidas_financiacion_padre = PartidaFinanciacion.find_all_by_padre_and_proyecto_id( true, @proyecto.id ).collect{ |p| [p.nombre, p.id]} if @proyecto
    @partidas_financiacion_padre = PartidaFinanciacion.find_all_by_padre_and_agente_id( true, params[:objeto_id] ).collect{ |p| [p.nombre, p.id] } unless @proyecto || @agente
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

  # en financiaciones: modifica o crea
  def modificar_crear
    @partida_financiacion = params[:id] ?  PartidaFinanciacion.find(params[:id]) : PartidaFinanciacion.new
    params[:partida_financiacion][:proyecto_id] = @proyecto.id if @proyecto
    params[:partida_financiacion][:agente_id] = params[:objeto_id] if params[:objeto_id]
    params[:partida_financiacion][:partida_financiacion_id] = nil if params[:partida_financiacion][:padre] == "1"
    @partida_financiacion.update_attributes params[:partida_financiacion]
    if @partida_financiacion.errors.empty?
      @partidas_financiacion = @proyecto ? @proyecto.partida_financiacion.all(:conditions => {:partida_financiacion_id => nil}, :order => :codigo) : Agente.find(params[:objeto_id]).partida_financiacion.all(:conditions => {:partida_financiacion_id => nil}, :order => :codigo)
      render(:update) { |page| page.modificar :update => params[:update_listado], :partial => "partidas", :mensaje => { :errors => @partida_financiacion.errors } }
    else
      @partidas_financiacion_padre = PartidaFinanciacion.find_all_by_padre_and_proyecto_id( true, @proyecto.id ).collect{ |p| [p.nombre, p.id]} if @proyecto
      @partidas_financiacion_padre = PartidaFinanciacion.find_all_by_padre_and_agente_id( true, params[:objeto_id] ).collect{ |p| [p.nombre, p.id] } unless @proyecto || @agente
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @partida_financiacion.errors} }
    end

    #msg @partida_financiacion
    #redirect_to :action => "listado"
  end

  # en financiaciones:  elimina
  def eliminar
    @partida_financiacion = PartidaFinanciacion.find(params[:id]).destroy
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @partida_financiacion.errors, :eliminar => true}}
  end

  #-- 
  # METODOS DE PARTIDAS ASOCIADAS CON PARTIDA_FINANCIACION -- Metodos AJAX 
  # ++

  # en financiaciones: lista las partidas del sistema asociadas
  def partidas_asociadas
     @partidas_asociadas = PartidaFinanciacion.find( params[:partida_financiacion_id] ).partida
    render :update do |page|
      page.replace_html params[:update], :partial => "partidas_asociadas", :locals => { :update => params[:update], :partida_financiacion_id => params[:partida_financiacion_id] }
    end
  end

  # en financiaciones: prepara el formulario para asociar partida del sistema
  def anadir_asociar_partida
    @partidas_financiacion = PartidaFinanciacion.find( params[:partida_financiacion_id] )
    @partidas_pendientes = Partida.partidas_pendientes_de_financiacion(@proyecto.id).collect {|e| [e.codigo_nombre ,e.id]} if @proyecto
    @partidas_pendientes = Partida.partidas_pendientes_de_financiacion_para_financiador(params[:objeto_id]).collect {|e| [e.codigo_nombre ,e.id]} unless @proyecto
    render :partial => "asociar_partida"
  end


  # en financiaciones: asocia las partidas del sistema
  def crear_asociacion_partida
    if ! params[:partida][:id].empty?
      @partidas_asociadas =  PartidaFinanciacion.find( params[:partida_financiacion_id] ).partida
      @partida_financiacion = @objeto = PartidaFinanciacion.find( params[:partida_financiacion_id] )
      @partida_financiacion.partida << Partida.find( params[:partida][:id] )
      render :update do |page|
        page.replace_html 'formulario', :inline => '<%= mensaje_error @partida_financiacion %><br>'
        page.call("Modalbox.resizeToContent") 
        page.replace_html params[:update], :partial => "partidas_asociadas", :locals => { :update => params[:update], :partida_financiacion_id => params[:partida_financiacion_id] }
        page.visual_effect :highlight, params[:update], :duration => 6
      end
    else
      render :update do |page|
        page.alert('Ninguna partida fue asociada')
        page.call("Modalbox.hide")
      end
    end
  end

  # en financiaciones: desasocia la partida
  def eliminar_asociar_partida
    #partida_financiacion = PartidaFinanciacion.find( params[:partida_financiacion_id] )
    #partida_financiacion.partida.delete( @partida = Partida.find( params[:partida_id] ) )
    PartidaXPartidaFinanciacion.destroy_all(:partida_id => params[:partida_id], :partida_financiacion_id => params[:partida_financiacion_id])
    @partidas_asociadas = PartidaFinanciacion.find( params[:partida_financiacion_id] ).partida
    render :update do |page|
      page.replace_html params[:update], :partial => "partidas_asociadas", :locals => { :update => params[:update], :partida_financiacion_id => params[:partida_financiacion_id] }
      page.visual_effect :highlight, params[:update] , :duration => 6
      page.replace_html 'MB_content', :inline => '<div id="mensajeok"><%= _("Se ha eliminado correctamente.") %></div><br>'
      page.call("Modalbox.resizeToContent")
    end
  end

 private

  # Se asegura de que el proyecto este en un estado que permita la modificacion de partidas
  def verificar_estado_ajax
    estado = @proyecto.definicion_estado if @proyecto
    # Si el proyecto no tiene estado o no esta cerrado y ademas esta en formulacion o no esta aprobado...
    unless @proyecto.nil? || (estado && !estado.cerrado && ( estado.formulacion || !estado.aprobado ))
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar las partidas.")    if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.") % {:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se pueden modificar las partidas.") unless @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end

end
