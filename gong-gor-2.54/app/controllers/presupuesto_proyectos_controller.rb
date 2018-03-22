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
# Controlador encargado de la gestion de la entidad presupuesto. Este controlador es utilizado desde las secciones:
# * Sección proyectos: se utiliza para la gestión del presupuesto
#
class PresupuestoProyectosController < ApplicationController
  before_filter :filtrado_listados_inicial, :only => [ :listado, :listado_por_actividades]
  before_filter :verificar_etapa, :except => [:calcula_importe]

  #before_filter :verificar_estado_proyecto, :only => [ :index, :modificar_crear, :eliminar, :modificar_crear_presupuesto_x_actividad, :eliminar_presupuesto_x_actividad ]
  before_filter :verificar_estado_formulacion_ajax, :only => [ :modificar_crear, :eliminar ]

  def verificar_etapa
    if @proyecto.etapa.empty?
      msg_error _("Tiene que definir por lo menos una etapa para acceder a la gestión del presupuesto")
      redirect_to :menu => :configuracion, :controller => :datos_proyecto, :action => :etapas
    end
  end

  def verificar_estado_formulacion_ajax
    unless @permitir_formulacion
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar la matriz")    if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " +  _("En este estado no se puede modificar el presupuesto.") unless @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end

  #def verificar_estado_proyecto
  #  unless @proyecto.estado_actual.definicion_estado.formulacion
  #    msg_error _("El proyecto se encuentra en estado de ") + @proyecto.estado_actual.definicion_estado.nombre + _(". En este estado no se puede modificar el presupuesto. No ha sido definido como 'estado de formulacion' por su administrador.")
  #    redirect_to :action => :listado
  #  end
  #end

  def filtrado_listados_inicial
    session[:presupuesto_proyectos_asc_desc] ||= "ASC"
    session[:presupuesto_proyectos_cadena_orden] ||= "partida.codigo"
    session[:presupuesto_proyectos_filtro_etapa] ||= "todas" #@proyecto.etapa.sort{ |a,b| a.fecha_inicio <=> b.fecha_inicio }.first.id
    session[:presupuesto_proyectos_filtro_agente] ||= "todos"
    session[:presupuesto_proyectos_filtro_moneda] ||= "todas"
    session[:presupuesto_proyectos_filtro_partida] ||= "todas"
  end

  # --
  # METODOS DE ENTRADA A PRESUPUESTO. Seleccion de ETAPA
  # ++

  # en proyectos: se redirecciona por defecto a listado

  def index
    Partida.all.each do |partida|
        msg_error _("Alguna partida de sistema no está aún asignada a alguna de las partidas del proyecto. Vaya a 'Configuración' > 'Partidas del proyecto' para comprobarlo.") unless partida.ocultar_proyecto || partida.partida_asociada(@proyecto)
    end
    redirect_to :action => :listado
  end

  # en proyectos: establece los parametros de ordenación
  def ordenado
    session[:presupuesto_proyectos_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC" 
    session[:presupuesto_proyectos_cadena_orden] = session[:presupuesto_proyectos_orden] = params[:orden] ? params[:orden] : "fecha_inicio"
    session[:presupuesto_proyectos_cadena_orden] = "partida.codigo" if session[:presupuesto_proyectos_orden] =~ /^partida\.codigo_nombre/
    redirect_to :action => "listado"
  end

  def filtrado
    session[:presupuesto_proyectos_filtro_etapa] = params[:filtro][:etapa]
    session[:presupuesto_proyectos_filtro_agente] = params[:filtro][:agente]
    session[:presupuesto_proyectos_filtro_moneda] = params[:filtro][:moneda]
    session[:presupuesto_proyectos_filtro_partida] = params[:filtro][:partida]
    redirect_to :action => params[:listado]
  end

  def elementos_filtrado
    filtro_etapa = [[_("Todas"), "todas"]] + @proyecto.etapa.sort{ |a, b| a.fecha_inicio <=> b.fecha_inicio }.collect{ |e| [e.nombre, e.id.to_s] }
    filtro_agente = [[_("Todos"), "todos"]]  + @proyecto.implementador.collect{ |e| [e.nombre, e.id.to_s] }
    filtro_moneda = [[_("Todas"), "todas"]]  + @proyecto.moneda.collect{ |e| [e.nombre, e.id.to_s] }
    filtro_partida = [[_("Todas"), "todas"]] + Partida.all(:order => "codigo").collect {|p| [p.codigo_nombre(@proyecto.id), p.id]}.sort{ |a,b| a[0] <=> b[0] }
    @opciones_filtrado = [{:rotulo =>  _("Seleccione etapa"), :nombre => "etapa", :opciones => filtro_etapa},
                          {:rotulo =>  _("Seleccione moneda"), :nombre => "moneda", :opciones => filtro_moneda},
                          {:rotulo =>  _("Seleccione agente"), :nombre => "agente", :opciones => filtro_agente} ]
    @etapa = Etapa.find( session[:presupuesto_proyectos_filtro_etapa]) unless session[:presupuesto_proyectos_filtro_etapa] == "todas"
    @resumen = {:url => {:action => :presupuesto, :controller => :resumen_proyecto, :sin_layout => true}}
    @accion_filtrado = {:action => :filtrado, :listado => :listado}

    @estado_filtrado = [(session[:presupuesto_proyectos_filtro_etapa] == "todas" ? _("Todas las etapas") : (@etapa.nombre + " (" + @etapa.fecha_inicio.to_s + "/" + @etapa.fecha_fin.to_s + ")")), 
                       (session[:presupuesto_proyectos_filtro_moneda] == "todas" ? _("Todas las monedas") : Moneda.find(session[:presupuesto_proyectos_filtro_moneda]).nombre), 
                       (session[:presupuesto_proyectos_filtro_agente] == "todos" ? _("Todos los agentes") : Agente.find(session[:presupuesto_proyectos_filtro_agente]).nombre),
            		       (session[:presupuesto_proyectos_filtro_partida] == "todas" ? _("Todas las partidas") : Partida.find(session[:presupuesto_proyectos_filtro_partida]).nombre) ] 


  end

  # --
  # METODOS DE GESTION DE Presupuesto
  # ++
  
  # en proyectos: listado de presupuestos del proyecto cargado en la sessión
  def listado
    elementos_filtrado
    #@formato_xls = @presupuestos.total_entries
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "presupuesto"
        @objetos = @presupuestos
        nom_fich = "presupuesto_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end


  def presupuesto_x_partida
    @partida = PartidaFinanciacion.find_by_id(params[:id])
    condiciones = { "presupuesto.proyecto_id" => @proyecto.id }
    condiciones["presupuesto.proyecto_id"] = @proyecto.id
    condiciones["presupuesto.etapa_id"] = session[:presupuesto_proyectos_filtro_etapa] unless session[:presupuesto_proyectos_filtro_etapa] == "todas"
    condiciones["presupuesto.agente_id"] = session[:presupuesto_proyectos_filtro_agente] unless session[:presupuesto_proyectos_filtro_agente] == "todos"
    condiciones["presupuesto.moneda_id"] = session[:presupuesto_proyectos_filtro_moneda] unless session[:presupuesto_proyectos_filtro_moneda] == "todas"
    condiciones["presupuesto.partida_id"] = session[:presupuesto_proyectos_filtro_partida] unless session[:presupuesto_proyectos_filtro_partida] == "todas"
    if @partida
      condiciones["partida_x_partida_financiacion.partida_financiacion_id"] = @partida.id
      otras_tablas = [:partida, :libro, :subpartida, :partida_x_partida_financiacion]
      @presupuestos = Presupuesto.includes(otras_tablas).where(condiciones).order("partida.codigo")
    else
      otras_tablas = [:partida, :libro, :subpartida]
      @presupuestos = Presupuesto.sin_partida_financiador(@proyecto).includes(otras_tablas).where(condiciones).order("partida.codigo")
    end

    render :update do |page|
      page.replace_html params[:update_listado], :partial => "presupuesto_x_partida"
    end
  end

  def datos_formulario
    @etapas = @proyecto.etapa.collect {|a|[a.nombre, a.id]}
    if params[:partida_id] && params[:partida_id] != "0"
      @partidas = PartidaFinanciacion.find(params[:partida_id]).partida.all(:order => "codigo").collect {|a| [a.codigo_nombre, a.id]} 
    else
      @partidas = Partida.all(:order => "codigo").collect {|a| [a.codigo_nombre(@proyecto.id), a.id]}
    end
    @implementadores = @proyecto.implementador.all(:order => "nombre").collect {|a|[a.nombre, a.id]}
    @monedas = @proyecto.moneda.all(:order => "abreviatura").collect {|a| [a.abreviatura, a.id]} 
    @paises = [[_("Ppto. Regional"),nil]] + @proyecto.pais_gasto.collect{|m| [m.nombre,m.id]}
  end

  def nuevo_copiar_datos
    presupuesto_copiar = Presupuesto.find(params[:id])
    @presupuesto = @objeto = Presupuesto.new
    Presupuesto.datos_basicos_igualar(@presupuesto, presupuesto_copiar)  
    @actividades = presupuesto_copiar.presupuesto_x_actividad
    @financiadores = presupuesto_copiar.presupuesto_x_agente
    datos_formulario
    render :partial => "formulario"
  end

  # en proyectos: prepara el formulario de edición o creación de presupuesto
  def editar_nuevo
    @presupuesto = @objeto = Presupuesto.where(proyecto_id: @proyecto.id).find_by_id(params[:id]) || Presupuesto.new(proyecto_id: @proyecto.id)
    @actividades = @presupuesto.presupuesto_x_actividad
    @financiadores = @presupuesto.presupuesto_x_agente
    datos_formulario
    render (:update) {|page| page.formulario :partial => "formulario", :update => params[:update]}
  end

  # en proyectos: modifica o crea un presupuesto
  def modificar_crear
    session[:presupuesto_proyectos_ultimo] = params
    #etapa = Etapa.find( session[:presupuesto_proyectos_filtro_etapa] )
    @presupuesto = Presupuesto.where(proyecto_id: @proyecto.id).find_by_id(params[:id]) || Presupuesto.new
    params[:presupuesto][:proyecto_id] = @proyecto.id
    #Recogemos la etapa anterior para verificar si hay que cambiar el detalle
    etapa_anterior_id =  @presupuesto.etapa_id 

    # Se asegura de que el importe sea el calculo de numero_unidades y coste_unitario
    if params[:presupuesto] && params[:presupuesto][:numero_unidades] && params[:presupuesto][:coste_unitario_convertido]
      coste_unitario = moneda_a_float params[:presupuesto][:coste_unitario_convertido]
      params[:presupuesto][:importe] = params[:presupuesto][:numero_unidades].to_f * coste_unitario
    end

    # Asignamos los valores al presupueseto sin guadarlos para poder comprobar_fechas_etapa y comprobar_concepto_unico
    @presupuesto.attributes = params[:presupuesto]
    @presupuesto.save if @presupuesto.errors.empty?
    if @presupuesto.errors.empty?
      # (Presupuesto detallado) Dividimos el presupuesto entre toda la etapa si es un nuevo presupuesto o la etapa ha variado
      @presupuesto.dividir_por_mes(@presupuesto.etapa.fecha_inicio, @presupuesto.etapa.fecha_fin) if (params[:id].nil? or etapa_anterior_id != @presupuesto.etapa_id)

      # Si se manda sin detalle tenemos que especificar e igualar los importes al del presupuesto 
      params["actividades"]["0"]["importe_convertido"] = @presupuesto.importe unless params["actividades_detallado"] || params["resultados"]
      params["actividades"]["0"]["numero_unidades"] = @presupuesto.numero_unidades unless params["actividades_detallado"] || params["resultados"]
      params["financiadores"]["0"]["importe_convertido"] = @presupuesto.importe unless params["financiadores_detallado"]

      # Actualiza actividades
      if params["resultados"]
        actividades = @proyecto.actividad.where(:resultado_id => params[:resultados].collect{|k,v| v[:resultado_id]})
        @presupuesto.dividir_por_actividades actividades
      elsif params["dividir_actividades"]["todas"] == "1"
        # Selecciona todas las actividades de la etapa
        actividades = @proyecto.actividad.all(:include => ["actividad_x_etapa"], :conditions => {"actividad_x_etapa.etapa_id" => @presupuesto.etapa_id}) unless params["actividades_detallado"]
        # o todas las actividades seleccionadas 
        actividades = params[:actividades].collect{|key,value| @proyecto.actividad.find_by_id value[:actividad_id]} if params["actividades_detallado"]
        # y las actualiza
        @presupuesto.dividir_por_actividades actividades
      else
        # Solo las actividades seleccionadas con los importes correspondientes
        @presupuesto.actualizar_presupuesto_x_actividad(params[:actividades])
      end
      # Actualiza financiadores
      @presupuesto.actualizar_presupuesto_x_agente params[:financiadores]
    end

    # obtenemos la partida del proyecto a la que pertenece
    # Recargamos el elemento del presupuesto para que los datos que se muestren en el listado sean los que se han grabado realmente en la BBDD.
    # Un ejemplo de este problema puede ser si se escriben varios deciamales y en la BBDD no se ha guardado ese detalle.
    @objeto = @presupuesto.reload
    if @presupuesto.errors.empty? or @presupuesto.id
      partida = PartidaFinanciacion.find_by_id(params[:partida_id])
      render(:update) do |page| 
        # Si el presupuesto ya existía
        if params[:id]
          page.modificar :update => params[:update], :partial => "presupuesto", :locals => { :presupuesto => @presupuesto, :partida => partida}, :mensaje => { :errors => @presupuesto.errors }  
        # Si es un nuevo presupuesto
        else
          nueva = params[:update_listado] +"_"+ (rand 1000000).to_s
          page.nueva_fila :update => params[:update_listado] + "_nuevo", :partial => "presupuesto", :nueva_fila => nueva, :locals => { :presupuesto => @presupuesto, :partida => partida }, :mensaje => { :errors => @presupuesto.errors } 
        end
        # Para el presupuesto por partidas, actualiza totales
        if partida
          page.replace "suma_" + params[:partida_id], :partial => "suma", :locals => {:objeto => partida }
          page.replace "suma_financiador_" + params[:partida_id], :partial => "suma_financiador", :locals => {:objeto => partida }
          page.replace "suma_maximo_" + params[:partida_id], :partial => "suma_maximo", :locals => {:objeto => partida }
          page.replace "caja_suma_total_inicio", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_inicio"}
          page.replace "caja_suma_total_fin", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_fin"}
        end
      end 
    else
    # Si hay fallo grabando el presupuesto mostramos el formulario con el mensaje de error 
      @actividades = @presupuesto.presupuesto_x_actividad
      @financiadores = @presupuesto.presupuesto_x_agente
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @presupuesto.errors} }
    end
  end

  # en proyectos: elimina un presupuesto
  def eliminar
    @objeto = Presupuesto.find(params[:id])
    @objeto.destroy
    partida = PartidaFinanciacion.find_by_id(params[:partida_id])
    render(:update) do |page|
      page.eliminar :update => params[:update], :mensaje =>  {:errors => @objeto.errors, :eliminar => true}
      # Para el presupuesto por partidas, actualiza totales
      if partida
        page.replace "suma_" + params[:partida_id], :partial => "suma", :locals => {:objeto => partida }
        page.replace "suma_financiador_" + params[:partida_id], :partial => "suma_financiador", :locals => {:objeto => partida }
        page.replace "suma_maximo_" + params[:partida_id], :partial => "suma_maximo", :locals => {:objeto => partida }
        page.replace "caja_suma_total_inicio", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_inicio"}
        page.replace "caja_suma_total_fin", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_fin"}
      end
    end
  end

  #-- 
  # METODOS AJAX PARA MANEJAR ACTIVIDADES Y FINANCIADORES 
  # ++

  # en proyectos: muestra el detalle de actividades para la linea de presupuesto 
  def detallar_actividades
    @presupuesto = @objeto = params[:id] ?  Presupuesto.find(params[:id]) : Presupuesto.new
    @actividades = @presupuesto.presupuesto_x_actividad
    render :update do |page|
      page.replace "actividades_detalle", :partial => "comunes/actividades_detalle"
    end
  end

  # en proyectos: muestra el detalle de resultados para la linea de presupuesto
  def detallar_resultados
    @presupuesto = @objeto = params[:id] ?  Presupuesto.find(params[:id]) : Presupuesto.new
    @resultados = []
    render :update do |page|
      page.replace "actividades_detalle", :partial => "comunes/resultados_detalle"
    end
  end

  # en proyectos: muestra el detalle de financiadores para la linea de presupuesto
  def detallar_financiadores
    @presupuesto = @objeto = params[:id] ?  Presupuesto.find(params[:id]) : Presupuesto.new
    @financiadores = @presupuesto.presupuesto_x_agente
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


  #-- 
  # OTROS METODOS AJAX
  # ++
 
   # en proyectos: hace un cambio del pais segun sea el agente implementador (para presupuestos nuevos)
  def cambia_pais
    agente = @proyecto.implementador.find_by_id params[:agente_id]
    pais_id = agente.nil? ? nil : agente.pais_id
    @paises = [[_("Ppto. Regional"),nil]] + @proyecto.pais_gasto.collect{|m| [m.nombre,m.id]}
    render :partial => "presupuesto_proyectos/pais", :locals => {:pais_id => pais_id}
  end
  
  def auto_complete_for_presupuesto_subpartida_nombre
    if params[:presupuesto] && params[:presupuesto][:partida_id]
      condiciones = ['nombre like ? and proyecto_id = ? and partida_id = ?', "%#{params[:search]}%", params[:proyecto_id].to_s, params[:presupuesto][:partida_id].to_s ]
    else
      condiciones = ['nombre like ? and proyecto_id = ?', "%#{params[:search]}%", params[:proyecto_id].to_s]
    end
    @subpartidas = Subpartida.find(:all, :conditions => condiciones)
    render :inline => "<%= auto_complete_result_3 @subpartidas, :nombre %>"
  end

	# En los formularios de edicion de presupuesto, calcula precios segun lo que haya metido
  def calcula_importe
    numero_unidades = params[:presupuesto][:numero_unidades].to_f
    coste_unitario = moneda_a_float params[:presupuesto][:coste_unitario_convertido] 
    @importe_formateado = ('%.2f' % (numero_unidades * coste_unitario)).to_s.sub(".",",")
    render :update do |page|
      # Cuando calculamos el importe del presupuesto total, modificamos sin mas
      if params[:update] == "presupuesto"
        page.replace_html "presupuesto_importe_convertido", :inline => "Importe <br><b><%= @importe_formateado %><br>"
        page[:presupuesto_importe].value = numero_unidades * coste_unitario if numero_unidades && coste_unitario
      # En caso contrario, modificamos un presupuesto por actividad
      else
        page.replace_html params[:update], :inline => "<%= texto_numero _('Importe'), 'actividad', 'importe_convertido','1_2', {name: '#{params[:update]}', value: '#{@importe_formateado}'} %>"
      end
    end
  end

	# En presupuesto por partidas, prepara el formulario de importe estimado para la partida
  def editar_nuevo_previsto
    @partida_financiacion = PartidaFinanciacion.find_by_id params[:id]
    render (:update) {|page| page.formulario :partial => "formulario_previsto_partida", :update => params[:update]}
  end

	# En presupuesto por partidas, guarda el formulario de importe estimado para la partida
  def modificar_crear_previsto
    @partida_financiacion = PartidaFinanciacion.find_by_id params[:id]
    @partida_financiacion.update_attribute :importe_convertido, params[:partida_financiacion][:importe_convertido]
    render :update do |page|
      page.modificar :update => "suma_" + params[:id], :partial => "suma", :locals => { :objeto => @partida_financiacion}, :mensaje => { :errors => @partida_financiacion.errors }
      page.replace "suma_previsto_" + params[:id], :partial => "suma_previsto", :locals => {:objeto => @partida_financiacion }
    end
  end

	# En presupuesto por partidas, prepara el formulario de presupuesto total previsto
  def editar_nuevo_total_previsto
    render (:update) {|page| page.formulario :partial => "formulario_total_previsto", :update => params[:update] }
  end

	# En presupuesto por partidas, guarda el formulario de total previsto
  def modificar_crear_total_previsto
    @proyecto.update_attribute(:importe_previsto_total, moneda_a_float(params[:proyecto][:importe_previsto_total_convertido]))
    @proyecto.update_attribute(:importe_previsto_subvencion, moneda_a_float(params[:proyecto][:importe_previsto_subvencion_convertido]))
    render :update do |page|
      page.replace "caja_suma_total_inicio", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_inicio"}
      page.replace "caja_suma_total_fin", :partial => "suma_totales", :locals => {:clase => "caja_suma_total_fin"}
      @proyecto.partida_financiacion.each do |partida|
        page.replace "suma_maximo_" + partida.id.to_s, :partial => "suma_maximo", :locals => {:objeto => partida }
      end
    end
  end

  #-- 
  # METODOS DE RECUPERAR EL ULTIMO PRESUPUESTO EDITADO
  # ++

  def editar_ultimo
    @presupuesto = @objeto = Presupuesto.new(session[:presupuesto_proyectos_ultimo]["presupuesto"])
    @actividades = [PresupuestoXActividad.new(session[:presupuesto_proyectos_ultimo]["actividades"]["0"])]
    @financiadores = [PresupuestoXAgente.new(session[:presupuesto_proyectos_ultimo]["financiadores"]["0"])]
    datos_formulario
    render :partial => "formulario"
  end

end
