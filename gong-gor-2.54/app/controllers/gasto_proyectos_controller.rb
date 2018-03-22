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
# * Sección proyectos: se utiliza para la gestión de los gastos relacionados con proyecto.
#
class GastoProyectosController < ApplicationController

  before_filter :verificar_estado_proyecto, :only => [ :index, :orden_facturas]
  before_filter :verificar_estado_ejecucion_ajax, :only => [ :modificar_crear, :eliminar, :eliminar_todo, :modificar_parcial, :descofinanciar ]
  before_filter :verificar_etapa_definida, :only => [:index, :cofinanciables]

  def verificar_etapa_definida
    if @proyecto.etapa.empty? 
      msg_error _("Tiene que definir por lo menos una etapa para poder acceder a la gestion de Gasto.")
      redirect_to :menu => :configuracion, :controller => :datos_proyecto, :action => :etapas
    end
  end

  def verificar_estado_proyecto
    unless @permitir_ejecucion
      msg_error _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar los gastos.")    if @proyecto.estado_actual.nil?
      msg_error _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se pueden modificar los gastos.") + " " + _("No ha sido definido como 'estado de ejecución' por su administrador.") unless @proyecto.estado_actual.nil?
      redirect_to :action => "listado" if params[:action] =~ /modificar_crear|eliminar/
      redirect_to :action => "listado_facturas" if params[:action] == "orden_facturas"
      redirect_to :action => params[:update] if params[:action] == "modificar_parcial"
    end
  end

  def verificar_estado_ejecucion_ajax
