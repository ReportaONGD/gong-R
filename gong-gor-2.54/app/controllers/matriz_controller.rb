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
# Controlador encargado de la gestión de la matriz. Este controlador es utilizado desde las secciones:
# * Sección proyectos: se utiliza para los objetivos especificos, resultados, actividades...

class MatrizController < ApplicationController
  
  before_filter :verificar_estado_formulacion, :only => [	:index ]

  before_filter :verificar_estado_formulacion_ajax, :only => [	:modificar_crear_objetivo_general,
								:modificar_crear_objetivo_especifico, :eliminar_objetivo_especifico,
								:modificar_crear_resultado, :eliminar_resultado,
								# Las actividades deberian permitirse solo en formulacion pero parece que no son modificacion sustancial
								#:crear_modificar_actividad, :eliminar_actividad,
								:crear_modificar_fuente_verificacion, :eliminar_fuente_verificacion,
								:crear_modificar_hipotesis, :eliminar_hipotesis,
								]

  before_filter :verificar_estado_ejecucion_ajax, :only => [	:crear_modificar_valor_variable, :eliminar_valor_variable ]
  before_filter :verificar_estado_no_cerrado_ajax, :only => [	:crear_modificar_indicador, :eliminar_indicador,
								# Pasamos la modificacion de actividades a no cerrado pues no es una modificacion substancial
								:crear_modificar_actividad, :eliminar_actividad,
								:crear_modificar_subactividad, :eliminar_subactividad ]

#  before_filter :verificar_accion_oe, :only => [		:modificar_crear_objetivo_especifico,
#								:eliminar_objetivo_especifico ]
#  before_filter :verificar_accion_resultado, :only => [		:modificar_crear_resultado,
#								:eliminar_resultado ]

