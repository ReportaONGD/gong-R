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
# Controlador encargado de la gestión de los documentos.
# Este controlador es utilizado desde las secciones:
# * Sección proyectos: se utiliza para listar, comentar, subir y descargar documentos
# * Sección financiaciones: se utiliza para listar, comentar, subir y descargar documentos
class DocumentoController < ApplicationController

  # Solo elimina cuando el documento pertenece
  before_filter :espacio_seleccionado, :except => [ :index, :seleccionar_espacio, :descargar ]
  before_filter :autorizar_documento, :only => [ :eliminar, :modificar_crear, :editar_nuevo, :asociar_o_nuevo, :asociar_documentos, :asociar ]


  # Este metodo es solamente para tener una variable que utilizamos mucho en muchos metodos
  def espacio_seleccionado
    @espacio_id = session[:espacio_proyecto_seleccionado] if params[:seccion] == "proyectos"
    @espacio_id = session[:espacio_agente_seleccionado] if params[:seccion] == "agentes"
    @espacio_id = session[:espacio_seleccionado] if params[:seccion] == "documentos"
    @espacio_id = Espacio.find_by_nombre("Plantillas Exportación").id  if params[:seccion] == "administracion"
  end


  # Este metodo controla si se puede actualizar un documento dado
  def autorizar_documento
    @documento = Documento.find_by_id(params[:id])
    espacio = Espacio.find_by_id(@espacio_id)
   
    # Hacemos la comprobacion salvo cuando estemos trabajando en administracio y sobre el espacio de plantillas
    unless params[:seccion] == "administracion" && @usuario_identificado.administracion && espacio.nombre == "Plantillas Exportación"
      # Ojo!. Hay errores en los logs del tipo:
      # NoMethodError (undefined method `escritura_permitida' for nil:NilClass):
      #   app/models/documento.rb:97:in `escritura_permitida'
      #     app/controllers/documento_controller.rb:48:in `autorizar_documento'
      if @documento && !@documento.escritura_permitida(@usuario_identificado, espacio)
        render (:update) {|page|  page.mensaje_informacion params[:update], _("No tiene permisos para borrar o modificar el documento."), :tipo_mensaje => "mensajefallo"}
      elsif @espacio_id && espacio.nil?
        render (:update) {|page|  page.mensaje_informacion params[:update], _("No se puede gestionar el documento desde este espacio."), :tipo_mensaje => "mensajefallo"}
      elsif @espacio_id && !(espacio.escritura_permitida @usuario_identificado)
        # Permitirmos anadir documentos solo a los usuarios incluidos en un determinado espacio
        render (:update) {|page|  page.mensaje_informacion params[:update], _("No tiene permisos para añadir documentos en este espacio."), :tipo_mensaje => "mensajefallo"}
      end
    end
  end

	# en proyectos y en financiación: se redirecciona por defecto a ordenado
  def index
    session[:espacio_seleccionado] = nil  if params[:seccion] == "documentos"
    session[:espacio_seleccionado] = Espacio.find_by_nombre("Plantillas Exportación").id  if params[:seccion] == "administracion"
    session[:espacio_proyecto_seleccionado] = @proyecto.espacio.id if params[:seccion] == "proyectos"
    session[:espacio_agente_seleccionado] = @agente.espacio.id if params[:seccion] == "agentes"	
    redirect_to :action => "ordenado"
  end

	# en proyectos y en financiación: establece los parametros de ordenación
  def ordenado
    session[:documento_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC" 
    session[:documento_orden] = params[:orden] ? params[:orden] : "adjunto_file_name" 
    redirect_to :action => "listado"
  end


  def seleccionar_espacio
    case params[:seccion]
      when "documentos" then
        espacio = Espacio.find_by_id params[:id]
        session[:espacio_seleccionado] = params[:id] if (params[:id] != params[:id].to_i) || (espacio && !espacio.usuario_no_permitido(@usuario_identificado))
      when "proyectos" then
        session[:espacio_proyecto_seleccionado] = params[:id]
      when "agentes" then
        session[:espacio_agente_seleccionado] = params[:id]
      when "administracion" then
        session[:espacio_seleccionado] = Espacio.find_by_nombre("Plantillas Exportación").id
    end
    redirect_to :action => :listado
  end

  def implementador
    @ruta = [{:nombre => _("Raíz")}, {:nombre => _("Implementadores"), :action => 'implementador'}]
    espacios = @usuario_identificado.agente.order('nombre')
    @espacios = espacios.inject([]) {|m,a| m.push({:nombre => a.nombre, :id => a.espacio.id, :action => 'seleccionar_espacio'}) }
    render 'listado'
  end

  def listado
    obtiene_espacios_y_documentos
  end

  # Descarga un zip con todos los documentos existentes en el espacio seleccionado
  def descargar_zip
    #require 'zip'
    obtiene_espacios_y_documentos

    t = Tempfile.new('download-zip-' + request.remote_ip)
    Zip::OutputStream.open(t.path) do |zos|
      @documentos.each do |file|
        if File.readable?(file.adjunto.path)
          zos.put_next_entry(file.adjunto_file_name)
          zos.write IO.read(file.adjunto.path)
        else
          logger.error "----------> ERROR (documento/descarga_zip): El fichero '%{nombre}' (%{path}) no existe"%{nombre: file.adjunto_file_name, path: file.adjunto.path}
        end
      end
    end

    send_file t.path, :type => "application/zip", :filename => (@espacio ? @espacio.nombre : "Root") + ".zip"
    t.close
  end

#--
# ACCIONES COMUNES DE DOCUMENTOS: crear, editar, eliminar, descargar
#++

	# en proyectos y en financiación: prepara el formulario de edición o creación
  def editar_nuevo
    if params[:documento]
      # Todo esto hay que hacerlo por el iframe de subida con ajax
      params[:tipo] ||= params[:url][:tipo] if params[:url]
      params[:objeto_id] ||= params[:url][:objeto_id] if params[:url]
      params[:i] ||= params[:url][:i] if params[:url]
      modificar_crear
    else
      @documento = params[:id] ?  Documento.find(params[:id]) : Documento.new
      carga_espacios_etiquetas
      espacio =  Espacio.find(@espacio_id) if @espacio_id
      render :update do |page|
        # Si se estamos navegando por espacios no dejamos que se pueda tocar espacios de plantillas
        #if params[:menu] == "documentos_generales" and (espacio.definicion_espacio_proyecto_id or espacio.proyecto_id or 
        #   espacio.definicion_espacio_agente_id or (espacio.agente_id && !espacio.agente.socia_local) or !espacio.modificable ) 
        #  page.mensaje_informacion params[:update], "No se puede incluir documentación para espacios de proyectos, o de agentes, o de administración, desde esta sección.", :tipo_mensaje => "mensajefallo"
        #else
          page.formulario :partial => "formulario", :update => params[:update]  unless params[:pisa_formulario]
          page.replace 'formulariocontenedor', :partial => "formulario", :locals => { :update => params[:update], :update_listado => params[:update_listado] }  if params[:pisa_formulario]
        #end
      end
    end
  end


  # Carga espacios y etiquetas
  def carga_espacios_etiquetas
    espacio =  Espacio.find_by_id(@espacio_id)
    # Obtiene los espacios para poder hacer un movimiento de documento
    obtiene_documentos_a_vincular
    @etiquetas = @etiquetas_exportacion = Etiqueta.where(:tipo => "plantilla")
    if espacio && espacio.proyecto_del_espacio
      @etiquetas = Etiqueta.where(tipo: ['proyecto','comunes']) - @etiquetas_exportacion
    elsif params[:tipo] == "Contrato"
      @etiquetas = Etiqueta.where(tipo: "contrato") - @etiquetas_exportacion
    elsif params[:seccion] == "documentos" or params[:seccion] == "agentes"
      @etiquetas = Etiqueta.where(tipo: ['comunes']) - @etiquetas_exportacion
    end
    @etiquetas_documento = @documento.etiqueta.collect{ |e| e.id }
    #@otras_etiquetas = @documento.etiqueta_ids - @etiquetas.collect{|e| e.id}
    #puts "------> OTRAS ETIQUETAS: " + @otras_etiquetas.inspect
  end



	# modifica o crea
  def modificar_crear
    @documento = Documento.find_by_id(params[:id]) || Documento.new
    # Solo ponemos el usuario_id si no existe o el documento es nuevo
    params[:documento][:usuario_id] = @usuario_identificado.id if !params[:id] || !@documento.usuario_id

    # Todo esto habra que limpiarlo para eliminar vinculacion de documentos con proyectos y agentes (es necesario?)
    espacio_actual = Espacio.find_by_id(@espacio_id) if params[:tipo].nil? || params[:tipo] == ""
    # Si estamos en documentacion general y un espacio de proyecto, le metemos proyecto_id
    if (espacio_actual && params[:documento] && params[:seccion] == "documentos" && espacio_actual.proyecto_del_espacio)
      params[:documento][:proyecto_id] = espacio_actual.proyecto_del_espacio.id
    # Si estamos en un espacio de agente y no hay agente_id, se lo metemos
    elsif (espacio_actual && params[:documento] && params[:seccion] == "documentos" && espacio_actual.agente_del_espacio)
      params[:documento][:agente_id] = espacio_actual.agente_del_espacio.id
    end
    
    # Actualiza el objeto
    @documento.update_attributes params[:documento]

    # Si hemos guardado el objeto sin errores, modificamos el resto de elementos relacionados
    if @documento.errors.empty?
      if params[:tipo] && params[:tipo] != ""
        # Si estamos trabajando en las fuentes de verificacion, gastos, o transferencias vinculamos el documento a la fuente de verificacion
        #tipo, objeto_id = obtiene_tipo_y_objeto
        logger.info ">>>>>>>>>>>>>>> Asociamos Documento a un objeto " + params[:tipo] + " <<<<<<<<<<<<<<<<<<"
        @objeto = eval( params[:tipo] ).find_by_id(params[:objeto_id].to_i)
        @obj_rel = params[:tipo] == "Contrato" ? @objeto.estado_actual : @objeto
        @obj_rel.documento << @documento unless @obj_rel.nil? || @objeto.documento.find_by_id(@documento.id)
        #Cargamos los documentos del objeto para refrescar el listado
        @documentos = @objeto.documento
      else
        # Si estamos trabajando en documentos por espacio
        cambio_de_espacio = false
        # Para cambiar un documento de espacio dentro de proyectos
        if params[:cambiar] and params[:cambiar][:espacio] == "1"
          # Si tenemos permisos para mover el documento...
          if (nuevo_espacio = Espacio.find_by_id(params[:cambiar][:espacio_id])) && espacio_actual.escritura_permitida(@usuario_identificado) && nuevo_espacio.escritura_permitida(@usuario_identificado) 
            (DocumentoXEspacio.find_by_documento_id_and_espacio_id @documento.id, @espacio_id).destroy
            DocumentoXEspacio.create :documento_id => @documento.id, :espacio_id => params[:cambiar][:espacio_id]
            # Ojo!. Hay errores en los logs del tipo:
            # NoMethodError (undefined method `[]' for nil:NilClass):
            #   app/controllers/documento_controller.rb:214:in `modificar_crear'
            #     app/controllers/documento_controller.rb:134:in `editar_nuevo'
            cambio_de_espacio = true if @espacio_id.to_s != params[:cambiar][:espacio_id] 
          else
            @documento.errors.add :base, _("No tiene permisos para escribir en ese espacio")
          end
        else
          documento_x_espacio = DocumentoXEspacio.find_or_create_by_documento_id_and_espacio_id @documento.id, params[:documento_x_espacio][:espacio_id]
        end
      end
      #Finalmente guardamos las etiquetas vinculadas al documento
      #@documento.etiqueta.clear
      #@documento.etiqueta_ids = params["etiqueta"].to_a.collect {|p| p[0] if p[1] == "1"}
      # Dejamos la gestion de sus ids en el modelo de documento
      @documento.set_etiqueta_ids(params["etiqueta"].to_a)

      # Devolvemos la vista de confirmacion
      responds_to_parent do
        # Si estamos en el listado de documentos
        unless params[:tipo] && params[:tipo] != ""
          i = params[:i] || params[:url][:i]
          render :update do |page|
            if cambio_de_espacio 
              page.remove "formularioinline"
              page.remove "formulariofondo"
              page.remove "formulariocontenedor"
              page.eliminar(:update => params[:update], :mensaje => { :errors => @documento.errors })
            elsif params[:id]
              page.modificar(:update => params[:update], :partial => "documento", :mensaje => { :errors => @documento.errors })
            else
              page.show "nuevos_documentos"
              page.modificar(:update => "documento_nuevo_" + params[:i], :partial => "nuevo_documento", :mensaje => { :errors => @documento.errors })
              page.replace "anadir", :inline => "<%= anadir(:url => {:action => 'asociar_o_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>"
            end
          end
        # Si es una vinculacion a un documento recargamos todo el listado
        else
          # Para otros objetos (en sublistado)
          render(:update){ |page|  page.modificar(:update_listado => params[:update_listado], :partial => "listado_asociados", :locals => {:objeto_id => params[:objeto_id], :tipo => params[:tipo] }, :mensaje => { :errors => @documento.errors}, :tipo_update => "sublistado") } 
        end
      end
    # Si ha habido errores al modificar el formulario
    else
      carga_espacios_etiquetas
      responds_to_parent do
        render(:update){ |page|  page.recargar_formulario :partial => "formulario", :mensaje => { :errors => @documento.errors } }
      end
    end
  end    

  def modificar_crear_imagen_datos_proyecto
    # Solo sube el documento si hay un proyecto
    if @proyecto
      documento = Documento.new
      params[:documento] = Hash.new
      params[:documento][:adjunto] = params[:file]
      params[:documento][:usuario_id] = @usuario_identificado.id
      params[:documento][:proyecto_id] = @proyecto.id

      # Actualiza el objeto
      documento.update_attributes params[:documento]

      if documento.errors.empty?
        # Lo mete en el espacio
        espacio = @proyecto.espacio
        documento_x_espacio = DocumentoXEspacio.find_or_create_by_documento_id_and_espacio_id(documento.id, espacio.id)
        # Y lo muestra de vuelta
        render json: {
          image: {
            url: url_for(:only_path => false, :action => 'descargar', :controller => "documento", :id => documento)
          }
        }, content_type: "text/html"
      end
    end
  end

  # elimina documento
  def eliminar
    @documento = Documento.find(params[:id])
    @espacio =  Espacio.find(@espacio_id) if @espacio_id

    # Averiguamos si el documento esta vinculado y tratamos de borrar el original, lo rechaza 
    vinculado = @espacio ? (@documento.espacio.size > 1 && @documento.espacio.first == @espacio) : true

    # Segun donde estemos podremos o no borrar
    # En ejecucion (documentos de gastos, contratos, transferencias o fuentes de verificacion de proyecto o de agente) podremos siempre borrar (no hay espacio asociado)
    if params[:menu] == "ejecucion_tecnica" || params[:menu] == "ejecucion_economica" || params[:menu] == "economico_agente"
      # Para que necesitamos el objeto?. Si hacemos un destroy directo del documento no eliminará también las relaciones?.
      @objeto = eval( params[:tipo] ).find_by_id(params[:objeto_id])
      # Eliminamos el documento (que el modelo se encargue de las desvinculaciones)
      @documento.destroy
      # Y decimos que no esta realmente vinculado
      vinculado = false
    # En el resto (documentacion general, de proyectos y de agentes) borramos si no está vinculado
    elsif !vinculado
      # Eliminamos el documento del espacio en el que estemos
      @espacio.documento.delete(@documento)
      # Si el documento no esta vinculado a ningun otro objeto lo borramos
      @documento.destroy if @documento.espacio.reload.empty?
    end

    render :update do |page|
        page.eliminar(:update => params[:update], :mensaje => { :errors => @documento.errors, :eliminar => true }) unless vinculado
        page.mensaje_informacion(params[:update], @documento.espacio.inject((_("No se puede borrar el documento por que se encuentra vinculado en algun espacio de documentación") + ":<br>").html_safe){|m,a| m += h(a.ruta + " / " + a.nombre) + "<br>".html_safe}, :tipo_mensaje => "mensajefallo") if vinculado
    end
  end

  def descargar
    @documento = Documento.find(params[:id])
      # file = File.new(@document.document.path, "r")
      # send_data(file.read,
      #  :filename     =>  @document.document_file_name,
      #  :type         =>  @document.document_content_type,
      #  :disposition  =>  'inline') 

    # Antes de descargar, comprobar que exista el fichero y marcar el error si no esta
    if File.exists?(@documento.adjunto.path)       
      send_file @documento.adjunto.path, :filename => @documento.adjunto_file_name, :type => @documento.adjunto_content_type, :disposition => 'inline'
    elsif @documento.adjunto_url
      file = open(@documento.adjunto_url)
      send_file( file, :filename => @documento.adjunto_file_name )
      #redirect_to @documento.adjunto_url 
    else
      msg_error _("No se pudo encontrar el documento.") + " " + _("Contacte con el administrador del sistema.")
      redirect_to :action => 'listado'
    end
  end


   # muestra los documentos vinculados a un objeto
  def listado_asociados
    @documentos = []
    @objeto = eval( params[:tipo] ).find_by_id(params[:objeto_id])
    @documentos = @objeto.documento if @objeto
    render :update do |page|
      page.replace_html params[:update], :partial => "listado_asociados", :locals => { :objeto_id => params[:objeto_id], :tipo => params[:tipo], :documentos => @documentos, :update_listado => params[:update]  }
    end
  end

  def asociar_o_nuevo
    render :update do |page|
      page.formulario :partial => "formulario_asociar_o_nuevo", :tipo => params[:tipo], :objeto_id => params[:objeto_id], :update => params[:update] 
    end
  end

  def asociar_documentos
    # Obtiene los documentos a vincular
    obtiene_documentos_a_vincular

    # Si pedimos asociar a algun tipo (fuente, gasto o transferencia), presentamos el formulario limitado
    if params[:tipo]
      render(:update) { |page| page.replace 'formulariocontenedor', :partial => "formulario_asociar" }
    # Si vamos a asociar sobre un espacio, presentamos el listado de navegacion
    else
      render(:update) { |page| page.replace_html 'formulariocontenido', :partial => "listado_asociar" }
    end
  end

  def espacios_donde_mover 
    # Obtiene los espacios donde mover 
    obtiene_documentos_a_vincular

    # Si pedimos asociar a algun tipo (fuente, gasto o transferencia), presentamos el formulario limitado
    render(:update) { |page| page.replace_html "mover_a_espacio", :partial => "listado_mover" }
  end

  #Asociamos un documento a un objeto o a un espacio
  def asociar
    if params[:tipo] and params[:tipo] != ""
      # Si estamos asociando a un objeto asociamos el documento al objeto
      @objeto = eval( params[:tipo] ).find_by_id(params[:objeto_id])
      @relacion = eval(params[:tipo] + "XDocumento").create( params[:tipo].tableize + "_id" => params[:objeto_id], "documento_id" => params[:documento][:id] )
      @documentos = @objeto.documento if @objeto
    else
      # Si no hay objeto asociamos el documento al espacio de navegacion
      @documento = Documento.find(params[:documento][:id])
      espacio_seleccionado_id = session[:espacio_proyecto_seleccionado] if @proyecto 
      espacio_seleccionado_id = session[:espacio_agente_seleccionado] if @agente
      espacio_seleccionado_id = session[:espacio_seleccionado] unless @proyecto or @agente
      @relacion = DocumentoXEspacio.create(:espacio_id => espacio_seleccionado_id, :documento_id => @documento.id )
    end
    if @relacion.errors.empty?
      if params[:tipo]    
        # Si la asociacion es a un objeto refrescamos el listado de documentos del objeto
        render(:update){ |page|  page.modificar(:update_listado => params[:update_listado], :partial => "listado_asociados", :locals => {:objeto_id => params[:objeto_id], :tipo => params[:tipo]}, :mensaje => { :errors => @relacion.errors}, :tipo_update => "sublistado") }
      elsif
        # Si el documento se asocia a un espacio lo mostramos en la zona de nuevos documentos
        render :update do |page|
          page.show "nuevos_documentos"
          page.modificar(:update => "documento_nuevo_" + params[:i], :partial => "nuevo_documento", :mensaje => { :errors => @documento.errors })
          page.replace "anadir", :inline => "<%= anadir(:url => {:action => 'asociar_o_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>"
        end
      end
    else
      # Si hay datos que fallan se vuelve al formulario
      obtiene_documentos_a_vincular
      if params[:tipo]
        render(:update) { |page|  page.recargar_formulario :partial => "formulario_asociar", :mensaje => { :errors => @relacion.errors } }
      else
        render(:update) { |page| page.mensaje_actualizacion "formularioinline", { :errors => @relacion.errors } }
      end
    end
  end

 private

  def obtiene_espacios_y_documentos
    session[:documento_orden] ||= "adjunto_file_name"
    session[:documento_asc_desc] ||= "ASC"
    orden = session[:documento_orden] + " " + session[:documento_asc_desc]
    contenido=Espacio.contenido(@usuario_identificado, @espacio_id, params[:seccion] == "administracion", orden)
    @espacio = contenido[:espacio]
    @espacios = contenido[:espacios]
    @documentos = contenido[:documentos]
    # Si estamos en la raiz, incluimos el espacio virtual de implementadores
    @espacios.push({:nombre => _("Implementadores"), :action => 'implementador', :descripcion => _("Espacio de delegaciones y socias locales asignadas")}) if @espacio_id.nil?
  end

  def obtiene_documentos_a_vincular
    @objeto = @proyecto ? @proyecto : @gasto
    if params[:tipo] == "FuenteVerificacion"
      #Si estamos asociando a una fuente de verificacion
      documentos_fuente =  FuenteVerificacion.find(params[:objeto_id]).documento
      documentos = (FuenteVerificacionXDocumento.find(:all, :include => [:documento], :conditions => {"documento.proyecto_id" => @proyecto.id}).collect {|d| d.documento}).uniq
      documentos = documentos - documentos_fuente
      @documentos = documentos.collect {|d| [d.adjunto_file_name, d.id]}
    elsif params[:tipo] == "Gasto"
      # Si estamos asociando a un gasto
      gasto = Gasto.find params[:objeto_id]
      gastos = Gasto.find_all_by_agente_id(@agente.id) if params[:seccion] == "agentes"
      gastos = Gasto.find(:all, :include => [:gasto_x_proyecto], :conditions => {"gasto_x_proyecto.proyecto_id" => @proyecto.id}) if params[:seccion] == "proyectos"
      documentos = (gastos.inject(Array.new){|sum, n| sum + n.documento} - gasto.documento).uniq
      @documentos = documentos.collect {|d| [d.adjunto_file_name, d.id]}
    elsif params[:tipo] == "Transferencia"
      # Si estamos asociando a un gasto
      transferencia = Transferencia.find_by_id params[:objeto_id]
      if @proyecto
        transferencias = Transferencia.find_all_by_proyecto_id @proyecto.id if params[:seccion] == "proyectos"
      elsif @agente
        condiciones = "(libro.agente_id = " + @agente.id.to_s + " OR libro_destinos_transferencia.agente_id = " + @agente.id.to_s + ")"
        transferencias = Transferencia.find(:all, :include => [:libro_origen, :libro_destino], :conditions => condiciones)
      end
      documentos = (transferencias.inject(Array.new){|sum, n| sum + n.documento} - transferencia.documento).uniq
      @documentos = documentos.collect {|d| [d.adjunto_file_name, d.id]}
    else
      # Si estamos asociando dentro de otro espacio
      # Primero recogemos los documentos del propio espacio
      @espacio_donde_vincular = Espacio.find_by_id(@espacio_id)
      documentos_a_excluir = @espacio_donde_vincular ? @espacio_donde_vincular.reload.documento : []
      # Obtenemos documentos y espacios del seleccionado
      @espacio_id = params[:espacio_id] if params[:espacio_id]
      obtiene_espacios_y_documentos
      # Y eliminamos los ya contenidos en el espacio
      @documentos = @documentos - documentos_a_excluir
    end
  end

end
