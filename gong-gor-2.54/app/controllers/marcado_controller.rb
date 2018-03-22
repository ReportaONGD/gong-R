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
# Controlador encargado de la gestion de la entidad Libro 
#
# NOTA: La terminologia utilizada en las vistas es cuenta
# Controlador encargado de la gestión de libros. Este controlador es utilizado desde las secciones:
# * Sección administración: se utiliza para crear libros y asignarles usuarios.
class MarcadoController < ApplicationController

  def editar
    @objeto = eval( params[:tipo].gsub( /[A-Za-z]+/ ) {$&.capitalize}.gsub(/_/, "") ).find( params[:id] ) 
    marcado_actual = @objeto.marcado
    if marcado_actual
      @listado_marcados = marcado_actual.marcado_hijo.collect {|m| [m.nombre, m.id]}
    else
      @listado_marcados = Marcado.find_all_by_primer_estado(true).collect {|m| [m.nombre, m.id]}
    end
    render (:update) { |page| page.formulario :update => params[:update] , :partial => "formulario_marcado" }  
  end

  def modificar
    @objeto =  eval( params[:tipo].gsub( /[A-Za-z]+/ ) {$&.capitalize}.gsub(/_/, "")).find( params[:id] ) 
    texto_comentario = nil
    if (params[:marcado][:eliminar] == "1")
      @objeto.update_attribute("marcado_id",  nil)
      texto_comentario = _("Marcado eliminado")
    elsif params[:marcado][:id]
      @objeto.update_attribute("marcado_id", params[:marcado][:id])
      texto_comentario = _("Marcado cambiado a %{estado}")%{estado: @objeto.marcado.nombre} 
    end
    if texto_comentario
      texto_comentario += ". " + params[:marcado][:texto] unless params[:marcado][:texto].blank?
      @objeto.comentario << Comentario.create(usuario_id: session[:usuario_identificado_id], texto: texto_comentario, )
      mandar_mensaje @objeto.comentario.order(:created_at).last
    end
    render(:update) do |page|
      if @objeto.class.name == "Presupuesto" 
        if params[:seccion] == "proyectos"
          if params[:actividad_id]
            @actividad = Actividad.find params[:actividad_id]
            @pxa = PresupuestoXActividad.find_by_presupuesto_id_and_actividad_id params[:id], params[:actividad_id]
            @presupuesto = Presupuesto.find( params[:id], :include => :presupuesto_x_actividad, :conditions => {"presupuesto_x_actividad.actividad_id" => params[:actividad_id]} ) # Esto parece algo absurdo pero lo recargamos para que al recargar la linea muestre la información de la actividad
            page.modificar :update => @pxa.id.to_s, :partial => "presupuesto_actividad/presupuesto", :locals => { :presupuesto => @presupuesto, :actividad => @actividad}, :mensaje => { :errors => @presupuesto.errors }
          else
            @partida = @objeto.partida_x_partida_financiacion.first.partida_financiacion unless @objeto.partida_x_partida_financiacion.empty?
            page.modificar :update => params[:update], :partial => "presupuesto_proyectos/presupuesto", :locals => { :presupuesto => @objeto, :partida => @partida}, :mensaje => { :errors => @objeto.errors } and !(params[:actividad_id])
          end
        elsif params[:seccion] == "agentes" 
          locals = {:presupuesto => @objeto,  :i => params[:i] }
          locals[:empleado] = Empleado.find_by_id(@objeto.empleado_id)           if @objeto.empleado_id
          page.modificar :update =>  params[:update], :partial => (params[:vista]||'presupuesto_agentes/presupuesto'), :locals => locals
        end
      elsif @objeto.class.name == "Ingreso"
        @ingreso = @objeto
        page.modificar :update => params[:update], :partial => "ingreso/ingreso", :locals => {:update => params[:update]} 
      elsif @objeto.class.name == "PresupuestoIngreso"
        @partida = @objeto.partida_ingreso
        @etapa = @objeto.etapa
        page.modificar update: params[:update], partial: "presupuesto_ingresos/presupuesto", locals: { presupuesto: @objeto }, mensaje: { errors: @objeto.errors }
      elsif @objeto.class.name == "Contrato"
        @contrato = @objeto
        page.modificar :update => params[:update], :partial => "contrato/contrato", :locals => {:update => params[:update], :contrato => @objeto}
      elsif @objeto.class.name == "Gasto"
        page.modificar :update => params[:update], :partial => "gasto_#{params[:seccion]}/gasto", :locals => {:gasto => @objeto, :update => params[:update], :i => params[:i]} 
      elsif @objeto.class.name == "Transferencia"
        page.modificar :update => params[:update], :partial => "transferencia/transferencia", :locals => {:transferencia => @objeto, :update => params[:update], :i => params[:i]} 
      end 
    end
  end

 private

  # De momento no le mandamos ningun mensaje a ningun usuario... revisar a cuales deberia hacerse
  def mandar_mensaje comentario=nil
    usuarios = []
    # Si estamos en un agente o tratamos con un gasto, vinculamos los administradores economicos del agente
    #usuarios += @objeto.agente.usuario.where("usuario_x_agente.rol" => "economico") if @objeto.class.name == "Gasto" || @agente
    # Si estamos en un proyecto, tambien a los coordinadores o usuarios de este
    #usuarios += @proyecto.usuario.where("usuario_x_proyecto.rol" => ["coordinador","usuario"]) if @proyecto

    for usuario in usuarios.uniq
      begin
        Correo.nuevo_comentario(request.host_with_port, usuario, params[:seccion], @proyecto||@agente, @objeto, comentario).deliver
      rescue => e
        logger.error "(GOR/MarcadoController) No se ha podido mandar el mail a " + usuario.correoe + ": " + e.inspect
      end
    end if comentario && comentario.errors.empty?
  end
end
