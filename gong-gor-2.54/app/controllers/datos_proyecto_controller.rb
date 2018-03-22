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
# Controlador encargado de la gestión de los datos de proyecto.
# Este controlador es utilizado desde las secciones:
# * Sección proyectos: se utiliza para establecer la identificación, el contexto,
# las relaciones, los objetivos y la sostenibilidad y las etapas del proyecto guardado en la session.




class DatosProyectoController < ApplicationController
  before_filter :verificar_estado_proyecto, :only => [ :index, :modificar_fechas_originales, :modificar_crear_etapa, :eliminar_etapa]
  before_filter :verificar_estado_proyecto_cofinanciacion, :only => [ :modificar_crear_proyecto_cofinanciador, :eliminar_proyecto_cofinanciador]

  # El metodo comprobar_periodo se encuentra en el ApplicationController
  before_filter :comprobar_periodo_identificador_financiador, :only => [:etapas, :relaciones]



  def verificar_estado_proyecto
    unless (@proyecto.estado_actual && @proyecto.estado_actual.definicion_estado.formulacion) || 
           (params[:etapa] && (@proyecto.estado_actual.nil? || @proyecto.estado_actual.definicion_estado.formulacion || (!@proyecto.estado_actual.definicion_estado.ejecucion && !@proyecto.estado_actual.definicion_estado.cerrado)))
      msg_error _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar los datos del proyecto.")    if @proyecto.estado_actual.nil?
      msg_error _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se pueden modificar los datos del proyecto.") + " " + _("No ha sido definido como 'estado de formulación' por su administrador.")    unless @proyecto.estado_actual.nil?
      redirect_to :action => "etapas" if params[:action] =~ /modificar_crear_etapa|modificar_fechas_originales|eliminar_etapa/
      redirect_to :action => "datos_proyecto_dinamicos_" + params[:pestana] if params[:action] =~ /modificar_datos_proyecto_dinamicos|eliminar_datos_dinamicos/
    end     
  end

  def verificar_estado_proyecto_cofinanciacion
    unless (@proyecto.estado_actual && !@proyecto.estado_actual.definicion_estado.cerrado)
      msg_error _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar los datos del proyecto.")    if @proyecto.estado_actual.nil?
      msg_error _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se pueden modificar los datos del proyecto.")  unless @proyecto.estado_actual.nil?
      redirect_to :action => "proyecto_cofinanciador"
    end
  end

  before_filter :verificar_estado_proyecto_ajax, :only => [ :relacionar, :eliminar_relacion]
  before_filter :verificar_borrado_cuenta, :only => [ :eliminar_relacion ]

  def verificar_estado_proyecto_ajax
    # Si el proyecto no tiene estado y queremos modificar etapas
    # O tiene estado y es cerrado
    # O tiene estado y no esta en ejecucion y queremos modificar otra cosa distinta de los libros
    if (@proyecto.estado_actual.nil? && params[:atributo] == "etapa") ||
       (@proyecto.estado_actual && @proyecto.estado_actual.definicion_estado.cerrado) ||
       (@proyecto.estado_actual && !@proyecto.estado_actual.definicion_estado.formulacion && params[:atributo] != "libro")
      render :update do |page|
        @mensaje_aviso = _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => @proyecto.estado_actual.definicion_estado.nombre} + " " + _("En este estado no se pueden modificar los datos del proyecto.") + " " + _("No ha sido definido como 'estado de formulación' por su administrador.")  if @proyecto.estado_actual
        @mensaje_aviso = _("El proyecto se encuentra 'sin estado'.") + " " + _("En este estado no se pueden modificar los datos del proyecto.") unless @proyecto.estado_actual
        page.replace_html "MB_content", :inline => "<%= mensaje_error @mensaje_aviso %>"
        page.call("Modalbox.resizeToContent")
      end
    end
  end

  # Permite el borrado de una cuenta solo si esta no lleva asociados pagos o transferencias
  def verificar_borrado_cuenta
    if params[:atributo] == "libro"
      cuenta = Libro.find_by_id params[:id]
      pagos = @proyecto.gasto.joins(:pago).where("pago.libro_id" => params[:id]).count
      @proyecto.pacs.each { |pac| pagos += pac.gasto.joins(:pago).where("pago.libro_id" => params[:id]).count }
      if ( pagos > 0 )
        render :update do |page|
          page.replace_html "MB_content", :inline => "<%= mensaje_error _('Hay %{num} pagos asociados a la cuenta. No se pudo desvincular.')%{:num => " + pagos.to_s + "} %>" if pagos > 0
        end
      end
    end
  end

  # en proyectos: se redirecciona por defecto a identificación
  def index
    redirect_to :action => "datos_proyecto_dinamicos"
  end

  # en proyectos: lista las relaciones del proyectos
  def relaciones
    @paises = @proyecto.pais.all(:order => "nombre")
    @monedas = @proyecto.moneda.all(:order => "nombre")
    @financiadores = @proyecto.financiador.all(:order => "nombre")
    @implementadores = @proyecto.implementador.all(:order => "nombre")
    @sector_poblacion = @proyecto.sector_poblacion
    @sector_intervencion = @proyecto.sector_intervencion
    @area_actuacion = @proyecto.area_actuacion
    @libro = @proyecto.libro.all(:order => "nombre")
    @proyecto_cofinanciador = @proyecto.proyecto_cofinanciador.all(:order => "nombre")
  end

  # en proyectos: prepara el formulario para añadir un pais
  def anadir_pais
    @relaciones = (Pais.find(:all, :order => "nombre")-@proyecto.pais).collect{ |p| [p.nombre, p.id]}    
    render :partial => "anadir_relacion", :locals => { :relacion => "pais" }
  end

  # en proyectos: prepara el formulario para añadir una moneda
  def anadir_moneda
    @relaciones = (Moneda.find(:all, :order => "nombre")-@proyecto.moneda).collect{ |m| [m.abreviatura + " " + m.nombre, m.id]}    
    render :partial => "anadir_relacion", :locals => { :relacion => "moneda" }
  end

  # en proyectos: prepara el formulario para añadir un agente implementador
  def anadir_implementador 
    @relaciones = (Agente.find_all_by_implementador( true, :order => "nombre" )-@proyecto.implementador).collect{ |m| [m.nombre, m.id]} 
    render :partial => "anadir_relacion", :locals => { :relacion => "implementador" }
  end

  # en proyectos: prepara el formulario para añadir un agente financiador
  def anadir_financiador
    @relaciones = (Agente.find_all_by_financiador( true, :order => "nombre" )-@proyecto.financiador).collect{ |m| [m.nombre, m.id]}  
    render :partial => "anadir_relacion", :locals => { :relacion => "financiador" }
  end

  # en proyectos: prepara el formulario para añadir un sector de población
  def anadir_sector_poblacion
    @relaciones = SectorPoblacion.find( :all, :order => "nombre" ).collect{ |m| [m.nombre, m.id]} 
    render :partial => "anadir_relacion", :locals => { :relacion => "sector_poblacion" }
  end

  # en proyectos: prepara el formulario para añadir un sector de intervención
  def anadir_sector_intervencion
    @relaciones = SectorIntervencion.order(:nombre).collect{ |m| [m.nombre, m.id]} 
    render partial: "anadir_relacion", locals: { relacion: "sector_intervencion" }
  end

  # en proyectos: prepara el formulario para añadir una area de actuación
  def anadir_area_actuacion
    @relaciones = AreaActuacion.order(:nombre).collect{ |m| [m.nombre, m.id]} 
    render partial: "anadir_relacion", locals: { relacion: "area_actuacion" }
  end

  # en proyectos: prepara el formulario para añadir una cuenta (libro)
  def anadir_libro
    l=[]
    libros=[]
    # Obtiene todos los libros de todos los usuarios involucrados (salvo los que esten ocultos)
    @proyecto.usuario.each { |usuario| l += usuario.libro.all(:conditions => ['oculto = ?', false]) }
    # Le quita los ya asignados, elimina duplicados y coge solo de los que la moneda este definida y el agente tambien
    (l-@proyecto.libro).each {|lib| libros << lib if libros.count(lib) == 0 && @proyecto.moneda.find_by_id(lib.moneda_id) && @proyecto.implementador.find_by_id(lib.agente_id) }
    # Ordena y prepara el desplegable 
    @relaciones = libros.sort! {|a,b| a.nombre <=> b.nombre}.collect{ |m| [m.nombre, m.id]}
    render :partial => "anadir_relacion", :locals => { :relacion => "libro" }
  end


  # Define un hash de relación atributo/modelo
  RELACIONES = { "pais" => "Pais", "moneda" => "Moneda", "implementador" => "Agente", "financiador" => "Agente", "sector_poblacion" => "SectorPoblacion", "sector_intervencion" => "SectorIntervencion", "area_actuacion" => "AreaActuacion", "libro" => "Libro" }

  # en proyecto: modifica o añade una relación 
  def relacionar
    vista = "datos"
    begin 
      obj=nil
      @proyecto.errors.clear
      case params[:atributo]
        when "area_actuacion"
          vista = "datos_relacion_categoria"
          obj = ProyectoXAreaActuacion.create(:proyecto_id => @proyecto.id, :area_actuacion_id => params[:relacion][:relacion_id], :porcentaje => params[:relacion][:porcentaje])
        when "sector_intervencion"
          vista = "datos_relacion_categoria"
          obj = ProyectoXSectorIntervencion.create(:proyecto_id => @proyecto.id, :sector_intervencion_id => params[:relacion][:relacion_id], :porcentaje => params[:relacion][:porcentaje])
        when "sector_poblacion"
          obj = ProyectoXSectorPoblacion.create(:proyecto_id => @proyecto.id, :sector_poblacion_id => params[:relacion][:relacion_id], :porcentaje => params[:relacion][:porcentaje])
        else
          @proyecto.send( params[:atributo] ) << eval(RELACIONES[params[:atributo]]).find(params[:relacion][:relacion_id])
      end
      obj.errors.each {|key,msg| @proyecto.errors.add(:base,msg)} if obj 
    rescue
      @proyecto.errors.add(:base,"La relación no es correcta.")
    end
    @relaciones = @proyecto.send params[:atributo]
    @relacion = eval(RELACIONES[params[:atributo]]).find(params[:relacion][:relacion_id])

    render :update do |page|
      page.replace_html 'formulario', :inline => '<%= mensaje_error(@proyecto) %>'
      page.replace_html params[:atributo], :partial => vista, :locals => { :relacion => params[:atributo] , :relaciones => @relaciones}
      page.visual_effect :highlight, params[:atributo] , :duration => 6
      # Si la relacion es pais, actualizamos tambien el listado de monedas por si hubo cambios
      if params[:atributo] == "pais"
        page.replace_html "moneda", :partial => "datos", :locals => { :relacion => "moneda", :relaciones => @proyecto.moneda}
        page.visual_effect :highlight, "moneda", :duration => 6
      end
      page.call("Modalbox.resizeToContent")
    end
  end

  # en proyectos: elimina una relación
  def eliminar_relacion
    # Cambiamos la forma de borrar para poder capturar los errores del modelo
    #@proyecto.send( params[:atributo] ).destroy( eval( RELACIONES[ params[:atributo] ] ).find( params[:id] ) )
    elemento = "proyecto_x_" + params[:atributo] unless params[:atributo] == "libro"
    elemento = "libro_x_proyecto" if params[:atributo] == "libro"
    if params[:atributo] == "sector_intervencion" || params[:atributo] == "area_actuacion"
      vista = "datos_relacion_categoria"
    else
      vista = "datos"
    end
    @objeto = @proyecto.send( elemento ).where(RELACIONES[ params[:atributo] ].underscore + "_id" => params[:id]).first
    @objeto.destroy if @objeto
    @relaciones = @proyecto.send params[:atributo]
    render :update do |page|
      page.replace_html params[:atributo], :partial => vista, :locals => { :relacion => params[:atributo] , :relaciones => @relaciones}
      page.visual_effect :highlight, params[:atributo] , :duration => 6
      page.replace_html 'MB_content', :inline => '<%= mensaje_error(@objeto, :eliminar => true) %><br>'
      page.call("Modalbox.resizeToContent")
    end
  end
  
  # --
  ########## ETAPAS Y PERIODOS ##########
  # ++

  # en proyectos: lista las etapas
  def etapas
    @etapa = params[:id] ?  Etapa.find(params[:id]) : nil
    @etapas = @proyecto.etapa.reload.sort! { |a,b| a.fecha_inicio <=> b.fecha_inicio }
    @periodos_seguimiento = @proyecto.periodo.all(:include => "tipo_periodo", 
                                                  :conditions =>{ "tipo_periodo.grupo_tipo_periodo" => ["seguimiento","final"], "tipo_periodo.oficial" => true}, 
                                                  :order=> "fecha_inicio")
    @periodos_seguimiento_interno = @proyecto.periodo.all(:include => "tipo_periodo", 
                                                           :conditions =>{ "tipo_periodo.grupo_tipo_periodo" => ["seguimiento", "final"], "tipo_periodo.oficial" => false}, 
                                                           :order=> "fecha_inicio")
    @prorrogas = @proyecto.periodo.includes(:tipo_periodo).
                                   where("tipo_periodo.grupo_tipo_periodo" => "prorroga").
                                   order(:fecha_inicio)
    @prorrogas_justificacion = @proyecto.periodo.includes(:tipo_periodo).
                                                 where("tipo_periodo.grupo_tipo_periodo" => "prorroga_justificacion").
                                                 order(:fecha_inicio)
    @formulaciones = @proyecto.periodo.all(:include => "tipo_periodo", 
                                           :conditions => { "tipo_periodo.grupo_tipo_periodo" => "formulacion"}, :order=> "fecha_inicio")
    render "etapas_periodos"
  end

  # en proyectos: crea una nueva etapa
  def editar_nuevo_etapa
    @etapa = params[:id] ?  Etapa.find(params[:id]) : nil
    render :partial => "comunes/etapa"
  end

  # en proyectos: modifica o crea una etapa
  def modificar_crear_etapa
    @etapa = params[:id] ?  Etapa.find(params[:id]) : Etapa.new(:proyecto_id => @proyecto.id)
    @etapa.update_attributes params[:etapa]
    msg @etapa
    redirect_to :action => 'etapas'
  end
    
  # en proyectos: elimina una etapa
  def eliminar_etapa
    (etapa = Etapa.find(params[:id])).destroy
    msg etapa
    redirect_to action: 'etapas'
  end

  # FECHAS ORIGINALES DEL PROYECTO
  # formulario de edicion de fechas originales del proyecto
  def editar_fechas_originales
    render partial: 'formulario_fechas_aprobadas_originales'
  end

  # modifica las fechas originales del proyecto
  def modificar_fechas_originales
    @proyecto.update_attributes params[:proyecto]
    msg @proyecto
    redirect_to action: 'etapas'
  end

  # PERIODOS
  # en proyectos: crea una nueva periodo
  def editar_nuevo_periodo
    @periodo = params[:id] ?  Periodo.find(params[:id]) : nil
    render :partial => "formulario_periodo"
  end

  # en proyectos: modifica o crea un periodo
  def modificar_crear_periodo
    msg = ""
    @periodo = params[:id] ?  Periodo.find(params[:id]) : Periodo.new(:proyecto_id => @proyecto.id)
    @periodo.update_attributes params[:periodo]
    msg @periodo
    redirect_to :action => 'etapas'
  end
    
  # en proyectos: eliminar un periodo
  def eliminar_periodo
    (periodo = Periodo.find(params[:id])).destroy
    msg periodo
    redirect_to :action => 'etapas'
  end
  
  def editar_fechas_peticion_prorroga
    tipo_periodo = params[:tipo_periodo] || "prorroga"
    render :partial => "fechas_peticion_prorroga", locals: {tipo_periodo: tipo_periodo}
  end

  def modificar_crear_fechas_peticion_prorroga
    tipo_periodo = params[:tipo_periodo] || "prorroga"
    fecha_limite = ("fecha_limite_peticion_" + tipo_periodo).to_sym
    fecha_aviso =  ("fecha_inicio_aviso_peticion_" + tipo_periodo).to_sym
    @proyecto.update_attributes( fecha_limite => params[:proyecto][fecha_limite],
                                 fecha_aviso => params[:proyecto][fecha_aviso] )
    msg @proyecto
    redirect_to :action => "etapas"
  end


  # --
  ########## PROYECTOS CONFINANCIADORES ##########
  # ++

  # Ordenado de proyectos
  def ordenado

  end

  # en proyectos: lista los proyectos cofinanciadores
  def proyecto_cofinanciador
    @proyectos_cofinanciadores = @proyecto.proyecto_x_proyecto
  end

  # en proyectos: crea un nuevo proyecto cofinanciador
  def editar_nuevo_proyecto_confinanciador
    @proyectos = Proyecto.order("nombre").collect{|p| [p.nombre, p.id] unless p.convenio? || p.agente.id == @proyecto.agente.id}.compact
    @proyecto_x_proyecto = ProyectoXProyecto.find_by_id(params[:id]) || ProyectoXProyecto.new
    render :partial => "formulario_proyecto_cofinanciador"
  end

  # en proyectos: modifica o crea un proyecto cofinanciador
  def modificar_crear_proyecto_cofinanciador
    proyecto_cofinanciador = @proyecto.proyecto_x_proyecto.find_by_id(params[:id]) || ProyectoXProyecto.new(:proyecto_id => @proyecto.id)
    proyecto_cofinanciador.update_attributes params[:proyecto_x_proyecto]
    msg proyecto_cofinanciador
    redirect_to :action => 'proyecto_cofinanciador'
  end

  # en proyectos: elimina un proyecto cofinanciador
  def eliminar_proyecto_cofinanciador
    proyecto_cofinanciador = @proyecto.proyecto_x_proyecto.find_by_id params[:id] 
    proyecto_cofinanciador.destroy
    msg_eliminar proyecto_cofinanciador
    redirect_to :action => 'proyecto_cofinanciador'
  end

  # --
  ########## IDENTIFICADOR FINANCIADOR ##########
  # ++
  def editar_identificador_financiador
    render :partial => "formulario_identificador_financiador"    
  end

  def modificar_identificador_financiador
    @financiadores = @proyecto.financiador.all(:order => "nombre")
    @proyecto.update_attribute "identificador_financiador", params[:proyecto][:identificador_financiador]
    render :update do |page|
      page.replace_html 'formulario', :inline => '<%= mensaje_error(@proyecto) %>'
      page.replace_html "financiador", :partial => "financiador"
      page.visual_effect :highlight, 'financiador' , :duration => 6
      page.call("Modalbox.resizeToContent")
    end
  end
  

end
#done

