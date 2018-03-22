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


class ContabilidadController < BaseImportacionController

  before_filter :elementos_filtrado, :only => [ :listado ]
  before_filter :verificar_etapa, :only => [ :resumen ]

  def index
    redirect_to :action => "listado"
  end

  # en agentes: establece los parametros de ordenación
  def ordenado
    session[:contabilidad_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    session[:contabilidad_orden] = params[:orden] ? params[:orden] : "codigo"
    redirect_to :action => params[:listado] || "listado"
  end

  def filtrado
    session[:contabilidad_filtro_tipo] = params[:filtro][:tipo] if params[:filtro]
    session[:contabilidad_filtro_centro_coste] = params[:filtro][:centro_coste] if params[:filtro]
    redirect_to :action => params[:listado] || "listado"
  end

  def elementos_filtrado
    session[:contabilidad_asc_desc] ||= "ASC"
    session[:contabilidad_orden] ||= "codigo"
    session[:contabilidad_filtro_tipo] ||= "todos"
    session[:contabilidad_filtro_centro_coste] ||= "todos"

    @tipo = session[:contabilidad_filtro_tipo] unless session[:contabilidad_filtro_tipo] == "todos"
    @centro_coste = session[:contabilidad_filtro_centro_coste] unless session[:contabilidad_filtro_centro_coste] == "todos"

    filtro_tipo = [[_("Todos"),"todos"]] + tipos_de_elemento_en_subcuentas
    filtro_centro_coste = [[_("Todos"),"todos"], [_("Sólo Subcuentas"), "false"], [_("Sólo Centros de Coste"), "true"]] 
    @opciones_filtrado = [{:rotulo =>  _("Elemento Contable"), :nombre => "centro_coste", :opciones => filtro_centro_coste},
                          {:rotulo =>  _("Tipo de subcuenta"), :nombre => "tipo", :opciones => filtro_tipo},
                         ]
    @accion_filtrado = {:action => :filtrado, :listado => :listado}
    @estado_filtrado = [ (@centro_coste ? (@centro_coste == "false" ? _("Sólo Subcuentas") : _("Sólo Centros de Coste")) : _("Subcuentas y Centros de Coste") ),
                         (@tipo || _("Todos los tipos")) ]
  end


	# en agentes: lista las cuentas contables y los centros de coste
  def listado 
    elementos_filtrado
    # Esto lo hacemos por posibles conflictos con el "nombre" del agente
    condiciones = {:agente_id => @agente.id}
    condiciones[:elemento_contable_type] = @tipo if @tipo
    condiciones[:centro_coste] = (@centro_coste == "true") if @centro_coste

    @subcuentas = @paginado = CuentaContable.where(condiciones).
                                             order(session[:contabilidad_orden] + " " + session[:contabilidad_asc_desc]).
                                             paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                                      per_page: (params[:format_xls_count] || session[:por_pagina]))
    
    @formato_xls = @subcuentas.total_entries
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "subcuenta_contable"
        @objetos = @subcuentas
        nom_fich = "mapeo_contable_" + @agente.nombre + "_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

	# en agentes: prepara el formulario de crear o editar
  def editar_nuevo
    @subcuenta = @agente.cuentas_contables_delegacion.find_by_id(params[:id]) || CuentaContable.new(:agente_id => @agente.id)
    @tipo_elementos = tipos_de_elemento_en_subcuentas
    @elementos = elementos_por_tipo_subcuenta @subcuenta.elemento_contable_type
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

	# en agentes: modifica o crea una 
  def modificar_crear
    @subcuenta = @agente.cuentas_contables_delegacion.find_by_id(params[:id]) || CuentaContable.new(:agente_id => @agente.id)
    @subcuenta.update_attributes params[:subcuenta]
    if @subcuenta.errors.empty?
      # Si es una ya existente, modifica la linea
      render(:update) { |page|   page.modificar :update => params[:update], :partial => "subcuenta" , :mensaje => { :errors => @subcuenta.errors } } if params[:id]
      # Si es una nueva la incluye en la parte superior del listado
      render :update do |page|
        page.show "nuevas_subcuentas"
        page.modificar :update => "subcuenta_nueva_" + params[:i], :partial => "nueva_subcuenta", :mensaje => { :errors => @subcuenta.errors }
        page.replace "formulario_anadir_anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>" unless params[:id]
      end unless params[:id] 
    else
      @tipo_elementos = tipos_de_elemento_en_subcuentas
      @elementos = elementos_por_tipo_subcuenta @subcuenta.elemento_contable_type
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @subcuenta.errors} }
    end 
  end

	# en agentes: elimina una subcuenta
  def eliminar
    @subcuenta = CuentaContable.find_by_id(params[:id])
    @subcuenta.destroy if @subcuenta
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @subcuenta.errors, :eliminar => true}}
  end

  #-- 
  # METODOS AJAX PARA CAMBIO DE TIPO 
  # ++

  def subcuenta_cambio_tipo
    @elementos = elementos_por_tipo_subcuenta params[:type]
    render :partial => "elemento"
  end

 private

  # Comprueba que exista etapa si estamos en agentes
  def verificar_etapa
    if @agente && @agente.etapa.empty?
      msg_error _("Tiene que definir por lo menos una etapa para acceder a la gestión de Subcuentas Contables")
      redirect_to :menu => :configuracion_agente, :controller => :datos_agente, :action => :etapas
    end
  end

  # Obtiene los tipos de elementos de subcuentas para el filtro del listado
  def tipos_de_elemento_en_subcuentas
    [ [_("Financiador"), "Agente"], [_("Convocatoria"), "Convocatoria"], [_("Proyecto"), "Proyecto"], [_("Cuenta/Caja"), "Libro"], [_("Partida"), "Partida"], [_("Subpartida"), "Subpartida"], [_("Partida de Ingreso"), "PartidaIngreso"] ]
  end

  def elementos_por_tipo_subcuenta tipo_elemento
    objs = nil
    # Lo hacemos en un case y no en un eval porque cada tipo de elemento tiene sus cosillas
    case tipo_elemento
      when "Proyecto"
        # Evitamos mapeo contra convenios
        #objs = Proyecto.where(:convenio_accion => nil).order(:nombre).collect{|p| [p.nombre, p.id] }
        objs  = Proyecto.includes(:proyecto_x_implementador).where("proyecto_x_implementador.agente_id = ? OR gestor_id = ?", @agente.id, @agente.id).
                         where(:convenio_accion => nil).order(:nombre).collect{|p| [p.nombre, p.id] }
      when "Libro"
        objs = @agente.libro.order(:nombre).collect{|p| [p.nombre, p.id] }
      when "Agente"
        objs = Agente.where(:financiador => true).order(:nombre).collect{|p| [p.nombre, p.id] }
      when "Partida"
        objs = Partida.order(:codigo).collect{|p| [p.codigo_nombre, p.id] }
      when "Subpartida"
        objs = @agente.subpartida.order(:nombre).collect{|p| [p.nombre + " (" + _("Partida") + ": " + p.partida.codigo + " - " + p.partida.nombre + ")", p.id] }
      when "Convocatoria"
        objs = Convocatoria.order(:codigo).collect{|p| [p.codigo, p.id]}
      when "PartidaIngreso"
        objs = PartidaIngreso.order(:nombre).collect{|p| [p.nombre, p.id]}
    end
    return objs
  end

end

