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
# Controlador encargado de la gestion de la tasas de cambio para financiacion tanto para gasto como para presupuesto. Este controlador es utilizado desde las seccion financiaciones
#

class TasaCambioController < ApplicationController

  before_filter :obtener_datos_tasa, except: [:modificar_crear_aplicar_tasa_cambio]

  #--
  # TASAS DE CAMBIO POR ETAPA
  # ++
  
    # en proyectos y agentes: lista las tasas de cambio a aplicar
  def tasa_cambio
    @tasas = tasas_x_etapa @etapa
    render :update do |page|
      page.replace_html params[:update], :partial => "listado_tasa_cambio"
    end

  end

    # en proyectos y agentes: crea una nueva tasa de cambio 
  def editar_nuevo_tasa_cambio
    @tasa = @etapa.tasa_cambio.find_by_id(params[:id]) || TasaCambio.new(:etapa_id => @etapa.id, :fecha_inicio => @etapa.fecha_inicio, :fecha_fin => @etapa.fecha_fin)
    render :partial => "formulario_tasa_cambio"
  end

    # en proyectos y agentes: modifica un rango temporal de tasa de cambio
  def modificar_crear_tasa_cambio
    if @etapa
      @tasa = @etapa.tasa_cambio.find_by_id(params[:id]) || TasaCambio.new(:etapa_id => params[:etapa_id])
      # Ajusta los tiempos cuando se selecciona toda la etapa
      if (params[:selector][:etapa] == "1")
        params[:tasa][:fecha_inicio] = @etapa.fecha_inicio.to_s
        params[:tasa][:fecha_fin] = @etapa.fecha_fin.to_s
      end
      # Fuerza a tasa fija si el objeto es presupuestos
      params[:tasa][:tasa_fija] = "true" if params[:tasa][:objeto] == "presupuesto"
      # Elimina la tasa de cambio a divisa si el objeto es presupuestos
      params[:tasa].delete(:tasa_fija) if params[:tasa][:objeto] == "presupuesto"
      # Obtiene el valor actual de las tasas para gastos mediante ponderada
      if params[:tasa][:tasa_fija] == "false"
        (tasa_cambio,tasa_cambio_divisa) = TasaCambio.media_ponderada((@proyecto||@agente), params[:tasa][:moneda_id].to_i, params[:tasa][:fecha_inicio], params[:tasa][:fecha_fin])
        params[:tasa][:tasa_cambio] = tasa_cambio
        params[:tasa][:tasa_cambio_divisa] = tasa_cambio_divisa
      end
      @tasa.update_attributes params[:tasa]
    end
    @tasas = tasas_x_etapa @etapa
    render :update do |page|
      page.replace_html params[:update], :partial => "listado_tasa_cambio"
      page.visual_effect :highlight, params[:update] , :duration => 6
      page.replace 'formulario', :inline => '<%= mensaje_error(@tasa) %><br>'
      page.call("Modalbox.resizeToContent")
    end
  end

  def eliminar_tasa_cambio
    @tasa = @etapa.tasa_cambio.find(params[:id])
    @tasa.destroy
    @tasas = tasas_x_etapa @etapa
    render :update do |page|
      page.replace_html params[:update], :partial => "listado_tasa_cambio"
      page.visual_effect :highlight, params[:update] , :duration => 6
      page.replace_html 'MB_content', :inline => '<%= mensaje_error(@tasa, :eliminar => true) %><br>'
      page.call("Modalbox.resizeToContent")
    end
  end

  # Aplica las TC a todo el proyecto y presenta el resultado
  def modificar_crear_aplicar_tasa_cambio
    TasaCambio.actualiza_gastos(@proyecto, params[:fecha_inicio], params[:fecha_fin]) if @proyecto
    render :update do |page|
      texto_mensaje = _("Se han revisado las tasas de cambio aplicadas a cada uno de los gastos del proyecto.")
      page.insert_html :after, "aplicar_tasas_cambio_borrado", :inline => mensaje_advertencia(:identificador => "info_tc", :texto => texto_mensaje)
      page.call('Element.hide("aplicar_tasas_cambio_borrado");Element.hide("aplicar_tasas_cambio_borradofondo");Element.show("info_tc_borrado");Element.show("info_tc_borradofondo")')
    end
  end

  private

	# Obtenemos etapa y monedas aplicables
    def obtener_datos_tasa
      if params[:etapa_id] && (@proyecto || @agente).moneda_principal
        @etapa = (@proyecto || @agente).etapa.find_by_id(params[:etapa_id])
        @monedas = ((@proyecto || @agente).moneda - [(@proyecto || @agente).moneda_principal]).collect {|m| [m.abreviatura, m.id]}
        # Pilla todos los financiadores menos el principal
        @financiadores = [ [@proyecto.agente.nombre,nil] ] + (@proyecto.financiador - [@proyecto.agente]).collect{|a| [a.nombre, a.id]} if @proyecto
      else 
        mensaje_error = _("No se ha definido la moneda principal. Contacte con el administrador para resolver el problema.")
        if params[:update]
          page.replace_html params[:update], :inline => mensaje_error
        else
          render :partial => mensaje_error
        end 
      end
    end

	# Devuelve las tasas de cambio en la etapa
    def tasas_x_etapa etapa
      return etapa.tasa_cambio.all(:order => "objeto desc, moneda.abreviatura asc, fecha_inicio asc", :include => "moneda")
    end

end
