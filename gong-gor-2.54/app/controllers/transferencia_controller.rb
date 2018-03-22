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
# Controlador encargado de la gestion de Transferencias. Este controlador es utilizado desde las secciones:
# * Sección agentes: se utiliza para gestionar las transferencias de un determinado agente
# * Sección proyectos: se utiliza para gestionar las transferencias de un proyecto

class TransferenciaController < ApplicationController
  
  before_filter :filtrado_ordenado_iniciales, :only => [:listado]
  before_filter :verificar_estado_proyecto, :only => [ :index, :guardar_vinculacion]
  before_filter :verificar_estado_ejecucion_ajax, :only => [ :modificar_crear, :eliminar ]

  def verificar_estado_proyecto
    unless @proyecto.nil? || @permitir_ejecucion
      msg_error( _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar los datos del proyecto.") ) if @proyecto.estado_actual.nil?
      msg_error( _("El proyecto se encuentra en estado '%{estado}'.") % {:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se pueden modificar los movimientos.") + " " + _("No ha sido definido como 'estado de ejecución' por su administrador.") ) unless @proyecto.estado_actual.nil?
      redirect_to :action => "listado"
    end if params[:seccion] == "proyectos"
  end
 
  def verificar_estado_ejecucion_ajax
    unless @proyecto.nil? || @permitir_ejecucion
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar los movimientos.")    if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " +  _("En este estado no se puede modificar los movimientos.") unless @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end
 
  # en proyectos y en agente: se redirecciona por defecto a filtrado_ordenado_iniciales creando el mensaje en funcion de la sección.
  def index
    objeto = singularizar_seccion
    #redirect_to :action => :filtrado_ordenado_iniciales
    redirect_to :action => :listado
  end

  # en proyectos y en agente: inicializa los defectos para ordenado y filtro y redirecciona a listado
  def filtrado_ordenado_iniciales
    if eval( "@" + singularizar_seccion ).etapa.empty? 
      msg_error _("Tiene que definir por lo menos una etapa para acceder a la gestión de transferencias.")
      redirect_to :menu => :configuracion, :controller => "datos_proyecto", :action => :etapas if params[:seccion] == "proyectos"
      redirect_to :menu => :configuracion_agente, :controller => "datos_agente", :action => :etapas unless params[:seccion] == "proyectos"
    else
      session[:transferencia_asc_desc] ||= "ASC" 
      session[:transferencia_orden] ||= "fecha_recibido"
      session[:transferencia_filtro_etapa] ||= "todas"
      session[:transferencia_filtro_libro] ||= "todas"
      session[:transferencia_filtro_tipo] ||= "todos"
      session[:transferencia_filtro_subtipo] ||= "todos"
      session[:transferencia_filtro_financiador] ||= "todos"
      #redirect_to :action => :listado
    end
  end

  # en proyectos y agentes: establece los parametros de ordenación
  def ordenado
    session[:transferencia_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    if params[:orden]
      session[:transferencia_orden] = case params[:orden]
        when "libro_origen.nombre" then "libro.nombre"
        when "libro_destino.nombre" then "libro_destinos_transferencia.nombre"
        when "tipo.capitalize" then "transferencia.tipo"
        else
          params[:orden]
      end
    else
      session[:transferencia_orden] = "fecha_enviado"
    end
    redirect_to :action => "listado"
  end

  # en proyectos y agentes: establece los parametros de filtro
  def filtrado
    session[:transferencia_filtro_etapa] = params[:filtro][:etapa]
    session[:transferencia_filtro_tipo] = params[:filtro][:tipo]
    session[:transferencia_filtro_libro] = params[:filtro][:libro]
    session[:transferencia_filtro_subtipo] = params[:filtro][:subtipo]
    session[:transferencia_filtro_financiador] = params[:filtro][:financiador]
    redirect_to :action => :listado
  end

  def elementos_filtrado
    @libro = Libro.find( session[:transferencia_filtro_libro] ) unless session[:transferencia_filtro_libro] == "todas"
    @etapa = Etapa.find( session[:transferencia_filtro_etapa] ) unless session[:transferencia_filtro_etapa] == "todas"
    @tipo = session[:transferencia_filtro_tipo].to_s unless session[:transferencia_filtro_tipo] == "todos"
    @subtipo = SubtipoMovimiento.find_by_id( session[:transferencia_filtro_subtipo] ) unless session[:transferencia_filtro_subtipo] == "todos"

    filtro_etapa = [[_("Todas"),"todas"]] +   eval( "@" + singularizar_seccion ).etapa.sort{ |a, b| a.fecha_inicio <=> b.fecha_inicio }.collect{ |e| [e.nombre, e.id] }
    filtro_libro = [[_("Todas"),"todas"]] +   eval( "@" + singularizar_seccion ).libro.select{|l| @usuario_identificado.libro.include? l}.collect {|a|[a.nombre, a.id]}
    filtro_subtipo = [[_("Todos"), "todos"]] + SubtipoMovimiento.all.collect{|a| [a.nombre, a.id]}

    @opciones_filtrado = [{:rotulo =>  _("Seleccione etapa"), :nombre => "etapa", :opciones => filtro_etapa},
                          {:rotulo =>  _("Seleccione cuenta"), :nombre => "libro", :opciones => filtro_libro},
                          {:rotulo =>  _("Seleccione tipo"), :nombre => "tipo", :opciones => filtro_tipo },
                          {:rotulo =>  _("Seleccione subtipo"), :nombre => "subtipo", :opciones => filtro_subtipo }  ]

    @accion_filtrado = {:action => :filtrado, :listado => :listado}

    @estado_filtrado = [(@etapa ? (@etapa.nombre + " (" + @etapa.fecha_inicio.to_s + "/" + @etapa.fecha_fin.to_s + ")") : _("Cualquier etapa")),
                       (@libro ? @libro.nombre : _("Cualquier cuenta/caja")),
                       (@tipo || _("Cualquier tipo")), (@subtipo ? @subtipo.nombre : _("Cualquier subtipo"))  ]

    # Para proyectos, incluye tambien filtro por financiador
    if params[:seccion] == "proyectos"
      @financiador = @proyecto.financiador.find_by_id( session[:transferencia_filtro_financiador] ) unless session[:transferencia_filtro_financiador] == "todos"
      filtro_financiador = [[_("Todos"), "todos"]] + @proyecto.financiador.collect{ |f| [f.nombre, f.id] } if params[:seccion] == "proyectos"
      @opciones_filtrado += [ {:rotulo => _("Seleccione financiador"), :nombre => "financiador", :opciones => filtro_financiador } ]
    end

    @resumen = {:url => {:action => :arqueo_caja, :controller => :resumen_proyecto, :sin_layout => true}, :mensaje => _("Ver resumen de arqueo de caja")}
  end

  # en proyectos y en agente: lista
  def listado
    elementos_filtrado

    if params[:seccion] == "proyectos"
      condiciones = "proyecto_id = " + @proyecto.id.to_s 
      if @proyecto.ocultar_gastos_otras_delegaciones && !@proyecto.usuario_admin?(@usuario_identificado)
        agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado)
        agentes_id_permitidos = agentes_permitidos.collect{|a| a.id}.join(",")
        condiciones += " AND (libro.agente_id IN (" + agentes_id_permitidos + ") OR libro_destinos_transferencia.agente_id IN (" + agentes_id_permitidos + ") )"
      end
    else
      condiciones = "(libro.agente_id = " + @agente.id.to_s + " OR libro_destinos_transferencia.agente_id = " + @agente.id.to_s + ")"
    end

    condiciones += " AND ( (fecha_enviado >= '" + @etapa.fecha_inicio.to_s + "' AND fecha_enviado <= '" + @etapa.fecha_fin.to_s + "')" +
                   " OR    (fecha_recibido >= '" + @etapa.fecha_inicio.to_s + "' AND fecha_recibido <= '" + @etapa.fecha_fin.to_s + "') )" if @etapa
    condiciones += " AND transferencia.tipo = '" + @tipo + "'" if @tipo
    #condiciones += " AND NOT remanente" if @tipo.nil? && @agente
    condiciones += " AND (libro_origen_id = " + @libro.id.to_s + " OR libro_destino_id = " + @libro.id.to_s + ")" if @libro
    condiciones += " AND transferencia_x_agente.agente_id = " + @financiador.id.to_s if @financiador
    condiciones += " AND subtipo_movimiento_id = " + @subtipo.id.to_s if @subtipo

    @transferencias = @paginado = Transferencia.includes([:libro_origen,:libro_destino,:transferencia_x_agente]).
                                                where(condiciones).
                                                order(session[:transferencia_orden] + " " + session[:transferencia_asc_desc]).
                                                paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                                         per_page: (params[:format_xls_count] || session[:por_pagina]))

    @formato_xls = @transferencias.total_entries
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "transferencia"
        @objetos = @transferencias
        nom_fich = "transferencias_" + (@proyecto||@agente).nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end

  end

	# en proyectos y en agente: prepara el formulario de edición o nuevo
  def editar_nuevo
    @transferencia = params[:id] || params[:nuevo_tipo] ? (Transferencia.find_by_id(params[:id]) || Transferencia.new(:tipo => params[:nuevo_tipo])) : nil 

    # Edicion de transferencia nueva o ya existente
    if @transferencia
      @etapa = Etapa.find_by_id( session[:transferencia_filtro_etapa] ) unless session[:transferencia_filtro_etapa] == "todas"
      datos_edicion

      render (:update) do |page|
        page.formulario(:partial => "formulario", :update => params[:update]) unless params[:nuevo_tipo]
        page.replace 'formulariocontenedor', :partial => "formulario", :locals => { :update => params[:update] }  if params[:nuevo_tipo]
      end
    # Formulario de nuevo libro
    else
      tipos = filtro_tipo
      # Elimina al primer elemento: "Todos"
      tipos.shift
      # Y el ultimo si hay un pac anterior: "Remanente"
      tipos.pop if @proyecto && @proyecto.pac_anterior
      render (:update) { |page| page.formulario(:partial => "formulario_nuevo", :update => params[:update], :locals => {:tipos => tipos}) } 
    end
  end

	# en proyectos y en agente: modifica o crea
  def modificar_crear
    @etapa = Etapa.find_by_id( session[:transferencia_filtro_etapa] ) unless  session[:transferencia_filtro_etapa] == "todas"
    @transferencia = Transferencia.find_by_id(params[:id]) || Transferencia.new( :proyecto_id => @proyecto ? @proyecto.id : nil )

    # Actualizamos la info de la transferencia segun los datos del formulario
    @transferencia.update_attributes params[:transferencia]

    # Si todo va bien, actualizamos tambien la info de financiadores (si existe)
    if @transferencia.errors.empty?
      @transferencia.actualizar_transferencia_x_agente params[:financiadores]
    end

    # Y actualizamos la pantalla segun haya sido el resultado
    @objeto = @transferencia 
    # Si no ha habido fallos grabando
    if @transferencia.errors.empty?
      @transferencia.reload
      # Si es una transferencia ya existente
      render(:update) { |page|   page.modificar :update => params[:update], :partial => "transferencia", :mensaje => { :errors => @transferencia.errors } } if params[:id]
      # Si es una nueva transferencia 
      render :update do |page|
        page.show "nuevas_transferencias"
        page.modificar :update => "transferencia_nueva_" + params[:i], :partial => "nueva_transferencia", :mensaje => { :errors => @transferencia.errors }
        page.replace "anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>" unless params[:id]
      end unless params[:id]
    # Si hay fallo grabando la transferencia mostramos el formulario con el mensaje de error
    else
      datos_edicion 
      @transferencia.transferencia_x_agente if params[:seccion] == "proyectos" && @transferencia.id
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @transferencia.errors} }
    end
  end

	# en proyectos y en agente: elimina una transferencia
  def eliminar
    @transferencia = Transferencia.find_by_id(params[:id]).destroy
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @transferencia.errors, :eliminar => true}}
  end

	# en proyectos y en agente: muestra la moneda del libro seleccionado
  def moneda_libro
    @moneda = params[:id] != "" ? Libro.find(params[:id]).moneda : nil
    render :update do |page|
      params[:destino].each do |upd|
        page.replace_html upd, :inline => <<-FIN
          &nbsp;<br> <%=  @moneda.abreviatura if @moneda %>
        FIN
      end
    end 
  end

	# en proyectos y agentes: calculadora de tasas de cambio
  def calcula_tasa_cambio
    importe_recibido = moneda_a_float params[:importe_recibido]
    importe_cambiado = moneda_a_float params[:importe_cambiado]
    @tc = (importe_recibido != 0 && importe_cambiado != 0 ? format("%.5f",importe_recibido / importe_cambiado) : "")
    #puts "-------------> TC: " + @tc
    render :update do |page|
      page.replace_html params[:update], :inline => "<%= _('Tasa Cambio:') + @tc.to_s %>"
    end
  end

	# en agentes: cambia el proyecto asociado
  def cambio_proyecto
    @transferencia = Transferencia.find_by_id(params[:transferencia_id]) || Transferencia.new(:tipo => params[:tipo])
    @proyecto = Proyecto.find_by_id(params[:proyecto_id])
    datos_edicion
    #puts "-----------> Tenemos libros destino: " + @libros_destino.inspect
    render :update do |page|
      page.replace "destino", :partial => "linea_recibido", :locals => {:libros => @libros_destino[:libros], :rotulo_libro => @libros_destino[:rotulo], :con_tc => !@libros_origen.nil? } if @libros_destino
      page.replace "financiadores", :partial => "linea_financiadores"
    end
  end

    # en proyectos: añade un financiador al formulario
  def anadir_financiador
    @proyecto ||= Proyecto.find_by_id(params[:proyecto_id])
    render :template => "comunes/anadir_financiador"
  end


  def gastos
    @gastos = GastoXTransferencia.find_all_by_transferencia_id( params[:transferencia_id] ).collect{ |gxt| Gasto.find(gxt.gasto_id) }
    render :update do |page|
      page.replace_html params[:update], :partial => "gastos", :locals => { :update => params[:update], :transferencia_id => params[:transferencia_id], :tipo => params[:tipo], :gastos => @gastos }
    end
  end

        # en proyectos y en financiación:  prepara el formulario de edición o creación de comentarios
  def asociar_gasto
    transferencia = Transferencia.find_by_id params[:transferencia_id]
    fecha_inicio = (transferencia.fecha_enviado || transferencia.fecha_recibido || date.today) - 15.days
    fecha_fin = (transferencia.fecha_recibido || transferencia.fecha_enviado || date.today) + 15.days

    # Si el proyecto tiene configurada visibilidad limitada y no somos admin, restringimos los agentes visibles
    if @proyecto.ocultar_gastos_otras_delegaciones && !@proyecto.usuario_admin?(@usuario_identificado)
      agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado)
      agentes_id_gasto = []
      agentes_id_gasto.push(transferencia.libro_origen.agente_id) if transferencia.libro_origen && agentes_permitidos.find_by_id(transferencia.libro_origen.agente_id)
      agentes_id_gasto.push(transferencia.libro_destino.agente_id) if transferencia.libro_destino && agentes_permitidos.find_by_id(transferencia.libro_destino.agente_id)
    # En caso contrario, permitimos todos
    else
      agentes_id_gasto = []
      agentes_id_gasto.push(transferencia.libro_origen.agente_id) if transferencia.libro_origen
      agentes_id_gasto.push(transferencia.libro_destino.agente_id) if transferencia.libro_destino
    end
   
    gastos = @proyecto.gasto.where("fecha > ? AND fecha < ?", fecha_inicio, fecha_fin).
                             where("agente_id IN (?)", agentes_id_gasto).order("fecha")
    @gastos = gastos.collect{ |g| [g.fecha.to_s + " -- " + g.importe.to_s + " " + g.moneda.abreviatura + " -- " + g.partida.nombre + " -- " + (g.concepto || "") , g.id]} 
    render :partial => "asociar_gasto", :locals => { :transferencia_id => params[:transferencia_id], :update => params[:update] }
  end

        # en proyectos y en financiación:  modifica o crea un comentario
  def guardar_asociar_gasto
    @gasto_x_transferencia = GastoXTransferencia.create( :gasto_id => params[:selector][:gasto], :transferencia_id => params[:transferencia_id] )
    @gastos = GastoXTransferencia.find_all_by_transferencia_id( params[:transferencia_id] ).collect{ |gxt| Gasto.find(gxt.gasto_id) }
    render :update do |page|
      page.replace 'formulario', :inline => '<%= mensaje_error(@gasto_x_transferencia) %><br>'
      page.call("Modalbox.resizeToContent")
      page.replace_html params[:update], :partial => "gastos", :locals => { :transferencia_id => params[:transferencia_id], :gastos => @gastos, :update => params[:update] }
      page.visual_effect :highlight, params[:update] , :duration => 6
    end
  end

        # en proyectos y en financiación:  elimina un comentario
  def eliminar_gasto
    @objeto = GastoXTransferencia.find(:first, :conditions => {:gasto_id => params[:gasto_id], :transferencia_id => params[:transferencia_id]})
    not @objeto.nil? and @objeto.destroy
    @gastos = GastoXTransferencia.find_all_by_transferencia_id( params[:transferencia_id] ).collect{ |gxt| Gasto.find(gxt.gasto_id) }
    render :update do |page|
      #page.replace "gastos_" + params[:transferencia_id], :partial => "gastos", :locals => { :transferencia_id => params[:transferencia_id], :gastos => @gastos }
      page.replace_html params[:update], :partial => "gastos", :locals => { :transferencia_id => params[:transferencia_id], :gastos => @gastos, :update => params[:update]} 
      page.visual_effect :highlight, params[:update] , :duration => 6
      page.replace_html 'MB_content', :inline => '<%= mensaje_error(@objeto, :eliminar => true) %><br>'
      page.call("Modalbox.resizeToContent")
    end
  end

 # --
 # VINCULACION DE MOVIMIENTOS
 # ++

  def vincular_movimientos
    @transferencia = Transferencia.find params[:id]
    condiciones = { "libro.agente_id" => @agente.id } if params[:seccion] == "agentes"
    condiciones = { "proyecto_id" => @proyecto.id } if params[:seccion] == "proyectos"
    condiciones[:transferencia_id] = nil
    condiciones[:entrante_saliente] = @transferencia.entrante_saliente == "entrante" ? "saliente" : "entrante"
    condiciones[:tipo] = @transferencia.tipo
    @transferencias = Transferencia.find(:all, :conditions => condiciones, :include => :libro, :order => " fecha asc ")
    @transferencias += [@transferencia.transferencia_vinculada] if @transferencia.transferencia_vinculada
    @transferencias = @transferencias.collect { |t| [t.fecha.to_s + "  //  " + t.importe_convertido + "  //  " + t.libro.nombre, t.id] }
    render :partial => "vincular_movimientos"
  end

  def guardar_vinculacion
    @transferencia = Transferencia.find params[:id]
    @transferencia.transferencia_vinculada.update_attribute :transferencia_id, nil if @transferencia.transferencia_vinculada
    if params[:transferencia][:desvincular] == "1"
      @transferencia.update_attribute :transferencia_id, nil
    else
      @transferencia.update_attribute :transferencia_id, params[:transferencia][:transferencia_id]
      @transferencia = Transferencia.find params[:transferencia][:transferencia_id]
      @transferencia.update_attribute :transferencia_id, params[:id]
    end
    redirect_to :action => "listado"
  end

  private

	# Obtiene los datos necesarios para una edicion
    def datos_edicion
      @proyectos = @agente.proyecto_implementador.collect{ |p| [p.nombre, p.id] if p.estado_actual && p.estado_actual.definicion_estado.ejecucion && !p.convenio? } if params[:seccion] == "agentes"
      @proyectos.delete(nil) if @proyectos
      @proyecto ||= @transferencia.proyecto
      @financiadores = @transferencia.transferencia_x_agente if @proyecto
      subs = SubtipoMovimiento.all(:conditions => {:tipo_asociado => nil}) + SubtipoMovimiento.all(:conditions => {:tipo_asociado => @transferencia.tipo})
      @subtipos = subs.collect{|s| [s.nombre, s.id]}.sort{ |a, b| a[0] <=> b[0]}
      obtiene_libros
    end

	# Obtiene los libros implicados segun las condiciones (tipo de transferencia)
    def obtiene_libros

      objeto = eval( "@" + singularizar_seccion ).libro
      cuentas_propias = objeto.all(:order => :nombre, :conditions => {:tipo => "banco", :bloqueado => :false}).select{|l| @usuario_identificado.libro.include? l}.collect {|a|[a.nombre, a.id]}
      cajas_propias = objeto.all(:order => :nombre, :conditions => {:tipo => "caja \"chica\"", :bloqueado => :false}).select{|l| @usuario_identificado.libro.include? l}.collect {|a|[a.nombre, a.id]}

      case @transferencia.tipo
        when "transferencia"
          @libros_origen = { :rotulo => _("Enviado desde Cuenta:"), :libros => cuentas_propias }
          # No hay cuenta origen o lo hay y es nuestra, podemos enviar a cualquier cuenta o caja para agentes
          # o a cualquiera de las del proyecto en seccion proyectos
          if @transferencia.libro_origen.nil? || (objeto.include?(@transferencia.libro_origen) && @usuario_identificado.libro.include?(@transferencia.libro_origen))
            objetos_destino = @proyecto.libro.all(:order => :nombre, :conditions => {:tipo => "banco", :bloqueado => :false}) if @proyecto
            objetos_destino = @agente.libro.all(:order => :nombre, :conditions => {:tipo => "banco", :bloqueado => :false}) unless @proyecto
            libros_transf_destino = objetos_destino.collect {|a|[a.nombre, a.id]}
          # Si la cuenta origen existe y no es nuestra, solo podremos recibir en libros propios 
          else
            libros_transf_destino = objeto.all.select{|l| @usuario_identificado.libro.include? l}.collect {|a|[a.nombre, a.id]}
          end
          @libros_destino = { :rotulo => _("Recibido en:"), :libros => libros_transf_destino }
        when "cambio"
          @libros_origen = { :rotulo => _("Desde Caja \"chica\""), :libros => cajas_propias }
          @libros_destino = { :rotulo => _("Hacia Caja \"chica\""), :libros => cajas_propias }
        when "retirada"
          @libros_origen = { :rotulo => _("Retirada desde:"), :libros => cuentas_propias }
          @libros_destino = { :rotulo => _("Cobrado en Caja \"chica\""), :libros => cajas_propias }
        when "ingreso"
          @libros_origen = { :rotulo => _("Ingreso desde:"), :libros => cajas_propias }
          @libros_destino = { :rotulo => _("A cuenta:"), :libros => cuentas_propias }
        when "devolucion"
          @libros_origen = { :rotulo => _("Cuenta:"), :libros => cuentas_propias + cajas_propias }
          @libros_destino = nil
        when "adelanto"
          @libros_origen = nil
          @libros_destino = { :rotulo => _("Recibido en:"), :libros => cuentas_propias + cajas_propias }
        when "reintegro"
          @libros_origen = { :rotulo => _("Reintegro desde:"), :libros => cuentas_propias }
          @libros_destino = nil
        else 
          @libros_origen = nil
          @libros_destino = { :rotulo => _("Cuenta:"), :libros => cuentas_propias }
      end
    end

    def filtro_tipo
      filtro = [ [_("Todos"),"todos"] ] + Transferencia.tipos_movimiento
      filtro.push([_("Remanente"),"remanente"]) if @agente || (@proyecto && @proyecto.pac_anterior)
      return filtro
    end

end
