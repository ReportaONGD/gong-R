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

# Controlador encargado de la creación de los datos basicos para el sistema.
# Este controlador es utilizado desde las secciones:
# * Sección administracion: se utiliza para crear, modificar o eliminar los datos basicos
# paises, monedas, partidas, sector de intervención, sector de población, area de actuación,
# definición de estado y tipo de tarea
class DatosBasicosController < ApplicationController

  # Permitimos solo actuar al admin
  before_filter :autorizar_admin
  
  # en administracion: se redirecciona por defecto a listado
  def index
    redirect_to :action => 'listado'
  end

  def ordenado
    session[:datos_basicos_orden] = params[:orden]
    session[:datos_basicos_orden] = "area_geografica_id" if params[:orden] == "area_geografica.nombre" 
    session[:datos_basicos_orden] = "grupo_dato_dinamico_id" if params[:orden] == "grupo_dato_dinamico.nombre"
    session[:datos_basicos_asc_desc] = params[:asc_desc]
    redirect_to :action => :listado, :nombre_dato_basico => session[:datos_basicos_nombre]
  end

  # en administracion: lista los datos basicos según params[:nombre_dato_basico]
  def listado
      session[:datos_basicos_orden] = "codigo" if session[:datos_basicos_asc_desc].nil? && params[:nombre_dato_basico] == "partida"
      session[:datos_basicos_orden] = "id" unless params[:nombre_dato_basico] 
      session[:datos_basicos_orden] = params[:orden] if params[:orden]
      session[:datos_basicos_asc_desc] = "ASC" if session[:datos_basicos_asc_desc].nil?
      params[:nombre_dato_basico] = "pais" unless params[:nombre_dato_basico]
      params[:action] =  "listado_" + params[:nombre_dato_basico]
      @nombre_dato = params[:nombre_dato_basico]
      @Nombre_dato = params[:nombre_dato_basico].gsub( /[A-Za-z]+/ ) {$&.capitalize}.gsub(/_/, "")
      @datos_basicos = @paginado = eval( @Nombre_dato ).order(session[:datos_basicos_orden]+" "+session[:datos_basicos_asc_desc]).
                                   paginate(:page => params[:page], :per_page => (session[:por_pagina]) )
      render :action => :listado
  end

  # en administracion: establece el nombre de dato y redirige hacia listado
  def listado_indicador_general
      session[:datos_basicos_nombre] = "indicador_general" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "indicador_general", :orden => "nombre", :page => params[:page]
  end

  # en administracion: establece el nombre de dato y redirige hacia listado
  def listado_pais
      session[:datos_basicos_nombre] = "pais" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "pais", :orden => "nombre", :page => params[:page]
  end

  # en administracion: establece el nombre de dato y redirige hacia listado
  def listado_area_geografica
      session[:datos_basicos_nombre] = "area_geografica" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "area_geografica", :orden => "nombre", :page => params[:page]
  end

  # en administracion: establece el nombre de dato y redirige hacia listado
  def listado_moneda
      session[:datos_basicos_nombre] = "moneda" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "moneda", :orden => "nombre", :page => params[:page]
  end

  # en administracion: establece el nombre de dato y redirige hacia listado
  def listado_partida
      session[:datos_basicos_nombre] = "partida" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "partida", :orden => "codigo", :page => params[:page]
  end

  # en administracion: establece el nombre de dato y redirige hacia listado
  def listado_categoria_sector_intervencion
      session[:datos_basicos_nombre] = "categoria_sector_intervencion" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "categoria_sector_intervencion", :orden => "nombre", :page => params[:page]
  end

  # en administracion: establece el nombre de dato y redirige hacia listado
  def listado_sector_intervencion
      session[:datos_basicos_nombre] = "sector_intervencion" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "sector_intervencion", :orden => "nombre", :page => params[:page]
  end

  # en administracion: establece el nombre de dato y redirige hacia listado
  def listado_sector_poblacion
      session[:datos_basicos_nombre] = "sector_poblacion" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "sector_poblacion", :orden => "nombre", :page => params[:page]
  end

  # en administracion: establece el nombre de dato y redirige hacia listado
  def listado_categoria_area_actuacion
      session[:datos_basicos_nombre] = "categoria_area_actuacion" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "categoria_area_actuacion", :orden => "nombre", :page => params[:page]
  end

  # en administracion: establece el nombre de dato y redirige hacia listado
  def listado_area_actuacion
      session[:datos_basicos_nombre] = "area_actuacion" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "area_actuacion", :orden => "nombre", :page => params[:page]
  end

  # en administracion: establece el grupo datos dinamicos y redirige hacia listado
  def listado_grupo_dato_dinamico
      session[:datos_basicos_nombre] = "grupo_dato_dinamico" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "grupo_dato_dinamico", :orden => "nombre", :page => params[:page]
  end
  
  # en administracion: establece el nombre de dato y redirige hacia listado
  def listado_definicion_dato
      session[:datos_basicos_nombre] = "definicion_dato" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "definicion_dato", :orden => "grupo_dato_dinamico_id", :page => params[:page]
  end

  # en administracion: establece el nombre de dato y redirige hacia listado
  def listado_tipo_tarea
      session[:datos_basicos_nombre] = "tipo_tarea" #añadimos esta varibale en la sesion para redirigir despues de ordenar
      redirect_to :action => :listado, :nombre_dato_basico => "tipo_tarea", :orden => "nombre", :page => params[:page]
  end

  def listado_estado_tarea
      session[:datos_basicos_nombre] = "estado_tarea" #añadimos esta varibale en la sesion para redirigir despues de ordenar
    redirect_to :action => :listado, :nombre_dato_basico => "estado_tarea", :orden => "nombre", :page => params[:page]
  end

  def listado_marcado
      session[:datos_basicos_nombre] = "marcado" #añadimos esta varibale en la sesion para redirigir despues de ordenar
    redirect_to :action => :listado, :nombre_dato_basico => "marcado", :orden => "nombre", :page => params[:page]
  end

  def listado_subtipo_movimiento
    session[:datos_basicos_nombre] = "subtipo_movimiento" #añadimos esta varibale en la sesion para redirigir despues de ordenar
    redirect_to :action => :listado, :nombre_dato_basico => "subtipo_movimiento", :orden => "nombre", :page => params[:page]
  end

  def listado_partida_ingreso
    session[:datos_basicos_nombre] = "partida_ingreso" #añadimos esta varibale en la sesion para redirigir despues de ordenar
    redirect_to :action => :listado, :nombre_dato_basico => "partida_ingreso", :orden => "nombre", :page => params[:page]
  end

  def listado_etiqueta_tecnica
    #puts "--------> Andamos por etiquetas tecnicas..."
    session[:datos_basicos_nombre] = "etiqueta_tecnica" #añadimos esta varibale en la sesion para redirigir despues de ordenar
    redirect_to :action => :listado, :nombre_dato_basico => "etiqueta_tecnica", :orden => "nombre", :page => params[:page]
  end
  
  def listado_tipo_periodo
    #puts "--------> Andamos por etiquetas tecnicas..."
    session[:datos_basicos_nombre] = "tipo_periodo" #añadimos esta varibale en la sesion para redirigir despues de ordenar
    redirect_to :action => :listado, :nombre_dato_basico => "tipo_periodo", :orden => "nombre", :page => params[:page]
  end
  

  # en administracion: prepara el formulario de edición o creación
  def editar_nuevo
    params[:nombre_dato_basico] = params[:tipo] if params[:tipo]
    case params[:nombre_dato_basico]
    when "marcado"
      then @estados_padre = Marcado.find(:all).collect{ |a| [a.nombre, a.id]}
    #when "definicion_dato"
    #  then @definiciones_estado = DefinicionEstado.find(:all, :conditions => {:tipo => "proyecto"}).collect{ |a| [a.nombre, a.id]}
    when "definicion_dato"
      then @grupos_datos = GrupoDatoDinamico.all(:order => "nombre").collect{ |a| [a.nombre, a.id]}
    when "pais"
      then @area_geografica = AreaGeografica.all.collect{ |a| [a.nombre, a.id]}
    end
    @Nombre_dato = params[:nombre_dato_basico].gsub( /[A-Za-z]+/ ){$&.capitalize}.gsub(/_/, "")
    @dato_basico = params[:id] ? eval( @Nombre_dato ).find( params[:id] )  : nil
    render :partial => "formulario_" + params[:nombre_dato_basico], :locals => { :nombre_dato_basico => params[:nombre_dato_basico]}
  end

  # en administracion: modifica o crea
  def modificar_crear
    @Nombre_dato = params[:nombre_dato_basico].gsub( /[A-Za-z]+/ ){$&.capitalize}.gsub(/_/, "")    
    @dato_basico = params[:id] ? eval( @Nombre_dato ).find( params[:id] ) : eval( @Nombre_dato ).new 
    @dato_basico.update_attributes params[:dato_basico]
    msg @dato_basico
    redirect_to :action => "listado", :nombre_dato_basico => params[:nombre_dato_basico]
  end

  # en administracion: elimina
  def eliminar
    @Nombre_dato = params[:nombre_dato_basico].gsub( /[A-Za-z]+/ ){$&.capitalize}.gsub(/_/, "")
    @dato = eval( @Nombre_dato ).find( params[:id] )
    @dato.destroy
    msg_eliminar @dato
    redirect_to :action => 'listado', :nombre_dato_basico => params[:nombre_dato_basico]
  end


	# Vinculaciones entre monedas y paises

  # Listado de vinculaciones de monedas y paises
  def moneda_x_pais
    pais = Pais.find_by_id params[:pais_id]
    @monedas = pais.moneda if pais
    render :update do |page|
      page.replace_html params[:update], :partial => "listado_moneda_x_pais"
    end
  end

  # Formulario para asociar una moneda a un pais
  def nuevo_moneda_x_pais
    pais = Pais.find_by_id params[:pais_id]
    @monedas = (Moneda.all(:order => "nombre") - pais.moneda).collect{|m| [m.nombre, m.id]} if pais
    render :partial => "formulario_moneda_x_pais", :locals => {:update => params[:update]}
  end

  # Crear asociacion de una moneda a un pais
  def crear_moneda_x_pais
    pais = Pais.find_by_id params[:pais_id]
    moneda = Moneda.find_by_id params[:moneda][:id]
    @mxp = MonedaXPais.create(:pais_id => pais.id, :moneda_id => moneda.id) if pais && moneda
    @monedas = pais.moneda
    render :update do |page|
      page.replace_html params[:update], :partial => "listado_moneda_x_pais"
      page.visual_effect :highlight, params[:update] , :duration => 6
      page.replace 'formulario', :inline => '<%= mensaje_error(@mxp) %><br>'
      page.call("Modalbox.resizeToContent")
    end
  end

  # Eliminar asociacion de una moneda a un pais
  def eliminar_moneda_x_pais
    pais = Pais.find_by_id params[:pais_id]
    @mxp = pais.moneda_x_pais.find_by_moneda_id(params[:id]) if pais
    @mxp.destroy if @mxp
    @monedas = pais.moneda
    render :update do |page|
      page.replace_html params[:update], :partial => "listado_moneda_x_pais"
      page.visual_effect :highlight, params[:update] , :duration => 6
      page.replace_html 'MB_content', :inline => '<%= mensaje_error(@mxp, :eliminar => true) %><br>'
      page.call("Modalbox.resizeToContent")
    end
  end

end
