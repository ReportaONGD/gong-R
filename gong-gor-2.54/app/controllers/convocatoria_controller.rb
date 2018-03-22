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


class ConvocatoriaController < ApplicationController

  # Esto es para poder usar el number_with_delimiter
  include ActionView::Helpers::NumberHelper

  before_filter :elementos_filtrado, :only => [ :listado ]
  before_filter :verificar_etapa, :only => [ :resumen ]

  def index
    redirect_to :action => "resumen"
  end

  # en convocatorias: establece los parametros de ordenación
  def ordenado
    session[:convocatoria_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    session[:convocatoria_orden] = params[:orden] ? params[:orden] : "nombre"
    redirect_to :action => "listado"
  end

  # en convocatorias: establece los parametros de filtro
  def filtrado
    session[:convocatoria_filtro_agente] = params[:filtro][:agente] if params[:filtro][:agente]
    session[:convocatoria_filtro_tipo] = params[:filtro][:tipo] if params[:filtro][:tipo]
    session[:convocatoria_filtro_cerrado] = params[:filtro][:cerrado] if params[:filtro][:tipo]
    redirect_to :action => :listado
  end

  def elementos_filtrado
    session[:convocatoria_asc_desc] ||= "ASC"
    session[:convocatoria_orden] ||= "nombre"
    session[:convocatoria_filtro_agente] ||= "todos"
    session[:convocatoria_filtro_tipo] ||= "todos"
    session[:convocatoria_filtro_cerrado] ||= "todos"

    #financiadores = Agente.where(:financiador => true, :implementador => false, :sistema => false).collect{|a| [a.nombre, a.id]}
    @financiador = Agente.find_by_id( session[:convocatoria_filtro_agente] ) unless session[:convocatoria_filtro_agente] == "todos"
    @tipo = TipoConvocatoria.find_by_id( session[:convocatoria_filtro_tipo] ) unless session[:convocatoria_filtro_tipo] == "todos"
    @cerrado = session[:convocatoria_filtro_cerrado] unless session[:convocatoria_filtro_cerrado] == "todos"

    datos_formulario
    filtro_agente = [[_("Todos"),"todos"]] + @financiadores
    filtro_tipo = [[_("Todos"),"todos"]] + @tipos_convocatoria
    filtro_cerrado = [ [_("Todos"),"todos"], [_("Abierto"), "abierto"], [_("Cerrado"), "cerrado"] ]
    
    @opciones_filtrado = [ {:rotulo => _("Seleccione financiador"), :nombre => "agente", :opciones => filtro_agente},
                           {:rotulo => _("Seleccione tipo"), :nombre => "tipo", :opciones => filtro_tipo},
                           {:rotulo => _("Seleccione estado"), :nombre => "cerrado", :opciones => filtro_cerrado} ]
    @accion_filtrado = {:action => :filtrado, :listado => :listado}
    @estado_filtrado = [ (@financiador ? @financiador.nombre : _("Todos los financiadores")), (@tipo ? @tipo.nombre : _("Todos los tipos")), @cerrado ? @cerrado : _("Todos los estados")  ]
  end


	# en convocatorias: lista las convocatorias
  def listado
    elementos_filtrado 
    condiciones = {} 
    condiciones[:agente_id] = @financiador.id if @financiador
    condiciones[:tipo_convocatoria_id] = @tipo.id if @tipo
    condiciones[:cerrado] = (@cerrado == "cerrado") unless @cerrado.nil?

    # Esto lo hacemos por posibles conflictos con el "nombre" del agente
    orden_convocatoria = session[:convocatoria_orden] == "nombre" ? "convocatoria.nombre" : session[:convocatoria_orden] == "nombre" 
    @convocatorias = @paginado = Convocatoria.includes(["agente"]).
                                              where(condiciones).
                                              order(session[:convocatoria_orden] + " " + session[:convocatoria_asc_desc]).
                                              paginate(page: (params[:format]=='xls' ? nil : params[:page]),
                                                       per_page: (params[:format_xls_count] || session[:por_pagina]))
    
    @formato_xls = @convocatorias.total_entries
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "convocatoria"
        @objetos = @convocatorias
        nom_fich = "convocatorias_financiacion_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

	# en convocatorias: prepara el formulario de crear o editar
  def editar_nuevo
    @convocatoria = Convocatoria.find_by_id(params[:id]) || Convocatoria.new
    datos_formulario
    render (:update) { |page| page.formulario(:partial => "formulario", :update => params[:update]) }
  end

	# en convocatorias: modifica o crea una 
  def modificar_crear
    @convocatoria = Convocatoria.find_by_id(params[:id]) || Convocatoria.new
    @convocatoria.update_attributes params[:convocatoria]
    if @convocatoria.errors.empty? && @convocatoria.actualizar_paises(params[:paises])
      # Si es una ya existente, modifica la linea
      render(:update) { |page|   page.modificar :update => params[:update], :partial => "convocatoria" , :mensaje => { :errors => @convocatoria.errors } } if params[:id]
      # Si es una nueva convocatoria la incluye en la parte superior del listado
      render :update do |page|
        page.show "nuevas_convocatorias"
        page.modificar :update => "convocatoria_nueva_" + params[:i], :partial => "nueva_convocatoria", :mensaje => { :errors => @convocatoria.errors }
        page.replace "formulario_anadir_anadir", :inline => "<%= anadir(:url => {:action => 'editar_nuevo', :i => (params[:i].to_i + 1).to_s, :update => 'formulario_anadir'}) %>" unless params[:id]
      end unless params[:id] 
    else
      datos_formulario
      render(:update) { |page| page.recargar_formulario :partial => "formulario", :mensaje => {:errors => @convocatoria.errors} }
    end 
  end

	# en convocatorias: elimina una
  def eliminar
    @convocatoria = Convocatoria.find_by_id(params[:id])
    @convocatoria.destroy if @convocatoria
    render (:update) {|page| page.eliminar :update => params[:update], :mensaje => {:errors => @convocatoria.errors, :eliminar => true}}
  end

  def resumen
    @listado_etapa = @agente.etapa.collect{|e| [e.nombre, e.id]} if @agente
    @listado_delegacion = [[_("Todas las delegaciones"), "todas"], [_("ONGD Agrupada"),"-1"]] + Agente.order("nombre").where(:implementador => true, :socia_local => false).collect{ |p| [p.nombre, p.id] }

    if @agente
      params[:delegacion] ||= @agente.id
      @etapa = @agente.etapa.find_by_id(params[:etapa])
      unless @etapa 
        @etapa = @agente.etapa.where("fecha_fin >= %s", Date.today).order("fecha_fin").last
        params[:etapa] = @etapa.id if @etapa
      end
      @f_inicio = @etapa.fecha_inicio
      @f_fin = @etapa.fecha_fin
    else
      @f_inicio = fecha params[:fecha_inicio] if params[:fecha_inicio]
      @f_fin = fecha params[:fecha_fin] if params[:fecha_fin]
      @f_inicio ||= Date.today.beginning_of_year
      @f_fin ||= Date.today.end_of_year
    end

    @delegacion = Agente.find_by_id params[:delegacion]

    if @f_inicio && @f_fin
      # Cabecera del informe
      lineas = [ :cabecera => [ [_("País Delegación"), "1_2"], [_("Objetivo Fondos"), "2_3_td"], [_("Convocatoria"), "2_3"], [_("Financiador"), "2_3"], [_("Paises presentados"), "1"], [_("Áreas de Actuación"), "1"], [_("Sectores de Intervención"), "1"], [_("Rol en proyectos"), "2_3"], [_("Total Fondos Solicitados"), "2_3_td"], [_("Solicitado Delegación"), "2_3_td"], [_("Proyectos Aprobados"), "1_2_td"], [_("Total Aprobado"), "2_3_td"], [_("Aprobado Delegación"), "2_3_td"], [_("Indirectos Delegación"), "2_3_td"] ] ] unless params[:delegacion] == "-1"
      lineas = [ :cabecera => [ [_("País ONGD"), "1_2"], [_("Objetivo Fondos"), "2_3_td"], [_("Convocatoria"), "2_3"], [_("Financiador"), "2_3"], [_("Paises presentados"), "1"], [_("Áreas de Actuación"), "1"], [_("Sectores de Intervención"), "1"], [_("Rol en proyectos"), "2_3"], [_("Total Fondos Solicitados"), "2_3_td"], [_("Solicitado ONGD"), "2_3_td"], [_("Proyectos Aprobados"), "1_2_td"], [_("Total Aprobado"), "2_3_td"], [_("Aprobado ONGD"), "2_3_td"], [_("Indirectos ONGD"), "2_3_td"] ] ] if params[:delegacion] == "-1"

      delegaciones = @delegacion ? Agente.where(:id => params[:delegacion]) : Agente.where(:socia_local => false)
      condiciones_pais = {"agente.implementador" => true, "agente.socia_local" => false}
      condiciones_pais["pais.id"] = @delegacion.pais_id if @delegacion
      partidas_indirectas = Partida.where(:tipo => "indirecto")
      # Recorre todos los paises con financiadores
      Pais.includes("agente").where(condiciones_pais).each do |pais|
        objetivos = Etapa.includes("agente").where(:agente_id => delegaciones, :fecha_inicio => @f_inicio..@f_fin, "agente.pais_id" => pais.id).group("moneda_id").sum("importe_previsto_subvencion")
        importe_previsto = importe_formateado objetivos
        nombre_pais = pais.nombre
        delegaciones_pais = delegaciones.where(:pais_id => pais.id)
        ongd_o_del_pais = params[:delegacion] == "-1" ? delegaciones : delegaciones_pais

        # Busca las convocatorias de la etapa donde haya algún proyecto en el que esté involucrada una delegación del país
        condiciones = {"fecha_publicacion" => @f_inicio..@f_fin, "proyecto_x_implementador.agente_id" => delegaciones_pais}
        convocatorias = Convocatoria.includes("agente").joins(:proyecto => [:proyecto_x_implementador]).where(condiciones)

        # Muestra el detalle de cada convocatoria, o si no tiene proyectos con agentes involucrados, al menos la previsión de financiación
        lineas.push( :contenido => [ nombre_pais, importe_previsto ] ) if convocatorias.empty? && importe_previsto != ""
        # Recorre todas las convocatorias
        convocatorias.each do |convocatoria|
          financiador = convocatoria.agente
          # Condiciones para la busqueda de proyectos
          #   esta asociado a la convocatoria y no es un pac
          condiciones_proyecto = {"proyecto.convocatoria_id" => convocatoria.id, "proyecto.convenio_id" => nil}
          #   en el proyecto participa alguna de las delegaciones del pais
          condiciones_proyecto["proyecto_x_implementador.agente_id"] = delegaciones_pais
          proyectos = Proyecto.includes("proyecto_x_implementador").where(condiciones_proyecto).all
          # Los paises, areas y sectores implicados son todos aquellos en los que se ejecutan los proyectos encontrados
          paises = Pais.includes("proyecto_x_pais").where("proyecto_x_pais.proyecto_id" => proyectos).group("pais.nombre").count.keys.join(", ")
          areas = AreaActuacion.includes("proyecto_x_area_actuacion").where("proyecto_x_area_actuacion.proyecto_id" => proyectos).group("area_actuacion.nombre").count.keys.join(", ")
          sectores = SectorIntervencion.includes("proyecto_x_sector_intervencion").where("proyecto_x_sector_intervencion.proyecto_id" => proyectos).group("sector_intervencion.nombre").count.keys.join(", ")
          # Roles e importes de proyectos presentados y aprobados (evitando los pacs)
          presentado, aprobado, presentado_delegacion, aprobado_delegacion, indirectos_delegacion = {}, {}, {}, {}, {}
          rol = { "Gestor" => 0, "Socio" => 0 }
          proyectos_aprobados = 0
          proyectos.each do |p|
            rol["Gestor"] += 1 if ongd_o_del_pais.include? p.gestor
            rol["Socio"] += 1 unless ongd_o_del_pais.include? p.gestor 
            # Obtiene el total financiado y el financiado para la delegacion
            subtotal_financiado = p.presupuesto_total_con_tc(:financiador => financiador)
            subtotal_financiado_delegacion = p.presupuesto_total_con_tc(:financiador => financiador,:implementador => ongd_o_del_pais)
            # Los metemos en el hash de monedas
            presentado[p.moneda_principal] = 0 unless presentado.has_key?(p.moneda_principal)
            presentado[p.moneda_principal] += subtotal_financiado
            presentado_delegacion[p.moneda_principal] = 0 unless presentado_delegacion.has_key?(p.moneda_principal)
            presentado_delegacion[p.moneda_principal] += subtotal_financiado_delegacion
            # Si el proyecto esta aprobado, metemos los datos en los hashes 
            if p.estado_actual && p.estado_actual.definicion_estado && p.estado_actual.definicion_estado.aprobado
              proyectos_aprobados += 1
              aprobado[p.moneda_principal] = 0 unless aprobado.has_key?(p.moneda_principal)
              aprobado[p.moneda_principal] += subtotal_financiado
              aprobado_delegacion[p.moneda_principal] = 0 unless aprobado_delegacion.has_key?(p.moneda_principal)
              aprobado_delegacion[p.moneda_principal] += subtotal_financiado_delegacion
              # los indirectos solo los buscamos si realmente esta aprobado
              indirectos_delegacion[p.moneda_principal] = 0 unless indirectos_delegacion.has_key?(p.moneda_principal)
              indirectos_delegacion[p.moneda_principal] += p.presupuesto_total_con_tc(:financiador => financiador,:implementador => ongd_o_del_pais,:partida => partidas_indirectas)
            end
          end
          roles = rol.collect{|k,v| _(k) + ": " + _("%{num} proyectos")%{:num => v} if v > 0}.compact.join(", ")
          importe_presentado = importe_formateado presentado
          importe_aprobado = importe_formateado aprobado
          importe_presentado_delegacion = importe_formateado presentado_delegacion
          importe_aprobado_delegacion = importe_formateado aprobado_delegacion
          importe_indirectos_delegacion = importe_formateado indirectos_delegacion
          lineas.push( :contenido => [ nombre_pais, importe_previsto, convocatoria.nombre, convocatoria.agente.nombre,
                                       paises, areas, sectores, roles, importe_presentado, importe_presentado_delegacion,
                                       proyectos_aprobados.to_s, importe_aprobado, importe_aprobado_delegacion, importe_indirectos_delegacion ] )
          nombre_pais = importe_previsto = ""
        end
      end
      lineas.push( :contenido => [ ] )
      
    end

      nombre = "convocatorias"
      titulo = (@delegacion ? @delegacion.nombre + " / " : "") + _("País") + ": " + (@pais ? @pais.nombre : _("Todos")) + " / "
      titulo += _("Periodo") + ": " + (@etapa ? @etapa.nombre + " " : "") + _("(desde %{fecha_inicio} hasta %{fecha_fin})") % {:fecha_inicio => @f_inicio.strftime('%d/%m/%Y'), :fecha_fin => @f_fin.strftime('%d/%m/%Y')} 
      @resumen = [{:listado => {:nombre => nombre, :titulo => titulo, :lineas => lineas}}]

      respond_to do |format|
        format.html do
          render :action => "resumen", :layout => (params[:sin_layout] ? false : true)
        end
        format.xls do
          nom_fich = "resumen_convocatorias_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/resumen', :xls => nom_fich, :layout => false
        end
      end

  end

  ### Listado de Proyectos ###
	# en convocatorias, presenta el listado de proyectos asociados a la convocatoria
  def proyectos
    convocatoria = Convocatoria.find(params[:id])
    @proyectos = convocatoria.proyecto.where(:convenio_id => nil)
    render(:update) { |page| page.replace_html params[:update], :partial => "proyectos", :locals => {:update_listado => params[:update]} }
  end

  ### METODOS AJAX ###
	# incluye un nuevo pais en el formulario
  def anadir_pais
    render :template => "convocatoria/anadir_pais"
  end

 private
  # Devuelve los datos para completar el formulario de edicion
  def datos_formulario
    #@financiadores = Agente.where(:financiador => true, :implementador => false).order("nombre").collect{|p| [p.nombre, p.id]}
    @financiadores = Agente.where(financiador: true).order(:nombre).collect{|p| [p.nombre, p.id]}
    @tipos_convocatoria = TipoConvocatoria.order("nombre").collect{|p| [p.nombre, p.id]}
    @paises = @convocatoria.convocatoria_x_pais if @convocatoria
  end

  # Comprueba que exista etapa si estamos en agentes
  def verificar_etapa
    if @agente && @agente.etapa.empty?
      msg_error _("Tiene que definir por lo menos una etapa para acceder a los informes")
      redirect_to :menu => :configuracion_agente, :controller => :datos_agente, :action => :etapas
    end
  end

  # Obtiene un hash moneda_id => importe y devuelve su valor * TC o un string con los valores por moneda
  def importe_formateado hash_importes
    if @agente && @agente.moneda_principal && @agente.moneda_principal.abreviatura && @etapa
      importes_sin_tc = []
      importes_con_tc = 0
      hash_importes.collect do |k,v|
        tc = @etapa.tasa_cambio.first(:conditions => ["moneda_id = ? AND objeto = 'presupuesto'", k])
        importes_con_tc += v * tc.tasa_cambio if tc
        importes_sin_tc.push( number_with_delimiter(('%.2f' % v).to_s, :separator => ",", :delimiter => ".") + " " + Moneda.find_by_id(k).abreviatura ) unless tc || v==0
      end
      importes = importes_con_tc==0 ? "" : number_with_delimiter(('%.2f' % importes_con_tc).to_s, :separator => ",", :delimiter => ".")
      importes += " " + @agente.moneda_principal.abreviatura + " + " unless importes=="" || importes_sin_tc.empty?
      importes += importes_sin_tc.join(" + ") unless importes_sin_tc.empty?
    else
      importes = hash_importes.collect do |k,v|
        number_with_delimiter(('%.2f' % v).to_s , :separator => ",", :delimiter => ".") + " " + Moneda.find_by_id(k).abreviatura
      end.join(" + ") 
    end
    return importes
  end
end

