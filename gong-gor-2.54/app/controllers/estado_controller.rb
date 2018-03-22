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
# Controlador encargado de los estados de proyecto y financiación. Este controlador es utilizado desde las secciones:
# * Sección proyectos: controla los estados
# * Sección financiaciones: controla los estados

class EstadoController < ApplicationController
  before_filter :verificar_usuario
  
  # El metodo comprobar_periodo se encuentra en el ApplicationController
  before_filter :comprobar_periodo_identificador_financiador
  
	# Verifica que el usuario esta autentificado y pertenece al proyecto
  def verificar_usuario
    if ! ( @usuario_identificado.send(params[:seccion]) == true and params[:seccion] == "proyectos" and @proyecto.usuario_autorizado?(@usuario_identificado) )
      msg_error _("No tiene permisos suficientes para acceder a este proyecto.")
      redirect_to "/inicio/tarea/inicio"
    end
  end

	# en proyectos y en financiación: se redirecciona por defecto a listado
  def index
    redirect_to :action => 'listado'
  end

	# en proyectos y en financiación: lista los estados anteriores y actual
  def listado
    @estados =  @proyecto.estado.order("id DESC")
    @campos = ['observacion']
  end

	# en proyectos y en financiación: prepara el formulario de cambio de estado actual
  def anadir_estado
      @estado_actual = @proyecto.estado_actual 
      @definicion_estado_siguiente = @estado_actual ? @estado_actual.definicion_estado.estado_hijo : DefinicionEstado.find_all_by_primer_estado(true)
      @definicion_estado_siguiente.collect!{ |a| [a.nombre + (a.descripcion.blank? ? "" : " (" + a.descripcion + ")"), a.id] }
      render :partial => "formulario_cambiar_estado"
  end

	# en proyectos y en financiación: modifica el estado actual y llama a Correo.cambio_estado.deliver
  def modificar_estado
    @msg = ""
    @estado_anterior = @proyecto.estado_actual
    @estado = Estado.new
    @estado.proyecto_id = @proyecto.id 
    # Ojo!. Hay errores en los logs del tipo
    # NoMethodError (undefined method `[]' for nil:NilClass):
    #   app/controllers/estado_controller.rb:65:in `modificar_estado'
    @estado.definicion_estado_id = params[:definicion_estado][:id]
    @estado.fecha_inicio = Time.now
    @estado.estado_actual = true
    @estado.usuario_id = @usuario_identificado.id
    @estado.save
    # Si se ha conseguido cambiar el estado...
    if @estado.errors.empty?
      # Modifica el estado anterior
      if @estado_anterior
        @estado_anterior.estado_actual = false
        observacion = @estado_anterior.observacion = params[:estado][:observacion] if params[:estado][:observacion]
        fecha = @estado_anterior.fecha_fin = Time.now()
        @estado_anterior.save
      end
      # Notifica a los usuarios
      @proyecto.usuario.uniq.each do |usuario|
        begin
          Correo.cambio_estado(request.host_with_port, usuario, params[:seccion], @proyecto, @estado).deliver
        rescue
          msg_error _("Se han producido errores enviando correos a los usuarios")
        end
      end
      # Las tareas se asignan como callbacks (after_create) en el modelo de estado
    # Si hay errores, los indica
    else
      msg @estado
    end
    redirect_to :action => 'listado'
  end

  def eliminar_estado
    @msg = ""
    @proyecto.estado_actual.destroy
    unless @proyecto.reload.estado.empty?
      ultimo_estado = (@proyecto.reload.estado.sort {|a,b| a.updated_at <=> b.updated_at}).last
      ultimo_estado.update_attribute("estado_actual", true)
    end
    for usuario in @proyecto.usuario
      begin
        #Correo.cambio_estado(request.host_with_port, usuario, params[:seccion], @proyecto.reload, @estado).deliver
      rescue
        @msg << "no se ha podido mandar el mail a " + usuario.correoe + "<br>"
      end
    end
    redirect_to :action => 'listado'
  end

	# en proyectos y en financiación: permite hacer observación al cambiar de estado
  def detalle
    @estado = Estado.find(params[:id])
    render :partial => "observaciones"
  end

	# en proyectos y en financiación: cierra el formulario de observación
  def cerrar_detalle
    render  :inline => ""
  end
end
#done
