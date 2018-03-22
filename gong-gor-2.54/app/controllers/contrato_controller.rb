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
# Controlador encargado de la gestion de la entidad contratos.
# Este controlador es utilizado desde las secciones:
# * Sección agentes: se utiliza para la gestión de contratos del agente (propios o referidos a proyectos).
# * Sección proyectos: se utiliza para la gestión de contratos de proyecto
#

class ContratoController < ApplicationController

  # --
  # METODOS DE GESTION DE Contratos 
  # ++

  # se redirecciona por defecto a listado
  def index
    redirect_to :action => :listado
  end

  # establece los parametros de ordenación
  def ordenado
    session[:contrato_asc_desc] = params[:asc_desc]
    session[:contrato_orden] = params[:orden]
    session[:contrato_orden] = "contrato." + params[:orden] if params[:orden] == "nombre"
    redirect_to :action => :listado
  end

  # en agentes: establece los parametros de filtro
  def filtrado
    if params[:filtro]
      session[:contrato_filtro_agente] = params[:filtro][:agente] if params[:filtro][:agente] && @proyecto
      if params[:filtro][:proyecto] && @agente
        params[:filtro][:proyecto].reject!(&:blank?) if params[:filtro][:proyecto].class.name == "Array"
        session[:contrato_filtro_proyecto] = params[:filtro][:proyecto]
      end
      session[:contrato_filtro_estado] = params[:filtro][:estado] if params[:filtro][:estado]
      session[:contrato_filtro_proveedor] = params[:filtro][:proveedor] if params[:filtro][:proveedor]
    end
    redirect_to :action => :listado
  end

  def elementos_filtrado
    session[:contrato_asc_desc] ||= "ASC"
    session[:contrato_orden] ||= "contrato.nombre"

    # Filtro de estado del contrato 
    session[:contrato_filtro_estado] ||= "abiertos"
    filtro_estado = [[_("Todos los abiertos"), "abiertos"], [_("Todos los cerrados"), "cerrados"], [_("Cualquier estado"), "todos"]] +
                    WorkflowContrato.order("orden").collect{|p| [p.nombre, p.id]}
    workflow_filtrado = WorkflowContrato.find_by_id session[:contrato_filtro_estado]
    @opciones_filtrado = [ {rotulo: _("Seleccione estado"), nombre: "estado", opciones: filtro_estado} ]
    @estado_filtrado = case session[:contrato_filtro_estado]
      when "abiertos" then [ _("Todos los contratos abiertos") ]
      when "cerrados" then [ _("Todos los contratos cerrados") ]
      when "todos"    then [ _("Todos los contratos") ]
      else                 [ _("Todos los contratos en estado '%{est}'")%{est: workflow_filtrado.nombre} ]
    end

    # Si estamos con un proyecto (seccion proyectos) permitimos elegir gestor
    if @proyecto
      session[:contrato_filtro_agente] ||= "todos"
      agente_filtrado = @proyecto.implementador.find_by_id session[:contrato_filtro_agente] unless session[:contrato_filtro_agente] == "todos"
      filtro_agente = [[_("Todos"), "todos"]] + @proyecto.implementador.collect{|f| [f.nombre, f.id.to_s]}
      @opciones_filtrado.push( {rotulo: _("Seleccione gestor"), nombre: "agente", opciones: filtro_agente} )
      @estado_filtrado.push( agente_filtrado ? agente_filtrado.nombre : _("Todos los gestores") )
    end

    # Si estamos con un agente (seccion agentes) permitimos elegir proyecto y proveedor
    if @agente
      session[:contrato_filtro_proyecto] = "todos" if session[:contrato_filtro_proyecto].blank?
      filtro_proyecto = @agente.proyecto_implementador.collect{|f| [f.nombre, f.id.to_s]}
      @opciones_filtrado.push( {rotulo: _("Seleccione proyectos"), nombre: "proyecto", opciones: filtro_proyecto, tipo: "multiple", clase: "3_2"} )
      proyectos_filtrado = @agente.proyecto_implementador.where(id: session[:contrato_filtro_proyecto])
      @estado_filtrado.push( _("Proyecto") + ": " + proyectos_filtrado.collect{|p| p.nombre}.join(", ")) unless proyectos_filtrado.empty?

      session[:contrato_filtro_proveedor] ||= "todos"
      proveedor_filtrado = @agente.proveedor.find_by_id session[:contrato_filtro_proveedor] unless session[:contrato_filtro_proveedor] == "todos"
      filtro_proveedor = [[_("Todos"), "todos"]] + @agente.proveedor.collect{|p| [p.nombre_nif, p.id.to_s]}
      @opciones_filtrado.push( {rotulo: _("Seleccione proveedor"), nombre: "proveedor", opciones: filtro_proveedor, clase: "1", enriquecido: true} )
      @estado_filtrado.push( proveedor_filtrado ? proveedor_filtrado.nombre : _("Todos los proveedores") )
    end

    @accion_filtrado = {:action => :filtrado, :listado => :listado}
  end

  # listado de contratos 
  def listado
    elementos_filtrado
    condiciones = case session[:contrato_filtro_estado]
      when "abiertos" then { "workflow_contrato.cerrado" => false }
      when "cerrados" then { "workflow_contrato.cerrado" => true }
      when "todos"    then {}
      else                 { "workflow_contrato.id" => session[:contrato_filtro_estado] }
    end
    # Si estamos en proyectos, aplicamos unos filtros
    if @proyecto
      condiciones["contrato.agente_id"] = session[:contrato_filtro_agente] unless session[:contrato_filtro_agente] == "todos"
      condiciones["contrato.proyecto_id"] = @proyecto.id
    end
    # Y si estamos en agentes, aplicamos otros
    if @agente
      condiciones["contrato.proveedor_id"] = session[:contrato_filtro_proveedor] unless session[:contrato_filtro_proveedor] == "todos"
      condiciones["contrato.agente_id"] = @agente.id
      condiciones["contrato.proyecto_id"] = session[:contrato_filtro_proyecto] unless session[:contrato_filtro_proyecto] == "todos"
    end

    # Y pide los totales del objeto con los filtros aplicados
    @importes_totales = (@proyecto || @agente).totales_contratos(condiciones)
    @num_contratos = (@proyecto || @agente).num_contratos(condiciones)
    @contratos = @paginado = Contrato.includes("workflow_contrato").joins(:proveedor).
                                      where(condiciones).
                                      order(session[:contrato_orden] + " " + session[:contrato_asc_desc]).
                                      paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                               per_page: (params[:format_xls_count] || session[:por_pagina]))

    @formato_xls = @contratos.total_entries
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "contrato"
        @objetos = @contratos
        nom_fich = "contratos_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

  # Muestra la ficha de un contrato
  def detalle
    @contrato = Contrato.where(condiciones_contrato).find_by_id(params[:id])

    # Para formato "pdf"
    if params[:format] == "pdf"
      begin
        # Le pasamos la propia url al phantomjs para que construya el pdf desde el html
        params.delete(:format)
        url = url_for(only_path: false, salida: "pdf")
        options = {margin: "1cm"}
        kit = Shrimp::Phantom.new( url, options, {"_session_id" => cookies[:_session_id]})
        send_file(kit.to_pdf, filename: "detalle_contrato_" + @contrato.codigo||@contrato.id.to_s + '.pdf', type: 'application/pdf', disposition: 'inline')
        # Evitamos que salga por pdf o por html (se envia desde el send_file)
        params[:salida] = "esto es solo para decir que se ignore los render"
      rescue => ex
        logger.error ex.message
        logger.error ex.backtrace
        msg_error _("Se produjo un error en el módulo de exportación a PDF.")
      end
    end

    # Por defecto generamos un html
    params[:salida] ||= "html"
    # Vuelca como partial para pdf o actualizando el div en el caso de html
    render :partial => "detalle" if params[:salida] == "pdf"
    render(:update) { |page| page.replace_html params[:update], partial: "detalle" } if params[:salida] == "html"    
  end

  # en agentes: prepara el formulario de edición o creación de contrato
  def editar_nuevo
    condiciones = condiciones_contrato
    @contrato = Contrato.where(condiciones).find_by_id(params[:id]) || Contrato.new(condiciones)
    datos_formulario
    render (:update) {|page| page.formulario :partial => "formulario", :update => params[:update]}
  end

  # Metodo ajax para el cambio de un tipo de contrato desde el formulario de edicion de contratos
  def cambia_tipo_contrato
    condiciones = condiciones_contrato
    @contrato = Contrato.where(condiciones).find_by_id(params[:id]) || Contrato.new(condiciones)
    @contrato.tipo_contrato = TipoContrato.where(agente_id: [@contrato.agente_id, nil].uniq).find_by_id params[:tipo_contrato_id] 
    render :partial => "campos_particulares_tipo"
  end

  # en agentes: modifica o crea un contrato
  def modificar_crear
    condiciones = condiciones_contrato
    @contrato = Contrato.where(condiciones).find_by_id(params[:id]) || Contrato.new(condiciones)

    # Si estamos en un proyecto, eliminamos el parametro "proveedor" para evitar modificaciones no deseadas
    params[:contrato].delete(:proveedor_id) if @proyecto

    # Guarda cambios
    @contrato.update_attributes params[:contrato]

    # Si no ha habido errores, se encarga de modificar las condiciones particulares
    @contrato.actualizar_datos_tipo_contrato params[:campo_tipo_contrato] if @contrato.errors.empty?

    # Cuando no ha habido errores al modificar/crear el contrato
    if @contrato.errors.empty?
      # se encarga de actualizar la info de actividades en proyectos
      if @proyecto
        # Actualizacion de actividades
        if params["dividir_actividades"]["todas"] == "1"
          # Selecciona todas las actividades de la etapa
          actividades = @proyecto.actividad unless params["actividades_detallado"]
          # o todas las actividades seleccionadas 
          actividades = params[:actividades].collect{|key,value| @proyecto.actividad.find_by_id value[:actividad_id]} if params["actividades_detallado"]
          # y las actualiza
          @contrato.dividir_por_actividades actividades
        else
          # Solo las actividades seleccionadas con los importes correspondientes
          @contrato.actualizar_contrato_x_actividad(params[:actividades])
        end
        # Actualizacion de financiadores 
        @contrato.actualizar_contrato_x_financiador(params[:financiadores])
      end

      # Y la info de lineas de items y de periodos
      @contrato.actualizar_contrato_x_items(params[:item])
      @contrato.actualizar_contrato_x_periodos(params[:periodo])
    end

    # Presenta el resultado final
    if @contrato.errors.empty?
      @contrato.reload
      #elementos_filtrado
      # Si el contrato ya existía
      render(:update)  { |page| page.modificar update: params[:update], partial: "contrato", locals: { contrato: @contrato }, mensaje: {errors: @contrato.errors} } if params[:id]
      # Si es un nuevo contrato
      render(:update) do |page|
        page.show "nuevos_contratos"
        page.modificar :update => "contrato_nuevo_" + params[:i], :partial => "nuevo_contrato", :mensaje => { :errors => @contrato.errors }
        page.replace "formulario_anadir_anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>"
      end unless params[:id]
    # Si hay fallo grabando el contrato mostramos el formulario con el mensaje de error
    else
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @contrato.errors} }
    end
  end

  # elimina un contrato
  def eliminar
    @contrato = Contrato.where(condiciones_contrato).find_by_id(params[:id])
    @contrato.destroy
    render(:update) do |page|
      page.eliminar :update => params[:update], :mensaje =>  {:errors => @contrato.errors, :eliminar => true}
    end
  end

  #--
  # METODOS Ajax 
  #++

  # añade una actividad al formulario
  def anadir_actividad
    render template: "comunes/anadir_actividad"
  end

  # añade un nuevo financiador al formulario
  def anadir_financiador
    render template: "comunes/anadir_financiador"
  end
  
  # añade un nuevo item al formulario
  def anadir_item
    render(:update) { |page| page.replace "item_" + params[:linea], partial: 'item', locals: {linea: params[:linea].to_i, ultima: true} }
  end 

  # añade un nuevo periodo al formulario
  def anadir_periodo
    condiciones = condiciones_contrato
    @contrato = Contrato.where(condiciones).find_by_id(params[:id]) || Contrato.new(condiciones)
    render(:update) { |page| page.replace "periodo_" + params[:linea], partial: 'periodo', locals: {linea: params[:linea].to_i, ultima: true} }
  end

  # En el formulario de edicion, calcula importe final segun num.unidades y coste.unidad 
  def calcula_importe
    numero_unidades = moneda_a_float params[:cantidad]
    coste_unitario = moneda_a_float params[:coste_unitario]
    importe_formateado = ('%.2f' % (numero_unidades * coste_unitario)).to_s.sub(".",",")
    render :update do |page|
      page[params[:update]].value = importe_formateado
    end
  end


  #--
  # METODOS DE Plantillas de documentos asociados
  #++

  # Genera un documento contrato (ojo, el codigo hay que pasarlo a una libreria para unificar y simplificar controladores)
  def crear_documento_contrato
    condiciones = condiciones_contrato
    @contrato = Contrato.where(condiciones).find_by_id(params[:id])
    @documento = Documento.includes("etiqueta").where("etiqueta.nombre" => "Contrato", "etiqueta.tipo" => "plantilla").find_by_id params[:docu_id]

    if @documento && File.exists?(@documento.adjunto.path)
      nom_fich = @contrato.codigo + "." + @documento.adjunto_file_name
      fichero = Tempfile.new("contrato_" + @contrato.codigo + "_" + SecureRandom.hex)
      fichero.close

      valores = @contrato.campos_plantilla.merge(campos_plantilla)

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
        redirect_to :action => 'listado'
      end
    else
      msg_error _("No se pudo encontrar una plantilla de 'Contrato'.") + " " + _("Contacte con el administrador del sistema.")
      redirect_to :action => 'listado'
    end
  end

  # Genera una nota de pago de contrato (ojo, el codigo hay que pasarlo a una libreria para unificar y simplificar controladores)
  def crear_nota_pago_periodo
    condiciones = condiciones_contrato
    @contrato = Contrato.where(condiciones).find_by_id(params[:id])
    @periodo = @contrato.periodo_contrato.find_by_id(params[:periodo_id]) if @contrato
    @documento = Documento.includes("etiqueta").where("etiqueta.nombre" => "Pago de Contrato", "etiqueta.tipo" => "plantilla").find_by_id params[:docu_id]

    if @documento && File.exists?(@documento.adjunto.path)
      nom_fich = @contrato.codigo + "." + @periodo.id.to_s + "." + @documento.adjunto_file_name
      fichero = Tempfile.new("pago_contrato_" + @periodo.id.to_s + "_" + SecureRandom.hex)
      fichero.close

      valores = @periodo.campos_plantilla.merge(campos_plantilla)

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
        redirect_to :action => 'listado'
      end
    else
      msg_error _("No se pudo encontrar una plantilla de 'Pago de Contrato'.") + " " + _("Contacte con el administrador del sistema.")
      redirect_to :action => 'listado'
    end
  end

  #--
  # METODOS DE Gestion de gastos asociados
  #++

  # Listado de gastos asociados
  def listado_gastos
    condiciones = condiciones_contrato
    @contrato = Contrato.where(condiciones).find_by_id(params[:id])

    gastos = @contrato.gasto.order(:fecha).
                       paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                per_page: (params[:format_xls_count] || session[:por_pagina]))

    @formato_xls = gastos.total_entries
    @listado_mas_info = {action: 'suma_total_listado_gastos', id: params[:id]}
    respond_to do |format|
      format.html do
        render(:update) do |page|
          page.replace_html(params[:update], partial: "listado_gastos", locals: {update_listado: params[:update], gastos: gastos})
        end
      end
      format.xls do
        @tipo = @proyecto ? "gasto" : "gasto_agentes"
        @objetos = gastos
        nom_fich = "gastos_contrato_" + @contrato.codigo + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', xls: nom_fich, layout: false
      end
    end
  end

  # Devuelve el importe total de gastos imputados
  def suma_total_listado_gastos
    condiciones = condiciones_contrato
    @contrato = Contrato.where(condiciones).find_by_id(params[:id])

    numero_elementos = @contrato.gasto.count
    suma_total = @contrato.importe_ejecutado_convertido
    render :update do |page|
      texto_mensaje = _("%{num} gastos con un importe total de %{val} %{mon}")%{num: numero_elementos, val: suma_total, mon: @contrato.moneda.abreviatura}
      page.insert_html :after, "cabecera", inline: mensaje_advertencia(identificador: "info_listado", texto: texto_mensaje)
      page.call('Element.show("info_listado_borrado")')
    end
  end

  # Presenta el formulario para añadir un gasto al contrato
  def editar_nuevo_gasto
    condiciones = condiciones_contrato
    @contrato = Contrato.where(condiciones).find_by_id(params[:id])

    datos_formulario_gastos

    render(:update){ |page| page.formulario partial: "formulario_gasto", update: params[:update] }
  end

  # Incluye un gasto existente al contrato
  def modificar_crear_gasto
    condiciones = condiciones_contrato
    @contrato = Contrato.where(condiciones).find_by_id(params[:id])

    params[:gxc][:contrato_id] = @contrato.id
    @gxc = GastoXContrato.create params[:gxc]

    if @gxc.errors.empty?
      div_intermedio = params[:update] + '_' + @gxc.id.to_s
      render :update do |page|
        page.insert_html :after, params[:update], '<div id="' + div_intermedio + '"></div>'
        page.modificar update: div_intermedio, partial: "gasto", locals: { update: params[:update], gasto: @gxc.gasto }, mensaje: { errors: @gxc.errors }
      end 
    else
      datos_formulario_gastos
      render(:update) { |page| page.recargar_formulario partial: "formulario_gasto", mensaje: {errors: @gxc.errors} }
    end
  end

  # Desvincula un gasto del contrato
  def eliminar_gasto
    condiciones = condiciones_contrato
    @contrato = Contrato.where(condiciones).find_by_id(params[:id])

    @gasto_x_contrato =  @contrato.gasto_x_contrato.find_by_gasto_id(params[:gasto_id])
    @gasto_x_contrato.destroy
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @gasto_x_contrato.errors, :eliminar => true}}
  end

 private

  # Condiciones comunes a la gestion de contratos
  def condiciones_contrato
    condiciones = {}
    condiciones["proyecto_id"] = @proyecto.id if @proyecto
    condiciones["agente_id"] = @agente.id if @agente
    return condiciones
  end

  # Parametros comunes edicion de un contrato 
  def datos_formulario
    @monedas = (@proyecto||@agente).moneda.collect {|a| [a.abreviatura, a.id]}
    @agentes = (@agente ? [ @agente ] : @proyecto.implementador.where(socia_local: false).order(:nombre)).collect {|a| [a.nombre, a.id]}
    @proveedores = @agente.proveedor.where(activo: true).collect {|p| [p.nombre_nif, p.id]} if @agente
    @proveedores = [ [@contrato.proveedor.nombre_nif, @contrato.proveedor.id] ] if @agente.nil? && @contrato && @contrato.proveedor
    @tipos_contrato = TipoContrato.where(agente_id: [@contrato.agente_id, nil].uniq).collect {|tc| [tc.nombre, tc.id]}
    # Detalles para actividades y financiadores
    @actividades = @contrato.contrato_x_actividad
    # Si es un contrato nuevo, le ponemos por defecto el financiador del proyecto
    if @contrato.id.nil? && params[:seccion] == "proyectos"
      @financiadores = [ ContratoXFinanciador.new(agente_id: @proyecto.agente.id, importe: 0.0 ) ]
    else
      @financiadores = @contrato.contrato_x_financiador
    end
  end

  # Parametros para la asignacion de un gasto al contrato
  def datos_formulario_gastos
    # Ponemos los filtros de los gastos que pueden estar asociados al contrato
    condiciones_gasto = { agente_id: @contrato.agente_id, proveedor_id: @contrato.proveedor_id,
                          moneda_id: @contrato.moneda_id, proyecto_origen_id: @contrato.proyecto_id,
                          fecha: @contrato.fecha_inicio..@contrato.fecha_fin }
    # Y evitamos los que ya estan asociados a algun contrato (REVISAR: NO FUNCIONA)
    outer_join_gasto = "LEFT OUTER JOIN gasto_x_contrato ON gasto_x_contrato.gasto_id = gasto.id"

    gastos = Gasto.joins(outer_join_gasto).where(condiciones_gasto).order("fecha")
    @gastos = gastos.collect{ |g| [I18n.l(g.fecha) + " -- " + g.importe_convertido + " " + g.moneda.abreviatura + " -- " + g.concepto, g.id]}
  end
end