#  before_filter :verificar_indicador_hipotesis_fuente_verificacion, :only =>[
#                                                               :crear_modificar_hipotesis, :crear_modificar_indicador, :crear_modificar_fuente_verificacion,
#                                                                :eliminar_indicador, :eliminar_hipotesis, :eliminar_fuente_verificacion ]


  def verificar_estado_formulacion
    unless @permitir_formulacion
      msg_error _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se puede modificar la matriz.")    if @proyecto.estado_actual.nil?
      msg_error _("El proyecto se encuentra en estado '%{estado}'.") % {:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se puede modificar la matriz.") + " " + _("No ha sido definido como 'estado de formulación' por su administrador.") unless @proyecto.estado_actual.nil?
      redirect_to :action => "matriz"
    end
  end

  def verificar_estado_formulacion_ajax
    unless @permitir_formulacion
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se puede modificar la matriz.")    if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.") % {:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se puede modificar la matriz.") unless @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end 
    end
  end

  def verificar_estado_ejecucion_ajax
    unless @permitir_ejecucion
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + _("En este estado no se pueden modificar los datos del proyecto.")  if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.") % { :estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se pueden modificar los datos del proyecto.") + " " + _("No ha sido definido como 'estado de ejecución' por su administrador.") unless @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end

  # Comprueba que no este cerrado
  def verificar_estado_no_cerrado_ajax
    #unless @permitir_formulacion || @permitir_ejecucion
    unless @proyecto && @proyecto.estado_actual && @proyecto.estado_actual.definicion_estado && !@proyecto.estado_actual.definicion_estado.cerrado
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar los datos del proyecto.")  if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto no se encuentra en un estado adecuado para modificar los datos.") unless @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end

  def verificar_accion_oe
   render :update do |page|
      mensaje = _("No se puede crear o borrar el elemento desde el PAC.")
      mensaje = _("Las acciones sólo se pueden crear o borrar desde el Convenio.") if @proyecto.convenio.convenio_accion == 'objetivo_especifico'
      page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
    end    unless @proyecto.convenio.nil? || (params[:action] == "modificar_crear_objetivo_especifico" && params[:id])
  end

  def verificar_accion_resultado
    render :update do |page|
      mensaje = _("Las acciones no se pueden crear o borrar desde el PAC sólo desde el Convenio.")
      page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
    end  unless @proyecto.convenio.nil? || @proyecto.convenio.convenio_accion != 'resultado' || (params[:action] == "modificar_crear_resultado" && params[:id])
  end

  def verificar_indicador_hipotesis_fuente_verificacion
    if params[:objetivo_especifico_id]
     render :update do |page|
        mensaje = _("No se puede modificar el elemento desde el PAC.")
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end    unless @proyecto.convenio.nil?
    elsif params[:resultado_id]
      render :update do |page|
        mensaje = _("No se puede modificar el elemento desde el PAC asdf.")
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
        end   unless @proyecto.convenio.nil? || @proyecto.convenio.convenio_accion != 'resultado'
    end
  end


  #--
  # OBJETIVO GENERAL
  #-
        # en proyectos: prepara el formulario de edición o creación del objetivo general 
  def editar_nuevo_objetivo_general
    @objetivo_general = @proyecto.objetivo_general || ObjetivoGeneral.new
    render(:update) { |page| page.formulario :partial => "formulario_objetivo_general", :update => params[:update] }
  end

        # en proyectos: modifica o crea el objetivo general 
  def modificar_crear_objetivo_general
    @objetivo_general = @proyecto.objetivo_general || ObjetivoGeneral.new(:proyecto_id => @proyecto.id)
    @objetivo_general.update_attributes params[:objetivo_general]
    @proyecto.reload
    render(:update){ |page|  page.modificar(:update_listado => params[:update_listado], :partial => "objetivo_general", :mensaje => { :errors => @objetivo_general.errors }) }
  end

  #--
  # OBJETIVOS ESPECIFICOS
  #--
	# en proyectos: se redirecciona por defecto a listado
  def index
    redirect_to :action => "matriz"
  end

	# en proyectos: lista los objetivos específicos
  def matriz
    @objetivos_especificos = @proyecto.objetivo_especifico.reorder(:codigo)
    @actividades = @proyecto.actividad.where(resultado_id: nil).reorder(:codigo)
    @resumen = {:url => {:action => :matriz, :controller => :resumen_proyecto, :sin_layout => true}}
    @formato_xls = 0
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "objetivo_especifico"
        @objetos = @objetivos_especificos
        @subobjetos = [ "indicador","fuente_verificacion","hipotesis" ]
        nom_fich = "matriz_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end


	# en proyectos: lista los resultados de un objeto específico
  def listado_objetivo_especifico
    @resumen = {:url => {:action => :matriz, :controller => :resumen_proyecto, :sin_layout => true}, :mensaje => "Ver resumen de matriz"}
    @resultados = session[:objetivo_especifico].resultado.reload.sort! {|x, y|  x.codigo <=> y.codigo }
  end

	# en proyectos: prepara el formulario de edición o creación de un objeto específico
  def editar_nuevo_objetivo_especifico
    @objetivo_especifico = params[:id] ?  ObjetivoEspecifico.find(params[:id]) : nil
    mensaje = params[:id] ? "Formulario de edición de objetivo especifico" :  "Formulario de alta de nuevo objetivo especifico"
    render(:update) { |page| page.formulario :partial => "formulario_objetivo_especifico", :update => params[:update] }
  end

	# en proyectos: modifica o crea un objeto específico
  def modificar_crear_objetivo_especifico
    @objetivo_especifico = params[:id] ?  ObjetivoEspecifico.find(params[:id]) : ObjetivoEspecifico.new(:proyecto_id => params[:proyecto_id])
    @objetivo_especifico.update_attributes params[:objetivo_especifico]
    @objetivos_especificos = @proyecto.objetivo_especifico.sort! {|x, y|  x.codigo <=> y.codigo }
    @actividades = @proyecto.actividad.where(resultado_id: nil).reorder(:codigo)
    render(:update){ |page|  page.modificar(:update_listado => params[:update_listado], :partial => "matriz", :mensaje => { :errors => @objetivo_especifico.errors }) } if @objetivo_especifico.id
    render(:update){ |page|  page.recargar_formulario :partial => "formulario_objetivo_especifico", :mensaje => { :errors => @objetivo_especifico.errors } } unless @objetivo_especifico.id
  end

	# en proyectos: elimina un objeto específico
  def eliminar_objetivo_especifico
    @objetivo_especifico = ObjetivoEspecifico.find(params[:id])
    @objetivo_especifico.destroy
    render(:update) { |page|  page.eliminar(:update => params[:update], :mensaje => { :errors => @objetivo_especifico.errors, :eliminar => true }) }
  end



  #--
  # RESULTADOS
  #++
	# en proyectos: prepara el formulario de edición o creación de un resultado
  def editar_nuevo_resultado
    @oe = @proyecto.objetivo_especifico.find_by_id(params[:objetivo_especifico_id])
    @resultado = @oe.resultado.find_by_id(params[:id])
    # Si el resultado es nuevo, generamos un codigo provisional para el
    unless @resultado
      last_res = @oe.resultado.order(:codigo).last
      if last_res
        pre, post = last_res.codigo.match(/^(.*[^\d]+)([\d]*)$/).captures
        tmp_code = pre + "%02d"%((post.to_i) + 1)
      else
        tmp_code = @oe.codigo + ".R01"
      end
      @resultado = Resultado.new(codigo: tmp_code)
    end
    render(:update) { |page| page.formulario :partial => "formulario_resultado", :update => params[:update] }
  end

	# en proyectos: modifica o crea un resultado
  def modificar_crear_resultado
    @resultado = params[:id] ?  Resultado.find(params[:id]) : Resultado.new
    @objetivo_especifico = ObjetivoEspecifico.find params[:objetivo_especifico_id]
    @resultado.proyecto_id = @proyecto.id
    @resultado.objetivo_especifico_id = params[:objetivo_especifico_id]
    @resultado.update_attributes params[:resultado]
    render(:update){ |page|  page.modificar(:update_listado => params[:update_listado], :partial => "resultados", :mensaje => { :errors => @resultado.errors }) }    if @resultado.id
    render(:update){ |page|  page.recargar_formulario :partial => "formulario_resultado", :mensaje => { :errors => @resultado.errors } } unless @resultado.id
  end

	# en proyectos: elimina un resultado
  def eliminar_resultado
    @resultado = Resultado.find(params[:id])
    @resultado.destroy
    @objetivo_especifico = ObjetivoEspecifico.find params[:objetivo_especifico_id]
    render(:update) { |page|  page.eliminar(:update => params[:update], :mensaje => { :errors => @resultado.errors, :eliminar => true }) }
  end

  #--
  # ACTIVIDADES
  #++
	# en proyectos: lista las actividades de un resultado
  def actividades
    @actividades = @proyecto.actividad.where(resultado_id: params[:resultado_id]).reorder(:codigo)
    render(:update) { |page| page.replace_html params[:update], :partial => "actividades", :locals => {:update_listado => params[:update]} }
  end

	# en proyectos: prepara el formulario de edición o creación de una actividad
  def nueva_editar_actividad
    @resultado = @proyecto.resultado.find_by_id(params[:resultado_id])
    @actividad = @proyecto.actividad.where(resultado_id: @resultado).find_by_id(params[:id])
    unless @actividad
      last_act = @proyecto.actividad.where(resultado_id: @resultado).order(:codigo).last
      if last_act
        pre, post = last_act.codigo.match(/^(.*[^\d]+)([\d]*)$/).captures
        tmp_code = pre + "%02d"%((post.to_i) + 1)
      else
        tmp_code = @resultado ? @resultado.codigo + ".A01" : "AG01"
      end
      @actividad = Actividad.new(codigo: tmp_code)
    end

    @update_formulario = params[:update_formulario]
    formulario_actividad_elementos
    render(:update) { |page| page.formulario :partial => "formulario_actividad", :update => params[:update] }
  end
  
  def formulario_actividad_elementos
    @paises = (@proyecto.pais + [@proyecto.gestor.pais]).uniq
    @etapas = @proyecto.etapa
    @actividades_convenio = Actividad.all(:order => "codigo", :conditions => {:proyecto_id => @proyecto.convenio_id}).collect{ |i| [i.codigo, i.id] } if @proyecto.convenio_id && params[:menu] == "formulacion"
  end
  

	# en proyectos: modifica o crea una actividad
  def crear_modificar_actividad
    @actividad = params[:id] ? Actividad.find(params[:id]) : Actividad.new
    @resultado = Resultado.find_by_id(params[:resultado_id])
    @objetivo_especifico = ObjetivoEspecifico.find(params[:objetivo_especifico]) if params[:objetivo_especifico]
    @objetivo_especifico = ObjetivoEspecifico.find(params[:objetivo_especifico_id]) if params[:objetivo_especifico_id]
    params[:actividad][:proyecto_id] =  @proyecto.id
    @actividad.update_attributes params[:actividad]
    # Cambiamos esto mas elegante, porque no hace destroy sino delete
    @actividad.pais_ids = params["pais"].to_a.collect {|p| p[0] if p[1] == "1"} if @actividad.errors.empty?
    @actividad.etapa_ids = params["etapa"].to_a.collect {|p| p[0] if p[1] == "1"} if @actividad.errors.empty?
    @actividad.etiqueta_tecnica_ids = params["etiqueta_tecnica"].to_a.collect {|p| p[0] if p[1] == "1"} if @actividad.errors.empty?
    #@actividades =  Resultado.find(params[:actividad][:resultado_id]).actividad.sort! {|x, y|  x.codigo <=> y.codigo }
    params.delete(:resultado_id) if params[:resultado_id] == [""]
    @actividades = @proyecto.actividad.all(:order => "codigo", :conditions => {:resultado_id => params[:resultado_id]})
    params[:resultado_id] = @resultado.id if @resultado
    if @actividad.id
      render(:update){ |page|  page.modificar(:update_listado => params[:update_listado], :partial => "actividades", :mensaje => { :errors => @actividad.errors}, :tipo_update => "sublistado") }
    else
      # Si hay datos que fallan se vuelve al formulario
      formulario_actividad_elementos
      render(:update){ |page|  page.recargar_formulario :partial => "formulario_actividad", :mensaje => { :errors => @actividad.errors } }
    end
  end


	# en proyectos: elimina una actividad
  def eliminar_actividad
    @actividad = Actividad.find(params[:id])
    @actividad.destroy
    #@actividades = Resultado.find(params[:resultado_id]).actividad.sort! {|x, y|  x.codigo <=> y.codigo }
    @actividades = @proyecto.actividad.all(:order => "codigo", :conditions => {:resultado_id => params[:resultado_id]})
    render(:update) { |page|  page.eliminar(:update => params[:update], :mensaje => { :errors => @actividad.errors, :eliminar => true }) }
  end


  #--
  # INDICADORES, FUENTES DE VERIFICACION Y HIPOTESIS
  #++
	# en proyectos: lista los indicadores y las fuentes de un objetivo específico
  def indicadores_fuentes_objetivo_especifico
    @indicadores = ObjetivoEspecifico.find( params[:objetivo_especifico_id] ).indicador.sort! {|x, y|  x.codigo <=> y.codigo } 
    @fuentes_verificacion = ObjetivoEspecifico.find( params[:objetivo_especifico_id] ).fuente_verificacion.sort! {|x, y|  x.codigo <=> y.codigo }
    @hipotesis = Hipotesis.find(:all, :conditions => { :objetivo_especifico_id => params[:objetivo_especifico_id]} )
    render(:update) { |page|  page.replace_html(params[:update], :partial => "indicadores_fuentes", :locals => {:objetivo_especifico_id => params[:objetivo_especifico_id] })}    
  end

	# en proyectos: lista los indicadores y las fuentes de un resultado
  def indicadores_fuentes_resultado
    @indicadores = Resultado.find( params[:resultado_id] ).indicador.sort! {|x, y|  x.codigo <=> y.codigo }
    @fuentes_verificacion = Resultado.find( params[:resultado_id] ).fuente_verificacion.sort! {|x, y|  x.codigo <=> y.codigo }
    @hipotesis = Hipotesis.find(:all, :conditions => { :resultado_id => params[:resultado_id]} )
    render(:update) { |page|   page.replace_html(params[:update], :partial => "indicadores_fuentes", :locals => {:resultado_id => params[:resultado_id]})}    
  end

  #--
  # INDICADORES
  #++
	# en proyectos: prepara el formulario de edición o creación de un indicador para un objeto específico
  def nuevo_editar_indicador
    @indicador = params[:id] ? Indicador.find(params[:id]) : Indicador.new
    @indicadores_convenio = Indicador.all(:order => "resultado.codigo, objetivo_especifico.codigo", :include => ["objetivo_especifico","resultado"], :conditions => ["objetivo_especifico.proyecto_id = ? OR resultado.proyecto_id = ?",@proyecto.convenio_id, @proyecto.convenio_id]).collect{ |i| [i.codigo_completo, i.id] } if @proyecto.convenio_id && params[:menu] == "formulacion"
    render(:update) { |page| page.formulario(:partial => "formulario_indicador", :update => params[:update])}
  end


	# en proyectos: modifica o crea un indicador para un objeto específico
  def crear_modificar_indicador
    @indicador = params[:id] ? Indicador.find(params[:id]) : Indicador.new()
    params['indicador'][:objetivo_especifico_id] = params[:objetivo_especifico_id] if params[:objetivo_especifico_id] && params[:objetivo_especifico_id]!=""
    params['indicador'][:resultado_id] = params[:resultado_id] if params[:resultado_id] && params[:resultado_id]!=""
    @indicador.update_attributes params[:indicador]
    @indicadores =  ObjetivoEspecifico.find(params[:objetivo_especifico_id]).indicador.sort! {|x, y|  x.codigo <=> y.codigo } if params[:objetivo_especifico_id] && params[:objetivo_especifico_id]!=""
    @indicadores =  Resultado.find(params[:resultado_id]).indicador.sort! {|x, y|  x.codigo <=> y.codigo } if params[:resultado_id] && params[:resultado_id]!=""
    render(:update){ |page|  page.modificar :update_listado => params[:update_listado], :partial => (@indicadores ? "indicadores" : "indicador/indicador"), :locals => {:update_listado => params[:update_listado], :fila => params[:update]}, :mensaje => { :errors => @indicador.errors } }    if @indicador.id
    render(:update){ |page|  page.recargar_formulario :partial => "formulario_indicador", :mensaje => { :errors => @indicador.errors } } unless @indicador.id
  end


	# en proyectos: elimina un indicador para un objeto específico
  def eliminar_indicador
    @objeto = Indicador.find(params[:id])
    @objeto.destroy
    @indicadores = ObjetivoEspecifico.find(params[:objetivo_especifico_id]).indicador.sort! {|x, y|  x.codigo <=> y.codigo } if params[:objetivo_especifico_id]
    @indicadores = Resultado.find(params[:resultado_id]).indicador.sort! {|x, y|  x.codigo <=> y.codigo } if params[:resultado_id]
    render(:update) { |page|  page.eliminar(:update => params[:update], :mensaje => { :errors => @objeto.errors, :eliminar => true }) }
  end


  #--
  # FUENTES DE VERIFICACION
  #++
	# en proyectos: prepara el formulario de edición o creación de una fuente de verificación para un objeto específico
  def nueva_editar_fuente_verificacion
    @fuente_verificacion = params[:id] ? FuenteVerificacion.find(params[:id]) : FuenteVerificacion.new
    @fv_convenio = FuenteVerificacion.all(:order => "resultado.codigo, objetivo_especifico.codigo", :include => ["objetivo_especifico","resultado"], :conditions => ["objetivo_especifico.proyecto_id = ? OR resultado.proyecto_id = ?",@proyecto.convenio_id, @proyecto.convenio_id]).collect{ |i| [i.codigo_completo, i.id] } if @proyecto.convenio_id && params[:menu] == "formulacion"
    condiciones = params[:objetivo_especifico_id] ?  { :objetivo_especifico_id => params[:objetivo_especifico_id] } : { :resultado_id => params[:resultado_id] }
    @indicadores = Indicador.find(:all, :conditions => condiciones ).collect{ |i| [i.codigo, i.id] }
    render(:update) { |page| page.formulario(:partial => "formulario_fuente_verificacion", :update => params[:update]) }
  end



	# en proyectos: modifica o crea una fuente de verificación para un objeto específico
  def crear_modificar_fuente_verificacion
    params['fuente_verificacion'][:objetivo_especifico_id] = params[:objetivo_especifico_id] if params[:objetivo_especifico_id]
    params['fuente_verificacion'][:resultado_id] = params[:resultado_id] if params[:resultado_id]
    @fuente_verificacion = params[:id] ? FuenteVerificacion.find(params[:id]) : FuenteVerificacion.new
    @fuente_verificacion.update_attributes params[:fuente_verificacion]
    @fuentes_verificacion = ObjetivoEspecifico.find(params[:objetivo_especifico_id]).fuente_verificacion.sort! {|x, y|  x.codigo <=> y.codigo } if params[:objetivo_especifico_id]
    @fuentes_verificacion = Resultado.find(params[:resultado_id]).fuente_verificacion.sort! {|x, y|  x.codigo <=> y.codigo } if params[:resultado_id]
    condiciones = params[:objetivo_especifico_id] ?  { :objetivo_especifico_id => params[:objetivo_especifico_id] } : { :resultado_id => params[:resultado_id] }
    @indicadores = Indicador.find(:all, :conditions => condiciones ).collect{ |i| [i.codigo, i.id] }
    render(:update){ |page|  page.modificar :update_listado => params[:update_listado], :partial => "fuentes_verificacion", :mensaje => { :errors => @fuente_verificacion.errors } }    if @fuente_verificacion.id
    render(:update){ |page|  page.recargar_formulario :partial => "formulario_fuente_verificacion", :mensaje => { :errors => @fuente_verificacion.errors } } unless @fuente_verificacion.id
  end


	# en proyectos: elimina una fuente de verificación para un objeto específico
  def eliminar_fuente_verificacion
    @objeto = FuenteVerificacion.find(params[:id])
    @objeto.destroy
    @fuentes_verificacion = ObjetivoEspecifico.find(params[:objetivo_especifico_id]).fuente_verificacion.sort! {|x, y|  x.codigo <=> y.codigo } if params[:objetivo_especifico_id]
    @fuentes_verificacion = Resultado.find(params[:resultado_id]).fuente_verificacion.sort! {|x, y|  x.codigo <=> y.codigo } if params[:resultado_id]
    render(:update) { |page|  page.eliminar(:update => params[:update], :mensaje => { :errors => @objeto.errors, :eliminar => true }) } 
  end


  #--
  # HIPOTESIS
  #++
  # en proyectos: prepara el formulario de edición o creación de una hipotesis para un objeto específico
  def nuevo_editar_hipotesis
    @hipotesis = params[:id] ? Hipotesis.find(params[:id]) : Hipotesis.new
    render(:update) { |page| page.formulario(:partial => "formulario_hipotesis", :update => params[:update])}
  end

	# en proyectos: modifica o crea una hipotesis para un objeto específico
  def crear_modificar_hipotesis
    @hipotesis_actual = params[:id] ? Hipotesis.find(params[:id]) : Hipotesis.new
    params['hipotesis'][:objetivo_especifico_id] = params[:objetivo_especifico_id] if params[:objetivo_especifico_id]
    params['hipotesis'][:resultado_id] = params[:resultado_id] if params[:resultado_id]
    @hipotesis_actual.update_attributes params[:hipotesis]
    condiciones = params[:objetivo_especifico_id] ?  { :objetivo_especifico_id => params[:objetivo_especifico_id] } : { :resultado_id => params[:resultado_id] }
    @hipotesis = Hipotesis.find(:all, :conditions => condiciones )
    render(:update){ |page|  page.modificar :update_listado => params[:update_listado], :partial => "hipotesis", :mensaje => { :errors => @hipotesis_actual.errors } }    if @hipotesis_actual.id
    render(:update){ |page|  page.recargar_formulario :partial => "formulario_hipotesis", :mensaje => { :errors => @hipotesis_actual.errors } } unless @hipotesis_actual.id
  end



	# en proyectos: elimina una hipotesis para un objeto específico
  def eliminar_hipotesis
    @objeto = Hipotesis.find(params[:id])
    @objeto.destroy
    condiciones = params[:objetivo_especifico_id] ?  { :objetivo_especifico_id => params[:objetivo_especifico_id] } : { :resultado_id => params[:resultado_id] }
    @hipotesis = Hipotesis.find( :all, :conditions => condiciones )
    render(:update) { |page|  page.eliminar(:update => params[:update], :mensaje => { :errors => @objeto.errors, :eliminar => true }) } 
  end



  #--
  # SUBACTIVIDADES
  #++

  def subactividades
    @actividades = @proyecto.actividad
  end

  def editar_nueva_subactividad
    @subactividad = Subactividad.find_by_id(params[:id]) || Subactividad.new
    render(:update) { |page| page.formulario(:partial => "formulario_subactividad", :update => params[:update])} 
  end

  def crear_modificar_subactividad
    actividad = Actividad.find_by_id(params[:actividad_id])
    @subactividad = Subactividad.find_by_id(params[:id]) || Subactividad.new(:actividad_id => (actividad ? actividad.id : nil))
    @subactividad.update_attributes params[:subactividad]
    render(:update){ |page|  page.modificar :update => params[:update], :partial => "subactividades", :locals => { :actividad => actividad }, :mensaje => { :errors => @subactividad.errors } }  if @subactividad.errors.empty?
    render(:update){ |page|  page.recargar_formulario :partial => "formulario_subactividad", :mensaje => { :errors => @subactividad.errors } } unless @subactividad.errors.empty? 
  end

  def eliminar_subactividad
    @subactividad = Subactividad.find_by_id(params[:id])
    @subactividad.destroy if @subactividad
    render(:update) { |page|  page.eliminar(:update => params[:update], :mensaje => { :errors => @subactividad.errors, :eliminar => true }) }
  end

end