#    unless @permitir_ejecucion
#      render :update do |page|
#        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar los gastos.")    if @proyecto.estado_actual.nil?
#        mensaje = _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " +  _("En este estado no se puede modificar los gastos.") unless @proyecto.estado_actual.nil?
#        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
#      end and return
#    end
  end




  def index
    redirect_to :action => :listado
  end

  def filtrado_ordenado_iniciales
    session[:gasto_proyectos_orden] ||= "fecha"
    session[:gasto_proyectos_asc_desc] ||= "ASC"
    session[:gasto_proyectos_cadena_orden] ||= "fecha"
    session[:gasto_proyectos_filtro_etapa] ||= "todas"
    session[:gasto_proyectos_filtro_moneda] ||= "todas"
    session[:gasto_proyectos_filtro_actividad] ||= "todas"
    session[:gasto_proyectos_filtro_proyecto] ||= "todos"
    session[:gasto_proyectos_filtro_agente] ||= "todos"
    session[:gasto_proyectos_filtro_financiador] ||= "todos"
    session[:gasto_proyectos_filtro_partida] ||= "todas"
    session[:gasto_proyectos_filtro_subpartida] ||= "todas"
    session[:gasto_proyectos_filtro_marcado] ||= "todos"
    session[:gasto_proyectos_filtro_inicio] ||= nil
    session[:gasto_proyectos_filtro_final] ||= nil
    session[:gasto_proyectos_filtro_aplicar_fecha] ||= false
  end

  # en proyectos: establece los parametros de ordenación
  def ordenado
    session[:gasto_proyectos_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    session[:gasto_proyectos_orden] = params[:orden] ? params[:orden] : "fecha"
    # Si estamos en el listado de numeracion de facturas la cadena de ordenación se hace en el propio metodo, y ponemos la cadena de orden a fecha para cuando se vuelva al listado de gastos que no de problemas
    session[:gasto_proyectos_cadena_orden] = session[:gasto_proyectos_orden] unless params[:listado] == "listado_facturas"
    session[:gasto_proyectos_cadena_orden] = "partida.codigo" if session[:gasto_proyectos_orden].include?("partida.codigo_nombre")
    session[:gasto_proyectos_cadena_orden] = "gasto_x_proyecto.importe" if session[:gasto_proyectos_orden].include?("importe")
    session[:gasto_proyectos_cadena_orden] = "proyecto_origen_id" if session[:gasto_proyectos_orden].include?("proyecto_origen")
    redirect_to :action => params[:listado] || "listado"
  end

  def filtrado
    session[:gasto_proyectos_filtro_etapa] = params[:filtro][:etapa]
    session[:gasto_proyectos_filtro_moneda] = params[:filtro][:moneda]
    session[:gasto_proyectos_filtro_actividad] = params[:filtro][:actividad]
    session[:gasto_proyectos_filtro_proyecto] = params[:filtro][:proyecto] if params[:listado] == "cofinanciables"
    session[:gasto_proyectos_filtro_cofinanciado] = params[:filtro][:cofinanciado] if params[:listado] == "cofinanciables"
    session[:gasto_proyectos_filtro_agente] = params[:filtro][:agente]
    session[:gasto_proyectos_filtro_financiador] = params[:filtro][:financiador]
    # Si indicamos subpartida y no subpartida, decimos que la partida es la de la subpartida
    if params[:filtro][:partida] == "todas" && params[:filtro][:subpartida] && params[:filtro][:subpartida] != "todas"
      session[:gasto_proyectos_filtro_partida] = Subpartida.find_by_id(params[:filtro][:subpartida]).partida_id.to_s
      session[:gasto_proyectos_filtro_subpartida] = params[:filtro][:subpartida]
    # Si indicamos partida y subpartida, comprobamos que la subpartida sea de la partida
    elsif params[:filtro][:partida] && params[:filtro][:partida] != "todas" && params[:filtro][:subpartida] && params[:filtro][:subpartida] != "todas"
      session[:gasto_proyectos_filtro_partida] = params[:filtro][:partida]
      session[:gasto_proyectos_filtro_subpartida] = Subpartida.find_by_id_and_partida_id(params[:filtro][:subpartida], params[:filtro][:partida]) ? params[:filtro][:subpartida] : "todas"
    # En otro caso...
    else
      session[:gasto_proyectos_filtro_partida] = params[:filtro][:partida]
      session[:gasto_proyectos_filtro_subpartida] = params[:filtro][:subpartida]
    end
    session[:gasto_proyectos_filtro_marcado] = params[:filtro][:marcado]
    session[:gasto_proyectos_filtro_aplicar_fecha] = params[:filtro][:aplicar_fecha] == "1" ? true : false
    if session[:gasto_proyectos_filtro_aplicar_fecha]
      session[:gasto_proyectos_filtro_inicio]= Date.new params[:filtro]["inicio(1i)"].to_i ,params[:filtro]["inicio(2i)"].to_i ,params[:filtro]["inicio(3i)"].to_i
      session[:gasto_proyectos_filtro_final]= Date.new params[:filtro]["final(1i)"].to_i ,params[:filtro]["final(2i)"].to_i ,params[:filtro]["final(3i)"].to_i
    else
      session[:gasto_proyectos_filtro_inicio], session[:gasto_proyectos_filtro_final] = nil, nil
    end
    redirect_to :action => params[:listado]
  end


  def elementos_filtrado
    origen = caller[0][/.*`([^']*)/,1]    #`#<-Lo he puesto paara los colores de mi codigo
    filtro_etapa = [[_("Todas"), "todas"]] + @proyecto.etapa.sort{ |a, b| a.fecha_inicio <=> b.fecha_inicio }.collect{ |e| [e.nombre, e.id.to_s] }
    filtro_actividad = [[_("Todas"), "todas"]] + @proyecto.actividad.collect{ |a| [a.codigo, a.id.to_s] }
    # Segun estemos o no asignados con rol de administracion vemos todos o solo socias y asignados
    if @proyecto.usuario_admin?(@usuario_identificado)
      implementadores = @proyecto.implementador
    else
      implementadores = @proyecto.implementadores_autorizados(@usuario_identificado)
    end
    filtro_agente = [[_("Todos"), "todos"]] + implementadores.collect{ |e| [e.nombre, e.id.to_s] }
    filtro_financiador = [[_("Todos"), "todos"]]  + @proyecto.financiador_gasto.collect{ |e| [e.nombre, e.id.to_s] }
    filtro_moneda = [[_("Todas"), "todas"]]  + @proyecto.moneda.collect{ |e| [e.nombre, e.id.to_s] }
    filtro_proyecto = [[_("Todos"), "todos"]] + @proyecto.proyecto_cofinanciador.collect{ |p| [p.nombre, p.id.to_s] }
    filtro_cofinanciado = [[_("Todos"), "todos"], [_("Sólo los ya cofinanciados"),"1"], [_("Sólo los no cofinanciados aún"), "2"]]
    filtro_partida = [[_("Todas"), "todas"]] + Partida.where(ocultar_proyecto: false).collect {|p| [p.codigo_nombre(@proyecto.id), p.id.to_s]}.sort{ |a,b| a[0] <=> b[0] }
    busqueda_subpartida = session[:gasto_proyectos_filtro_partida] == "todas" ? {} : {:partida_id => session[:gasto_proyectos_filtro_partida]}
    filtro_subpartida = [[_("Todas"), "todas"]] + @proyecto.subpartida.where(busqueda_subpartida).order("nombre").collect{ |p| [p.nombre, p.id.to_s] }
    filtro_marcado = [[_("Todos"), "todos"]] + Marcado.all(:order => "nombre").collect {|p| [p.nombre, p.id.to_s] }
    @opciones_filtrado = origen=="cofinanciables" ? [{:rotulo =>  _("Seleccione proyecto"), :nombre => "proyecto", :opciones => filtro_proyecto}] : []
    @opciones_filtrado += [     {:rotulo =>  _("Seleccione etapa"), :nombre => "etapa", :opciones => filtro_etapa},
                                {:rotulo =>  _("Seleccione moneda"), :nombre => "moneda", :opciones => filtro_moneda},
                                {:rotulo =>  _("Seleccione agente"), :nombre => "agente", :opciones => filtro_agente},
                                {:rotulo =>  _("Seleccione financiador"), :nombre => "financiador", :opciones => filtro_financiador},
                                {:rotulo =>  _("Seleccione partida"), :nombre => "partida", :opciones => filtro_partida} ]

    @opciones_filtrado += [     {:rotulo =>  _("Seleccione estado"), :nombre => "cofinanciado", :opciones => filtro_cofinanciado} ] if origen=="cofinanciables"

    @opciones_filtrado += [     {:rotulo =>  _("Seleccione subpartida"), :nombre => "subpartida", :opciones => filtro_subpartida},
                                {:rotulo =>  _("Seleccione actividad"), :nombre => "actividad", :opciones => filtro_actividad} ] unless origen=="cofinanciables"

    @opciones_filtrado += [     {:rotulo =>  _("Seleccione marcado"), :nombre => "marcado", :opciones => filtro_marcado},
                                {:rotulo =>  _("Fecha inicio"), :nombre => "inicio", :tipo => "calendario"},
                                {:rotulo =>  _("Fecha fin"), :nombre => "final", :tipo => "calendario"},
                                {:rotulo =>  _("Aplicar filtro fecha") + ": ", :nombre => "aplicar_fecha", :tipo => "checkbox"} ]

    @accion_filtrado = {:action => :filtrado, :listado => params[:action]}
    @resumen = {:url => {:menu => :resumen, :action => :gasto, :controller => :resumen_proyecto, :sin_layout => true}}

    @estado_filtrado = origen=="cofinanciables" ? [
        (session[:gasto_proyectos_filtro_proyecto] == "todos" ? _("Todos los proyectos") : Proyecto.find(session[:gasto_proyectos_filtro_proyecto]).nombre)
    ] : []
    @estado_filtrado += [session[:gasto_proyectos_filtro_cofinanciado] == "1" ? _("Sólo los ya cofinanciados") : _("Sólo los no cofinanciados aún")] if origen=="cofinanciables" && session[:gasto_proyectos_filtro_cofinanciado] != "todos"
    @estado_filtrado += [
        (session[:gasto_proyectos_filtro_etapa] == "todas" ? _("Todas las etapas") : @etapa.nombre + " (" + @etapa.fecha_inicio.to_s + "/" + @etapa.fecha_fin.to_s + ")"),   
        (session[:gasto_proyectos_filtro_moneda] == "todas" ? _("Todas las monedas") : Moneda.find(session[:gasto_proyectos_filtro_moneda]).nombre),
        (session[:gasto_proyectos_filtro_agente] == "todos" ? _("Todos los agentes") : Agente.find(session[:gasto_proyectos_filtro_agente]).nombre),
        (session[:gasto_proyectos_filtro_financiador] == "todos" ? _("Todos los financiadores") : Agente.find(session[:gasto_proyectos_filtro_financiador]).nombre),
        (session[:gasto_proyectos_filtro_marcado] == "todos" ? _("Cualquier marcado") : Marcado.find(session[:gasto_proyectos_filtro_marcado]).nombre),
	(session[:gasto_proyectos_filtro_partida] == "todas" ? _("Todas las partidas") : Partida.find(session[:gasto_proyectos_filtro_partida]).nombre)
    ]
    @estado_filtrado += [
        (session[:gasto_proyectos_filtro_subpartida] == "todas" ? _("Todas las subpartidas") : Subpartida.find(session[:gasto_proyectos_filtro_subpartida]).nombre),
        (session[:gasto_proyectos_filtro_actividad] == "todas" ? _("Todas las actividades") : Actividad.find(session[:gasto_proyectos_filtro_actividad]).codigo)
    ] unless origen=="cofinanciables"

  end

  # --
  # METODOS DE GESTION DE Gasto: Listados de gasto, modificar_crear, y eliminar
  # ++

  # en proyectos: lista en función de la etapa y del proyecto
  def listado
    filtrado_ordenado_iniciales
    (joins, condiciones, condiciones_marcado) = condiciones_listado

    # Metemos antes el where de marcado para facilitar la composicion de la query
    @gastos = @paginado =  Gasto.joins(joins).where(condiciones_marcado).
                                 joins(:partida, :gasto_x_proyecto, :agente).where(condiciones).
                                 order(session[:gasto_proyectos_cadena_orden] + " " + session[:gasto_proyectos_asc_desc]).
                                 paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                          per_page: (params[:format_xls_count] || session[:por_pagina]) )

    # en proyectos: en caso de que la seccion sea proyecto hacemos una ultima transformacion a los elementos del listado para obtener el importe por proyecto.
    # Si el parametro select del find funcionase mejor no haria falta hacer a posteriori esto.
    @gastos.each {|p| p.importe_x_proyecto @proyecto }

    elementos_filtrado

    @formato_xls = @gastos.total_entries
    @listado_mas_info = {:action => 'suma_total_listado'}

    respond_to do |format|
      format.html
      format.xls do
        @tipo = "gasto"
        @objetos = @gastos
        @subobjetos = [ "pago" ]
        nom_fich = "gastos_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

	# en proyectos: prepara el popup con informacion del importe total de los gastos mostrados
  def suma_total_listado
    filtrado_ordenado_iniciales
    (joins, condiciones, condiciones_marcado) = condiciones_listado
    gastos = Gasto.joins(joins).where(condiciones_marcado).includes([:gasto_x_proyecto,:partida,:agente]).where(condiciones)
    numero_elementos = gastos.count
    suma_total = gastos.joins(:gasto_x_proyecto => :tasa_cambio_proyecto).sum("gasto_x_proyecto.importe*tasa_cambio")
    suma_total_formateada = float_a_moneda(suma_total)
    render :update do |page|
      texto_mensaje = _("%{num} gastos con un importe total (aplicando tasas de cambio) de %{val} %{mon}")%{:num => numero_elementos, :val => suma_total_formateada, :mon => @proyecto.moneda_principal.abreviatura}
      page.insert_html :after, "cabecera",:inline => mensaje_advertencia(:identificador => "info_listado", :texto => texto_mensaje)
      page.call('Element.show("info_listado_borrado")')
    end 
  end

  def datos_formulario
    # Ponemos la fecha inicio y la fecha fin para filtrar en el selector de fechas.
    if session[:gasto_proyectos_filtro_etapa] == "todas" 
      @fecha_inicio = @proyecto.etapa.minimum("fecha_inicio")
      @fecha_fin = @proyecto.etapa.maximum("fecha_fin")
    else
      etapa = Etapa.find( session[:gasto_proyectos_filtro_etapa] )
      @fecha_inicio, @fecha_fin = etapa.fecha_inicio, etapa.fecha_fin
    end
    @partidas = @proyecto.partidas_mapeadas.collect {|p| [p.codigo_nombre(@proyecto.id), p.id]}
    # Solo se deja gestionar los libros asignados al proyecto sobre los que tiene permiso el usuario
    @libros = @proyecto.libro.all(:conditions => {:bloqueado => :false}, :order => "nombre").select{|l| @usuario_identificado.reload.libro.include? l}
    # Solo se deja gestionar los implementadores asignados al proeycto sobre los que tiene permiso el usuario.
    posibles_agentes = @proyecto.implementador.where(id: @usuario_identificado.agente).order("nombre")
    # Si el usuario pertenece a una oficina/delegacion puede tambien gestionar los gastos de las socias locales
    if @usuario_identificado.delegacion
      posibles_agentes += @proyecto.implementador.where(socia_local: true).order("nombre")
    end
    @implementadores = posibles_agentes.uniq.collect {|a|[a.nombre, a.id]}
    @monedas = @proyecto.moneda.collect{|m| [m.abreviatura,m.id]}
    @paises = [[_("Gasto Regional"),nil]] + @proyecto.pais_gasto.collect{|m| [m.nombre,m.id]}
  end

  # No se bien para que pueda servir... lo comento y con el tiempo se quitara (sram-22092014)
  #def nuevo_copiar_datos
  #  gasto_copiar, @gasto = Gasto.find(params[:id]), Gasto.new
  #  Gasto.datos_basicos_igualar(@gasto, gasto_copiar)
  #  @objeto = @gasto 
  #  @actividades = gasto_copiar.actividad @proyecto
  #  @financiadores = gasto_copiar.financiador @proyecto
  #  datos_formulario
  #  render :partial => "formulario"
  #end

  # en proyectos: prepara el formulario de edición o creación
  def editar_nuevo
    @gasto = @objeto = params[:id] ?  Gasto.find(params[:id]) : Gasto.new(proyecto_origen_id: @proyecto.id)
    @gasto_x_proyecto = @gasto.gasto_x_proyecto.find_by_proyecto_id(@proyecto.id)
    @actividades = @gasto.actividad @proyecto
    @financiadores = @gasto.financiador @proyecto
    datos_formulario
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

  # en proyectos: prepara el formulario de copia de gasto
  def editar_copia
    gasto_orig = @proyecto.gasto.find_by_id(params[:id]) || Gasto.new
    attribs = gasto_orig.attributes
    # Le quitamos los atributos que no sos susceptibles de borrar
    attribs.delete("orden_factura_agente")
    attribs.delete("ref_contable")
    # Y generamos la copia
    @gasto = @objeto = Gasto.new(gasto_orig.attributes)
    @pago = gasto_orig.pago.first
    @actividades = gasto_orig.actividad @proyecto
    @financiadores = gasto_orig.financiador @proyecto
    datos_formulario
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) } 
  end

  # en proyectos: modifica o crea comprobando que las fechas de la etapa coinciden
  def modificar_crear
    session[:gasto_proyectos_ultimo] = params
    if session[:gasto_proyectos_filtro_etapa] == "todas" 
      fecha_inicio = @proyecto.etapa.minimum("fecha_inicio")
      fecha_fin = @proyecto.etapa.maximum("fecha_fin")
    else
      etapa = Etapa.find( session[:gasto_proyectos_filtro_etapa] )
      fecha_inicio, fecha_fin = etapa.fecha_inicio, etapa.fecha_fin
    end
    #params[:gasto][:fecha] =  params[:gasto][:fecha]
    gasto = params[:id] ?  Gasto.find(params[:id]) : Gasto.new(:proyecto_origen_id => @proyecto.id)
    gasto.attributes = params[:gasto]
    if gasto.comprobar_fecha_etapa fecha_inicio, fecha_fin
      libro = Libro.find_by_id(params[:pago][:libro_id]) if gasto.pago.count <= 1 && params[:pago] && params[:pago][:total] && params[:pago][:libro_id]
      params[:gasto][:moneda_id] = libro.moneda_id if libro
      params[:gasto][:agente_id] = libro.agente_id if libro
      gasto.update_attributes params[:gasto]
      if gasto.errors.empty?
        gxp = gasto.gasto_x_proyecto.find_by_proyecto_id(@proyecto.id) || GastoXProyecto.new(:gasto_id => gasto.id, :proyecto_id => @proyecto.id)
        # Ojo, hay errores en los logs del tipo:
        # NoMethodError (undefined method `[]=' for nil:NilClass):
        #   app/controllers/gasto_proyectos_controller.rb:313:in `modificar_crear'
        params[:gasto_x_proyecto][:importe_convertido] = params[:gasto][:importe_convertido] if params[:gasto] && params[:gasto][:importe_convertido]
        gxp.update_attributes params[:gasto_x_proyecto]
        # Genera un pago unico con fecha del gasto si se ha seleccionado y el gasto es nuevo
        if ( gasto.pago.count <= 1 && params[:pago] && params[:pago][:total] == "1" )
          pago = gasto.pago.first || Pago.new
          pago.importe = gasto.importe
          pago.fecha = gasto.fecha
          pago.observaciones = params[:gasto][:concepto]
          pago.libro_id = params[:pago][:libro_id]
          pago.forma_pago = params[:pago][:forma_pago]
          pago.referencia_pago = params[:pago][:referencia_pago]
          pago.gasto = gasto
          pago.save
        end
        gasto_salvado = true

    # Aqui tendriamos que cortar el if anterior y abrir uno nuevo
    # para permitir guardar los datos de actividades y financiadores aun con errores (p.ej. cambiarlos fuera de etapa del agente)
        # Si se manda sin detalle tenemos que especificar e igualar los importes al del gasto
        params["actividades"]["0"]["importe_convertido"] = gasto.importe unless params["actividades_detallado"] || params["resultados"]
        # Actualiza actividades
        if params["resultados"]
          actividades = @proyecto.actividad.where(:resultado_id => params[:resultados].collect{|k,v| v[:resultado_id]})
          gasto.dividir_por_actividades actividades, @proyecto
        elsif params["dividir_actividades"]["todas"] == "1"
          # Todas las actividades detalladas
          gasto.dividir_por_actividades(params[:actividades], @proyecto) if params["actividades_detallado"]
          # Todas las actividades de la etapa
          gasto.dividir_por_actividades(@proyecto.actividad, @proyecto) unless params["actividades_detallado"]
        else
          # Solo las actividades seleccionadas con los importes correspondientes
          gasto.actualizar_gasto_x_actividad(params[:actividades], @proyecto)
          # Este contador lo utilizamos despues para ver si en la distribución por financiadores ha habido algun error.
          errores_tras_guardar_actividades = gasto.errors.size 
        end

        # Actualiza financiadores si se ha enviado algo de info
        if params["financiadores"]
          # ... igualamos importes de gasto
          params["financiadores"]["0"]["importe_convertido"] = gasto.importe unless params["financiadores_detallado"]
          # ... y sincroniza la info
          gasto.actualizar_gasto_x_agente params[:financiadores], @proyecto
        end
        # Si ha dado un error de distribucion por actividades y tenemos la variable de configuración especifica activda
        # ("CLOSE_EXPENSES_FORM_ON_ACTIVITIES_ERRORS" ó "CLOSE_EXPENSES_FORM_ON_FINANCIERS_ERRORS") creamos cerrar_formulario_con_errores a true.
        # Esto lo hacemos para diferenciar posteriormente si vamos a cerrar o no el formulario de gasto
        config_errores_actividades =  GorConfig.getValue("CLOSE_EXPENSES_FORM_ON_ACTIVITIES_ERRORS")
        config_errores_financiadores = GorConfig.getValue("CLOSE_EXPENSES_FORM_ON_FINANCIERS_ERRORS")
        cerrar_formulario_con_errores = true if config_errores_actividades == "TRUE" and errores_tras_guardar_actividades > 0
        cerrar_formulario_con_errores = true if config_errores_financiadores  == "TRUE" and gasto.errors.size > errores_tras_guardar_actividades
        cerrar_formulario_con_errores = false if config_errores_actividades != "TRUE" and errores_tras_guardar_actividades > 0
        cerrar_formulario_con_errores = false if config_errores_financiadores != "TRUE" and gasto.errors.size > errores_tras_guardar_actividades
      else
        gasto_salvado = false 
      end
    end

    @gasto = @objeto = gasto
    # Si no ha habido fallos grabando el gasto y no es nuevo o se ha guardado completamente sin errores, 
    # o si la variable cerrar_formulario_con_errores esta a true. ESta utlima variable depende de las variables de configuracion:
    # CLOSE_EXPENSES_FORM_ON_ACTIVITIES_ERRORS, CLOSE_EXPENSES_FORM_ON_FINANCIERS_ERRORS
    if gasto_salvado && (@gasto.errors.empty? || !params[:id] || cerrar_formulario_con_errores)
      # Refrescamos el gasto para que no use la copia cacheada y aparezcan los gastos por proyecto
      @gasto = @objeto = gasto.reload
      # Marcamos errores generales y de proyecto para el gasto
      gasto.marcado_errores
      # Si es un gasto que ya existia
      render(:update) { |page|   page.modificar :update => params[:update], :partial => "gasto" , :mensaje => { :errors => @gasto.errors } } if params[:id]
      # Si es un nuevo gasto
      render :update do |page|
        page.show "nuevos_gastos"
        # Si viene de un "anadir", lo metemos en su sitio y avanzamos el contador de ids
        if params[:i]
          page.modificar :update => "gasto_proyecto_nuevo_" + params[:i], :partial => "nuevo_gasto", :mensaje => { :errors => @gasto.errors }
          page.replace "anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>"
        # Si es una copia, incluimos antes un div donde meter la linea
        else
          page.insert_html :after, "gasto_proyecto_copia", '<div id="gasto_proyecto_copia_' + @gasto.id.to_s + '"></div>'
          page.modificar :update => "gasto_proyecto_copia_" + @gasto.id.to_s, :partial => "nuevo_gasto", :mensaje => { :errors => @gasto.errors }
        end
      end unless params[:id]
    else
    # Si hay fallo grabando el gasto mostramos el formulario con el mensaje de error 
      @actividades = @gasto.actividad @proyecto
      @financiadores = @gasto.financiador @proyecto
      @gasto_x_proyecto = @gasto.gasto_x_proyecto.find_by_proyecto_id(@proyecto.id)
      #puts "---------------------->(guardado) " + @financiadores.inspect
      #puts "---------------------->(formulario) " + params[:financiadores].inspect
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @gasto.errors} }
    end
  end

  # en proyectos: elimina
  def eliminar
    @gasto = Gasto.find(params[:id])
    @gasto.destroy
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @gasto.errors, :eliminar => true}}
  end

  # en proyectos: elimina todos los gastos existentes
  def eliminar_todo
    (joins, condiciones, condiciones_marcado) = condiciones_listado
    # Permitimos solo borrar los gastos generados en el propio proyecto
    condiciones[:proyecto_origen_id] = @proyecto.id
    @gastos = Gasto.joins(joins).where(condiciones_marcado).all(
                                :include => [:partida, :gasto_x_proyecto, :agente],
                                :order => (session[:gasto_proyectos_cadena_orden] + " " + session[:gasto_proyectos_asc_desc]),
                                :conditions => condiciones)

    # Si no tenemos la doble confirmacion del borrado, la presentamos
    unless params[:doble_confirmacion]
      mensaje  = _("Se van a eliminar %{num} líneas de gasto.")%{num: @gastos.count} + "<br><br>"
      mensaje += _("Solo se borrarán los gastos generados en el proyecto. Los gastos creados por los agentes o los gastos cofinanciados no serán borrados.") + "<br><br>"
      mensaje += _("Esta acción es irreversible.") + "<br>" + _("¿Está seguro de querer borrar todos los gastos del listado?")
      render(:update) do |page|
        page.replace_html "filacabecera_confirmacion", :inline => mensaje
        page.hide "filacabecera_pregunta"
        page.hide "filacabecera_boton_confirma"
        page.show "filacabecera_confirmacion"
        page.show "filacabecera_boton_confirma_segunda"
      end
    else
      errores = false 
      @gastos.each do |gasto|
        gasto.destroy
        errores = true unless gasto.errors.empty?
      end
      render(:update) do |page|
        texto_actualizar = _("Todos los gastos fueron borrados.") unless errores
        texto_actualizar = _("Se produjeron errores borrando alguno de los gastos.") if errores
        mensaje = texto_actualizar + "<br>" + link_to(_("Es necesario actualizar el listado."), {action: :listado})
        page.insert_html :before, "listado_gastos", '<div id="mensajeok">' + mensaje + '</div>' unless errores
        page.replace_html "filacabecera_borrado", :inline => '<div class="fila">' + mensaje + '</div>' if errores
        page.eliminar :update => "listado_gastos", :mensaje => {:errors => (errores ? [["",texto_actualizar]] : []), :eliminar => true}
        page.replace_html "paginacion", :inline => mensaje 
      end
    end
  end

  #-- 
  # METODOS DE RECUPERAR EL ULTIMO GASTO EDITADO
  # ++

  def editar_ultimo
    #render :partial => "formulario"
  end


  #-- 
  # METODOS AJAX PARA MANEJAR ACTIVIDADES Y FINANCIADORES 
  # ++

  def detallar_actividades
    @gasto = @objeto = params[:id] ?  Gasto.find(params[:id]) : Gasto.new
    @actividades = @gasto.actividad @proyecto
    render :update do |page|
      page.replace "actividades_detalle", :partial => "comunes/actividades_detalle"
    end
  end

  # en proyectos: muestra el detalle de resultados para la linea de presupuesto
  def detallar_resultados
    @gasto = @objeto = params[:id] ?  Gasto.find(params[:id]) : Gasto.new
    @resultados = []
    render :update do |page|
      page.replace "actividades_detalle", :partial => "comunes/resultados_detalle"
    end
  end

  def detallar_financiadores
    @gasto = @objeto = params[:id] ?  Gasto.find(params[:id]) : Gasto.new
    @financiadores = @gasto.financiador @proyecto
    render :update do |page|
      page.replace "financiadores_detalle", :partial => "comunes/financiadores_detalle"
    end
  end

  # en proyectos: añade un financiador al formulario
  def anadir_financiador
    render :template => "comunes/anadir_financiador"
  end

  # en proyectos: añade una actividad al formulario
  def anadir_actividad
    render :template => "comunes/anadir_actividad"
  end

  # en proyectos: añade un resultado al formulario
  def anadir_resultado
    render :template => "comunes/anadir_resultado"
  end


  # --
  # METODOS DE GESTION DE GASTOS COFINANCIADOS.
  # --  

	# en proyectos: muestra el listado de todos los gastos disponibles para vincular
  def cofinanciables
    filtrado_ordenado_iniciales
    (condiciones, condiciones_cofinanciados) = condiciones_cofinanciables

    @gastos = @paginado = Gasto.includes(:gasto_x_proyecto).includes(:gasto_x_agente).
                                where(condiciones_cofinanciados).
                                includes([:partida, :agente]).
                                where(condiciones).
                                order(session[:gasto_proyectos_cadena_orden] + " " + session[:gasto_proyectos_asc_desc]).
                                paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                         per_page: (params[:format_xls_count] || session[:por_pagina]))
    elementos_filtrado

    @formato_xls = @gastos.total_entries
    @listado_mas_info = {:action => 'suma_total_listado_cofinanciables'}
    
    @partidas_mapeadas_ids = @proyecto.partidas_mapeadas.collect {|p| p.id }

    respond_to do |format|
      format.html
      format.xls do
        @tipo = "gasto"
        @objetos = @gastos
        @subobjetos = [ "pago" ]
        nom_fich = "gastos_cofinanciables_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d") 
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

        # en agentes: prepara el popup con informacion del importe total de los gastos mostrados
  def suma_total_listado_cofinanciables
    filtrado_ordenado_iniciales
    (condiciones, condiciones_cofinanciados) = condiciones_cofinanciables
    gastos = Gasto.includes(:gasto_x_proyecto).includes(:gasto_x_agente).where(condiciones_cofinanciados).includes([:partida, :agente]).where(condiciones)
    gastos_cofinanciados = gastos.where("gasto_x_proyecto.proyecto_id" => @proyecto.id)

    numero_elementos = gastos.count
    numero_elementos_cofinanciados = gastos_cofinanciados.count
    suma_total = gastos.joins(:gasto_x_proyecto => :tasa_cambio_proyecto).sum("gasto_x_proyecto.importe*tasa_cambio")
    suma_total_cofinanciados = gastos_cofinanciados.joins(:gasto_x_proyecto => :tasa_cambio_proyecto).sum("gasto_x_proyecto.importe*tasa_cambio")
    suma_total_formateada = float_a_moneda(suma_total)
    suma_total_cofinanciados_formateada = float_a_moneda(suma_total_cofinanciados)
    render :update do |page|
      texto_mensaje = _("%{num} gastos con un importe total (aplicando tasas de cambio) de %{val} %{mon}")%{:num => numero_elementos, :val => suma_total_formateada, :mon => @proyecto.moneda_principal.abreviatura}
      texto_mensaje += "<br><br>"
      texto_mensaje += _("%{num} gastos usados en el proyecto, con un importe total (aplicando tasas de cambio) de %{val} %{mon}")%{:num => numero_elementos_cofinanciados, :val => suma_total_cofinanciados_formateada, :mon => @proyecto.moneda_principal.abreviatura}
      page.insert_html :after, "cabecera",:inline => mensaje_advertencia(:identificador => "info_listado", :texto => texto_mensaje) 
      page.call('Element.show("info_listado_borrado")')
    end
  end


	# en proyectos: desasigna un gasto del proyecto
  def descofinanciar
    @gasto = Gasto.find_by_id params[:id]
    @gxp = @gasto.gasto_x_proyecto.find_by_proyecto_id(@proyecto.id) if @gasto
    if @gxp
      @gasto.gasto_x_actividad.find_all_by_proyecto_id(@proyecto.id).each { |gxa| gxa.destroy }
      @gasto.gasto_x_agente.find_all_by_proyecto_id(@proyecto.id).each { |gxa| gxa.destroy }
      @gxp.destroy
      # Cargamos las partidas mapeadas
      @partidas_mapeadas_ids = @proyecto.partidas_mapeadas.collect {|p| p.id}
      # Si descofinanciamos desde listado de gastos generales
      render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @gxp.errors, :eliminar => true}} unless params[:cofinanciable]
      # Si descofinanciamos desde listado de gastos cofinanciables
      render(:update) { |page| page.actualizar :update => params[:update], :partial => "cofinanciable", :mensaje => { :errors => @gxp.errors } } if params[:cofinanciable]
    end
  end

  # --
  # METODOS DE GESTION DE FACTURAS: orden de facturas
  # --

  # Listado de facturas con la numeración de gestión del proyecto
  def listado_facturas
    #msg "Ordenado por numeracion de factura (ver info)", {:now => true}
    filtrado_ordenado_iniciales
    # Utilizamos el mismo metodo que para las condiciones del listado general.
    joins, condiciones, condiciones_marcado = condiciones_listado
    # La ordenacion la realizacion aqui en vez de en ordenado por que es bastante especifica.
    if session[:gasto_proyectos_orden].include?("numeracion_factura") && session[:gasto_proyectos_asc_desc] == "DESC"
      orden = "gasto.proyecto_origen_id DESC, gasto.agente_id DESC, gasto.orden_factura_proyecto DESC, gasto.fecha DESC"
    elsif session[:gasto_proyectos_orden].include?("orden_factura") && session[:gasto_proyectos_asc_desc] == "DESC"
      orden = session[:gasto_proyectos_cadena_orden] = "gasto_x_proyecto.orden_factura DESC" 
    elsif session[:gasto_proyectos_orden].include?("orden_factura") && session[:gasto_proyectos_asc_desc] == "ASC"
      orden = session[:gasto_proyectos_cadena_orden] = "gasto_x_proyecto.orden_factura" 
    else
      orden = "gasto.proyecto_origen_id, gasto.agente_id, gasto.orden_factura_proyecto, gasto.fecha"
    end
    @gastos=  @paginado = Gasto.joins(joins).
                                where(condiciones_marcado).
                                includes([:partida, :gasto_x_proyecto, :agente]).
                                where(condiciones).
                                order(orden).
                                paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                         per_page: (params[:format_xls_count] || session[:por_pagina]))
    @formato_xls = @gastos.total_entries
    elementos_filtrado
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "factura"
        @objetos = @gastos
        nom_fich = "facturas" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end
  

  # en proyectos: ordena las facturas
  def orden_facturas_financiador
    if params[:selector]
      condiciones = { "gasto_x_proyecto.proyecto_id" => @proyecto.id }
      @etapa = Etapa.find( session[:gasto_proyectos_filtro_etapa] ) unless session[:gasto_proyectos_filtro_etapa] == "todas"
      condiciones["gasto.fecha"] = @etapa.fecha_inicio..@etapa.fecha_fin if @etapa 
      condiciones["gasto.moneda_id"] = session[:gasto_proyectos_filtro_moneda] unless session[:gasto_proyectos_filtro_moneda] == "todas"
      condiciones["gasto.agente_id"] = session[:gasto_proyectos_filtro_agente] unless session[:gasto_proyectos_filtro_agente] == "todos"
      condiciones["gasto.partida_id"] = session[:gasto_proyectos_filtro_partida] unless session[:gasto_proyectos_filtro_partida] == "todas"
      orden = (params[:selector][:tipo] == "partida" && params[:selector][:tipo] == "subpartida")? "partida.id,fecha" : "fecha"
      @gastos =  Gasto.find( :all, :order => orden, :include => [:partida, :gasto_x_proyecto], :conditions => condiciones )
      contador = {} 

      nombre_proyecto = @proyecto.identificador_financiador == "" ? @proyecto.nombre.to_s : @proyecto.identificador_financiador
      nombre_proyecto += @proyecto.convenio_id ? "-" + @proyecto.nombre.to_s : ""

      prefijo = params[:selector][:tipo] == "simple" ? "" : nombre_proyecto 
      contador[prefijo] = 1
      @gastos.each do |gasto|
        gasto_x_proyecto = GastoXProyecto.find :first, :conditions => { 'proyecto_id' => @proyecto.id, 'gasto_id' => gasto.id }
        n_pais = gasto.pais ? (gasto.pais.codigo == "" ? gasto.pais.nombre : gasto.pais.codigo) : _("Regional")
        prefijo = nombre_proyecto + "/" + n_pais unless params[:selector][:tipo] == "simple" || params[:selector][:tipo] == "fecha"
        contador[prefijo] = 1 if !contador[prefijo]
        # En el caso de que el orden sea por partidas tenemos que cambiar el codigo de numeracion con cada una
        if (params[:selector][:tipo] == "partida" || params[:selector][:tipo] == "subpartida") 
          partida = gasto.partida.partida_asociada @proyecto if gasto.partida
          subpartida = Subpartida.find_by_id(gasto_x_proyecto.subpartida_id) if gasto_x_proyecto.subpartida_id
          if !partida
            prefijo=nil
          #elsif subpartida.nil? && params[:selector][:tipo] == "subpartida"
          #  prefijo=nil
          else
            prefijo += "/" + partida.codigo.to_s + ((params[:selector][:tipo] == "subpartida" && !subpartida.nil?) ? "/" + subpartida.numero.to_s : "")
            contador[prefijo] = 1 if !contador[prefijo]
          end
        end
        if prefijo
          gasto_x_proyecto.orden_factura = prefijo + (prefijo == "" ? "" : "/") + format("%03d",contador[prefijo].to_s)
          contador[prefijo] += 1 
          gasto_x_proyecto.save
        end
      end  
    end
    redirect_to :action => :listado_facturas
  end

        # en proyectos: genera la etiqueta para pegar a la factura
  def generar_etiqueta
    factura = GastoXProyecto.find_by_id(params[:id])
    if factura
      partida_asociada = factura.gasto.partida.partida_asociada(@proyecto) if factura.gasto.partida && factura.gasto.partida.partida_asociada(@proyecto)
      imagen = Magick::Image.new(500,280)
      imagen.format = 'PNG'

      text = Magick::Draw.new
      text.font_family = 'helvetica'
      text.pointsize = 24 
      text.gravity = Magick::NorthGravity
      posicion = 30
      word_wrap(factura.orden_factura, 30).split("\n").each do |row|
        text.annotate(imagen, 0, 0, 0, posicion += 30, row)
      end

      text.pointsize = 20 
      text.align = Magick::LeftAlign
      texto  = "Fecha: " + factura.gasto.fecha.to_s + "\n"
      texto += "Factura: " + (factura.gasto.numero_factura || "") + "\n"
      texto += "Partida: " + ( partida_asociada ? partida_asociada.codigo + " (" + partida_asociada.nombre.upcase + ")" : "N/A" ) + "\n"
      texto += "Subpartida: " + Subpartida.find(factura.subpartida_id).nombre.upcase if factura.subpartida_id
  
      posicion = 140 
      word_wrap(texto, 30).split("\n").each do |row|
        text.annotate(imagen, 0, 0, 20, posicion += 20, row)
      end   

      send_data imagen.to_blob, :filename => 'Etiqueta_' + factura.orden_factura + '.png', :disposition => 'inline', :type => 'application/png'
    end
  end

  # --
  # METODOS AJAX DEL FORMULARIO: Moneda y subpartida.
  # ++

  # en proyectos: devuelve la moneda del libro seleccionado para el fomulario
  def moneda_libro
    @moneda = params[:id] != "" ? Libro.find(params[:id]).moneda : nil
    render :inline => <<-FIN
      <%= _("Moneda") %> <br> <%=  @moneda.abreviatura if @moneda %>
      <%= hidden_field('gasto', 'moneda_id', :value => @moneda.id) if @moneda%>
    FIN
  end

  # en proyectos: devuelve las subpartidas asociadas a la partida seleccionada para el fomulario
  def subpartida
    render :partial => "subpartida", :locals => { :partida_id => params[:id]}
  end

  # en proyectos: hace un cambio del pais segun sea el libro con el que se paga el gasto
  def cambia_pais
    if params[:pais_id]
      libro = @proyecto.libro.find_by_id params[:pais_id]
      pais_id = libro.nil? ? nil : libro.pais_id
    else
      agente = @proyecto.implementador.find_by_id params[:agente_id]
      pais_id = agente.nil? ? nil : agente.pais_id
    end
    @paises = [[_("Gasto Regional"),nil]] + @proyecto.pais_gasto.collect{|m| [m.nombre,m.id]}
    render :partial => "gasto_proyectos/pais", :locals => {:pais_id => pais_id}
  end

  # --
  # METODOS AJAX DEL FORMULARIO: Autocomplete del emisor de la factura 
  # ++

  def auto_complete_for_gasto_proveedor_nombre
    @proveedores = Proveedor.where(activo: true, agente_id: @proyecto.implementador).find(:all, :conditions => ['nombre like ?', "%#{params[:search]}%"])
    render :inline => "<%= auto_complete_result_3 @proveedores, :nombre %>"
  end
  def auto_complete_for_gasto_proveedor_nif
    @proveedores = Proveedor.where(activo: true, agente_id: @proyecto.implementador).find(:all, :conditions => ['nif like ?', "%#{params[:search]}%"])
    render :inline => "<%= auto_complete_result_3 @proveedores, :nif %>"
  end

  def completa_proveedor_nif
    proveedor = Proveedor.where(activo: true, agente_id: @proyecto.implementador).find_by_nombre("#{params[:search]}")
    render :update do |page|
      # Cambiamos la forma anterior de sustitucion del elemento para mantener el ajax de actualizacion en el
      page.replace "contenedor_gasto_proveedor_nif", :partial => "gasto_proyectos/proveedor_nif", :locals => {obj_value: proveedor.nif} 
    end if proveedor
    render nothing: true unless proveedor
  end
  def completa_proveedor_nombre
    proveedor = Proveedor.where(activo: true, agente_id: @proyecto.implementador).find_by_nif("#{params[:search]}")
    render :update do |page|
      # Cambiamos la forma anterior de sustitucion del elemento para mantener el ajax de actualizacion en el
      page.replace "contenedor_gasto_proveedor_nombre", :partial => "gasto_proyectos/proveedor_nombre", :locals => {obj_value: proveedor.nombre}
    end if proveedor
    render nothing: true unless proveedor
  end

  # --
  # METODOS DE MODIFICACION PARCIAL DE LA INFORMACION DE GASTOS DE VARIOS PROYECTOS
  # ++

	# en proyectos: obtiene info para la edicion de un gasto cofinanciado
  def editar_parcial
    @gasto = @objeto = Gasto.find_by_id(params[:id]) || Gasto.new
    @gasto_x_proyecto = @gasto.gasto_x_proyecto.find_by_proyecto_id(@proyecto.id) || @gasto.gasto_x_proyecto.new(:proyecto_id => @proyecto.id, :importe => @gasto.importe)
    @actividades = @gasto.actividad @proyecto
    # Si el proyecto ya esta asignado cogemos sus financiadores...
    @financiadores = @gasto.financiador @proyecto
    # ... y si no cogemos los del proyecto original del gasto
    @financiadores = @gasto.financiador Proyecto.find_by_id(@gasto.proyecto_origen_id) if @gasto_x_proyecto.id.nil? && @financiadores.size == 0
    datos_formulario
    # Averigua si se debe permitir modificar la partida para los gastos de agente
    render(:update) { |page| page.formulario :partial => "formulario_parcial", :update => params[:update] }
  end

        # en proyectos: modifica un gasto cofinanciado
  def modificar_parcial
    @etapa = Etapa.find_by_id( session[:gasto_proyectos_filtro_etapa] )
    @gasto = @objeto = Gasto.find_by_id(params[:id])
    # Averigua si se debe permitir modificar la partida para los gastos de agente
    @partidas_mapeadas_ids = @proyecto.partidas_mapeadas.collect {|p| p.id}
    if @gasto
      @gasto_x_proyecto = @gasto.gasto_x_proyecto.find_by_proyecto_id(@proyecto.id) || (@gasto.proyecto_origen_id ? @gasto.gasto_x_proyecto.new(:proyecto_id => @proyecto.id,:importe => @gasto.importe) : nil)
      @gasto_x_proyecto.update_attributes params[:gasto_x_proyecto] if @gasto_x_proyecto
      @gasto_x_proyecto.save if @gasto_x_proyecto
      # Si no ha habido fallos grabando
      if @gasto_x_proyecto && @gasto_x_proyecto.errors.empty?
        # Actualiza actividades
        params["actividades"]["0"]["importe_convertido"] = @gasto.importe unless params["actividades_detallado"]
        if params["dividir_actividades"]["todas"] == "1"
          # Todas las actividades detalladas
          @gasto.dividir_por_actividades(params[:actividades], @proyecto) if params["actividades_detallado"]
          # Todas las actividades de la etapa
          @gasto.dividir_por_actividades(@proyecto.actividad, @proyecto) unless params["actividades_detallado"]
        else
          # Solo las actividades seleccionadas con los importes correspondientes
          @gasto.actualizar_gasto_x_actividad(params[:actividades], @proyecto) if params[:actividades] && params[:actividades].size > 0
        end

        # Actualiza financiadores
        @gasto.actualizar_gasto_x_agente(params[:financiadores], @proyecto) if params[:financiadores]

        @gasto.reload if @gasto.errors.empty?
        @gasto.marcado_errores

        # Si no ha habido fallos grabando
        render(:update) { |page|  page.modificar :update => params[:update], :partial => params[:cofinanciable] ? "cofinanciable" : "gasto", :mensaje => { :errors => @gasto.errors } }
      else
        @actividades = @gasto.actividad @proyecto
        # Si el proyecto ya esta asignado cogemos sus financiadores...
        @financiadores = @gasto.financiador @proyecto
        # ... y si no cogemos los del proyecto original del gasto
        @financiadores = @gasto.financiador Proyecto.find_by_id(@gasto.proyecto_origen_id) if (@gasto_x_proyecto.nil? || @gasto_x_proyecto.id.nil?) && @financiadores.size == 0
        datos_formulario
        render(:update) { |page| page.recargar_formulario :partial => "formulario_parcial", :update => params[:update], :mensaje => {:errors => @gasto_x_proyecto.errors} }
      end
    end
  end

  # Nota de Gasto 
  def nota_gasto
    @documento = Documento.includes("etiqueta").where("etiqueta.nombre" => "Nota de Gasto", "etiqueta.tipo" => "plantilla").find_by_id params[:id]
    gasto = @proyecto.gasto.find_by_id params[:gasto_id] 
    if @documento && gasto && File.exists?(@documento.adjunto.path)
      gxp = gasto.gasto_x_proyecto.find_by_proyecto_id @proyecto.id
      nom_fich = @proyecto.nombre + "." + gasto.id.to_s + "." + @documento.adjunto_file_name
      fichero = Tempfile.new("gasto_" + gasto.id.to_s + "_" + SecureRandom.hex)
      fichero.close

      valores = {
        "p_nombre" => @proyecto.nombre,
        "p_convocatoria" => @proyecto.convocatoria.nombre,
        "p_financiador" => @proyecto.convocatoria.agente.nombre,
        "g_importe" => gxp.importe_convertido,
        "g_fecha" => gasto.fecha,
        "g_moneda" => gasto.moneda.nombre,
        "g_mon" => gasto.moneda.abreviatura,
        "g_partida" => gasto.partida.codigo_nombre(@proyecto),
        "g_subpartida" => (gxp.subpartida ? gxp.subpartida.nombre : ""),
        "g_actividad" => gasto.importes_por_actividades(@proyecto).join(", "),
        "g_financiador" => gasto.importes_por_financiadores(@proyecto).join(", "),
        "g_proyecto_cofinanciador" => ((gasto.gasto_x_proyecto - [gxp]).collect{|g| g.proyecto ? g.proyecto.nombre : _("Delegación") + " (" + gasto.agente.nombre + ")"}).join(", "),
        "g_implementador" => gasto.agente.nombre,
        "g_pais" => gasto.pais.nombre,
        "g_concepto" => gasto.concepto,
        "g_observaciones" => gasto.observaciones,
        "usuario" => @usuario_identificado.nombre_completo,
        "g_num_factura" => gasto.numero_factura,
        "g_proveedor" => (gasto.proveedor ? gasto.proveedor.nombre : ""),
        "g_proveedor_dni" => (gasto.proveedor ? gasto.proveedor.nif : "") }

      Rol.where(seccion: "proyectos").each do |rol|
        valores["p_" + rol.nombre.downcase] = @proyecto.usuario.where("usuario_x_proyecto.rol_id" => rol.id).collect {|u| u.nombre_completo}.uniq.join(", ")
      end if @proyecto

      begin 
        source = Word::WordDocument.new(@documento.adjunto.path)
        #puts "--------> PARRAFOS: " + source.main_doc.paragraphs.inspect
        valores.each { |k,v| source.replace_all("{{" + k.to_s.upcase + "}}", v.to_s) }
        source.save(fichero.path)
        send_file fichero.path, :filename => nom_fich, :type => @documento.adjunto_content_type, :disposition => 'inline'
        #send_file @documento.adjunto.path, :filename => nom_fich, :type => @documento.adjunto_content_type, :disposition => 'inline'
      rescue => ex
        logger.error ex.message
        logger.error ex.backtrace
        msg_error = _("Se produjo un error leyendo la plantilla: %{msg_err}")%{:msg_err => ex.message}
        redirect_to :action => 'listado'
      end
    else
      msg_error _("No pudo encontrarse el Gasto.") + " " + _("Contacte con el administrador del sistema.") unless gasto
      msg_error _("No se pudo encontrar una plantilla de 'Nota de Gasto'.") + " " + _("Contacte con el administrador del sistema.")  if gasto
      redirect_to :action => 'listado'
    end
  end

 private

  # Prepara los filtros para el listado
  def condiciones_listado
    joins = [ :gasto_x_proyecto ]
    condiciones = { "gasto_x_proyecto.proyecto_id" => @proyecto.id }

    # A no ser que el usuario este asignado con un rol de administracion, le impone filtros especiales
    if @proyecto.usuario_admin?(@usuario_identificado)
      condiciones["gasto.agente_id"] = session[:gasto_proyectos_filtro_agente] unless session[:gasto_proyectos_filtro_agente] == "todos"
    else
      agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado)
      condiciones["gasto.agente_id"] = agentes_permitidos.find_by_id(session[:gasto_proyectos_filtro_agente]) unless session[:gasto_proyectos_filtro_agente] == "todos"
      condiciones["gasto.agente_id"] = agentes_permitidos if session[:gasto_proyectos_filtro_agente] == "todos"
    end

    # Filtros a aplicar sobre los gastos seleccionados
    if session[:gasto_proyectos_filtro_aplicar_fecha] and  (session[:gasto_proyectos_filtro_inicio] <= session[:gasto_proyectos_filtro_final])
      condiciones["gasto.fecha"] = session[:gasto_proyectos_filtro_inicio]..session[:gasto_proyectos_filtro_final]
    elsif  session[:gasto_proyectos_filtro_etapa] != "todas"
      @etapa = Etapa.find( session[:gasto_proyectos_filtro_etapa] )
      condiciones["gasto.fecha"] = @etapa.fecha_inicio..@etapa.fecha_fin
    end
    condiciones["gasto.moneda_id"] = session[:gasto_proyectos_filtro_moneda] unless session[:gasto_proyectos_filtro_moneda] == "todas"
    # Cuando filtramos por financiador, tenemos que tener cuidado para recoger solo los financiadores en este proyecto
    unless session[:gasto_proyectos_filtro_financiador] == "todos"
      joins.push(:gasto_x_agente)
      condiciones["gasto_x_agente.agente_id"] = session[:gasto_proyectos_filtro_financiador]
      condiciones["gasto_x_agente.proyecto_id"] = @proyecto.id
    end
    joins.push(:gasto_x_actividad) unless session[:gasto_proyectos_filtro_actividad] == "todas"
    condiciones["gasto_x_actividad.actividad_id"] = session[:gasto_proyectos_filtro_actividad] unless session[:gasto_proyectos_filtro_actividad] == "todas"
    condiciones["gasto.partida_id"] = session[:gasto_proyectos_filtro_partida] unless session[:gasto_proyectos_filtro_partida] == "todas"
    condiciones["gasto_x_proyecto.subpartida_id"] = session[:gasto_proyectos_filtro_subpartida] unless session[:gasto_proyectos_filtro_subpartida] == "todas"
    # Sustituimos las condiciones de marcado por un join + where antes del paginate
    #condiciones["gasto.marcado_id"] = session[:gasto_proyectos_filtro_marcado] unless session[:gasto_proyectos_filtro_marcado] == "todos"
    condiciones_marcado = ["gasto.marcado_id = ? OR gasto_x_proyecto.marcado_proyecto_id = ?", session[:gasto_proyectos_filtro_marcado], session[:gasto_proyectos_filtro_marcado]] unless session[:gasto_proyectos_filtro_marcado] == "todos"

    return joins, condiciones, condiciones_marcado
  end

  # Prepara los filtros para el listado de cofinanciables
  def condiciones_cofinanciables
    @etapa = Etapa.find_by_id( session[:gasto_proyectos_filtro_etapa] ) unless session[:gasto_proyectos_filtro_etapa] == "todas"
    condiciones = {"proyecto_origen_id" => @proyecto.proyecto_cofinanciador}

    # A no ser que el usuario este asignado con un rol de administracion, le impone filtros especiales
    if @proyecto.usuario_admin?(@usuario_identificado)
      condiciones["gasto.agente_id"] = @proyecto.implementador if session[:gasto_proyectos_filtro_agente] == "todos"
      condiciones["gasto.agente_id"] = session[:gasto_proyectos_filtro_agente] unless session[:gasto_proyectos_filtro_agente] == "todos"
    else
      agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado)
      condiciones["gasto.agente_id"] = agentes_permitidos if session[:gasto_proyectos_filtro_agente] == "todos"
      condiciones["gasto.agente_id"] = agentes_permitidos.find_by_id(session[:gasto_proyectos_filtro_agente]) unless session[:gasto_proyectos_filtro_agente] == "todos"
    end
    
    condiciones["gasto.fecha"] = @etapa.fecha_inicio..@etapa.fecha_fin unless session[:gasto_proyectos_filtro_etapa] == "todas"
    condiciones["gasto.partida_id"] = session[:gasto_proyectos_filtro_partida] unless session[:gasto_proyectos_filtro_partida] == "todas"
    condiciones["gasto.proyecto_origen_id"] = session[:gasto_proyectos_filtro_proyecto] unless session[:gasto_proyectos_filtro_proyecto] == "todos"
    # Filtro de financiadores del gasto
    condiciones["gasto_x_agente.agente_id"] = session[:gasto_proyectos_filtro_financiador] unless session[:gasto_proyectos_filtro_financiador] == "todos"
    # El filtro de gastos ya pillados o sin pillar lo aplicamos segun se haya elegido
    condiciones_cofinanciados = {}
    condiciones_cofinanciados["gasto_x_proyecto.proyecto_id"] = @proyecto.id if session[:gasto_proyectos_filtro_cofinanciado] == "1"
    # El filtro de no cofinanciados es un poco asin... averiguar como se haria mas elegantemente
    condiciones_cofinanciados = ["gasto.id NOT IN (SELECT gasto_id FROM gasto_x_proyecto WHERE proyecto_id = ?)", @proyecto.id] if session[:gasto_proyectos_filtro_cofinanciado] == "2"
    # Si el filtro de moneda es todas, escogemos solo aquellas aceptadas por el proyecto
    condiciones["gasto.moneda_id"] = @proyecto.moneda if session[:gasto_proyectos_filtro_moneda] == "todas"
    condiciones["gasto.moneda_id"] = session[:gasto_proyectos_filtro_moneda] unless session[:gasto_proyectos_filtro_moneda] == "todas"
    # Filtro sobre marcado
    condiciones["gasto.marcado_id"] = session[:gasto_proyectos_filtro_marcado] unless session[:gasto_proyectos_filtro_marcado] == "todos"

    return condiciones, condiciones_cofinanciados
  end

  def word_wrap(text, columns = 80)
    text.split("\n").collect do |line|
      line.length > columns ? line.gsub(/(.{1,#{columns}})([\s\/]+|$)/, "\\1\n").strip : line
    end * "\n"
  end
end

