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
# Controlador encargado de la gestión de los datos dinamicos de proyecto.
# Este controlador es utilizado desde las secciones:
# * Sección proyectos: se utiliza para establecer los datos dinamicos


class DatosProyectoDinamicosController < ApplicationController
  #before_filter :verificar_estado_proyecto, :only => [ :index, :modificar_beneficiarios, :modificar_crear_etapa, :modificar_crear_proyecto_cofinanciador, :modificar_datos_proyecto_dinamicos , :modificar_datos_dinamicos, :eliminar_datos_dinamicos, :eliminar_relacion, :eliminar_etapa, :eliminar_proyecto_cofinanciador, :anadir_datos_proyecto_dinamicos]

  before_filter :verificar_estado_proyecto_ajax, :only => [:anadir_nuevo, :modificar_crear, :eliminar ]
  before_filter :verificar_estado_proyecto_modalbox, :only => [ :editar_dato_dinamico, :modificar_dato_dinamico ]

  def verificar_estado_proyecto_modalbox
    grupo_datos = GrupoDatoDinamico.find_by_id params[:grupo_datos_id]
    # Si el proyecto no tiene estado y queremos modificar etapas
    # O tiene estado y es cerrado
    # O tiene estado y esta en ejecucion y queremos modificar otra cosa distinta de los libros o los datos de 
    unless (@permitir_identificacion && !grupo_datos.seguimiento) || (@permitir_ejecucion && grupo_datos.seguimiento)
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar la matriz") if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se puede modificar la información de proyecto.") if @proyecto.estado_actual && !@proyecto.estado_actual.definicion_estado.formulacion
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se pueden modificar los datos de seguimiento del proyecto.") if @proyecto.estado_actual && !@proyecto.estado_actual.definicion_estado.ejecucion
        mensaje = _("El proyecto se encuentra Cerrado.") if @proyecto.estado_actual && @proyecto.estado_actual.definicion_estado.cerrado
        page.replace_html "MB_content", :inline => "<%= mensaje_error mensaje %>", locals: { mensaje: mensaje }
      end
    end
  end

  def verificar_estado_proyecto_ajax
    #puts "----------> Grupo Datos ID: " + params[:grupo_datos_id]
    grupo_datos = GrupoDatoDinamico.find_by_id params[:grupo_datos_id]
    #puts "----------> Grupo Datos: " + grupo_datos.inspect
    # Si el proyecto no tiene estado y queremos modificar etapas
    # O tiene estado y es cerrado
    # O tiene estado y esta en ejecucion y queremos modificar otra cosa distinta de los libros o los datos de 
    #puts "---------> Son datos de seguimiento?: " + grupo_datos.seguimiento.inspect
    unless (@permitir_identificacion && !grupo_datos.seguimiento) || (@permitir_ejecucion && grupo_datos.seguimiento)
      #puts "----------> No tenemos permitida la identificacion " unless @permitir_identificacion && !grupo_datos.seguimiento
      #puts "----------> No tenemos permitida la formulacion " unless @permitir_formulacion && !grupo_datos.seguimiento
      #puts "----------> No tenemos permitida la ejecucion " unless @permitir_ejecucion && grupo_datos.seguimiento
      render :update do |page|
        mensaje = _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar la matriz") if @proyecto.estado_actual.nil?
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se puede modificar la información de proyecto.") if @proyecto.estado_actual && !@proyecto.estado_actual.definicion_estado.formulacion
        mensaje = _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se pueden modificar los datos de seguimiento del proyecto.") if @proyecto.estado_actual && !@proyecto.estado_actual.definicion_estado.ejecucion
        mensaje = _("El proyecto se encuentra Cerrado.") if @proyecto.estado_actual && @proyecto.estado_actual.definicion_estado.cerrado
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end


  # en proyectos: se redirecciona por defecto a identificación
  def index
    redirect_to :action => "listado"
  end

  # :en proyecto, prepara el listado de datos dinamicos segun grupos
  def listado
    # Comentamos para pensar en que menu se meterian los datos de cierre
    #@grupos_datos = GrupoDatoDinamico.where(seguimiento: (params[:menu] == "ejecucion_tecnica"), cierre: !(params[:menu] == "ejecucion_tecnica") ).order("rango")
    @grupos_datos = GrupoDatoDinamico.where(seguimiento: (params[:menu] == "ejecucion_tecnica")).order("rango")
  end

  # :en proyecto, lista un grupo de datos preparando la exportacion a pdf
  def listado_grupo_pdf
    begin
      grupo_datos = GrupoDatoDinamico.find_by_id params[:grupo_datos_id]
      url = url_for(:only_path => false, :action => :listado_grupo, :grupo_datos_id => params[:grupo_datos_id])
      options = { :margin => "1cm" }
      kit = Shrimp::Phantom.new( url, options, {"_session_id" => cookies[:_session_id]})
      send_file(kit.to_pdf, :filename => @proyecto.nombre + "_" + grupo_datos.nombre + '.pdf', :type => 'application/pdf', :disposition => 'inline')
      #render :partial => 'datos_dinamicos', :locals => {:grupo_datos_id => params[:grupo_datos_id], :datos => datos, :update_listado => nil}
    rescue
      msg_error _("Se produjo un error en el módulo de exportación a PDF.")
      redirect_to :action => "listado"
    end
  end
  # :en proyecto, lista un grupo de datos
  def listado_grupo
    grupo_datos = GrupoDatoDinamico.find_by_id params[:grupo_datos_id]
    datos = @proyecto.datos_dinamicos( grupo_datos ) if grupo_datos
    render :partial => 'datos_dinamicos', :locals => {:grupo_datos_id => params[:grupo_datos_id], :datos => datos, :update_listado => nil}
  end

  # --
  ######### GESTIONAR DATOS PROYECTO DINAMICOS ###########
  # ++

  # :en proyecto, prepara el formulario para añadir un dato dinamico al proyecto según el grupo 
  def anadir_nuevo
    @definiciones_dato = DefinicionDato.where(grupo_dato_dinamico_id: params[:grupo_datos_id]).order(:rango) - @proyecto.dato_texto.collect{|d| DefinicionDato.find_by_id d.definicion_dato_id}
    render(:update){ |page| page.formulario :partial => "formulario_anadir_datos_proyecto_dinamicos", :update => params[:update] }
  end

  # :en proyecto, prepara el formulario para incluir uno o varios datos dinamicos al proyecto
  def modificar_crear
    params[:definicion_dato_ids ] ||= []
    params[:definicion_dato_ids].each do |def_dat|
      definicion_dato = DefinicionDato.find(def_dat)
      ProyectoXDefinicionDato.create :proyecto_id => @proyecto.id, :definicion_dato_id => def_dat
      eval( "Dato" + definicion_dato.tipo).create(:proyecto_id => @proyecto.id, :definicion_dato_id => def_dat)
    end
    render (:update) do |page|
      # actualizamos el listado de datos
      grupo = GrupoDatoDinamico.find_by_id(params[:grupo_datos_id])
      datos = @proyecto.datos_dinamicos(grupo) 
      page.replace_html params[:update_listado], :partial => "datos_dinamicos", :locals => {:grupo_datos_id => grupo.id, :datos => datos, :update_listado => params[:update_listado]}
    end
  end

  # :en proyecto, elimina un datos dinamico del proyecto
  def eliminar
    # Contenido del dato dinamico
    contenido = eval( "Dato" + DefinicionDato.find(params[:definicion_dato_id]).tipo).find_by_id(params[:dato_id])
    contenido.destroy if contenido
    # Contenedor del dato dinamico
    @dato_borrado = ProyectoXDefinicionDato.find_by_proyecto_id_and_definicion_dato_id(@proyecto.id, params[:definicion_dato_id])
    @dato_borrado.destroy if @dato_borrado
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => (@dato_borrado ? @dato_borrado.errors : []), :eliminar => true}}
  end


  # --
  ######### GESTIONAR VALORES DE DATOS PROYECTO DINAMICOS ###########
  # ++

  # prepara el formulario de edición del valor de un dato dinamico
  def editar_dato_dinamico
    @dato_dinamico = eval("Dato" + params[:tipo]).find( params[:dato_id] )
    render :partial => "formulario_dato_dinamico", :pestana => params[:pestana]
  end

  # guarda el valor modificado de un dato dinamico
  def modificar_dato_dinamico
    @dato_dinamico = eval( "Dato" + params[:tipo]).find( params[:dato_id] )
    @dato_dinamico.update_attribute( :dato, valor_dato_externo(params[:selector][:proyecto_externo])||params[:dato_dinamico][:dato] )
    msg @dato_dinamico
    render :update do |page|
      page.replace_html 'formulario', :inline => '<%= mensaje_error(@dato_dinamico) %><br>'
      page.call("Modalbox.resizeToContent")
      page.replace_html params[:update], :partial => "dato_dinamico", :locals => { :grupo_datos_id => params[:grupo_datos_id], :dato => @dato_dinamico, :update => params[:update]}
      page.visual_effect :highlight, params[:update] , :duration => 6
    end
  end

  # Presenta el valor de un dato de otro proyecto 
  def dato_externo
    texto = valor_dato_externo(params[:selector_proyecto_externo])
    render :partial => "dato_externo", :locals => { :texto => texto}
  end

  # Obtiene el valor de un dato de otro proyecto
  def valor_dato_externo proyecto_id=nil
    texto = nil
    dato = eval( "Dato" + params[:tipo]).find( params[:dato_id] )
    if dato && dato.definicion_dato
      dato_externo = DatoTexto.find_by_proyecto_id_and_definicion_dato_id(proyecto_id,dato.definicion_dato_id)
      texto = dato_externo.dato if dato_externo
    end
    return texto
  end

end

