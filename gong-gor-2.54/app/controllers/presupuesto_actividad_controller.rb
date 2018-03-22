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
class PresupuestoActividadController < ApplicationController

  before_filter :filtrado_listados_inicial, :only => [ :listado]

  before_filter :filtro_presupuesto_x_actividad, :only => [ :presupuesto_x_actividad, :modificar_crear_presupuesto_x_actividad, :eliminar_presupuesto_x_actividad ]
  before_filter :verificar_estado_formulacion_ajax, :only => [ :modificar_crear, :eliminar ]

  # --
  # FILTROS
  # ++

  def verificar_estado_formulacion_ajax
    unless @permitir_formulacion
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar la matriz")    if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se puede modificar el presupuesto.") unless @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end

  def filtro_presupuesto_x_actividad
    @etapa = Etapa.find( session[:presupuesto_actividad_filtro_etapa] ) unless session[:presupuesto_actividad_filtro_etapa] == "todas"
    @condiciones = { "presupuesto.proyecto_id" => @proyecto.id }
    @condiciones["presupuesto.etapa_id"] = @etapa.id unless session[:presupuesto_actividad_filtro_etapa] == "todas"
    @condiciones["presupuesto.agente_id"] = session[:presupuesto_actividad_filtro_agente] unless session[:presupuesto_actividad_filtro_agente] == "todos"
    @condiciones["presupuesto.moneda_id"] = session[:presupuesto_actividad_filtro_moneda] unless session[:presupuesto_actividad_filtro_moneda] == "todas"
    @condiciones["presupuesto.partida_id"] = session[:presupuesto_actividad_filtro_partida] unless session[:presupuesto_actividad_filtro_partida] == "todas"
  end



  def filtrado_listados_inicial
    session[:presupuesto_actividad_asc_desc] ||= "ASC"
    session[:presupuesto_actividad_cadena_orden] ||= "partida.codigo"
    session[:presupuesto_actividad_filtro_etapa] ||= "todas" #@proyecto.etapa.sort{ |a,b| a.fecha_inicio <=> b.fecha_inicio }.first.id
    session[:presupuesto_actividad_filtro_agente] ||= "todos"
    session[:presupuesto_actividad_filtro_moneda] ||= "todas"
    session[:presupuesto_actividad_filtro_partida] ||= "todas"
  end


  def index
    redirect_to :action => :listado_por_actividades
  end



  def filtrado
    session[:presupuesto_actividad_filtro_etapa] = params[:filtro][:etapa]
    session[:presupuesto_actividad_filtro_agente] = params[:filtro][:agente]
    session[:presupuesto_actividad_filtro_moneda] = params[:filtro][:moneda]
    session[:presupuesto_actividad_filtro_partida] = params[:filtro][:partida]
    redirect_to :action => params[:listado]
  end

  def elementos_filtrado
    filtro_etapa = [[_("Todas"), "todas"]] + @proyecto.etapa.sort{ |a, b| a.fecha_inicio <=> b.fecha_inicio }.collect{ |e| [e.nombre, e.id.to_s] }
    filtro_agente = [[_("Todos"), "todos"]]  + @proyecto.implementador.collect{ |e| [e.nombre, e.id.to_s] }
    filtro_moneda = [[_("Todas"), "todas"]]  + @proyecto.moneda.collect{ |e| [e.nombre, e.id.to_s] }
    filtro_partida = [[_("Todas"), "todas"]] + Partida.all(:order => "codigo").collect {|p| [p.codigo_nombre(@proyecto.id), p.id.to_s]}.sort{ |a,b| a[0] <=> b[0] }
    @opciones_filtrado = [{:rotulo =>  _("Seleccione etapa"), :nombre => "etapa", :opciones => filtro_etapa},
                          {:rotulo =>  _("Seleccione moneda"), :nombre => "moneda", :opciones => filtro_moneda},
                          {:rotulo =>  _("Seleccione agente"), :nombre => "agente", :opciones => filtro_agente},
                	  {:rotulo =>  _("Seleccione partida"), :nombre => "partida", :opciones => filtro_partida} ]
    @accion_filtrado = {:action => :filtrado, :listado => :listado}
    @etapa = Etapa.find( session[:presupuesto_actividad_filtro_etapa]) unless session[:presupuesto_actividad_filtro_etapa] == "todas"
    @resumen = {:url => {:action => :presupuesto, :controller => :resumen_proyecto, :sin_layout => true}}
  end


  def listado
    @actividades = @proyecto.actividad.where("resultado_id IS NOT NULL") + @proyecto.actividad.where(resultado_id: nil)
    elementos_filtrado
  end

  def presupuesto_x_actividad
    @actividad = Actividad.find_by_id(params[:id])

    condiciones = { "presupuesto.proyecto_id" => @proyecto.id }
    condiciones["presupuesto.etapa_id"] = session[:presupuesto_actividad_filtro_etapa] unless session[:presupuesto_actividad_filtro_etapa] == "todas"
    condiciones["presupuesto.agente_id"] = session[:presupuesto_actividad_filtro_agente] unless session[:presupuesto_actividad_filtro_agente] == "todos"
    condiciones["presupuesto.moneda_id"] = session[:presupuesto_actividad_filtro_moneda] unless session[:presupuesto_actividad_filtro_moneda] == "todas"
    condiciones["presupuesto.partida_id"] = session[:presupuesto_actividad_filtro_partida] unless session[:presupuesto_actividad_filtro_partida] == "todas"

    if @actividad
      condiciones["presupuesto_x_actividad.actividad_id"] = @actividad.id
      @presupuestos =  Presupuesto.find( :all, :order => (session[:presupuesto_actividad_cadena_orden] + " " + session[:presupuesto_actividad_asc_desc]), 
                     :include => [:partida, :libro, :subpartida, :presupuesto_x_actividad], :conditions => condiciones) 
    else
      @presupuestos =  Presupuesto.sin_actividad(@proyecto).all( :order => (session[:presupuesto_actividad_cadena_orden] + " " + session[:presupuesto_actividad_asc_desc]), 
                     :include => [:partida, :libro, :subpartida], :conditions => condiciones)
    end

    render :update do |page|
      page.replace_html "actividad_sub_" + (params[:id]||"0"), :partial => "presupuesto_x_actividad"
    end
  end

  def datos_formulario
    @etapas = @proyecto.etapa.collect {|a|[a.nombre, a.id]}
    @partidas = Partida.all(:order => "codigo").collect {|a| [a.codigo_nombre(@proyecto.id), a.id]}.sort{ |a,b| a[0] <=> b[0] }
    @implementadores = @proyecto.implementador.all(:order => "nombre").collect {|a|[a.nombre, a.id]}
    @monedas = @proyecto.moneda.all(:order => "abreviatura").collect {|a| [a.abreviatura, a.id]} 
    @paises = [[_("Ppto. Regional"),nil]] + @proyecto.pais_gasto.collect{|m| [m.nombre,m.id]}
  end

  def nuevo_o_elegir_concepto
    #render (:update) {|page| page.formulario :partial => "nuevo_o_elegir_concepto", :update => "formulario_anadir_" + params[:actividad_id] }
    render (:update) {|page| page.formulario :partial => "nuevo_o_elegir_concepto", :update => params[:update] }
  end

  # en proyectos: prepara el formulario de edición o creación de presupuesto
  def editar_nuevo
    if params[:presupuesto] 
      @presupuesto = @objeto = Presupuesto.find_by_concepto_and_proyecto_id(params[:presupuesto][:concepto], @proyecto.id)
      @nueva_vinculacion = true
    end
    unless @presupuesto
      @presupuesto = @objeto = params[:id] ?  Presupuesto.find(params[:id]) : Presupuesto.new
      @nueva_vinculacion = nil
    end
    @actividades = @presupuesto.presupuesto_x_actividad
    @financiadores = @presupuesto.presupuesto_x_agente
    @presupuesto_x_actividad = params[:id] ? PresupuestoXActividad.find_by_presupuesto_id_and_actividad_id(params[:id], params[:actividad_id]) : PresupuestoXActividad.new
    datos_formulario
    mensaje = (@presupuesto.presupuesto_x_actividad.size >= 2 or @nueva_vinculacion) ? _("Este concepto se encuentra en varias actividades. El importe y las unidades son la parte correspondiente para esta actividad") : nil
    render :update  do |page| 
      page.remove "formulariocontenedor" unless params[:id]
      page.formulario :partial => "presupuesto_proyectos/formulario", :mensaje_formulario => mensaje, :update => params[:update] 
    end
  end

  def financiadores
    @presupuesto = @objeto = params[:id] ?  Presupuesto.find(params[:id]) : Presupuesto.new
    @financiadores = @presupuesto.presupuesto_x_agente
    render :update do |page|
      page.replace "financiadores", :partial => "financiadores"
    end 
  end

  # en proyectos: añade un financiador al formulario
  def anadir_financiador
    render :template => "comunes/anadir_financiador"
  end

  def calcula_importe
    numero_unidades = moneda_a_float params[:presupuesto_x_actividad][:numero_unidades] 
    coste_unitario = moneda_a_float params[:presupuesto][:coste_unitario_convertido] 
    @importe_formateado = ('%.2f' % (numero_unidades * coste_unitario)).to_s.sub(".",",")
    render :update do |page|
      page.replace_html "presupuesto_importe_convertido", :inline => "<%= _('Importe') %> <br><b><%= @importe_formateado %><br>"
      page[:presupuesto_x_actividad_importe].value = numero_unidades * coste_unitario if numero_unidades && coste_unitario
    end
    
  end


  # en proyectos: modifica o crea un presupuesto
  def modificar_crear
    session[:presupuesto_actividad_ultimo] = params
    #etapa = Etapa.find( session[:presupuesto_actividad_filtro_etapa] )
    @presupuesto = params[:id] ?  Presupuesto.find(params[:id]) : Presupuesto.new()
    @presupuesto_x_actividad = PresupuestoXActividad.find_by_presupuesto_id_and_actividad_id(params[:id], params[:actividad_id]) 
    @presupuesto_x_actividad ||= PresupuestoXActividad.new( )
    @presupuesto.proyecto_id = @proyecto.id
    @presupuesto.attributes = params[:presupuesto]
    @presupuesto_x_actividad.actividad_id = params[:actividad_id]
    @presupuesto_x_actividad.attributes = params[:presupuesto_x_actividad]
    ActiveRecord::Base.transaction do
      unless params[:id]
        @presupuesto.importe, @presupuesto.numero_unidades = @presupuesto_x_actividad.importe, @presupuesto_x_actividad.numero_unidades 
        @presupuesto.save
        @presupuesto.presupuesto_x_actividad << @presupuesto_x_actividad
      else
        @presupuesto.presupuesto_x_actividad << @presupuesto_x_actividad
        @presupuesto.importe = @presupuesto.presupuesto_x_actividad.inject(0) {|suma, pxa| suma + pxa.importe}
        @presupuesto.numero_unidades = @presupuesto.presupuesto_x_actividad.inject(0) {|suma, pxa| suma + pxa.numero_unidades}
        @presupuesto.save
      end
      @presupuesto_x_actividad.errors.each {|k,m| @presupuesto.errors.add "",m}
      @errores = @presupuesto.errors
      # Si algo falla no gurdamos ni presupuesto ni presupuesto por actividad
      raise ActiveRecord::Rollback unless @presupuesto_x_actividad.errors.empty? and @presupuesto.errors.empty?
    end   
    if (@presupuesto_x_actividad.errors.empty? and @presupuesto.errors.empty?) or params[:id]
      @presupuesto.subpartida.update_attribute(:proyecto_id, @proyecto.id)  if @presupuesto.subpartida
      # Si se manda sin detalle tenemos que especificar e igualar los importes al del presupuesto
      params["financiadores"]["0"]["importe_convertido"] = @presupuesto.importe if params["financiadores_detallado"]["detallado"] == "no"
      @presupuesto.actualizar_presupuesto_x_agente params[:financiadores] 
      # obtenemos la actividad del proyecto a la que pertenece
      @objeto = @presupuesto = Presupuesto.find( params[:id], :include => :presupuesto_x_actividad, :conditions => {"presupuesto_x_actividad.actividad_id" => params[:actividad_id]} ) if params[:id] # Esto parece algo absurdo pero lo recargamos para que al recargar la linea muestre la información de la actividad editada
      actividad = Actividad.find(params[:actividad_id])
      render(:update) do |page| 
        if params[:id] and !(params[:nueva_vinculacion])
          page.modificar :update => params[:update], :partial => "presupuesto", :locals => { :presupuesto => @presupuesto, :actividad => actividad }, :mensaje => { :errors => @presupuesto.errors}  
        else
        # Si es un nuevo gasto
          page.nueva_fila :update => "nuevo_" + actividad.id.to_s, :partial => "presupuesto", :nueva_fila => @presupuesto_x_actividad.id.to_s, :locals => { :presupuesto => @presupuesto, :actividad => actividad }, :mensaje => { :errors => @presupuesto.errors} 
        end
        page.replace "suma_" + params[:actividad_id], :partial => "presupuesto_proyectos/suma", :locals => {:objeto => actividad }
      end
    else
    # Si hay fallo grabando el gasto mostramos el formulario con el mensaje de error
      @financiadores = @presupuesto.presupuesto_x_agente
      @objeto = @presupuesto
      @presupuesto.id = nil #Esto es un poco chapu, pero está dando problemas
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "presupuesto_proyectos/formulario", :mensaje => {:errors => @presupuesto.errors} }
    end 
  end




  def eliminar
    @actividad = Actividad.find_by_id(params[:actividad_id])
    @pxa = PresupuestoXActividad.find_by_presupuesto_id_and_actividad_id(params[:id], params[:actividad_id])
    presupuesto = @pxa.presupuesto
    @pxa.destroy
    # recalculamos unidades e importe
    presupuesto.importe = presupuesto.presupuesto_x_actividad.inject(0) {|suma, pxa| suma + pxa.importe}
    presupuesto.numero_unidades = presupuesto.presupuesto_x_actividad.inject(0) {|suma, pxa| suma + pxa.numero_unidades}
    presupuesto.save unless presupuesto.importe == 0
    presupuesto.destroy if presupuesto.importe == 0
    render :update do |page| 
      page.eliminar :update => params[:update], :mensaje =>  {:errors => @pxa.errors, :eliminar => true}
      page.replace "suma_" + params[:actividad_id], :partial => "presupuesto_proyectos/suma", :locals => {:objeto => @actividad }
    end
  end

  def auto_complete_for_presupuesto_subpartida_nombre
    @subpartidas = Subpartida.find(:all, :conditions => ['nombre LIKE ? AND proyecto_id = ?', "%#{params[:search]}%", params[:proyecto_id].to_s]) unless params[:presupuesto] && params[:presupuesto][:partida_id]
    @subpartidas = Subpartida.find(:all, :conditions => ['nombre LIKE ? AND proyecto_id = ? AND partida_id = ?', "%#{params[:search]}%", params[:proyecto_id].to_s, params[:presupuesto][:partida_id].to_s]) if params[:presupuesto] && params[:presupuesto][:partida_id]
    render :inline => "<%= auto_complete_result_3 @subpartidas, :nombre %>"
  end

  def auto_complete_for_presupuesto_concepto
    @presupuesto = Presupuesto.find(:all, :conditions => ['presupuesto.concepto like ? and proyecto_id = ?', "%#{params[:search]}%", @proyecto.id])
    render :inline => "<%= auto_complete_result_3 @presupuesto, :concepto %>"
  end

end
