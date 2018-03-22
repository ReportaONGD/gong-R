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
# Controlador encargado del resumen inicial del usuario o el proyecto. Este controlador es utilizado desde las secciones:
# * Sección inicio: visualizar los datos relativos al usuario
# * Sección proyectos: visualizar y los datos relativos al proyecto

class InfoController  < ApplicationController

  before_filter :obtiene_proyectos
  before_filter :comprobar_tasas_cambio

  # El metodo comprobar_periodo_identificador_financiador se encuentra en el ApplicationController
  before_filter :comprobar_periodo_identificador_financiador

  def index
    if @proyecto
      @periodos={}
      @periodos["oficiales"] = periodos_elemento("oficiales")
      @periodos["internos"]  = periodos_elemento("internos")
      @periodos["prorrogas"] = periodos_elemento("prorrogas")
      condiciones_tareas = ["estado_tarea.activo IS TRUE AND proyecto_id = ? AND usuario_asignado_id = ?",@proyecto.id, @usuario_identificado.id]
    elsif @agente
      condiciones_tareas = ["estado_tarea.activo IS TRUE AND agente_id = ? AND usuario_asignado_id = ?",@agente.id, @usuario_identificado.id]
    else
      @periodos={}
      @periodos["oficiales"] = periodos_elemento("oficiales")
      @periodos["internos"]  = periodos_elemento("internos")
      @periodos["prorrogas"] = periodos_elemento("prorrogas")
      c_posibles_prorrogas = ["(fecha_inicio_aviso_peticion_prorroga IS NOT NULL AND fecha_inicio_aviso_peticion_prorroga < ? AND fecha_limite_peticion_prorroga IS NOT NULL AND fecha_limite_peticion_prorroga > ?) OR (fecha_inicio_aviso_peticion_prorroga_justificacion IS NOT NULL AND fecha_inicio_aviso_peticion_prorroga_justificacion < ? AND fecha_limite_peticion_prorroga_justificacion IS NOT NULL AND fecha_limite_peticion_prorroga_justificacion > ?)", Date.today, Date.today, Date.today, Date.today]
      @proyectos_fechas_prorroga = @usuario_identificado.proyecto.where(c_posibles_prorrogas)
      condiciones_tareas = ["estado_tarea.activo IS TRUE AND proyecto_id IN (?) AND usuario_asignado_id = ?",@usuario_identificado.proyecto, @usuario_identificado.id]
    end
    @tareas = Tarea.find( :all, :conditions => condiciones_tareas, :include => [:tipo_tarea, :estado_tarea], :order => ("fecha_inicio"))
    render 'proyecto' if @proyecto
    render 'agente' if @agente
    render 'usuario' unless @proyecto || @agente 
  end

  def listado_periodo
    tipo = params[:tipo]
    periodos = periodos_elemento(tipo)
    respond_to do |format|
      format.html do
        render(:update) { |page|  page.replace("periodos_" + tipo, partial: "periodos", locals: {periodos: periodos, tipo: tipo}) }
      end
    end
  end

  def mas_proyectos
    render :update do |page|
      page.replace params[:update], :partial => 'proyectos'
    end
  end

  # Genera las cajas de detalle de un proyecto
  def listado_proyecto_detalle
    respond_to do |format|
      format.html do
        render(:update) { |page|  page.replace_html(params[:update], partial: "listado_proyecto_detalle") }
      end
    end
  end

  # Obtiene el detalle de financiacion del proyecto
  def detalle_financiadores_proyecto
    render partial: "detalle_financiadores_proyecto"
  end

  # METODOS DE Plantillas de documentos asociados Ficha Resumen
  #++

  # Genera un documento  (ojo, el codigo hay que pasarlo a una libreria para unificar y simplificar controladores)
  def ficha_resumen
    @proyecto = Proyecto.find_by_id(params[:proyecto_id])
    @documento = Documento.includes("etiqueta").where("etiqueta.nombre" => "Ficha Resumen", "etiqueta.tipo" => "plantilla").first

    if @documento && File.exists?(@documento.adjunto.path)
      nom_fich = @proyecto.nombre + "." + @documento.adjunto_file_name
      fichero = Tempfile.new("proyecto_" + @proyecto.id.to_s + "_" + SecureRandom.hex)
      fichero.close

      valores = @proyecto.campos_plantilla.merge(campos_plantilla)

      begin
        source = Word::WordDocument.new(@documento.adjunto.path)
        # Hay que cambiar la forma de hacerlo para que se lean las claves del documento y se busque el valor
        valores.each { |k,v| source.replace_all("{{" + k.to_s.upcase + "}}", v.to_s) }
        source.save(fichero.path)
        send_file fichero.path, :filename => nom_fich, :type => @documento.adjunto_content_type, :disposition => 'inline'
      rescue => ex
        logger.error ex.message
        logger.error ex.backtrace
        msg_error = _("Se produjo un error leyendo la plantilla: %{msg_err}")%{:msg_err => ex.message}
        redirect_to :action => 'index'
      end
    else
      msg_error _("No se pudo encontrar una plantilla de 'ficha_resumen'.") + " " + _("Contacte con el administrador del sistema.")
      redirect_to :action => 'index'
    end
  end

 private

  def obtiene_proyectos
    @proyectos = @agente.proyecto_implementador.includes("definicion_estado").where("definicion_estado.aprobado" => true, "definicion_estado.cerrado" => false, "convenio_id" => nil) if @agente
    @proyectos = @usuario_identificado.proyecto.includes(:definicion_estado).where("NOT definicion_estado.cerrado").
                                       order("definicion_estado.orden desc, proyecto.nombre").
                                       paginate(:page => (params[:page] || 1), :per_page => 3) unless @proyecto || @agente
  end

  def periodos_elemento tipo=nil
    proyectos = @proyecto || @usuario_identificado.proyecto.joins(:definicion_estado).where("definicion_estado.cerrado" => false)
    if tipo=="oficiales"
      condiciones = ["tipo_periodo.oficial = 1 AND tipo_periodo.grupo_tipo_periodo NOT IN ('prorroga','prorroga_justificacion')"]
    elsif tipo=="internos"
      condiciones = ["tipo_periodo.oficial = 0 AND tipo_periodo.grupo_tipo_periodo NOT IN ('prorroga','prorroga_justificacion')"]
    elsif tipo=="prorrogas"
      condiciones = ["tipo_periodo.grupo_tipo_periodo IN ('prorroga','prorroga_justificacion')"]
    end
    condicion_periodo_cerrado = (GorConfig.getValue(:SHOW_ONLY_PERIODS_TO_BE_ACCEPTED) == "FALSE") ?
                                "" : "periodo_cerrado = 0" 
    return Periodo.where(condicion_periodo_cerrado).
                   includes(:tipo_periodo).
                   where(condiciones).
                   where(proyecto_id: proyectos).
                   order(:fecha_inicio).
                   paginate(page: params[:page]||1, per_page: session[:por_pagina])
  end

  # Comprueba que existan tasas de cambio para presupuesto y para gastos
  def comprobar_tasas_cambio
    if @proyecto && @proyecto.estado_actual && @proyecto.definicion_estado.aprobado
      mensaje = ""
      # Comprueba que haya TC de gasto para cada moneda configurada
      tasas = TasaCambio.where(objeto: "Gasto").joins(:etapa).where("etapa.proyecto_id" => @proyecto.id)
      @proyecto.moneda.each do |moneda|
        if tasas.where(moneda_id: moneda.id).empty?
          mensaje += "<br>".html_safe unless mensaje.empty?
          mensaje += _("No se ha configurado una tasa de cambio para la moneda %{mon}.")%{mon: moneda.abreviatura}
        end
      end 
      msg_error mensaje, now: true unless mensaje.empty?
    end
  end
end
