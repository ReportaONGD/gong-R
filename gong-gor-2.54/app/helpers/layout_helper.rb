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
# metodos de navegación utilizados en el layout 

module LayoutHelper

  # Devuelve las secciones visibles para el usuario
  def secciones
    secciones = []
    # La ultima siempre sera salir
    secciones.push({ nombre: 'salir', url: '/inicio/usuario/salir', titulo: _('Salir de la aplicación') })
    # y administracion
    secciones.push({ nombre: 'administracion', url: '/administracion/proyecto/proyecto/', titulo: _('Administración del sistema') }) if @usuario_identificado.administracion
    # Y el resto de secciones segun los roles del usuario
    secciones.push({ nombre: 'socios', url: '/socios/gestion_socios/socio/', titulo: _('Gestión de Socios') }) if @usuario_identificado.socios
    secciones.push({ nombre: 'cuadromando', url: '/cuadrodemando/economico', titulo: _('Cuadro de Mando') }) if @usuario_identificado.cuadromando
    secciones.push({ nombre: 'documentos', url: '/documentos/', titulo: _('Gestión Documental') }) if @usuario_identificado.documentos
    secciones.push({ nombre: 'agentes', url: '/agentes/', titulo: _('Gestión de Agentes y Delegaciones') }) if @usuario_identificado.agentes 
    secciones.push({ nombre: 'proyectos', url: '/proyectos/', titulo: _('Gestión de Proyectos') }) if @usuario_identificado.proyectos
    # Desactivamos el boton de la seccion de programas marco hasta que esten preparadas sus vistas
    secciones.push({ nombre: 'programas_marco', url: '/programas_marco/', titulo: _('Programas Marco') }) if @usuario_identificado.programas_marco && false
    # La primera siempre sera inicio    
    secciones.push({ nombre: 'inicio', url: '/inicio/info/', titulo: _('Página inicial') })
    Plugin.activos.each{ |plugin|  secciones = eval(plugin.clase)::seccion_menu(@usuario_identificado, secciones) if eval(plugin.clase).respond_to?('seccion_menu')  }
    return secciones
  end

  def ruta_seccion
    case params[:seccion]
      when "administracion" then
        cadena = _("Administración del sistema")
      when "informes_aecid" then
        cadena = _("Justificación a AECID (GONG-R)")
      when "programas_marco" then
        cadena = _("Programas Marco")
      when "proyectos" then
        if @proyecto
          cadena = _("Proyecto")
          cadena = _("Convenio") if @proyecto.convenio?
          # Para los PACs dejamos como enlace el convenio
          if @proyecto.convenio_id
            ruta_convenio = {:menu => :resumen, :controller => :info, :action => :index, :proyecto_id => @proyecto.convenio_id} 
            cadena = _("PAC") + " (" + link_to(truncate(h(@proyecto.convenio.nombre), :length =>20), ruta_convenio) + ")"
          end
          cadena += " : " + h(@proyecto.nombre)
        else
          cadena = _("Listado de Proyectos y Convenios asignados")
        end
      when "socios" then
        cadena = _("Gestión de socios")
      when "cuadromando" then
        cadena = _("Cuadro de Mando")
      when "agentes" then
	cadena = _("Agente") 
        cadena += "&nbsp;:&nbsp;"
        if @agente
          cadena += h(@agente.nombre)
        else
          cadena += _("Listado de agentes asignados")
        end
      when "inicio" then
        cadena = _("Usuario") + " <i>".html_safe + h(@usuario_identificado.nombre) + "</i>".html_safe
      when "documentos" then
        cadena = _("Documentos Comunes")
      else
        cadena = params[:seccion]
    end
    return cadena.html_safe
  end

  def menu
    objs_seccion = menu_seccion
    obj_menu = objs_seccion.find {|c| c[:url][:menu] == params[:menu].to_s} if params[:menu]
    obj_menu = objs_seccion.find {|c| c[:url][:controller] == params[:controller]} unless params[:menu]
    texto_menu = obj_menu[:rotulo] if obj_menu
    # Ponemos esto por si el menu de entrada (Infocontroller) no esta habilitado pero si que lo estan otras opciones del menú
    texto_menu = _("Otras opciones") unless obj_menu
    unless objs_seccion.size == 0 # Si NO hay un controlador no pìntamos el menu
      cadena_menu = "<ul class='menu'>"
      for menu in objs_seccion
         cadena_menu += "<li>" + link_to(menu[:rotulo], menu[:url]) + "</li>" unless (@proyecto && @proyecto.convenio? && !menu[:convenio])
      end
      cadena_menu += "</ul>"
    end
    cadena = link_to(texto_menu, :controller => params[:controller])
    return cadena << (cadena_menu || "").html_safe
  end

  def menu_acciones otros={}
    cadena_acciones = "<ul class='menu'>"
    #acciones = controladores_menu otros
    #texto_accion = acciones.find {|c| c[:url][:controller] == params[:controller]}[:rotulo]
    accion = controladores_menu(otros).find {|c| c[:url][:controller] == params[:controller]}
    texto_accion = accion[:rotulo] if accion
    for menu in controladores_menu otros
      unless @proyecto && ( (@proyecto.convenio_id && menu[:pac] == false) || (@proyecto.convenio? && menu[:convenio] == false) || (@proyecto.convenio_id.nil? && menu[:proyecto] == false) )
        # Esta chapu la tenemos que hacer asi porque si hacemos el link_to para seleccionada y luego para cadena_acciones, los enlaces de los plugins no se generan bien
        enlace = link_to(menu[:rotulo], menu[:url])
        seleccionada = enlace if menu[:url][:controller] == params[:controller] and (  menu[:url][:action] ?  menu[:url][:action] == params[:action] : true )
        cadena_acciones += "<li>" + enlace + "</li>"
      end
    end
    cadena_acciones += "</ul>"
    cadena = otros[:menu].nil? && seleccionada ? seleccionada.html_safe : link_to("Otras opciones")
    return cadena << cadena_acciones.html_safe
  end


  # Para cada seccion se definen aqui los controladores a los que se tendran acceso.
  # TODO: Estaria bien que cambiemos esto por controladores_administracion, controladores_proyectos, controladores_ ... etc
  def menu_seccion seccion=params[:seccion]
    objetos = case seccion 
        when "cuadromando"
              [	{:rotulo => _("Cuadro de Mando Técnico"), :url => {:menu => "tecnico"}}, 
	     	{:rotulo => _("Cuadro de Mando Económico"), :url => {:menu => "economico"}} ]
        when "proyectos"
            if params[:action] == "listado_usuario"
              []
            else
              menu_seccion_x_rol([ { :rotulo => _("Resumen"), :convenio => true, :url => {:menu => "resumen"}},
		                    { :rotulo => _("Configuración"), :convenio => true, :url => {:menu => "configuracion"}},
                        { :rotulo => _("Identificación"), :convenio => true, :url => { :menu => "identificacion"}},
		                    { :rotulo => _("Formulación"), :convenio => true, :url => { :menu => "formulacion"}},
		                    { :rotulo => _("Ejecución Técnica"), :convenio => true, :url => { :menu => "ejecucion_tecnica"}} ,
                        { :rotulo => _("Ejecución Económica"), :convenio => false, :url => { :menu => "ejecucion_economica"}},
		                    { :rotulo => _("Documentos"), :convenio => true, :url => { :menu => "documentos_proyecto"} }])                         
            end
        when "agentes"
          if params[:action] == "listado_usuario"
            []
          else
             menu_seccion_x_rol([ { :rotulo => _("Resumen"), :url => {:menu => "resumen_agente"} },
                       { :rotulo => _("Configuración"), :url => {:menu => "configuracion_agente"} },
                       { :rotulo => _("Gestión Económica"), :url => {:menu => "economico_agente"} },
                       { :rotulo => _("Documentos"), :url => { :menu => "documentos_agente"} }])

           end
        when "administracion"
            [ { :rotulo => _("Agentes"), :url => {:menu => "agente", :controller => "agente"}},
              { :rotulo => _("Cuentas"), :url => {:menu => "cuentas", :controller => "libro"}},
              { :rotulo => _("Programas Marco"), :url => {:menu => "programa_marco", :controller => "programa_marco", :action => "listado"}},
              { :rotulo => _("Convocatorias"), :url => {:menu => "convocatoria", :controller => "convocatoria", :action => "listado"}},
              { :rotulo => _("Proyectos"), :url => {:menu => "proyecto", :controller => "proyecto"}},
              { :rotulo => _("Usuarios"), :url => {:menu => "usuario", :controller => "usuario"}},
              { :rotulo => _("Grupos de Usuarios"), :url => {:menu => "grupo", :controller => "grupo_usuario"}},
              { :rotulo => _("Espacios"),  :url => {:menu => "espacio", :controller => "espacio"}},
              { :rotulo => _("Parametrización"), :url => {:menu => "datos_parametrizacion", :controller => "datos_basicos"}},
              { :rotulo => _("Configuración del sistema"), :url => {:menu => "datos_configuracion", :controller => "gor_config"}} ]
        when "socios"
            [ {:rotulo => _("Socios"),  :url => {:menu => "gestion_socios", :controller => "socio"}},
              {:rotulo => _("Listado de Pagos"),  :url => {:menu =>"pagos_socios", :controller => "pago_socio"}},
              {:rotulo => _("Generar Pagos"), :url => {:menu => "pagos_socios", :controller => "pago_socio", :action => "generar_pagos"}},
              {:rotulo => _("Vista Resumen Socios"),  :url => {:menu => "resumen_socios", :controller => "resumen_socio", :action => "categorias"}},
              {:rotulo => _("Generación modelo 182"), :url => {:menu => "informe_socios", :controller => "resumen_socio", :action => "modelo_182"}} ]

        when "documentos"
            [ {:rotulo => _("Documentos generales"), :url => {:menu => "documentos_generales", :controlador => "documento"}}]

        when "inicio"
            [ {:rotulo => _("Vista general"), :url => {:controller => "info"}},
              {:rotulo => _("Tareas"), :url => {:controller => "tarea"}} ]
        else
          []
    end

    Plugin.activos.collect { |plugin| objetos = eval(plugin.clase)::menu_seccion(seccion, objetos) if eval(plugin.clase).respond_to?('menu_seccion') }
    return objetos 
  end

  # Se llama al metodo menu_acciones del controlador en el que nos encontramos para ver las acciones que ofrece para la navegacion dicho controlador en dicha seccion.
  def controladores_menu otros={}
    menu = otros[:menu] || params[:menu]
    objetos = case menu.to_s
    when "resumen"
      [{:rotulo => _("Cuadro resumen"), :url => { :controller => "info" } }, 
       {:rotulo => _("Tareas"), :url => { :controller => "tarea" }, :otros => ["comentario"] }, 
       {:rotulo => _("Resumen Matriz"), :url => { :controller => "resumen_proyecto", :action => "matriz"}},
       {:rotulo => _("Resumen Presupuesto"), :url => { :controller => "resumen_proyecto", :action => "presupuesto"}},
       {:rotulo => _("Previsión de Gastos mensuales"), :url => { :controller => "resumen_proyecto", :action => "presupuesto_detallado"}},
       {:rotulo => _("Resumen Gasto"), :url => { :controller => "resumen_proyecto", :action => "gasto"}},
       {:rotulo => _("Arqueos de caja/cuenta"), :url => { :controller => "resumen_proyecto", :action => "arqueo_caja"}},
       {:rotulo => _("Resumen de Transferencias"), :url => { :controller => "resumen_proyecto", :action => "transferencia"}},
       {:rotulo => _("Resumen Tesoreria"), :url => { :controller => "resumen_proyecto", :action => "estado_tesoreria"}},
       {:rotulo => _("Resumen de Proveedores"), :url => { :controller => "resumen", :action => "proveedor"}},
       {:rotulo => _("Resumen de Seguimiento Técnico"), :url => { :controller => "resumen_proyecto", :action => "seguimiento_tecnico"}},
       {:rotulo => _("Resumen Ejecutivo"), :url => { :controller => "resumen_proyecto", :action => "resumen_ejecutivo"}},
       {:rotulo => _("Resumen Empleados"), :url => { :controller => "resumen_empleados_proyecto", :action => "resumen_empleados"}},
       {:rotulo => _("Usuarios Asignados"), :url => { :controller => "usuario", :action => "listado"} } ]

    when "resumen_agente"
      [{:rotulo => _("Cuadro resumen"), :url => {:controller => "info"}},
       {:rotulo => _("Tareas"), :url => {:controller => "tarea"}},
       {:rotulo => _("Presupuesto"), :url => {:controller => "resumen_agente", :action => "presupuesto"}},
       {:rotulo => _("Seguimiento Gasto"), :url => {:controller => "resumen_agente", :action => "gasto"}},
       {:rotulo => _("Arqueo de Cuenta/Caja"), :url => {:controller => "resumen_agente", :action => "arqueo_caja"}},
       {:rotulo => _("Resumen de Proyectos"), :url => {:controller => "resumen_proyectos_agente", :action => "proyectos"}},
       {:rotulo => _("Previsión de Gastos"), :url => {:controller => "resumen_proyectos_agente", :action => "cronograma_proyectos"}},
       {:rotulo => _("Transferencias a Proyectos"), :url => {:controller => "resumen_proyectos_agente", :action => "transferencia"}},
       {:rotulo => _("Resumen de Proveedores"), :url => {:controller => "resumen", :action => "proveedor"}},
       {:rotulo => _("Seguimiento convocatorias"), :url => {:controller => "convocatoria"}},
       {:rotulo => _("Resumen Ejecutivo"), :url => {:controller => "resumen_proyectos_agente", :action => "resumen_ejecutivo"}},
       {:rotulo => _("Resumen de Personal"), :url => {:controller => "resumen_empleados_agente", :action => "resumen_empleados"}}] 

    when "configuracion"
      [{:rotulo => _("Estado del proyecto"), :url => { :controller => "estado" } }, 
       {:rotulo => _("Etapas, periodos y tasas de cambio"), :url => { :controller => "datos_proyecto", :action => "etapas"}, :otros => ["tasa_cambio", "tarea"] }, 
       {:rotulo => _("Relaciones del proyecto"), :pac => false, :url => { :controller => "datos_proyecto", :action => "relaciones"}},
       {:rotulo => _("Proyectos cofinanciadores"), :convenio => false, :url => { :controller => "datos_proyecto", :action => "proyecto_cofinanciador"}},
       {:rotulo => _("Partidas del financiador"), :pac => false, :url => { :controller => "partida_financiacion"}},
       {:rotulo => _("Subpartidas"), :pac => false, :url => {:controller => "subpartida"}},
       {:rotulo => _("Cálculo de Remanentes"), :convenio => false, :proyecto => false, :url => { :controller => "remanente"}},
       {:rotulo => _("Relación de Personal"), :pac => false, :url => { :controller => "personal"}},
       {:rotulo => _("Exportación partidas/subpartidas"), :pac => false, :url => { :controller => "exportacion" } },
       {:rotulo => _("Importación partidas/subpartidas"), :pac => false, :url => { :controller => "importacion" } }   ]

    when "configuracion_agente"
      [{ :rotulo => _("Etapas y tasas de cambio"),:url => {:controller => "datos_agente", :action => "etapas"}, :otros => ["tasa_cambio"]},
       { :rotulo => _("Subpartidas del agente"), :url => {:controller => "subpartida"}},
       { :rotulo => _("Monedas del agente"), :url => {:controller => "datos_agente", :action => "monedas" }},
       { :rotulo => _("Convocatorias"), :url => {:controller => "convocatoria", :action => "listado" }},
       { :rotulo => _("Usuarios"), :url => {:controller => "usuario", :action => "listado"}},
       { :rotulo => _("Proyectos gestionados"), :url => {:controller => "proyecto", :action => "listado"}, :otros => ["relaciones_usuario", "grupo_usuario"] },
       { :rotulo => _("Libros del agente"), :url => {:controller => "libro", :action => "listado"}, :otros => ["relaciones_usuario", "grupo_usuario"]},
       { :rotulo => _("Proveedores"), :url => {:controller => "proveedor", :action => "listado" }},
       { :rotulo => _("Tipos de Contrato"), :url => {:controller => "tipo_contrato", :action => "listado" }},
       { :rotulo => _("Workflow de Contratos"), :url => {:controller => "workflow_contrato" }}, 
       { :rotulo => _("Empleados"), :url => {:controller => "empleado" }} 
      ]

    when "identificacion"
      [{:rotulo => _("Información del Proyecto"), :url => { :controller => "datos_proyecto_dinamicos", :action => "listado" } },
       {:rotulo => _("Titulares de derecho"), :url => { :controller => "beneficiarios", :action => "listado" } }
      ]

    when "formulacion"
      [{:rotulo => _("Matriz"), :url => { :controller => "matriz", :action => "matriz" } },
       {:rotulo => _("Subactividades"), :convenio => false, :url => { :controller => "matriz", :action => "subactividades" } },
       {:rotulo => _("Cronograma"), :url => { :controller => "cronograma", :action => "listado" } },
       {:rotulo => _("Indicadores"), :url => { :controller => "indicador", :action => "listado" }, :otros => ["comentario"] },
       {:rotulo => _("Presupuesto por partidas"), :url => { :controller => "presupuesto_proyectos" }, :otros => ["comentario","marcado","presupuesto_detallado"] }, 
       {:rotulo => _("Presupuesto por actividades"), :url => { :controller => "presupuesto_actividad", :action => "listado" }, :otros => ["comentario","marcado","presupuesto_detallado"] }, 
       {:rotulo => _("Documento Formulación"), :url => { :controller => "resumen_proyecto", :action => "documento_formulacion"}},
       {:rotulo => _("Inicio Actividades"), :url => { :controller => "resumen_proyecto", :action => "inicio_actividades"}},
       {:rotulo => _("Exportación matriz/presupuesto"), :url => { :controller => "exportacion" } }, 
       {:rotulo => _("Importación matriz/presupuesto"), :url => { :controller => "importacion" } }] 
 
    when "ejecucion_tecnica"
      [{:rotulo => _("Cronograma de Seguimiento"), :url => { :controller => "cronograma", :action => "listado" } },
       {:rotulo => _("Seguimiento de OEs y Resultados"), :url => { :controller => "matriz", :action => "matriz" }, :otros => ["comentario"] },
       {:rotulo => _("Seguimiento Actividades"), :url => { :controller => "actividad", :action => "listado" }, :otros => ["comentario"] },
       {:rotulo => _("Seguimiento Indicadores"), :url => { :controller => "indicador", :action => "listado" }, :otros => ["comentario"] },
       {:rotulo => _("Seguimiento Fuentes de Verificación"), :url => { :controller => "fuente_verificacion", :action => "listado_fuentes_verificacion" }, :otros => ["comentario","documento"] },
       {:rotulo => _("Información de Seguimiento"), :url => { :controller => "datos_proyecto_dinamicos", :action => "listado" } }, 
       {:rotulo => _("Informe Final"), :url => { :controller => "resumen_proyecto", :action => "informe_final"}}]

    when "ejecucion_economica"
      [{:rotulo => _("Gastos"), :convenio => false, :url => { :controller => "gasto_proyectos" }, :otros => ["comentario","documento","marcado", "pago"] },
       {:rotulo => _("Gastos cofinanciables"), :convenio => false, :url => { :controller => "gasto_proyectos", :action => "cofinanciables" } },
       {:rotulo => _("Numeración facturas"), :convenio => false, :url => { :controller => "gasto_proyectos", :action => "listado_facturas" } },
       {:rotulo => _("Movimientos"), :convenio => false, :url => { :controller => "transferencia" }, :otros => ["comentario","documento","marcado"] },
       {:rotulo => _("Contratos"), :convenio => false, :url => { :controller => "contrato" }, :otros => ["comentario","marcado","estado_contrato"] },
       {:rotulo => _("Exportación gastos/movimientos"), :convenio => false, :url => { :controller => "exportacion" } },
       {:rotulo => _("Importación gastos/movimientos"), :convenio => false, :url => { :controller => "importacion" } }] 

    when "economico_agente"
      [{:rotulo => _("Presupuesto de Ingresos"), :url => {:controller => "presupuesto_ingresos" }, :otros => ["comentario","presupuesto_detallado","marcado"]},
       {:rotulo => _("Presupuesto de Gastos"), :url => {:controller => "presupuesto_agentes" }, :otros => ["comentario","presupuesto_detallado","presupuesto_proyectos","marcado"]},
       {:rotulo => _("Presupuesto de Personal"), :url => {:controller => "presupuesto_empleado_agentes" }, :otros => ["comentario", "marcado"]},
       {:rotulo => _("Ingresos"), :url => {:controller => "ingreso" }, :otros => ["comentario","marcado"]},
       {:rotulo => _("Gastos"), :url => {:controller => "gasto_agentes" }, :otros => ["comentario","documento", "pago","marcado"]},
       {:rotulo => _("Movimientos"), :url => {:controller => "transferencia"}, :otros => ["comentario","documento"]},
       {:rotulo => _("Contratos"), :url => { :controller => "contrato" }, :otros => ["estado_contrato","comentario","documento","marcado"] },
       {:rotulo => _("Exportación Económica"), :url => { :controller => "exportacion" }},
       {:rotulo => _("Importación Económica"), :url => {:controller => "importacion" }}
      ]

    when "datos_parametrizacion"
      [{ rotulo: _("Área Geográfica"), url: { controller: "datos_basicos", action: "listado_area_geografica"} },
       { rotulo: _("Área de Actuación"), url: { controller: "datos_basicos", action: "listado_area_actuacion"} },
       { rotulo: _("Categorías de Área de Actuación"), url: { controller: "datos_basicos", action: "listado_categoria_area_actuacion"}},
       { rotulo: _("Categorías de Sector de Intervención"), url: { controller: "datos_basicos", action: "listado_categoria_sector_intervencion"}},
       { rotulo: _("Datos de proyecto"), url: { controller: "datos_basicos", action: "listado_definicion_dato"}},
       { rotulo: _("Estado tareas"), url: { controller: "datos_basicos", action: "listado_estado_tarea"}},
       { rotulo: _("Etiquetas Documentales"), url: { controller: "etiqueta"}},
       { rotulo: _("Etiquetas Técnicas"), url: { controller: "datos_basicos", action: "listado_etiqueta_tecnica"}},
       { rotulo: _("Grupos de Datos de Proyecto"), url: { controller: "datos_basicos", action: "listado_grupo_dato_dinamico"}},
       { rotulo: _("Indicadores Generales"), url: { controller: "datos_basicos", action: "listado_indicador_general" } },
       { rotulo: _("Marcado"), url: { controller: "datos_basicos", action: "listado_marcado"}},
       { rotulo: _("Monedas"), url: { controller: "datos_basicos", action: "listado_moneda"}},
       { rotulo: _("Partidas de Gastos"), url: { controller: "datos_basicos", action: "listado_partida"}},
       { rotulo: _("Partidas de Ingresos"), url: { controller: "datos_basicos", action: "listado_partida_ingreso"}},
       { rotulo: _("País"), url: { controller: "datos_basicos", action: "listado_pais"}},
       { rotulo: _("Plantillas de Exportación"), url: { controller: "documento"}},
       { rotulo: _("Sector de Intervención"), url: { controller: "datos_basicos", action: "listado_sector_intervencion"}},
       { rotulo: _("Sector de Población"), url: { controller: "datos_basicos", action: "listado_sector_poblacion"}},
       { rotulo: _("Subtipos de Movimiento"), url: { controller: "datos_basicos", action: "listado_subtipo_movimiento"}},
       { rotulo: _("Tipos de Agentes"), url: { controller: "tipo_agente", action: "listado"}},
       { rotulo: _("Tipos de Contrato"), url: { controller: "tipo_contrato", action: "listado"}},
       { rotulo: _("Tipos de Convocatorias"), url: { controller: "tipo_convocatoria"}},
       { rotulo: _("Tipos de Periodos"), url: { controller: "datos_basicos", action: "listado_tipo_periodo"}}, 
       { rotulo: _("Tipos de Tareas"), url: { controller: "datos_basicos", action: "listado_tipo_tarea"}},
       { rotulo: _("Workflow de Contratos"), url: { controller: "workflow_contrato" }},
       { rotulo: _("Workflow de Proyectos"), url: { controller: "definicion_estado" }},
      ]
    when "datos_configuracion"
      [
       { rotulo: _("Backup"), url: { controller: "backup"} },
       { rotulo: _("Parámetros de configuración"), url: { controller: "gor_config"} },
       { rotulo: _("Plugins"), url: { controller: "plugin"} },
       { rotulo: _("Roles de Usuario"), url: { controller: "rol"} },
      ]
    
    when "documentos_proyecto"
         [{:rotulo => (_"Documentos por espacios"), :url => { :controller => "documento" }, :otros => ["comentario"]},
          {:rotulo => _("Busqueda por etiquetas"), :url => { :controller => "documento_busqueda" }, :otros => ["comentario"]},
          {:rotulo => _("Documentos de gastos"), :url => { :controller => "documento_busqueda", :action => "listado_gastos"}},
          {:rotulo => _("Documentos de transferencias"), :url => { :controller => "documento_busqueda", :action => "listado_transferencias"}}] 

    when "documentos_agente"
         [{:rotulo => (_"Documentos por espacios"), :url => { :controller => "documento" }, :otros => ["comentario", "contrato"]},
          {:rotulo => _("Documentos de gastos"), :url => { :controller => "documento_busqueda", :action => "listado_gastos"}},
          {:rotulo => _("Documentos de transferencias"), :url => { :controller => "documento_busqueda", :action => "listado_transferencias"}}] 

    when "documentos_generales"
         [{:rotulo => (_"Documentos por espacios"), :url => { :controller => "documento" }},
          {:rotulo => _("Busqueda por etiquetas"), :url => { :controller => "documento_busqueda" }}] 
    else
      []
    end

    Plugin.activos.collect { |plugin| objetos = eval(plugin.clase)::controladores_menu(menu, objetos) if eval(plugin.clase).respond_to?('controladores_menu') }
    # Elimina los menus que no estan siendo utilizados por el rol del usuario
    objetos = controladores_menu_x_rol objetos, menu.to_s if @proyecto or @agente
    
    return objetos
  end

  # Genera un boton de información
  def mensaje_informacion
    objeto_id = "ayuda_menu"
    cadena = ('<span id="' + objeto_id + '" class="popup_link">').html_safe + icono("informacion", _("Ayuda")) + '</span>'.html_safe
    cadena << ('<div id="' + objeto_id + '_popup" class="popup" style="display:none">').html_safe
    texto_ayuda(params[:seccion], params[:controller], params[:action]).each do |linea|
      cadena << simple_format(linea)
    end
    cadena << eval( 'javascript_tag "new Popup(\"' + objeto_id + '_popup\",\"' + objeto_id + '\", {position:\'auto\',trigger:\'click\'} )"' ).html_safe
    return cadena << '</div>'.html_safe
  end

  # Elimina los menus que no estan siendo utilizados por el rol del usuario en caso de que no tenga ningun submenu asociado
  def menu_seccion_x_rol menus_de_seccion=[]    
    menus_a_eliminar = []
    # Recorremos los menus para ver si tiene submenus asociados y para poner el primer menu por defecto
    menus_de_seccion.each do |objeto|
      controladores = controladores_menu({:menu => objeto[:url][:menu]})
      # Si no existen controladores habilitados pra el menu lo eliminamos
      if controladores.empty?
        menus_a_eliminar.push(objeto)
      else
        # Si existe algun controlador habilitado para el menu ponemos como ruta del menu el primer controlador habilitado que tenemos
        objeto[:url][:controller] = controladores.first[:url][:controller]
        objeto[:url][:action] = controladores.first[:url][:action] if controladores.first[:url][:action]
      end
    end
    return (menus_de_seccion - menus_a_eliminar)
  end


  # Elimina los sub-menus que no estan siendo utilizados por el rol del usuario
  def controladores_menu_x_rol controladores=[], menu
    # Buscamos los permisos del rol del usuario en el proyecto seleccionado y para el menu seleccionado
    rel = @usuario_identificado.usuario_x_proyecto.find_by_proyecto_id(@proyecto.id) if @proyecto
    # Añadimos una condicion mas para la siguiente linea por que @agente es una variable que se carga no se donde en algun caso de proyectos
    rel = @usuario_identificado.usuario_x_agente.find_by_agente_id(@agente.id) if @agente and params[:seccion] == "agentes"
    permisos = rel ? PermisoXRol.where(rol_id: rel.rol_id, menu: menu) : []
    permisos = permisos.collect {|p| p.controlador}
    controladores_a_eliminar = []
    # Recorremos el menu de controladores para ver si tiene permisos
    controladores.each do |controlador|
      controladores_a_eliminar.push(controlador) unless permisos.include? controlador[:url][:controller]
    end
    # devolvemos solo los controladores sobre los que el usuario tiene permisos asociados
    return (controladores - controladores_a_eliminar)
  end

end
