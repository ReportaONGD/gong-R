# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2015 Free Software's Seed, CENATIC y IEPALA
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
# Controlador encargado de la gestión del workflow de contratos

# Usamos el net/http para descargar el detalle de contrato en cambios de estado
require 'net/http'

class EstadoContratoController < ApplicationController
  before_filter :verificar_condiciones, only: [:modificar_crear]

  # Se redirecciona por defecto al listado 
  def index
    redirect_to action: 'listado'
  end

  # Lista los estados registrados para el contrato
  def listado
    contrato = (@proyecto||@agente).contrato.find_by_id params[:id]
    @estados = contrato.estado_contrato if contrato
    render :update do |page|
      page.replace_html params[:update], :partial => "listado", :locals =>  {:update_listado => params[:update]}
    end
  end

  # en administracion: prepara el formulario de edición o creación
  def editar_nuevo
    datos_formulario
    render(:update){ |page| page.formulario :partial => "formulario_cambiar_estado", :update => params[:update] }
  end

  # en gestion de estados de un contrato: cambia el estado
  def modificar_crear
    contrato = (@proyecto||@agente).contrato.find_by_id params[:id]
    estado_anterior = contrato.estado_contrato.find_by_id params[:estado_anterior_id]
    # PENDIENTE: Debemos validar que "estado_anterior" tenga el "estado_actual" a true 
    @estado = EstadoContrato.create(contrato_id: contrato.id, fecha_inicio: Date.today, usuario_id: @usuario_identificado.id,
                                    estado_actual: true, workflow_contrato_id: params[:nuevo_estado][:id])
    if @estado.errors.empty?
      if params[:selector] && params[:selector][:detalle] == "1"
        errores_docu = sube_documento_detalle_contrato
        logger.error "----------> ERROR: " + errores_docu.inspect unless errores_docu.empty?
      end
      # Eliminamos al estado anterior como "estado_actual"
      estado_anterior.update_attributes(estado_actual: false, observaciones: params[:estado_anterior][:observaciones], fecha_fin: Date.today) if estado_anterior 
      @estados = contrato.estado_contrato
      # Y luego actualizamos el listado de estados 
      render(:update) { |page| page.replace_html params[:update_listado], :partial => "listado", :locals => {:update_listado => params[:update_listado]} }
    else
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "formulario_cambiar_estado", :update => params[:update], :mensaje => {:errors => @estado.errors} }
    end
  end

 private

  # Adjunta el detalle del contrato al estado actual
  def sube_documento_detalle_contrato
    errores = [] 
    # Metemos todo en un try-catch para capturar errores
    begin
      contrato = @estado.contrato
      # Descargamos el detalle del contrato (lo hacemos asi para poder enviar la cookie)
      uri = url_for(only_path: false, controller: "contrato", action: "detalle", id: contrato.id, format: "pdf")
      url = URI.parse( uri )
      headers = { "Cookie" => "_session_id=" + cookies[:_session_id] }
      result = Net::HTTP.start(url.host, url.port) {|http| http.send_request('GET', url.path, "format=pdf", headers) }
      # Y lo guardamos en un fichero temporal 
      tmp_file = Tempfile.new( ['detalle_contrato_', '.pdf'] )
      tmp_file.binmode
      tmp_file.write(result.body)
      tmp_file.flush

      # Si todo ha ido bien, creamos el documento
      docu_data = { descripcion: _("Detalle del contrato en el momento de cambio de estado a '%{nuevo}'")%{nuevo: @estado.workflow_contrato.nombre},
                    proyecto_id: contrato.proyecto_id, agente_id: contrato.agente_id, usuario_id: @usuario_identificado.id }
      documento = Documento.new( docu_data )
      documento.adjunto = tmp_file
      documento.save

      # Y lo vinculamos con el estado si todo fue ok
      if documento.errors.empty?
        cxd = ContratoXDocumento.create(estado_contrato_id: @estado.id, documento_id: documento.id)
        errores = cxd.errors.full_messages unless cxd.errors.empty?
      else
        errores = documento.errors.full_messages
      end
    rescue Exception => e
      logger.error "--------> (sube_documento_detalle_contrato) Exception: " + e.inspect
      errores.push _("Problemas descargando detalle de contrato.")
    end
    return errores
  end

  # Carga los datos del formulario
  def datos_formulario
    contrato = (@proyecto||@agente).contrato.find_by_id params[:id]
    @estado_actual = contrato.estado_actual
    @estado_siguiente = @estado_actual ? @estado_actual.workflow_contrato.estado_hijo.order(:orden) : WorkflowContrato.where(primer_estado: true)
    @estado_siguiente.collect!{ |a| [a.nombre, a.id] }
  end

  # Se asegura de que el cambio pueda producirse
  def verificar_condiciones
  end

end
