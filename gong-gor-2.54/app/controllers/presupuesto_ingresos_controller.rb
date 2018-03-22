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
# Controlador encargado de la gestion de la entidad presupuesto de ingresos.
# Este controlador es utilizado desde las secciones:
# * Sección agentes: se utiliza para la gestión del presupuesto relacionado con agente.
#

class PresupuestoIngresosController < ApplicationController
  before_filter :verificar_etapa


  # --
  # METODOS DE GESTION DE Presupuesto
  # ++

  # en agentes: se redirecciona por defecto a listado
  def index
    redirect_to :action => :listado
  end

  # en agentes: listado de presupuestos para el agente de la sessión
  def listado
    elementos_filtrado
  end

  # en agentes: devuelve el presupuesto para una partida dada
  def presupuesto_x_partida
    @presupuestos = @agente.presupuesto_ingreso.where(etapa_id: @etapa, partida_ingreso_id: @partida)
    render :update do |page|
      page.replace_html params[:update_listado], :partial => "presupuesto_x_partida"
    end
  end

  # en agentes: prepara el formulario de edición o creación de presupuesto
  def editar_nuevo
    datos_formulario
    @presupuesto = @agente.presupuesto_ingreso.where(etapa_id: @etapa, partida_ingreso_id: @partida).find_by_id(params[:id]) || PresupuestoIngreso.new
    render (:update) {|page| page.formulario :partial => "formulario", :update => params[:update]}
  end

  # en agentes: modifica o crea un presupuesto
  def modificar_crear
    @presupuesto = @agente.presupuesto_ingreso.where(etapa_id: @etapa, partida_ingreso_id: @partida).find_by_id(params[:id])
    @presupuesto ||= PresupuestoIngreso.new(agente_id: @agente.id, etapa_id: @etapa.id, partida_ingreso_id: @partida.id)

    # Guarda cambios
    @presupuesto.attributes = params[:presupuesto]
    @presupuesto.save

    if @presupuesto.errors.empty?
      render(:update) do |page|
        # Si el presupuesto ya existía
        if params[:id]
          page.modificar update: params[:update], partial: "presupuesto", locals: { presupuesto: @presupuesto }, mensaje: { errors: @presupuesto.errors }
        # Si es un nuevo presupuesto
        else
          nueva = params[:update_listado] + "_" + @presupuesto.id.to_s
          page.nueva_fila update: params[:update_listado] + "_nuevo", partial: "presupuesto", nueva_fila: nueva, locals: { presupuesto: @presupuesto }, mensaje: { errors: @presupuesto.errors }
        end
        # En cualquier caso, actualiza totales
        if @partida
          page.replace "suma_" + @partida.id.to_s, :partial => "suma", :locals => {:objeto => @partida }
          page.replace "caja_suma_total_inicio", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_inicio"}
          page.replace "caja_suma_total_fin", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_fin"}
        end
      end
    # Si hay fallo grabando el presupuesto mostramos el formulario con el mensaje de error
    else
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @presupuesto.errors} }
    end
  end

  # en agentes: elimina un presupuesto
  def eliminar
    @presupuesto = @agente.presupuesto_ingreso.where(etapa_id: @etapa, partida_ingreso_id: @partida).find_by_id(params[:id])
    @presupuesto.destroy
    partida = PartidaFinanciacion.find_by_id(params[:partida_id])
    render(:update) do |page|
      page.eliminar :update => params[:update], :mensaje =>  {:errors => @presupuesto.errors, :eliminar => true}
      # Actualiza totales
      if @partida 
        page.replace "suma_" + @partida.id.to_s, :partial => "suma", :locals => {:objeto => @partida }
        page.replace "caja_suma_total_inicio", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_inicio"}
        page.replace "caja_suma_total_fin", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_fin"}
      end
    end
  end

  # AJAX para el cambio de financiador en el formulario de presupuestos
  def cambia_financiador
    datos_formulario
    render partial: "formulario_proyecto", locals: {reiniciar_javascript_chosen: true}
  end

 private

  # Comprueba que al menos haya una etapa definida y si la hay obtiene la que el usuario ha seleccionado
  def verificar_etapa
    if @agente.etapa.empty?
      msg_error _("Tiene que definir por lo menos una etapa para acceder a la gestión del presupuesto")
      redirect_to :menu => :configuracion_agente, :controller => :datos_agente, :action => :etapas
    else
      session[:presupuesto_ingresos_filtro_etapa] = params[:etapa_id] if params[:etapa_id]
      @etapa = @agente.etapa.find_by_id session[:presupuesto_ingresos_filtro_etapa] 
      @partida = PartidaIngreso.find_by_id params[:partida_id]
    end
  end

  # Elementos para el filtrado
  def elementos_filtrado
    @etapas = [[_("Seleccione Etapa"), "none"]] + @agente.etapa.sort{ |a, b| a.fecha_inicio <=> b.fecha_inicio }.collect{ |e| [e.nombre, e.id.to_s] }
  end

  # Parametros comunes edicion de un presupuesto 
  def datos_formulario
    @monedas = @agente.moneda.collect {|a| [a.abreviatura, a.id]}
    @financiadores = Agente.where(financiador: true).order("nombre").collect{|f| [f.nombre, f.id.to_s]}

    financiador = Agente.where(financiador: true).find_by_id(params[:financiador_id])
    proyectos = @agente.proyecto_implementador.joins(:agente).where("agente.id" => financiador.id) if financiador
    proyectos = @agente.proyecto_implementador unless financiador
    proyectos_no_cerrados = proyectos.joins(:definicion_estado).where("definicion_estado.cerrado" => false)

    # Mostramos centros de coste si esta el plugin de contabilidad activo y si no, solo el nombre
    contabilidad_no_activa = Plugin.activos.find_by_clase("GorContabilidad").nil?
    @proyectos = proyectos_no_cerrados.collect do |p|
                   cc = p.cuenta_contable.where(agente_id: @agente.id).collect{|cc| cc.codigo}.join(', ') unless contabilidad_no_activa
                   nombre = cc.blank? ? p.nombre : "#{p.nombre} (#{cc})"
                   [nombre, p.id.to_s]
                 end
  end

end

