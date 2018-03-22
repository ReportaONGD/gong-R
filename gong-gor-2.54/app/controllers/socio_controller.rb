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
# Controlador encargado de la gestión de socio. Este controlador es utilizado desde las secciones:
# * Sección socio: se utiliza para crear socio y asignarles usuarios.


class SocioController < ApplicationController


	# en socio: se redirecciona por defecto a ordenado de socio
  def index
    redirect_to :action => 'ordenado'
  end

	# en socio: lista los socios que hay en el sistema
  def listado
    @socio = Socio.find_by_id params[:id]
    @socios = Socio.includes(:naturaleza_socio).
                    order((session[:socio_orden] || "nombre") + " " + (session[:socio_asc_desc] || "ASC")).
                    paginate(page: params[:page], per_page: (session[:por_pagina] or 20))
  end

  # en socio: establece los parametros de ordenación
  def ordenado
    session[:socio_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"   
    session[:socio_orden] = params[:orden] ? params[:orden] : "nombre" 
    redirect_to :action => "listado"
  end
  
  # en socio: prepara el formulario de edición o creación de un socio
  def editar_nuevo
    @socio = Socio.find_by_id(params[:id]) || Socio.new 
    @tratamiento = [ [ _( "Don" ), 1 ], [ _( "Doña" ), 2 ], [ _( "Sr." ), 3 ], [ _( "Sra." ), 4 ] ]
    @paises = Pais.all.collect{ |p| [ p.nombre, p.nombre ] }
    @naturaleza_socio = NaturalezaSocio.find( :all ).collect{ |n| [ n.naturaleza, n.id ] }
    render :partial => "formulario"
  end

	# en socio: modifica o crea un socio
  def modificar_crear
    @socio = Socio.find_by_id(params[:id]) || Socio.new
    @socio.update_attributes params[:socio]
    msg @socio
    redirect_to :action => "listado"
  end

	# en socio: elimina un socio
  def eliminar
    @socio = Socio.find(params[:id])
    @socio.destroy
    msg_eliminar @socio
    redirect_to :action => 'listado'
  end

  def informacion_socio
    @informacion_socio = InformacionSocio.find_by_socio_id(params[:id]) || InformacionSocio.new(socio_id: params[:id])
    render :update do |page|
      page.replace_html params[:update], :partial => "informacion_socio", :locals => {:update => params[:update] }
    end 
  end

  def editar_nuevo_informacion_socio
    @informacion_socio = InformacionSocio.find_by_socio_id(params[:id]) || InformacionSocio.new(socio_id: params[:id])
    @tipo_cuota_socio = TipoCuotaSocio.find( :all ).collect{ |t| [ t.tipo_cuota,  t.id ] }
    @origen_socio = OrigenSocio.find( :all ).collect{ |o| [ o.origen,  o.id ] }
    @forma_pago_socio = FormaPagoSocio.find( :all ).collect{ |f| [ f.forma_pago, f.id ] }
    @naturaleza_socio = NaturalezaSocio.find( :all ).collect{ |n| [ n.naturaleza, n.id ] }
    render :partial => "formulario_informacion_socio"
  end

  def modificar_crear_informacion_socio
    @informacion_socio = InformacionSocio.find_by_socio_id( params[:id] ) || InformacionSocio.new(socio_id: params[:id])
    @informacion_socio.update_attributes params[:informacion_socio]
    if @informacion_socio.errors.empty? && params[:informacion_socio][:forma_pago_socio_id] == FormaPagoSocio.find_by_forma_pago(_("Tarjeta"))
      @informacion_socio.datos_tarjeta_socio ||= DatosTarjetaSocio.new
      @informacion_socio.datos_tarjeta_socio.update_attributes params[:datos_tarjeta_socio]
    end 
    render :update do |page|
      if @informacion_socio.errors.empty? && (@informacion_socio.datos_tarjeta_socio.nil? || @informacion_socio.datos_tarjeta_socio.errors.empty?)
        page.call("Modalbox.hide")
        page.replace_html params[:update], :partial => "informacion_socio", :locals => {:id => params[:id], :update => params[:update] }
        page.visual_effect :highlight, params[:update], :duration => 6
      else
        page.replace_html 'formulario', :inline => '<%= mensaje_error(@informacion_socio) %><br>' unless @informacion_socio.errors.empty?
        page.replace_html 'formulario', :inline => '<%= mensaje_error(@informacion_socio.datos_tarjeta_socio) %><br>' unless @informacion_socio.datos_tarjeta_socio.nil? || @informacion_socio.datos_tarjeta_socio.errors.empty?
        page.call("Modalbox.resizeToContent")
      end
    end 
  end

  def listado_pago_socio
    session[:socio_seleccionado] = Socio.find_by_id params[:id]
    redirect_to :action => "index", :controller => "pago_socio"
  end

end
#done
