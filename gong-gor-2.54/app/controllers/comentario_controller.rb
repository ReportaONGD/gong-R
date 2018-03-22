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

class ComentarioController  < ApplicationController

  #--
  # Cómo usar los comentarios combinados con marcado y que todo se refresque bien (icono de comentarios y marcado de linea)
  #
  # 1.- En la vista, invocamos el boton de comentarios/marcado con el helper 'icono_remote'. El helper hace lo mismo que
  #     'remote', pero le pone automaticamente un id al icono necesario para encontrarlo luego desde este controlador
  #   a) Los parametros a pasar son: "icono", "Texto", {:url, :html}
  #
  # 2.- Al helper le pasamos en :url => {}
  #   a) :update => id html del contenedor de sublistados
  #   b) :tipo => tipo de objeto que permite comentarios ("Gasto", "Presupuesto", ...)
  #   c) :objeto_id => id del objeto anterior
  #   d) :update_objeto => id html de la linea del objeto anterior (la que contiene el boton), donde aplicaremos el marcado
  #
  # 3.- Al helper le pasamos en :html => {}
  #    a) :id => id html que tendra el boton (debe ser :update + "_comentario")
  #++

  # en proyectos y en financiación: lista los comentarios en un sublistado
  def comentarios
    @comentarios = eval( params[:tipo] ).find(params[:objeto_id]).comentario
    render :update do |page|
      page.replace_html params[:update], :partial => "comentarios", :locals => { :objeto_id => params[:objeto_id], :tipo => params[:tipo], :comentarios => @comentarios, :update_listado => params[:update] }
    end
  end

	# en proyectos y en financiación:  prepara el formulario de edición o creación de comentarios
  def anadir_comentario
    # Obtiene el marcado del objeto y los posibles estados posteriores 
    #tipo_obj = eval( params[:tipo].gsub( /[A-Za-z]+/ ) {$&.capitalize}.gsub(/_/, "") ) if params[:tipo]
    tipo_obj = eval( params[:tipo] )
    if params[:update_objeto] && tipo_obj && tipo_obj.column_names.include?("marcado_id")
      obj = tipo_obj.find_by_id(params[:objeto_id])
      @marcado_actual = obj.marcado
      if @marcado_actual
        @listado_marcados = [ ["No cambiar", @marcado_actual.id] ] + @marcado_actual.marcado_hijo.collect {|m| [m.nombre, m.id]}
      else
        @listado_marcados = [ ["No cambiar", nil] ] + Marcado.find_all_by_primer_estado(true).collect {|m| [m.nombre, m.id]}
      end
    end
    render (:update) { |page|  page.formulario :update => params[:update], :partial => "nuevo_comentario", :locals => { :objeto_id => params[:id], :tipo => params[:tipo]}  }
  end

	# en proyectos y en financiación:  modifica o crea un comentario
  def editar_crear_comentario
    @comentario = Comentario.new(elemento_type: params[:tipo], elemento_id: params[:objeto_id])
    params[:comentario][:usuario_id] = @usuario_identificado.id
    @comentario.update_attributes params[:comentario]
    objeto = eval( params[:tipo] ).find_by_id(params[:objeto_id])
    @comentarios = objeto.comentario << @comentario if @comentario.errors.empty?
    @comentarios = objeto.comentario unless @comentario.errors.empty?
    # Actualiza el marcado si es necesario y posible
    if @comentario.errors.empty? && params[:marcado] && eval( params[:tipo] ).column_names.include?("marcado_id")
      viejo_marcado = Marcado.find_by_id(objeto.marcado_id)
      if params[:marcado][:eliminar] == "1"
        objeto.update_attribute("marcado_id",  nil)
      elsif params[:marcado][:id] && params[:marcado][:id] != ""
        nuevo_marcado = Marcado.find_by_id(params[:marcado][:id])
        objeto.update_attribute("marcado_id", params[:marcado][:id])
      end
    end
    # Para documentos, el mail va para el propietario
    if objeto && objeto.class.name == "Documento"
      usuarios = [objeto.usuario]
    else
      # Enviar los mails a todos los relacionados (si estamos en inicio, el comentario es de una tarea)
      if @proyecto.nil? && @agente.nil? && @comentario.tarea
        usuarios = [@comentario.tarea.usuario, @comentario.tarea.usuario_asignado, UserInfo.current_user].compact
      elsif @proyecto.nil? && @agente.nil? && !@comentario.tarea
        usuarios = nil
      else
        # Desactivamos la generacion de correos de comentarios hasta que se resuelva a quien debe ir dirigido
        # (hay que relacionar el objeto con los permisos de los usuarios destinatarios)
        #usuarios = (@proyecto || @agente).usuario
        usuarios = nil
      end
    end
    @mensaje = ""
    for usuario in usuarios.uniq
      begin
        Correo.nuevo_comentario(request.host_with_port, usuario, params[:seccion], @proyecto||@agente, objeto, @comentario).deliver
      rescue
        @mensaje << "No se ha podido mandar el mail a " + usuario.correoe + "<br>"
      end
    end if @comentario.errors.empty? && usuarios
    @comentario.errors.add "", @mensaje unless @mensaje == ""
    render (:update) do |page|
      # Actualizamos el div de comentarios
      page.modificar :update_listado => params[:update_listado], :partial => "comentarios", :mensaje => {:errors => @comentario.errors }
      # y cambia el icono de comentarios si nos dicen cual es
      page.replace params[:update_objeto] + "_comentario_icono", icono("comentarios_r", _("Ver comentarios"), params[:update_objeto] + "_comentario_icono") if params[:update_objeto]
      # y le cambiamos la clase del div de la linea padre para refrescar el marcado
      page.call 'Element.removeClassName', params[:update_objeto], viejo_marcado.color if viejo_marcado && viejo_marcado.color
      page.call 'Element.addClassName', params[:update_objeto], nuevo_marcado.color if nuevo_marcado && nuevo_marcado.color 
    end 
  end

	# en proyectos y en financiación:  elimina un comentario
  def eliminar_comentario
    @objeto = eval( params[:tipo] ).find(params[:objeto_id])
    @comentarios = @objeto.comentario
    @comentario = Comentario.find_by_id(params[:id])
    @comentario.destroy if !@comentario.sistema || @usuario_identificado.administracion
    render (:update) do |page|
      # Actualiza el sublistado de comentarios
      page.eliminar :update => params[:update], :mensaje => {:errors => @comentario.errors, :eliminar => true}
      # y cambiamos el icono de comentarios si esta vacio y nos dicen cual es 
      page.replace params[:update_objeto] + "_comentario_icono", icono("comentarios", _("Ver comentarios"),params[:update_objeto] + "_comentario_icono") if params[:update_objeto] && @comentarios.empty?
    end
  end
end
