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
class LibroController < ApplicationController
  
  # en administracion: se redirecciona por defecto a ordenado
  def index
    redirect_to :action => 'ordenado'
  end

  def filtrado_condiciones
    session[:libro_asc_desc] ||= "ASC"
    session[:libro_orden] ||= "nombre"
    session[:libro_filtro_agente] ||= "todos" unless params[:seccion] == "agentes"
    session[:libro_filtro_agente] = @agente.id.to_s if params[:seccion] == "agentes"
    session[:libro_filtro_moneda] ||= "todos"
    session[:libro_filtro_pais] ||= "todos"
    session[:libro_filtro_tipo] ||= "todos"

    condiciones = {} 
    condiciones["agente_id"] = session[:libro_filtro_agente] unless session[:libro_filtro_agente] == "todos"
    condiciones["moneda_id"] = session[:libro_filtro_moneda] unless session[:libro_filtro_moneda] == "todos"
    condiciones["pais_id"] = session[:libro_filtro_pais] unless session[:libro_filtro_pais] == "todos"
    condiciones["tipo"] = session[:libro_filtro_tipo] unless session[:libro_filtro_tipo] == "todos"
    @condiciones = condiciones
    if params[:seccion] == "agentes"
      agentes = [[ @agente.nombre, @agente.id ]]
    else
      agentes =  [[_("Todos"), "todos"]] + Agente.all(:order => "nombre", :conditions => {:implementador => true }).collect {|p| [p.nombre, p.id.to_s]}
    end
    monedas = [[_("Todas"), "todos"]] + Moneda.all(:order => "nombre").collect {|p| [p.nombre, p.id.to_s]}
    paises = [[_("Todos"), "todos"]] + Pais.all(:order => "nombre").collect {|p| [p.nombre, p.id.to_s]}
    tipos = [[_("Todos"), "todos"], [_("Banco"), "banco"], [_('Caja "chica"'), 'caja "chica"']]
    @opciones_filtrado = [	{:rotulo => _("Seleccione agente"), :nombre => "agente", :opciones => agentes},
				{:rotulo => _("Seleccione moneda"), :nombre => "moneda", :opciones => monedas},
				{:rotulo => _("Seleccione país"), :nombre=> "pais", :opciones =>  paises},
                                {:rotulo => _("Seleccione tipo"), :nombre=> "tipo", :opciones => tipos } ]
    @accion_filtrado = {:action => :filtrado }
  end

  # en administracion: lista las agentes que hay en el sistema
  def listado
    filtrado_condiciones
    #@listado_monedas = Moneda.find(:all, :order => "nombre").collect {|p| [p.nombre , p.id]}
    #@listado_agentes = Agente.find(:all, :order => "nombre").collect {|p| [p.nombre, p.id]}
    #@listado_paises = Pais.find(:all, :order => "nombre").collect {|p| [p.nombre, p.id]}
    @libros = @paginado = Libro.includes([:pais, :agente]).
                                where(@condiciones).
                                order(session[:libro_orden] + " " + session[:libro_asc_desc]).
                                paginate(page: params[:page], per_page: (session[:por_pagina] or 20))
  end

  # en administracion: establece los parametros de ordenación
  def ordenado
    session[:libro_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"   
    session[:libro_orden] = params[:orden] ? params[:orden] : "nombre" 
    session[:libro_orden] = "tipo" if session[:libro_orden] == "tipo.capitalize"
    redirect_to :action => "listado"
  end

  def filtrado
    session[:libro_filtro_agente] = params[:filtro][:agente]
    session[:libro_filtro_moneda] = params[:filtro][:moneda]
    session[:libro_filtro_pais] = params[:filtro][:pais]
    session[:libro_filtro_tipo] = params[:filtro][:tipo]
    redirect_to :action => "listado"
  end
  
  # en administracion: prepara el formulario de edición o creación
  def editar_nuevo
    @libro = Libro.find_by_id(params[:id]) || Libro.new
    selectores_formulario
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

  # en administracion: modifica o crea
  def modificar_crear
    if params[:seccion] == "agentes"
      params[:libro][:agente_id] = @agente.id
      @libro = @agente.libro.find_by_id(params[:id])
    else
      @libro = Libro.find_by_id(params[:id])
    end
    @libro ||= Libro.new
    @libro.update_attributes params[:libro]

    if @libro.errors.empty?
      render(:update) { |page|   page.modificar :update => params[:update], :partial => "libro" , :mensaje => { :errors => @libro.errors } } if params[:id]
      # Si es un libro persona 
      render :update do |page|
        page.show "nuevos_libros"
        page.modificar :update => "libro_nuevo_" + params[:i], :partial => "nuevo_libro", :mensaje => { :errors => @libro.errors }
        page.replace "formulario_anadir_anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>" unless params[:id]
      end unless params[:id]
    else
      selectores_formulario 
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @libro.errors} }
    end

  end

  # en administracion: elimina
  def eliminar
    @libro = Libro.find_by_id(params[:id])
    @libro.destroy
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @libro.errors, :eliminar => true}}
  end


  # en administracion: muestra el formulario para asociar usuarios
  def usuarios
    #sleep 10
    @libro = @objeto = Libro.find(params[:id])
    # @libros = @libro.usuario_x_libro
    @usuarios = @libro.usuario_x_libro
    @listado_usuarios = Usuario.find(:all).collect {|a| [a.nombre, a.id]}
    render :partial => "usuario/usuarios"
  end

  # en administracion: guarda la asociación de usuarios
  def guardar_usuarios
    @libro = @objeto = Libro.find(params[:id])
    @libro.actualizar_usuario_x_libro params[:usuarios]
    render  :template => "usuario/guardar_usuarios"
  end

  # en administracion: añade un usuario al formulario
  def anadir_usuario
    @objeto = Libro.find(params[:id])
    @listado_usuarios = Usuario.find(:all).collect {|a| [a.nombre, a.id]}
    render :template => "usuario/anadir_usuario" 
  end

 private

  # Variables donde recoger los valores para los selectores del formulario de edicion
  def selectores_formulario
    @listado_monedas = Moneda.find(:all, :order => "nombre").collect {|p| [p.nombre , p.id]} unless params[:seccion] == "agentes"
    @listado_monedas = @agente.moneda.order("nombre").collect {|p| [p.nombre , p.id]} if params[:seccion] == "agentes"
    @listado_agentes = Agente.find(:all, :conditions => {:implementador => true}, :order => "nombre").collect {|p| [p.nombre, p.id]} unless params[:seccion] == "agentes"
    @listado_agentes = [ [@agente.nombre, @agente.id] ] if params[:seccion] == "agentes"
    @listado_paises = Pais.find(:all, :order => "nombre").collect {|p| [p.nombre, p.id]}
    @paises = Pais.find(:all).collect {|p| [p.nombre, p.id]}
  end
end
