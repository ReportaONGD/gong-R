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
# * Sección socio: se utiliza para visualizar los pagos de los socios y crear pago de un socio


class PagoSocioController < ApplicationController


  # por defecto redirecionamos hacia ordenado pago
  def index
    session[:socio_seleccionado] = nil
    #redirect_to :action => 'ordenado_pago'
    redirect_to :action => 'filtrado_ordenado_iniciales'
  end

	# en pago_socio: lista los pagos de los socios
  def listado_pago
    condiciones = Hash.new
    condiciones["forma_pago_socio_id"] = session[:pago_socio_filtro_forma_pago] unless session[:pago_socio_filtro_forma_pago] == "todas"
    condiciones["socio_id"] = session[:socio_seleccionado].id if session[:socio_seleccionado]
    unless session[:pago_socio_filtro_fechas] == "todas"
      condiciones["fecha_pago"] = Date.today..(Date.today + session[:pago_socio_filtro_fechas].to_i.months).at_end_of_month if session[:pago_socio_filtro_fechas].to_i > 0
      condiciones["fecha_pago"] = (Date.today + session[:pago_socio_filtro_fechas].to_i.months).at_beginning_of_month..Date.today unless session[:pago_socio_filtro_fechas].to_i > 0
    end

    @pagos = @paginado = PagoSocio.includes(["socio"]).
                                   where(condiciones).
                                   order(session[:pago_socio_orden] + " " + session[:pago_socio_asc_desc]).
                                   paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                            per_page: (params[:format_xls_count] || nil))
    elementos_filtrado

    @formato_xls = @pagos.total_entries
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "pago_socio"
        @objetos = @pagos
        @subobjetos = [ "socio.informacion_socio.datos_tarjeta_socio" ]
        nom_fich = "pagos_socios_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end

  end

  # en pago_socio: establece los parametros de filtrado y ordenación iniciales de los pagos
  def filtrado_ordenado_iniciales
    session[:pago_socio_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"   
    session[:pago_socio_orden] = params[:orden] ? params[:orden] : "fecha_pago" 
    session[:pago_socio_filtro_forma_pago] = "todas"
    session[:pago_socio_filtro_fechas] = "todas"
    redirect_to :action => "listado_pago"
  end

  # en pago_socio: establece los parametros de ordenación
  def ordenado
    session[:pago_socio_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    session[:pago_socio_orden] = params[:orden] ? params[:orden] : "fecha"
    session[:pago_socio_orden] = "socio.nombre" if params[:orden].include?("nombre_completo")
    redirect_to :action => params[:listado] || "listado"
  end

  def filtrado
    session[:pago_socio_filtro_forma_pago] = params[:filtro][:forma_pago]
    session[:pago_socio_filtro_fechas] = params[:filtro][:fechas]
    redirect_to :action => params[:listado]
  end

  def elementos_filtrado
    filtro_forma_pago = [[_("Todas"), "todas"]]  + FormaPagoSocio.all.collect{ |e| [e.forma_pago, e.id.to_s] }
    filtro_fechas = [[_("Cualquier Fecha"), "todas"], [_("Próximo Mes"), "1"], [_("Próximo Trimestre"), "3"], [_("Próximo Semestre"), "6"], [_("Próximo Año"), "12"], [_("Último Mes"), "-1"], [_("Último Trimestre"), "-3"], [_("Último Semestre"), "-6"], [_("Último Año"), "-12"] ]
    @opciones_filtrado = [	{:rotulo => _("Forma de Pago: "), :nombre => "forma_pago", :opciones => filtro_forma_pago},
				{:rotulo => _("Fecha de Pago: "), :nombre => "fechas", :opciones => filtro_fechas} ]

    if session[:pago_socio_filtro_fechas] == "todas"
      cadena_fecha = _("Cualquier Fecha")
    else
      cadena_fecha = session[:pago_socio_filtro_fechas].to_i > 0 ? _("Próximo") : _("Último")
      if session[:pago_socio_filtro_fechas].to_i.abs == 1
        cadena_fecha += " " + _("mes")
      else
        cadena_fecha = cadena_fecha.pluralize + " " + session[:pago_socio_filtro_fechas].to_i.abs.to_s + " " + _("meses")
      end
    end
    @estado_filtrado = [(session[:pago_socio_filtro_forma_pago] == "todas" ? _("Todas las formas de pago") : FormaPagoSocio.find(session[:pago_socio_filtro_forma_pago]).forma_pago ),
			cadena_fecha ]
    @accion_filtrado = {:action => :filtrado, :listado => :listado_pago} 
  end

  # en pago_socio: prepara el formulario de edición o creación de pago
  def editar_nuevo_pago
    @pago = params[:id] ?  PagoSocio.find(params[:id]) : nil
    @formas_pago = FormaPagoSocio.all.collect {|fp| [fp.forma_pago, fp.id]}
    @socios = session[:socio_seleccionado] ? [session[:socio_seleccionado]].collect {|p| [p.nombre, p.id]} : Socio.find(:all).collect {|p| [p.nombre + " " + p.apellido1 + " " + p.apellido2, p.id]}
    render :partial => "formulario_pago"
  end

	# en pago_socio: modifica o crea un pago
  def modificar_crear_pago
    @pago = params[:id] ?  PagoSocio.find(params[:id]) : PagoSocio.new 
    @pago.update_attributes params[:pago]
    msg @pago
    redirect_to :action => "listado_pago"
  end

	# en pago_socio: elimina un pago
  def eliminar_pago
    @pago = PagoSocio.find(params[:id])
    @pago.destroy
    msg_eliminar = @pago
    redirect_to :action => 'listado_pago'
  end

  
  def generar_pagos
    @listado_tipo = [[_("Todos los Tipos"),"todos"]] + FormaPagoSocio.all.collect{ |e| [e.forma_pago, e.id.to_s] }
    #@listado_fechas = [[_("Próximo Mes"), "1"], [_("Próximo Trimestre"), "3"], [_("Próximo Semestre"), "6"], [_("Próximo Año"), "12"]]
    @listado_fechas = [[_("Próximo Mes"), "1"]]
    @import_error = "" 
    if params[:tipo] && params[:fecha]
      @pagos = []
      condiciones = {"informacion_socio.activo" => true}
      condiciones["informacion_socio.forma_pago_socio_id"] = params[:tipo] unless params[:tipo] == "todos"
      # Busca todos los socios activos con esas condiciones
      todos_socios = Socio.all(:include => ["informacion_socio"], :conditions => condiciones)
      PagoSocio.transaction do
        # Recorre los socios buscando los que ya han pagado en esas fechas (esto habria que hacerlo con un outer join)
        todos_socios.each do |socio|
          periodo = socio.informacion_socio.tipo_cuota_socio.meses.month
          # Como fecha limite sumamos 2 meses para pasar a principios de mes (al generar el pago lo ponemos el primer dia del siguiente mes)
          fecha_limite = (Date.today + (2 + params[:fecha].to_i).month ).at_beginning_of_month
          pagos = socio.pago_socio.last(:order => "fecha_emision ASC", :conditions => {:fecha_emision => (Date.today - periodo)..(fecha_limite - periodo) })
          # No tienen pagos hechos 
          if pagos.nil?
            ultimo_pago = socio.pago_socio.last(:order => "fecha_pago")
            fecha = (ultimo_pago.fecha_pago + socio.informacion_socio.tipo_cuota_socio.meses.month) unless ultimo_pago.nil? 
            fecha = (Date.today + 1.month).at_beginning_of_month if ultimo_pago.nil? || fecha < Date.today
            # Solo coge los que les toca pagar dentro del periodo, no mas adelante
            if fecha < fecha_limite
              pago = PagoSocio.new(:socio_id => socio.id, :forma_pago_socio_id => socio.informacion_socio.forma_pago_socio_id, :importe => socio.informacion_socio.importe_cuota, :concepto => "Pago", :fecha_pago => fecha, :fecha_emision => Date.today, :fecha_alta_sistema => Date.today)
              @pagos.push(pago)
              if params[:commit] == _("Generar Pagos Nuevos")
                pago.save
                pago.errors.each {|a, m| @import_error += m + "<br>" } 
              end
            end
          end
        end
        raise(ActiveRecord::Rollback, "Hacemos un rollback") if @import_error != ""
      end 
    end
  end

end
