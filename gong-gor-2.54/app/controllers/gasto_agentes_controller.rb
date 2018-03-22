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
# Controlador encargado de la gestion de Gastos. Este controlador es utilizado desde las secciones:
# * Sección agentes: se utiliza para la gestión de los gastos relacionados con agente.
#
class GastoAgentesController < ApplicationController

  # --
  # METODOS DE ENTRADA A PRESUPUESTO. Seleccion de ETAPA
  # ++

  # en agentes: se redirecciona por defecto a listado_etapas
  def index
    redirect_to :action => :filtrado_ordenado_iniciales
  end


  # --
  # METODOS DE GESTION DE Gasto: Listados de gasto, modificar_crear, y eliminar
  # ++

  def filtrado_ordenado_iniciales
    if @agente.etapa.empty? 
      msg_error _("Tiene que definir por lo menos una etapa")
      redirect_to :menu => :configuracion_agente, :controller => :datos_agente, :action => :etapas
    else
      session[:gasto_agentes_asc_desc] = "ASC" 
      session[:gasto_agentes_cadena_orden] = "fecha"
      session[:gasto_agentes_filtro_etapa] = "todas"
      session[:gasto_agentes_filtro_moneda] = "todas"
      session[:gasto_agentes_filtro_proyecto] = "todos"
      session[:gasto_agentes_filtro_partida] = "todas"
      session[:gasto_agentes_filtro_subpartida] = "todas"
      session[:gasto_agentes_filtro_marcado] = "todos"
      session[:gasto_agentes_filtro_inicio], session[:gasto_agentes_filtro_final] = nil, nil 
      session[:gasto_agentes_filtro_aplicar_fecha] = false
      session[:gasto_agentes_filtro_ref_contable] = ""
      session[:gasto_agentes_filtro_empleado] = "todos"
      redirect_to :action => :listado
    end
  end

  # en agentes: establece los parametros de ordenación
  def ordenado
    session[:gasto_agentes_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC" 
    session[:gasto_agentes_cadena_orden] = session[:gasto_agentes_orden] = params[:orden] ? params[:orden] : "fecha"
    session[:gasto_agentes_cadena_orden] = "partida.codigo" if session[:gasto_agentes_orden] == "partida.codigo_nombre"
    redirect_to :action => "listado"
  end

  def filtrado
    session[:gasto_agentes_filtro_etapa] = params[:filtro][:etapa]
    session[:gasto_agentes_filtro_moneda] = params[:filtro][:moneda]
    session[:gasto_agentes_filtro_proyecto] = params[:filtro][:proyecto]
    session[:gasto_agentes_filtro_partida] = params[:filtro][:partida]
    session[:gasto_agentes_filtro_subpartida] = params[:filtro][:subpartida]
    session[:gasto_agentes_filtro_marcado] = params[:filtro][:marcado]
    session[:gasto_agentes_filtro_aplicar_fecha] = params[:filtro][:aplicar_fecha] == "1" ? true : false
    if session[:gasto_agentes_filtro_aplicar_fecha]
      session[:gasto_agentes_filtro_inicio]= Date.new params[:filtro]["inicio(1i)"].to_i ,params[:filtro]["inicio(2i)"].to_i ,params[:filtro]["inicio(3i)"].to_i
      session[:gasto_agentes_filtro_final]= Date.new params[:filtro]["final(1i)"].to_i ,params[:filtro]["final(2i)"].to_i ,params[:filtro]["final(3i)"].to_i
    else
      session[:gasto_agentes_filtro_inicio], session[:gasto_agentes_filtro_final] = nil, nil
    end
    session[:gasto_agentes_filtro_ref_contable] = params[:filtro][:ref_contable]
    session[:gasto_agentes_filtro_empleado] = params[:filtro][:empleado]
    redirect_to :action => :listado
  end

  # De momento no funciona por que habria que modificar el comportamiento del autocomplete para el filtrado paa que mostrase la caja encima del fild text
  def auto_complete_for_filtro_concepto
    @gastos= Gasto.find(:all, :conditions => ['concepto like ? and agente_id = ?', "%#{params[:search]}%", params[:agente_id].to_s])
    render :partial => "concepto"
  end



 def elementos_filtrado
    filtro_etapa = [[_("Todas"), "todas"]] + @agente.etapa.sort{ |a, b| a.fecha_inicio <=> b.fecha_inicio }.collect{ |e| [e.nombre, e.id.to_s] }
    filtro_proyecto =[[_("Todos"), "todos"], [_("No vinculado a proyectos"), "no vinculado"]] + @agente.proyecto_implementador.collect{ |e| [e.nombre, e.id.to_s]}
    filtro_moneda =[[_("Todas"), "todas"]] + @agente.moneda.collect{ |e| [e.nombre, e.id.to_s]}
    filtro_empleado =[[_("Todos"), "todos"]] + @agente.empleado.collect{ |e| [e.nombre, e.id.to_s]}
    filtro_partida =[[_("Todas"), "todas"]] + Partida.find(:all, :conditions => "ocultar_agente is NULL OR ocultar_agente = 0" ).collect{ |e| [e.nombre, e.id.to_s]}
    filtro_subpartida =[[_("Todas"), "todas"]] + @agente.subpartida.collect{ |e| [e.nombre, e.id.to_s]}
    filtro_marcado = [[_("Todos"), "todos"]] + Marcado.all(:order => "nombre").collect{ |e| [e.nombre, e.id.to_s] }

    @opciones_filtrado = [{:rotulo =>  _("Seleccione etapa"), :nombre => "etapa", :opciones => filtro_etapa},
                          {:rotulo =>  _("Seleccione moneda"), :nombre => "moneda", :opciones => filtro_moneda},
                          {:rotulo =>  _("Seleccione empleado"), :nombre => "empleado", :opciones => filtro_empleado},
                          {:rotulo =>  _("Seleccione partida"), :nombre => "partida", :opciones => filtro_partida},
                          {:rotulo =>  _("Seleccione subpartida"), :nombre => "subpartida", :opciones => filtro_subpartida},
                          {:rotulo =>  _("Seleccione proyecto"), :nombre => "proyecto", :opciones => filtro_proyecto},
                          {:rotulo =>  _("Seleccione marcado"), :nombre => "marcado", :opciones => filtro_marcado},
                          {:rotulo =>  _("Seleccione ref.contable"), :nombre => "ref_contable", :tipo => "texto"},
                          {:rotulo =>  _("Fecha inicio"), :nombre => "inicio", :tipo => "calendario"},
                          {:rotulo =>  _("Fecha fin"), :nombre => "final", :tipo => "calendario"}, 
                          {:rotulo =>  _("Aplicar filtro fecha"), :nombre => "aplicar_fecha", :tipo => "checkbox"}] 

    texto_proyectos = if session[:gasto_agentes_filtro_proyecto] == "todos"
                        _("Cualquier proyecto")
                      elsif session[:gasto_agentes_filtro_proyecto] == "no vinculado"
                        _("No vinculado a proyectos")
                      else
                        Proyecto.find(session[:gasto_agentes_filtro_proyecto]).nombre
                      end

    @accion_filtrado = {:action => :filtrado }
  end

  # en agentes: lista en función de la etapa y del agente
  def listado
    (condiciones, condiciones_marcado, condiciones_ref_contable) = condiciones_listado
    @paginado = @gastos = Gasto.where(condiciones_marcado).where(condiciones_ref_contable).
                                includes([:partida, :gasto_x_proyecto, :subpartida_agente]).
                                where(condiciones).
                                order(session[:gasto_agentes_cadena_orden] + " " + session[:gasto_agentes_asc_desc]).
                                paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                         per_page: (params[:format_xls_count] || session[:por_pagina]) )
    elementos_filtrado

    @formato_xls = @gastos.total_entries
    @listado_mas_info = {:action => 'suma_total_listado'}

    respond_to do |format|
      format.html
      format.xls do
        @tipo = "gasto_agentes"
        @objetos = @gastos
        nom_fich = "gasto_agente_" + @agente.nombre.gsub(' ','_') + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

        # en agentes: prepara el popup con informacion del importe total de los gastos mostrados
  def suma_total_listado
    #filtrado_ordenado_iniciales
    (condiciones, condiciones_marcado, condiciones_ref_contable) = condiciones_listado
    gastos = Gasto.where(condiciones_marcado).where(condiciones_ref_contable).includes([:partida, :gasto_x_proyecto, :subpartida_agente]).where(condiciones)
    numero_elementos = gastos.count
    suma_total = gastos.joins(:tasa_cambio_agente).sum("importe*tasa_cambio")
    suma_total_formateada = float_a_moneda(suma_total)
    render :update do |page|
      texto_mensaje = _("%{num} gastos con un importe total (aplicando tasas de cambio) de %{val} %{mon}")%{:num => numero_elementos, :val => suma_total_formateada, :mon => @agente.moneda_principal.abreviatura}
      page.insert_html :after, "cabecera",:inline => mensaje_advertencia(:identificador => "info_listado", :texto => texto_mensaje)
      page.call('Element.show("info_listado_borrado")')
    end
  end

  def datos_formulario
    # Como a veces nos pueden llegar peticiones desde otro controlador, asumimos el filtro de etapa a "todas" si no se ha definido aun
    session[:gasto_agentes_filtro_etapa] ||= "todas"
    # Si no se ha filtrado por la etapa, la seleccionamos segun la fecha del gasto
    if session[:gasto_agentes_filtro_etapa] == "todas" && @gasto && @gasto.fecha
      et = @agente.etapa.where("fecha_inicio <= ? AND fecha_fin >= ?", @gasto.fecha, @gasto.fecha).first
      session[:gasto_agentes_filtro_etapa] = et ? et.id : "todas"
    end
    # Ponemos la fecha inicio y la fecha fin para filtrar en el selector de fechas.
    if session[:gasto_agentes_filtro_etapa] == "todas" 
      @fecha_inicio = @agente.etapa.minimum("fecha_inicio")
      @fecha_fin = @agente.etapa.maximum("fecha_fin")
    else
      @etapa = Etapa.find( session[:gasto_agentes_filtro_etapa] )
      @fecha_inicio, @fecha_fin = @etapa.fecha_inicio, @etapa.fecha_fin
      params[:disabled] = @etapa.cerrada
    end
    partidas = Partida.all(:order => "codigo", :conditions => {"ocultar_agente" => false} )
    @partidas = partidas.collect {|p| [p.codigo_nombre, p.id]}
    partidas_empleado = partidas.select {|p| p.tipo_empleado }
    @partidas_empleado = partidas_empleado.empty? ? [] : partidas_empleado.collect {|p| p.id}
    @libros = @agente.libro.all(:order => "nombre", :conditions => {:bloqueado => :false}).select{|l| @usuario_identificado.libro.include? l}
    #@monedas = @agente.libro.collect{|l| [l.moneda.abreviatura,l.moneda_id]}.uniq
    @monedas = @agente.moneda.collect{|m| [m.abreviatura,m.id]}
    @paises = [ [@agente.pais.nombre, @agente.pais.id] ]
    @proyectos = @gasto.gasto_x_proyecto @proyecto
    @empleados = @agente.empleado.collect{|e| [e.nombre, e.id] }
  end

  # en agentes: prepara el formulario de edición o creación
  def editar_nuevo
    @gasto = @objeto = params[:id] ?  Gasto.find(params[:id]) : Gasto.new(agente_id: @agente.id)
    datos_formulario
    render :update do |page|
      # Para permitir abrir el formulario desde importacion contable... habria que cambiar todos los formularios de gasto para meterle el update
      update = params[:update] || (params[:id] ? @gasto.id.to_s : "formulario_anadir") 
      #page.formulario(:partial => "gasto_proyectos/formulario", :update => params[:id] ? @gasto.id.to_s : "formulario_anadir" ) if session[:gasto_agentes_filtro_etapa] != "todas"
      page.formulario(:partial => "gasto_proyectos/formulario", :update => update) if session[:gasto_agentes_filtro_etapa] != "todas"
      #page.mensaje_informacion params[:id] ? @gasto.id.to_s : "formulario_anadir", _("Seleccione etapa para poder gestionar la fecha del gasto"), :tipo_mensaje => "mensajefallo" if session[:gasto_agentes_filtro_etapa] == "todas"
      page.mensaje_informacion update, _("Seleccione etapa para poder gestionar la fecha del gasto"), :tipo_mensaje => "mensajefallo" if session[:gasto_agentes_filtro_etapa] == "todas"
    end
  end

  # en agentes: prepara el formulario de copiado de gasto 
  def editar_copia
    gasto_orig = Gasto.find_by_id(params[:id]) || Gasto.new
    @gasto = @objeto = Gasto.new(gasto_orig.attributes)
    @pago = gasto_orig.pago.first
    datos_formulario
    # Esto tiene que ir detras de 'datos_formulario' para recoger los proyectos del gasto original
    @proyectos = gasto_orig.gasto_x_proyecto
    render :update do |page|
      page.formulario(:partial => "gasto_proyectos/formulario", :update => "formulario_anadir" ) if session[:gasto_agentes_filtro_etapa] != "todas"
      page.mensaje_informacion "formulario_anadir", _("Seleccione etapa para poder gestionar la fecha del gasto"), :tipo_mensaje => "mensajefallo" if session[:gasto_agentes_filtro_etapa] == "todas"
    end
  end

  # en agentes: modifica o crea comprobando que las fechas de la etapa coinciden
  def modificar_crear
    gasto = params[:id] ?  Gasto.find(params[:id]) : Gasto.new(:agente_id => @agente.id)
    libro = Libro.find_by_id(params[:pago][:libro_id]) if gasto.pago.count <= 1 && params[:pago] && params[:pago][:total] && params[:pago][:libro_id]
    params[:gasto][:moneda_id] = libro.moneda_id if libro
    gasto.attributes = params[:gasto]
    # Comprobamos que la fecha está dentro de la etapa antes de hacer nada
    etapa = Etapa.find( session[:gasto_agentes_filtro_etapa] ) if session[:gasto_agentes_filtro_etapa] != "todas"
    if session[:gasto_agentes_filtro_etapa] != "todas" and params[:gasto][:fecha] != "" and 
    (params[:gasto][:fecha].to_date >= etapa.fecha_inicio && params[:gasto][:fecha].to_date <= etapa.fecha_fin)
      gasto.update_attributes params[:gasto]
      # Actualiza el gasto_x_proyectos 
      if gasto.errors.empty?
        gasto.actualizar_gasto_x_proyecto params[:proyectos]
        # Si ha dado un error de distribucion por proyectos y tenemos la variable de configuración especifica activda
        # ("CLOSE_EXPENSES_FORM_ON_PROJECTS_ERRORS") creamos cerrar_formulario_con_errores a true.
        # Esto lo hacemos para diferenciar posteriormente si vamos a cerrar o no el formulario de gasto
        config_errores_proyectos =  GorConfig.getValue("CLOSE_EXPENSES_FORM_ON_PROJECTS_ERRORS")
        cerrar_formulario_con_errores = true if config_errores_proyectos == "TRUE" and gasto.errors.size > 0
      end
      # Genera un pago unico con fecha del gasto si se ha seleccionado y el gasto es nuevo
      if ( gasto.pago.count <= 1 && gasto.errors.empty? && params[:pago] && params[:pago][:total] == "1" ) and 
        pago = gasto.pago.first || Pago.new
        pago.importe = gasto.importe
        pago.fecha = gasto.fecha
        pago.libro_id = params[:pago][:libro_id]
        pago.observaciones = params[:gasto][:concepto]
        pago.forma_pago = params[:pago][:forma_pago]
        pago.referencia_pago = params[:pago][:referencia_pago]
        pago.gasto = gasto
        pago.save
      end
    else
      gasto.errors.add("fecha", _("La fecha no se encuentra dentro de la etapa seleccionada.")) if session[:gasto_agentes_filtro_etapa] != "todas"
      gasto.errors.add("fecha", _("Seleccione etapa para poder gestionar la fecha del gasto")) unless session[:gasto_agentes_filtro_etapa] != "todas"
    end
    @gasto = @objeto = gasto  
    if gasto.errors.empty? or cerrar_formulario_con_errores
      # recargamos el objeto por si se ha producido un error que visualmetne no aparezca modificado...
      @gasto = @objeto = gasto.reload
      # Marcamos errores para el gasto
      gasto.marcado_errores
      # Si no ha habido fallos grabando
      render(:update) { |page|   page.modificar :update => @gasto.id.to_s, :partial => "gasto" , :mensaje => { :errors => @gasto.errors } } if params[:id]
      # Si es un nuevo gasto
      render :update do |page|
        page.show "nuevos_gastos"
        page.nueva_fila :update => "nuevo", :partial => "gasto", :nueva_fila => @gasto.id.to_s, :mensaje => { :errors => @gasto.errors }
      end unless params[:id]
    else
      # Si hay fallo grabando el gasto mostramos el formulario con el mensaje de error 
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "gasto_proyectos/formulario", :mensaje => {:errors => @gasto.errors} }
    end
  end

  # en agentes: elimina
  def eliminar
    @gasto = Gasto.find(params[:id])
    @gasto.destroy
    render (:update) {|page| page.eliminar :update => @gasto.id.to_s, :mensaje => {:errors => @gasto.errors, :eliminar => true}}
  end

  # --
  # METODOS AJAX DEL FORMULARIO: Moneda y subpartida.
  # ++

  # en agentes:  devuelve la moneda del libro seleccionado para el fomulario
  def moneda_libro
    @moneda = params[:id] != "" ? Libro.find(params[:id]).moneda : nil
    render :inline => <<-FIN
      <%= _("Moneda") %> <br> <%=  @moneda.abreviatura if @moneda %>
      <%= hidden_field('gasto', 'moneda_id', :value => @moneda.id) if @moneda%>
    FIN
  end

  # Devuelve las subpartidas y el listado de empleados asociadas a la partida seleccionada para el fomulario
  def subpartida
    @gasto = params[:gasto_id] ? Gasto.find_by_id(params[:gasto_id]) : Gasto.new
    @partida = Partida.find_by_id params[:id]
    @empleados = @agente.empleado.collect{|e| [e.nombre, e.id] } if @partida.tipo_empleado
    # Mantenemos compatibilidad con gastos de proyectos pues el formulario de edicion de gastos es de estos
    # render partial: "subpartida", locals: { partida_id: params[:id]}
    render(:update) do |page| 
      page.replace_html "formulario_empleado",  :partial => "empleado", :locals => {:gasto => @gasto}
      page.replace_html "subpartida",  :partial => "subpartida", :locals => { :partida_id => params[:id]}
    end
  end

  # en proyectos: hace un cambio del pais segun sea el libro con el que se paga el gasto
  def cambia_pais
    if params[:pais_id]
      libro = @agente.libro.find_by_id params[:pais_id]
      pais = libro.pais if libro
      pais_id = pais.nil? ? nil : pais.id
      pais_nombre = pais.nil? ? nil : pais.nombre
    else
      pais_id = @agente.pais_id
    end
    @paises = [[@agente.pais.nombre,@agente.pais.id]]
    # Confirmar esto para ver si permitimos desde agentes gastos en paises distintos
    @paises.push([pais.nombre,pais.id]) unless pais_nombre.nil? || pais_id == @agente.pais_id
    render :partial => "gasto_proyectos/pais", :locals => {:pais_id => pais_id}
  end

  # --
  # METODOS AJAX DEL FORMULARIO: Autocomplete del emisor de la factua 
  # ++

  def auto_complete_for_gasto_proveedor_nombre
    @proveedores = @agente.proveedor.where(activo: true).find(:all, :conditions => ['nombre like ?', "%#{params[:search]}%"])
    render :inline => "<%= auto_complete_result_3 @proveedores, :nombre %>"
  end
  def auto_complete_for_gasto_proveedor_nif
    @proveedores = @agente.proveedor.where(activo: true).find(:all, :conditions => ['nif like ?', "%#{params[:search]}%"])
    render :inline => "<%= auto_complete_result_3 @proveedores, :nif %>"
  end

  def completa_proveedor_nif
    proveedor = @agente.proveedor.where(activo: true).find_by_nombre("#{params[:search]}")
    render :update do |page|
      # Cambiamos la forma anterior de sustitucion del elemento para mantener el ajax de actualizacion en el
      page.replace "contenedor_gasto_proveedor_nif", :partial => "gasto_proyectos/proveedor_nif", :locals => {obj_value: proveedor.nif}  
    end if proveedor
    render nothing: true unless proveedor
  end
  def completa_proveedor_nombre
    proveedor = @agente.proveedor.where(activo: true).find_by_nif("#{params[:search]}")
    render :update do |page|
      # Cambiamos la forma anterior de sustitucion del elemento para mantener el ajax de actualizacion en el
      page.replace "contenedor_gasto_proveedor_nombre", :partial => "gasto_proyectos/proveedor_nombre", :locals => {obj_value: proveedor.nombre}
    end if proveedor
    render nothing: true unless proveedor
  end

  # --
  # METODOS AJAX DEL FORMULARIO PARA PROYECTOS
  # ++

  # en agentes: muestra el formulario para añadir proyectos
  def proyectos
    @gasto = @objeto = Gasto.find(params[:id])
    @proyectos = @gasto.gasto_x_proyecto @proyecto
    render :partial => "proyectos"
  end

  # en agentes: guarda los proyectos asociados a gasto.
  def guardar_proyectos
    @gasto = @objeto = Gasto.find(params[:id])
    @gasto.actualizar_gasto_x_proyecto params[:proyectos]
    render :update do |page|
      page.replace 'formulario', :inline => '<%= mensaje_error(@gasto) %><br>'
      #page.visual_effect :highlight, @gasto.id.to_s, :duration => 6
    end

  end

  # en agentes: añade un proyecto al formulario
  def anadir_proyecto
    render :update do |page|
      page.replace "proyecto_" + params[:linea], :partial => "proyecto" , :locals =>  { :linea => params[:linea].to_i, :ultima => true}
      #page.call("Modalbox.resizeToContent")
    end
  end


  # --
  # METODOS DE MODIFICACION PARCIAL DE LA INFORMACION DE GASTOS PROVENIENTES DE PROYECTOS 
  # ++

        # en agentes: obtiene info para la edicion de un gasto introducido en un proyecto
  def editar_parcial
    @gasto = @objeto = Gasto.find_by_id(params[:id]) || Gasto.new
    render(:update) { |page| page.formulario :partial => "formulario_parcial", :update => params[:id] }
  end

        # en agentes: modifica un gasto originado en un proyecto 
  def modificar_parcial
    @gasto = @objeto = Gasto.find_by_id(params[:id]) || Gasto.new
    @gasto.update_attributes params[:gasto]
    if @gasto.errors.empty?
      @gasto = @objeto = @gasto.reload
      # Marcamos errores para el gasto
      @gasto.marcado_errores
      # Si no ha habido fallos grabando
      render(:update) { |page|   page.modificar :update => @gasto.id.to_s, :partial => "gasto" , :mensaje => { :errors => @gasto.errors } }
    else
      # Si hay fallo grabando el gasto mostramos el formulario con el mensaje de error 
      render(:update) { |page| page.recargar_formulario :partial => "formulario_parcial", :mensaje => {:errors => @gasto.errors} }
    end

  end

 private
  # Prepara los filtros para el listado
  def condiciones_listado
    condiciones = {:agente_id => @agente.id }
    if session[:gasto_agentes_filtro_aplicar_fecha] and  (session[:gasto_agentes_filtro_inicio] <= session[:gasto_agentes_filtro_final])
      condiciones["gasto.fecha"] = session[:gasto_agentes_filtro_inicio]..session[:gasto_agentes_filtro_final]
    elsif  session[:gasto_agentes_filtro_etapa] != "todas"
      @etapa = Etapa.find( session[:gasto_agentes_filtro_etapa])
      condiciones["gasto.fecha"] = @etapa.fecha_inicio..@etapa.fecha_fin
    end
    condiciones["gasto.moneda_id"] = session[:gasto_agentes_filtro_moneda] unless session[:gasto_agentes_filtro_moneda] == "todas"
    condiciones["gasto.empleado_id"] = session[:gasto_agentes_filtro_empleado] unless session[:gasto_agentes_filtro_empleado] == "todos"
    condiciones["gasto.partida_id"] = session[:gasto_agentes_filtro_partida] unless session[:gasto_agentes_filtro_partida] == "todas"
    condiciones["gasto.subpartida_agente_id"] = session[:gasto_agentes_filtro_subpartida] unless session[:gasto_agentes_filtro_subpartida] == "todas"
    condiciones["gasto_x_proyecto.proyecto_id"] = session[:gasto_agentes_filtro_proyecto] unless session[:gasto_agentes_filtro_proyecto] == "todos" or session[:gasto_agentes_filtro_proyecto] == "no vinculado"
    condiciones["gasto_x_proyecto.proyecto_id"] = nil if session[:gasto_agentes_filtro_proyecto] == "no vinculado"
    # Reemplazados el filtro de marcado por in where antes del paginate
    condiciones_marcado = ["marcado_id = ? OR marcado_agente_id = ?", session[:gasto_agentes_filtro_marcado], session[:gasto_agentes_filtro_marcado]] unless session[:gasto_agentes_filtro_marcado] == "todos"
    # Condiciones para la referencia contable
    condiciones_ref_contable = ["gasto.ref_contable LIKE ?", session[:gasto_agentes_filtro_ref_contable]] unless session[:gasto_agentes_filtro_ref_contable].blank?

    return condiciones, condiciones_marcado, condiciones_ref_contable
  end
end
