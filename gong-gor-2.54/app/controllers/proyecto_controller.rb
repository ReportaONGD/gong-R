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
# Controlador encargado de la gestion de proyecto. Este controlador es utilizado desde las secciones:
# * Sección administracion: se utiliza para crear proyectos
# * Sección proyectos: se utiliza para seleccionar el proyecto y cargar lo en la sessión

class ProyectoController < ApplicationController

  def index
    redirect_to :action => "listado" if params[:seccion] == "administracion"
    redirect_to :action => "listado_usuario" unless params[:seccion] == "administracion"
  end


  def filtrado_condiciones
    session[:proyecto_asc_desc] ||= "ASC"
    session[:proyecto_orden] ||= "proyecto.nombre"
    session[:proyecto_filtro_estado] ||= "activos"
    session[:proyecto_filtro_pais] ||= []
    session[:proyecto_filtro_financiador] ||= "todos"
    session[:proyecto_filtro_ano] ||= "todos"
    session[:proyecto_filtro_tipo_convocatoria] ||= "todos"
    session[:proyecto_filtro_convocatoria] ||= "todas"
    session[:proyecto_filtro_sector_intervencion] ||= "todos"
    session[:proyecto_filtro_area_actuacion] ||= "todas"
    session[:proyecto_filtro_sector_poblacion] ||= "todos"
    session[:proyecto_filtro_nombre] ||= ""

    condiciones = "convenio_id IS NULL" 
    condiciones += " AND gestor_id = " + @agente.id.to_s if params[:seccion] == "agentes"
    condiciones += " AND proyecto_x_pais.pais_id IN (" + session[:proyecto_filtro_pais].join(",") + ")" unless session[:proyecto_filtro_pais].blank?
    condiciones += " AND convocatoria.agente_id = " + session[:proyecto_filtro_financiador] unless session[:proyecto_filtro_financiador] == "todos"
    condiciones += " AND convocatoria.tipo_convocatoria_id = " + session[:proyecto_filtro_tipo_convocatoria] unless session[:proyecto_filtro_tipo_convocatoria] == "todos"
    condiciones += " AND YEAR(convocatoria.fecha_publicacion) = " + session[:proyecto_filtro_ano].to_s unless session[:proyecto_filtro_ano] == "todos"
    condiciones += " AND convocatoria_id = " + session[:proyecto_filtro_convocatoria] unless session[:proyecto_filtro_convocatoria] == "todas"
    condiciones += " AND definicion_estado.id = " + session[:proyecto_filtro_estado] unless session[:proyecto_filtro_estado] == "todos" or session[:proyecto_filtro_estado] == "activos" or session[:proyecto_filtro_estado] == "sin_estado"
    condiciones += " AND definicion_estado.cerrado = 0" if session[:proyecto_filtro_estado] == "activos"
    condiciones += " AND estado.proyecto_id IS NULL" if session[:proyecto_filtro_estado] == "sin_estado"
    condiciones += " AND proyecto_x_sector_intervencion.sector_intervencion_id = " + session[:proyecto_filtro_sector_intervencion] unless session[:proyecto_filtro_sector_intervencion] == "todos"
    condiciones += " AND proyecto_x_area_actuacion.area_actuacion_id = " + session[:proyecto_filtro_area_actuacion] unless session[:proyecto_filtro_area_actuacion] == "todas"
    condiciones += " AND proyecto_x_sector_poblacion.sector_poblacion_id = " + session[:proyecto_filtro_sector_poblacion] unless session[:proyecto_filtro_sector_poblacion] == "todos"
    # Ojo!... tenemos que sanear esto para evitar inyecciones sql. Hay alguna otra forma menos retorcida?
    condiciones += " AND proyecto.nombre LIKE " + ActiveRecord::Base.connection.quote(session[:proyecto_filtro_nombre]) unless session[:proyecto_filtro_nombre].blank?
    # Solo si el plugin de Contabilidad esta activo usamos el filtro de cuentas contables
    # esto nos permitimos meterlo aqui porque el codigo del plugin esta en el core y no
    # en el propio plugin
    unless (sin_contabilidad_activa = Plugin.activos.find_by_clase("GorContabilidad").nil?) || session[:proyecto_filtro_cuenta_contable].blank?
      condiciones += " AND cuenta_contable.codigo LIKE " + ActiveRecord::Base.connection.quote(session[:proyecto_filtro_cuenta_contable])
    end
    @condiciones = condiciones

    paises = Pais.order("nombre").collect {|p| [p.nombre, p.id.to_s]}

    convocatorias = Convocatoria.where("fecha_publicacion is not null").order(:fecha_publicacion)
    anno_inicio = (convocatorias.empty? ? Date.today : convocatorias.first.fecha_publicacion).year
    anno_fin = (convocatorias.empty? ? Date.today : convocatorias.last.fecha_publicacion).year
    annos = [[_("Todos"), "todos"]] + (anno_inicio..anno_fin).collect{|x| [x, x.to_s]}

    agentes =  [[_("Todos"), "todos"]] + Agente.all(:order => "nombre", :conditions => {:financiador => true }).collect {|p| [p.nombre, p.id.to_s]}
    convocatorias = [[_("Todas"), "todas"]] + Convocatoria.all(:order => "nombre").collect {|p| [p.nombre, p.id.to_s]}
    tipos_convocatoria = [[ _("Todos"), "todos"]] + TipoConvocatoria.all(order: "nombre").collect {|t| [t.nombre, t.id.to_s]}
    sectores_intervencion = [[_("Todos"), "todos"]] + SectorIntervencion.all(:order => "nombre").collect {|p| [p.nombre, p.id.to_s]}
    areas_actuacion = [[_("Todas"), "todas"]] + AreaActuacion.all(:order => "nombre").collect {|p| [p.nombre, p.id.to_s]}
    sectores_poblacion = [[_("Todos"), "todos"]] + SectorPoblacion.all(:order => "nombre").collect {|p| [p.nombre, p.id.to_s]}
    estado =  [[_("Todos"), "todos"]] + [[_("Proyectos abiertos"),"activos"], [_("Proyectos sin estado"),"sin_estado"]] + DefinicionEstado.all(:order => "orden").collect {|p| [p.nombre_completo, p.id.to_s]}
    
    @opciones_filtrado = [      {:rotulo => _("Seleccione Nombre"), :nombre => "nombre", :tipo => "texto"},
				{:rotulo => _("Seleccione Año"), :nombre => "ano", :opciones => annos },
                                {:rotulo => _("Seleccione Convocatoria"), :nombre => "convocatoria", :opciones => convocatorias, :enriquecido => true },
                                {:rotulo => _("Tipo de Convocatoria"), :nombre => "tipo_convocatoria", :opciones => tipos_convocatoria },
				{:rotulo => _("Seleccione Financiador"), :nombre => "financiador", :opciones => agentes, :enriquecido => true },
                                {:rotulo => _("Seleccione Estado"), :nombre=> "estado", :opciones => estado },
				{:rotulo => _("Sector de Intervención"), :nombre => "sector_intervencion", :opciones => sectores_intervencion},
				{:rotulo => _("Área de Actuación"), :nombre => "area_actuacion", :opciones => areas_actuacion},
				{:rotulo => _("Sector de Población"), :nombre => "sector_poblacion", :opciones => sectores_poblacion},
                                {:rotulo => _("Seleccione Países"), :nombre => "pais", :opciones =>  paises, :tipo => "multiple"},
                         ] 
    @opciones_filtrado.push( {:rotulo => _("Centro de Coste"), nombre: "cuenta_contable", tipo: "texto"} ) unless sin_contabilidad_activa
    @accion_filtrado = {:action => :filtrado }
  end

  # en administracion y agentes: lista
  def listado
    filtrado_condiciones
    join_tables = [:definicion_estado, :proyecto_x_pais, :convocatoria, :proyecto_x_sector_intervencion, :proyecto_x_area_actuacion, :proyecto_x_sector_poblacion]
    join_tables.push(:cuenta_contable) unless Plugin.activos.find_by_clase("GorContabilidad").nil? || session[:proyecto_filtro_cuenta_contable].blank?
    @proyectos = @paginado = Proyecto.includes(join_tables).
                                      where(@condiciones).
                                      order(session[:proyecto_orden] + " " + session[:proyecto_asc_desc] ).
                                      paginate(page: params[:page], per_page: (session[:por_pagina] or 20) )

    @formato_xls = @proyectos.total_entries

    respond_to do |format|
      format.html
      format.xls do
        @tipo = "proyecto"
        @objetos = @proyectos
        nom_fich = "proyectos_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

  # en administracion, proyectos y agentes: establece los parametros de ordenación
  def ordenado
    session[:proyecto_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"   
    session[:proyecto_orden] = params[:orden] ? params[:orden] : "proyecto.nombre"
    session[:proyecto_orden] = "proyecto.nombre" if params[:orden] == "nombre"
    session[:proyecto_orden] = "pais.nombre" if params[:orden] == "pais_principal.nombre"
    session[:proyecto_orden] = "definicion_estado.nombre" if params[:orden] == "estado_actual.definicion_estado.nombre"
    if params[:seccion].nil? || params[:seccion] == "proyectos"
      redirect_to :action => "listado_usuario"
    else
      redirect_to :action => "listado"
    end
  end


  # Condiciones de filtrado del listado de proyectos
  def filtrado
    if params[:filtro]
      session[:proyecto_filtro_estado] = params[:filtro][:estado]
      session[:proyecto_filtro_pais] = params[:filtro][:pais].reject!(&:blank?) if params[:filtro][:pais].class.name == "Array"
      session[:proyecto_filtro_financiador] = params[:filtro][:financiador]
      session[:proyecto_filtro_ano] = params[:filtro][:ano]
      session[:proyecto_filtro_convocatoria] = params[:filtro][:convocatoria]
      session[:proyecto_filtro_tipo_convocatoria] = params[:filtro][:tipo_convocatoria]
      session[:proyecto_filtro_sector_intervencion] = params[:filtro][:sector_intervencion]
      session[:proyecto_filtro_area_actuacion] = params[:filtro][:area_actuacion]
      session[:proyecto_filtro_sector_poblacion] = params[:filtro][:sector_poblacion]
      session[:proyecto_filtro_nombre] = params[:filtro][:nombre]
      session[:proyecto_filtro_cuenta_contable] = params[:filtro][:cuenta_contable]
    end
    if params[:seccion].nil? || params[:seccion] == "proyectos"
      redirect_to :action => "listado_usuario"
    else
      redirect_to :action => "listado"
    end
  end
 
  # en administracion y agentes: prepara el formulario de nuevo proyecto/convenio
  def editar_nuevo_selector
    render :partial => "formulario_nuevo"
  end
 
  # en administracion y agentes: prepara el formulario de edición o creación
  def editar_nuevo
    @proyecto = Proyecto.find_by_id(params[:id]) unless params[:seccion] == "agentes"
    @proyecto = Proyecto.find_by_id_and_gestor_id(params[:id], @agente.id) if params[:seccion] == "agentes"
    @paises = Pais.all(:order => "nombre").collect {|p| [p.nombre, p.id]}
    @financiadores = Agente.find_all_by_financiador(true, :order => "nombre").collect {|a| [a.nombre, a.id]}
    condicion_libros = {:tipo => "banco"}
    condicion_libros[:moneda_id] = @proyecto.moneda_id if @proyecto
    if params[:seccion] == "agentes"
      @implementadores = [ [@agente.nombre, @agente.id] ]
      @implementador = @agente
      condicion_libros[:agente_id] = @agente.id
    else
      @implementadores = Agente.find_all_by_implementador(true, :order => "nombre").collect {|a| [a.nombre, a.id]}
      @implementador = @proyecto && @proyecto.libro_principal ? @proyecto.libro_principal.agente : nil 
    end
    @libros = Libro.all(:order => "nombre", :conditions => condicion_libros).collect {|a| [a.nombre, a.id]}
    @convocatorias = Convocatoria.where(cerrado: false).order("nombre").collect {|a| [a.nombre, a.id]}
    # Le incluimos la convocatoria del proyecto actual si esta cerrada
    @convocatorias.unshift [@proyecto.convocatoria.nombre, @proyecto.convocatoria_id] if @proyecto && @proyecto.convocatoria && @proyecto.convocatoria.cerrado
    @monedas = Moneda.all(:order => "nombre").collect {|a| [a.nombre, a.id]}
    @convenio_id = params[:convenio_id] if params[:convenio_id]
    if params[:nuevo_tipo]
      render (:update) do |page|
        page.replace 'formulario', :partial => "formulario", :locals => {:es_convenio => params[:nuevo_tipo] == "convenio"}
        page.call("Modalbox.resizeToContent({resizeDuration: 0.5})")
      end
    else
      render :partial => "formulario", :locals => {:es_convenio => (@proyecto ? @proyecto.convenio? : false)}
    end
  end

	# Callback ajax para rellenar el libro en cambio de moneda o de implementador
  def libro_cambio_moneda
    proyecto = Proyecto.find_by_id(params[:proyecto_id]) unless params[:seccion] == "agentes"
    proyecto = @agente.proyecto_implementador.find_by_id(params[:proyecto_id]) if params[:seccion] == "agentes"
    libro_id = proyecto.libro_id if proyecto
    params[:implementador_id] = @agente.id if params[:seccion] == "agentes"
    libros = Libro.all(:order => "nombre", :conditions => {:tipo => "banco", :moneda_id => params[:moneda_id], :agente_id => params[:implementador_id]}).collect {|a| [a.nombre, a.id]}
    render :update do |page|
      page.replace "selector_libro_financiador", :partial => "selector_libro_financiador", :locals => { :libros => libros, :libro_id => libro_id }
    end
  end

	# en administracion: modifica o crea
  def modificar_crear
    unless params[:seccion] == "agentes"
      @proyecto = Proyecto.find_by_id(params[:id])
    else
      @proyecto = Proyecto.find_by_id_and_gestor_id(params[:id], @agente.id)
      params[:proyecto][:gestor_id] = @agente.id
    end
    es_nuevo = @proyecto.nil?
    @proyecto ||= Proyecto.new
    params[:proyecto][:pais_principal_id] = "" if params[:selector].nil? || params[:selector][:multipais] == "1"
    @proyecto.update_attributes params[:proyecto]

    # Si estamos creando un pac...
    if params[:convenio_id]
      convenio = Proyecto.find_by_id params[:convenio_id]
      @proyectos = convenio.pacs
      render :update do |page|
        page.replace_html params[:update], :partial => "listado_proyectos_convenio"
        page.visual_effect :highlight, params[:update] , :duration => 6
        page.replace 'formulario', :inline => '<%= mensaje_error(@proyecto) %><br>'
        page.call("Modalbox.resizeToContent")
      end
    else
      msg @proyecto
      # Si todo ha ido OK y estamos en la seccion de agentes, mandamos un mail a los admins diciendo que se ha
      # creado el proyecto desde la delegacion
      if params[:seccion] == "agentes" && @proyecto.errors.empty? && es_nuevo
        # Envia correo de advertencia
        usuarios_mail = Usuario.where(administracion: true)
        # Revisa si en la configuracion existe un grupo de notificaciones y si es así, envía correo a
        # ellos. En caso contrario, deja notificacion a los administradores.
        grupo = GorConfig.getValue(:NEW_PROJECT_GROUP_SEND_MAIL)
        usuarios_mail = Usuario.joins(:grupo_usuario).where("grupo_usuario.nombre" => grupo).uniq unless grupo.blank?
        usuarios_mail.each do |usuario|
          begin
            Correo.nuevo_proyecto(request.host_with_port, usuario, @proyecto, @usuario_identificado).deliver
          rescue => ex
            logger.info "--------> Error enviando mail (proyecto/modificar_crear): " + ex.inspect
            msg_error _("No se ha podido mandar el mail a algún usuario")
          end
        end 
      end
      redirect_to :action => "listado"
    end
  end

  # en administracion: elimina
  def eliminar
    @proyecto = Proyecto.find_by_id(params[:id]) unless params[:seccion] == "agentes"
    @proyecto = Proyecto.find_by_id_and_gestor_id(params[:id], @agente.id) if params[:seccion] == "agentes"
    @proyecto.destroy if @proyecto
    if params[:convenio_id] 
      convenio = Proyecto.find_by_id(params[:convenio_id]) unless params[:seccion] == "agentes"
      convenio = @agente.proyecto_implementador.find_by_id(params[:convenio_id]) if params[:seccion] == "agentes"
      @proyectos = convenio ? convenio.pacs : []
      render :update do |page|
        page.replace_html params[:update], :partial => "listado_proyectos_convenio"
        page.visual_effect :highlight, params[:update] , :duration => 6
        page.replace_html 'MB_content', :inline => '<%= mensaje_error(@proyecto, :eliminar => true) %><br>'
        page.call("Modalbox.resizeToContent")
      end
    else
      msg_eliminar @proyecto
      redirect_to :action => 'listado'
    end
  end
  
  # en proyectos: lista los proyectos asociados al usuario declarado en la sessión
  def listado_usuario
    filtrado_condiciones
    join_tables = [:definicion_estado, :proyecto_x_pais, :convocatoria, :proyecto_x_sector_intervencion, :proyecto_x_area_actuacion, :proyecto_x_sector_poblacion]
    join_tables.push(:cuenta_contable) unless Plugin.activos.find_by_clase("GorContabilidad").nil? || session[:proyecto_filtro_cuenta_contable].blank?
    @proyectos = @paginado = @usuario_identificado.proyecto.reload.includes(join_tables).
                                                   where(@condiciones).
                                                   order(session[:proyecto_orden] + " " + session[:proyecto_asc_desc]).
                                                   paginate(page: params[:page], per_page: (session[:por_pagina] or 20) )
    @formato_xls = @proyectos.total_entries
    respond_to do |format|
      format.html
      format.xls do
        @tipo = "proyecto"
        @objetos = @proyectos
        nom_fich = "proyectos_" + Time.now.strftime("%Y-%m-%d")
        render 'comunes_xls/listado', :xls => nom_fich, :layout => false
      end
    end
  end

  # en convenios: lista los proyectos asociados
  def listado_proyectos_convenio
    convenio = Proyecto.find_by_id(params[:convenio_id]) unless params[:seccion] == "agentes"
    convenio = @agente.proyecto_implementador.find_by_id(params[:convenio_id]) if params[:seccion] == "agentes"
    @proyectos = convenio ? convenio.pacs : []
    render :update do |page|
      page.replace_html params[:update], :partial => "listado_proyectos_convenio"
    end

  end

end
