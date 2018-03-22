# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2015 Free Software's Seed
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


class TipoContratoController < ApplicationController

  before_filter :tipo_contrato, except: [ :index, :ordenado, :filtrado, :elementos_filtrado, :listado, :listado_documentos, :listado_campos ]
  before_filter :elementos_filtrado, only: [ :listado ]

  # --
  # Metodos de Gestión de Tipos de Contrato
  # ++

  def index
    redirect_to :action => :listado 
  end

  # en agentes: establece los parametros de ordenación
  def ordenado
    session[:tipo_contrato_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    session[:tipo_contrato_orden] = params[:orden] ? params[:orden] : "nombre"
    redirect_to :action => :listado
  end

  # en agentes: establece los parametros de filtro
  def filtrado
    session[:tipo_contrato_filtro_creador] = params[:filtro][:creador] if params[:filtro][:creador]
    redirect_to :action => :listado
  end

  def elementos_filtrado
    session[:tipo_contrato_asc_desc] ||= "ASC"
    session[:tipo_contrato_orden] ||= "nombre"
    session[:tipo_contrato_filtro_creador] ||= "todos"

    @creador = Agente.find_by_id( session[:tipo_contrato_filtro_creador] ) if session[:tipo_contrato_filtro_creador].to_i > 0

    datos_formulario
    opciones_generales = { "todos" => _("Todos"), "general" => _("Administración General") }
    filtro_creador = opciones_generales.collect{|k,v| [v,k]} + @agentes
    
    @opciones_filtrado = [ {:rotulo => _("Seleccione creador"), :nombre => "creador", :opciones => filtro_creador} ]
    @accion_filtrado = {:action => :filtrado, :listado => :listado}
    @estado_filtrado = [ (@creador ? @creador.nombre : (opciones_generales[session[:tipo_contrato_filtro_creador]] || _("Todos")) ) ]
  end


  # en agentes y administracion: lista los tipos de contrato
  def listado
    elementos_filtrado 
    condiciones = {}
    condiciones[:agente_id] = @creador.id if @creador
    condiciones[:agente_id] = nil if session[:tipo_contrato_filtro_creador] == "general"
    condiciones[:agente_id] = [@agente.id, nil] if @agente && session[:tipo_contrato_filtro_creador] == "todos"

    @tipos_contrato = @paginado = TipoContrato.where(condiciones).
                                               order(session[:tipo_contrato_orden] + " " + session[:tipo_contrato_asc_desc]).
		                               paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                                        per_page: (params[:format_xls_count] || session[:por_pagina]))

    @formato_xls = @tipos_contrato.total_entries
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "tipo_contrato"
        @objetos = @tipos_contrato
        nom_fich = "tipos_contrato_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

  # en agentes y administracion: prepara el formulario de crear o editar
  def editar_nuevo
    @tipo_contrato||= TipoContrato.new(agente_id: (@agente ? @agente.id: nil))
    datos_formulario
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

  # en agentes y administracion: modifica o crea un tipo de contrato 
  def modificar_crear
    @tipo_contrato||= TipoContrato.new(agente_id: (@agente ? @agente.id: nil))
    @tipo_contrato.update_attributes params[:tipo_contrato]
    if @tipo_contrato.errors.empty?
      # Si es uno ya existente, modifica la linea
      render(:update) { |page|   page.modificar :update => params[:update], :partial => "tipo_contrato" , :mensaje => { :errors => @tipo_contrato.errors } } if params[:id]
      # Si es uno nuevo lo incluye en la parte superior del listado
      render :update do |page|
        page.show "nuevos_tipos_contrato"
        page.modificar :update => "tipo_contrato_nuevo_" + params[:i], :partial => "nuevo_tipo_contrato", :mensaje => { :errors => @tipo_contrato.errors }
        page.replace "formulario_anadir_anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>"
      end unless params[:id] 
    else
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @tipo_contrato.errors} }
    end 
  end

  # en agentes y administracion: elimina un tipo de contrato 
  def eliminar
    @tipo_contrato.destroy if @tipo_contrato
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @tipo_contrato.errors, :eliminar => true}}
  end

  # --
  # Metodos de Gestión de Documentos asociados a Tipos de Contrato
  # Esto lo hacemos asi y no en el controlador de documentos para poder filtrar que documentos asociamos
  # ++

  # Lista todos los documentos asociados al tipo de contrato proporcionado
  def listado_documentos
    @tipo_contrato = TipoContrato.find_by_id params[:id]
    @documentos = @tipo_contrato.documento
    render(:update) { |page| page.replace_html(params[:update], partial: "listado_documentos", locals: {update_listado: params[:update]}) }
  end

  # Prepara el formulario de asociacion de documento 
  def editar_nuevo_documento
    @documentos = Documento.joins(:etiqueta).where("etiqueta.tipo" => "plantilla", "etiqueta.nombre" => "Contrato") - @tipo_contrato.documento 
    render(:update){ |page| page.formulario partial: "formulario_documento", update: params[:update] }
  end

  # Registra una nueva asociacion de tipo de contrato  
  def modificar_crear_documento
    # Busca el documento de plantilla documental de contratos que tenga ese documento_id
    documento_id = params[:documento] ? params[:documento][:id] : nil
    @documento = Documento.joins(:etiqueta).where("etiqueta.tipo" => "plantilla", "etiqueta.nombre" => "Contrato").find_by_id(documento_id)
    @tcx = @tipo_contrato.tipo_contrato_x_documento.create(documento_id: @documento.id) if @documento
    @documentos = @tipo_contrato.documento
    errores = @tcx ? @tcx.errors : []
    render(:update) do |page|
      page.modificar :update => params[:update_listado], :partial => "listado_documentos", mensaje: { errors: errores }, locals: { update_listado: params[:update_listado] }
    end
  end

  # Elimina la asocicion con el tipo de contrato proporcionado
  def eliminar_documento
    @documento = @tipo_contrato.tipo_contrato_x_documento.find_by_documento_id(params[:documento_id])
    @documento.destroy if @documento
    @documentos = @tipo_contrato.documento
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @documento.errors, :eliminar => true}}
  end


  # --
  # Metodos de Gestión de Campos asociados a Tipos de Contrato
  # ++

  # Lista los campos asociados al tipo de contrato  
  def listado_campos
    @tipo_contrato = TipoContrato.find_by_id params[:id] 
    @campos = @tipo_contrato.campo_tipo_contrato 
    render(:update) { |page| page.replace_html(params[:update], partial: "listado_campos", locals: {update_listado: params[:update]}) }
  end

  # Prepara el formulario de creacion/edicion de campo
  def editar_nuevo_campo
    @campo = @tipo_contrato.campo_tipo_contrato.find_by_id(params[:campo_id]) || CampoTipoContrato.new(tipo_contrato_id: @tipo_contrato.id)
    datos_formulario_campo
    render(:update){ |page| page.formulario partial: "formulario_campo", update: params[:update] }
  end

  # en proyectos: hace un cambio del tipo de condiciones segun el tipo de campo
  def cambia_tipo_condicion
    @campo = CampoTipoContrato.find_by_id(params[:campo_id]) || CampoTipoContrato.new()
    @campo.tipo_campo = params[:tipo_campo]
    datos_formulario_campo
    render :partial => "condicion_campo"
  end


  # Guarda la modificacion/creacion del campo en bbdd
  def modificar_crear_campo
    @campo = @tipo_contrato.campo_tipo_contrato.find_by_id(params[:campo_id]) || CampoTipoContrato.new(tipo_contrato_id: @tipo_contrato.id)
    @campo.update_attributes params[:campo]

    if @campo.errors.empty?
      @campos = @tipo_contrato.campo_tipo_contrato
      render(:update) do |page|
        page.modificar :update => params[:update_listado], :partial => "listado_campos", mensaje: { errors: @campo.errors }, locals: { update_listado: params[:update_listado] }
      end
    else
      datos_formulario_campo
      render(:update) { |page| page.recargar_formulario partial: "formulario_campo", mensaje: {errors: @campo.errors} }
    end

  end

  # Elimina el campo asociado
  def eliminar_campo
    @campo = @tipo_contrato.campo_tipo_contrato.find_by_id(params[:campo_id])
    @campo.destroy if @campo
    @campos = @tipo_contrato.campo_tipo_contrato
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @campo.errors, :eliminar => true}}
  end

 private
  # Obtiene el tipo de contrato segun los parametros enviados
  def tipo_contrato
    @tipo_contrato = TipoContrato.where(agente_id: @agente.id).find_by_id(params[:id]) if @agente
    @tipo_contrato = TipoContrato.find_by_id(params[:id]) if params[:seccion] == "administracion" 
  end

  # datos del formulario de edicion de tipo
  def datos_formulario
    @agentes = Agente.where(implementador: true, socia_local: false).order(:nombre).collect{|p| [p.nombre, p.id]} if administracion? 
    @agentes = [[@agente.nombre, @agente.id]] if @agente
  end

  # datos del formulario de edicion de campos
  def datos_formulario_campo
    @tipos_condiciones = [[_("Sin condición"), nil]] + ((CampoTipoContrato::TIPOS_DE_CAMPO[@campo.tipo_campo])||[]).collect{|c| [c,c]}
  end

  def administracion? 
    params[:seccion] == "administracion"
  end
end

