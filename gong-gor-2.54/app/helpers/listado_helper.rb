# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2014 Free Software's Seed
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
# helpers utilizados en listados 

module ListadoHelper

  #-- METODOS DE  LISTADO
  #++
  # el array que devuelve el helper reponde al modelo : rotulo, ancho de columna (hasta 9_2, 4,5), atributo y si true entonces con posibilidad de ordenado si se pasa a cabecera_listado
  def campos_listado modelo
    campos = case modelo
      #when "proyecto" then [[_("Nombre"),"1y1_4", "nombre", true ], [_("Título"),"3_2", "titulo", false ], [_("Estado"),"1_2","estado_actual.definicion_estado.nombre", true], [_("Convocatoria"),"2_3", "convocatoria.codigo", true], [_("País"),"1_2", "pais_principal.nombre", true] ]
      when "proyecto" then [[_("Nombre"),"1y1_4", "nombre", "proyecto.nombre" ], [_("Título"),"3_2", "titulo", false ], [_("Estado"),"1_2","estado_actual.definicion_estado.nombre", "definicion_estado.nombre"], [_("Convocatoria"),"2_3", "convocatoria.codigo", true], [_("País"),"1_2", "paises_definidos", false] ]
      when "proyecto_ampliado" then [[_("Nombre"),"1y1_4", "nombre"], [_("Título"),"3_2", "titulo"], [_("Estado"),"1_2","estado_actual.definicion_estado.nombre"], [_("Convocatoria"),"2_3", "convocatoria.codigo"], [_("País"),"1_2", "paises_definidos"]]
      when "proyecto_resumido" then [[_("Nombre"),"1y1_4", "nombre", true ], [_("Título"),"3_2", "titulo", false ], [_("Estado"),"1_2","estado_actual.definicion_estado.nombre", true] , [_("País"),"1_2", "pais_principal.nombre", true] ]
      when "pac" then [[_("Nombre"),"2", "nombre", true ], [_("Título"),"3_2", "titulo", false ], [_("Estado"),"1_2","estado_actual.definicion_estado.nombre"]]
      when "programa_marco" then [[_("Nombre"), "3_2", "nombre", true], [_("Objetivo"), "2", "objetivo_general"], [_("Activo"), "1_3", "activo"]]
      when "usuario_adm" then [[_("Usuario"),"1", "nombre" ],  [_("Nombre completo"),"2", "nombre_completo"], [_("Correo"),"1","correoe"] ,[_("Admin."),"1_3", "administracion"], [_("Bloq."),"1_3", "bloqueado", true] ]
      when "usuario" then [[_("Usuario"),"1", "nombre" ],  [_("Nombre completo"),"2", "nombre_completo"], [_("Correo"),"1","correoe"] ]
      when "usuario_prj" then  [[_("Usuario"),"3_4", "usuario.nombre" ],  [_("Nombre completo"),"3_2", "usuario.nombre_completo"], [_("Correo"),"1","usuario.correoe"], [ _("Rol"), "3_4", "rol_asignado.nombre"], [_("Grupo"), "3_4", "grupo_usuario.nombre"] ]
      when "usuario_x" then [ [ _("Usuario"), "1", "usuario.nombre" ],[ _("Rol"), "3_4", "rol_asignado.nombre"] ]
      when "usuario_x_proyecto" then [ [_("Proyecto"), "1", "proyecto.nombre"], [_("Convocatoria"),"1", "proyecto.convocatoria.codigo"], [_("Estado"), "1", "proyecto.estado_actual.definicion_estado.nombre"], [ _("Rol"), "3_4", "rol_asignado.nombre"]]
      when "usuario_x_agente" then  [ [_("Agente"), "3", "agente.nombre"], [ _("Rol"), "3_4", "rol_asignado.nombre"]]
      when "usuario_x_libro" then  [ [_("Libro"), "2", "libro.nombre"], [_("Moneda"),"1_3", "libro.moneda.abreviatura"], [_("Cuenta"),"3_2", "cuenta"] ]
      when "grupo_usuario" then [ [_("Nombre"), "2", "nombre" ], [_("Ocultar en proyectos"), "1_2", "ocultar_proyecto"], [_("Asignar a nuevos proyectos con rol"), "2_3", "asignar_proyecto_rol.nombre"] ]
      when "grupo_usuario_x" then [[ _("Grupo"), "1", "grupo_usuario.nombre" ], [ _("Rol"), "3_4", "rol_asignado.nombre"] ]
      when "convocatoria" then [[ _("Código"), "1", "codigo", true], [_("Nombre"), "3_2", "nombre", true], [_("Financiador"), "1", "agente.nombre", true], [_("Fecha Pub."), "1_2", "fecha_publicacion"], [_("Fecha Pres."), "1_2", "fecha_presentacion"] ]
      when "tipo_convocatoria" then [[ _("Nombre"), "2", "nombre" ]]
      when "tipo_agente" then [[ _("Nombre"), "2", "nombre" ]]
      when "gor_config" then [[ _("Parámetro"), "1", "name" ], [_("Valor"), "1", "value"], [_("Descripción"), "5_2", "description"] ]
      when "subcuenta_contable" then [[ _("Código"), "2_3", "codigo", true], [_("Descripción"), "2", "descripcion"], [_("Asociado"), "1_3", "esta_vinculado?"], [_("Tipo"), "1_2", "elemento_contable_type", true], [_("Elemento"), "1", "elemento_contable.codigo_nombre"] ]
      when "pais" then
        if params[:seccion] == "administracion"
          [["&nbsp;","1_2","codigo"], [_("País"),"2", "nombre", true], [_("Área Geográfica"), "2", "area_geografica.nombre", true]]
        else
          [[_("País"),"1", "nombre"], [_("Área Geográfica"), "1_2", "area_geografica.nombre"]]
        end
      when "moneda" then [[_("Moneda"),"1", "nombre", "nombre"], [_("Abreviatura"),"1_2", "abreviatura", "abreviatura"]]
      when "partida" then [ [_("Código"),"1_2", "codigo", true ],[_("Nombre"),"1", "nombre", true], [_("Tipo"),"1_2", "tipo_mayusculas"], [_("Descripción"),"1", "descripcion"], [_("Ocultar en agente"),"1_2", "ocultar_agente", true], [_("Ocultar en proyecto"),"1_2", "ocultar_proyecto", true], [_("Tipo personal"),"1_2", "tipo_empleado", true] ]
      when "subpartida" then [ [_("Nombre"), "5_2", "nombre", "subpartida.nombre"], [_("Partida"), "2","partida.codigo_nombre" + (@proyecto ? " " + @proyecto.id.to_s : ""), "partida.codigo"] ]
      when "area_geografica" then [[_("Nombre"), "3_2", "nombre",true], [_("Descripción"),"2", "descripcion"]]
      when "sector_poblacion" then [[_("Nombre"), "3_2", "nombre",true ], [_("Descripción"),"2", "descripcion"]]
      when "categoria_sector_intervencion" then [[_("Nombre"), "3_2", "nombre",true], [_("Descripción"),"2", "descripcion"]]
      when "sector_intervencion" then [[_("Nombre"), "3_2", "nombre",true], [_("Categoría"), "1", "categoria_sector_intervencion.nombre"], [_("Descripción"),"2", "descripcion"]]
      when "categoria_area_actuacion" then [[_("Nombre"), "3_2", "nombre",true], [_("Descripción"),"2", "descripcion"]]
      when "area_actuacion" then [[_("Nombre"), "3_2", "nombre", true], [_("Categoría"), "1", "categoria_area_actuacion.nombre"], [_("Descripción"),"2", "descripcion"]]
      when "etiqueta_tecnica" then [[_("Nombre"), "3_2", "nombre", true], [_("Descripción"),"2", "descripcion"]]

      when "sector_poblacion_relaciones" then [[_("Nombre"), "1", "nombre",true ], [_("Porcentaje"), "1_2", "porcentaje_x_proyecto " + @proyecto.id.to_s]]
      when "categoria_relaciones" then [[_("Categoría"), "1", "nombre"], [_("Porcentaje"), "1_2", "porcentaje"]]
      when "sector_intervencion_relaciones" then [[_("Nombre"), "1", "nombre",true], [_("Porcentaje"), "1_2", "porcentaje_x_proyecto " + @proyecto.id.to_s]]
      when "area_actuacion_relaciones" then [[_("Nombre"), "1", "nombre", true], [_("Porcentaje"), "1_2", "porcentaje_x_proyecto " + @proyecto.id.to_s]]

      when "agente" then [[_("Nombre"), "1", "nombre", true], [_("Nombre completo"), "3_2", "nombre_completo"], [_("País"), "1", "pais.nombre"], [_("Financiador"), "1_2", "financiador", true], [_("Implementador"), "1_2", "implementador", true]]
      when "financiacion" then [[_("Nombre"),"1", "nombre", true ],  [_("Título"),"2", "titulo"], [_("Financiador"),"1","financiador.nombre", true]]
      when "libro" then [[_("Nombre"),"3_2", "nombre", true ],[_("Agente"),"3_4", "agente.nombre", true], [_("Moneda"),"1_3", "moneda.abreviatura"], [_("País"),"1_2", "pais.nombre", true], [_("Cuenta"),"3_4", "cuenta"], [_("Tipo"),"1_2", "tipo.capitalize", true], [_("Bloq."),"1_3", "bloqueado", true] ]
      when "libro_relaciones" then [[_("Nombre"),"3_2", "nombre", true ],[_("Agente"),"3_4", "agente.nombre", true], [_("Moneda"),"1_3", "moneda.abreviatura"], [_("País"),"1_2", "pais.nombre", true], [_("Cuenta"),"1", "cuenta"], [_("Tipo"),"1_2", "tipo.capitalize", true]]
      when "beneficiarios" then [[_("País"), "1", "pais.nombre"], [_("Total Directos"), "2_3_td", "directos"], [_("Total Indirectos"), "2_3_td", "indirectos"], [_("Población Total"), "2_3_td", "poblacion_total_de_la_zona"]]
      when "proyecto_cofinanciado" then [[_("Nombre"), "1", "nombre", true], [_("Título"),"5_2", "titulo", false ] ]
      when "proyecto_cofinanciador" then [[_("Nombre"), "1", "proyecto_cofinanciador.nombre", false], [_("Título"),"5_2", "proyecto_cofinanciador.titulo", false ], [_("Importe"),"1_2", "importe", false ], [_("Pública"), "1_3", "financiacion_publica", false], [_("Privada"), "1_3", "financiacion_privada", false] ]
      when "documento" then [[_("Nombre"), "3_2", "adjunto_file_name", true], [_("Descripción"), "3_2", "descripcion"], [_("Modificado"), "1_2", "updated_at", true], [_("Usuario"), "2_3", "usuario.nombre", true] ]
      when "documento_gastos" then [[_("Nombre"), "2", "adjunto_file_name"], [_("G.Importe"), "1_2_td", "gasto.first.importe"], ["&nbsp;","1_4", "gasto.first.moneda.abreviatura"], [_("G.Concepto"),"1", "gasto.first.concepto"]]
      when "documento_transferencias" then [[_("Nombre"), "5_4", "adjunto_file_name"], [_("Fecha"),"1_3", "transferencia.first.fecha_enviado"], [_("Tipo"), "1_2", "transferencia.first.tipo.capitalize"], [_("Enviado"),"1_3_td", "transferencia.first.importe_enviado_convertido" ], ["&nbsp;","1_5", "transferencia.first.moneda_enviada.abreviatura"], [_("Cuenta Origen"),"1", "transferencia.first.libro_origen.nombre"], [_("Ingresado"),"1_3_td", "transferencia.first.importe_cambiado_convertido" ],["&nbsp;","1_5", "transferencia.first.moneda_cambiada.abreviatura"], [_("Cuenta Destino"),"1_2", "transferencia.first.libro_destino.nombre"]]

      when "objetivo_especifico" then [[_("Código"),"1_3","codigo"],[_("Descripción"),"4","descripcion"]]
      when "resultado" then [[_("Código"),"1_3","codigo"],[_("Descripción"),"4","descripcion"]]
      when "etapa" then 
        if params[:seccion] == "agentes"
          [ [_("Nombre"),"1", "nombre"], [_("Fecha inicio"),"1_2", "fecha_inicio" ],[_("Fecha fin"),"1_2", "fecha_fin"], [_("Meses"),"1_4", "meses" ], [_("Cerrada"),"1_3", "cerrada"], [_("Descripción"),"3_2", "descripcion"]]
        else
          [ [_("Nombre"),"1", "nombre"], [_("Fecha inicio"),"1_2", "fecha_inicio" ],[_("Fecha fin"),"1_2", "fecha_fin"], [_("Meses"),"1_4", "meses" ], [_("Descripción"),"3_2", "descripcion"]]
        end
      when "financiador" then [[_("Nombre"), "3_2", "nombre"]]
      when "implementador" then [[_("Nombre"), "3_2", "nombre"]]
      when "actividad" then [[_("Código y descripción"), "3", "codigo_descripcion"]]
      when "tasa_cambio" then [[_("Moneda"), "1_4", "moneda.abreviatura"], [_("Fecha inicio"),"1_2", "fecha_inicio"],[_("Fecha fin"),"1_2", "fecha_fin"],[_("Aplica a"),"1_2","tipo"],[_("Modo"),"1_2","modo"], [_("Tasa Cambio"), "1_2_td", "cadena_tasa_cambio"],[_("País"),"2_3","pais.nombre"]]
      when "tasa_cambio_gasto" then
        if params[:seccion] == "proyectos"
          campos_listado("gasto_agentes").push([_("T.Cambio"), "1_2_td", "tasa_cambio_proyecto " + @proyecto.id.to_s + ".tasa_cambio"],[_("Importe x TC"), "1_2_td", "importe_x_proyecto_en_base " + @proyecto.id.to_s])
        else
          campos_listado("gasto_agentes").push([_("T.Cambio"), "1_2_td", "tasa_cambio_agente.tasa_cambio"],[_("Importe x TC"), "1_2_td", "importe_implantador_en_base"]) 
        end
      when "gasto" then [[_("Fecha"),"1_3", "fecha", true], [_("Importe"),"1_2_td", "gasto_x_proyecto.first.importe", true],["&nbsp","1_4", "moneda.abreviatura", true], [_("Partida"),"3_4","partida.codigo_nombre " + (@proyecto ? @proyecto.id.to_s : "nil"), true], [_("Concepto"),"1", "concepto", true], [_("Implementador"), "3_4", "agente.nombre", true], [_("Cambio"), "1_4", "updated_at", true] ]
      when "gasto_cofinanciable" then [ [_("Fecha"),"1_3", "fecha", true], [_("Importe"),"1_2_td", "importe", true],["&nbsp;".html_safe,"1_4", "moneda.abreviatura", true], [_("Partida"),"3_4","partida.codigo_nombre " + (@proyecto ? @proyecto.id.to_s : "nil"), true], [_("Concepto"),"1", "concepto", true], [_("Implementador"), "3_4", "agente.nombre", true], [_("Proyecto Origen"),"1", "proyecto_origen", true] ]
      when "gasto_agentes" then [ ["#", "1_4", "orden_factura_agente", false], [_("Fecha"),"1_3", "fecha", true], [_("Importe"),"1_2_td", "importe", true],["&nbsp;".html_safe,"1_4", "moneda.abreviatura", true], [_("Partida"),"1","partida.codigo_nombre", true], [_("Concepto"),"3_2", "concepto", true], [_("Cambio"), "1_4", "updated_at", true] ]
      when "gasto_agentes_empleado" then
        campos_listado("gasto_agentes").push([_("Empleado"), "1_3", "empleado.nombre", false])
      when "presupuesto" then [[_("Partida"),"3_4", "partida.codigo_nombre", true], [_("Subpartida"),"1", "subpartida.nombre", true], [_("Concepto"),"1", "concepto", true], [_("Agente"), "1_2", "agente.nombre"], [_("Importe"),"1_2_td", "importe" ],["&nbsp;".html_safe,"1_5", "moneda.abreviatura"]]
      when "presupuesto_empleado" then [[_("Partida"),"3_4", "partida.codigo_nombre", true], [_("Subpartida"),"1", "subpartida.nombre", true], [_("Concepto"),"3_2", "concepto", true], [_("Importe"),"1_2_td", "importe" ],["&nbsp;".html_safe,"1_5", "moneda.abreviatura"]]
      when "presupuesto_actividad" then [[_("Partida"),"3_4", "partida.codigo_nombre", true], [_("Subpartida"),"1", "subpartida.nombre", true], [_("Concepto"),"1", "concepto", true], [_("Agente"), "1_2", "agente.nombre"], [_("Importe"),"1_2_td", "presupuesto_x_actividad.first.importe" ],["&nbsp;".html_safe,"1_5", "moneda.abreviatura"]]
      when "presupuesto_agentes" then [[_("Partida"),"1", "partida.codigo_nombre", true], [_("Subpartida"),"1", "subpartida.nombre", true], [_("Concepto"),"3_2", "concepto", true], [_("Importe"),"1_2_td", "importe" ],["&nbsp;".html_safe,"1_4", "moneda.abreviatura"]]
      when "presupuesto_ingresos" then [[_("Importe"),"1_2_td","importe"], ["&nbsp;".html_safe,"1_4", "moneda.abreviatura"], [_("Concepto"), "5_2", "concepto"], [_("Financiador"), "1", "financiador.nombre"] ]
      when "presupuesto_ingresos_funcionamiento" then [[_("% Funcionamiento"), "1_4_td", "porcentaje_funcionamiento"], [_("Importe Ejecución"),"1_2_td","importe"], ["&nbsp;".html_safe,"1_4", "moneda.abreviatura"], [_("Concepto"), "2", "concepto"], [_("Financiador"), "1", "financiador.nombre"] ]
      when "detalle_presupuestos_proyecto" then [[_("Concepto"), "3", "presupuesto_concepto"], [_("Importe"), "1_2_td", "importe"]]
      when "definicion_estado" then [[_("Orden"),'1_3','orden',true], [_("Nombre"),'2_3','nombre',true], [_("Estados anteriores"), '3_2', 'estado_padre_visualizacion'], [_("Inicial"), '1_3', 'primer_estado'],[_("Formu."), '1_3', 'formulacion'],[_("Ejec."), '1_3', 'ejecucion'], [_("Reporte"), '1_3', 'reporte'], [_("Cerrado"), '1_3', 'cerrado'], [_("Aprobado"), '1_3', 'aprobado'] ]
      when "workflow_contrato" then [[_("Orden"),'1_3','orden',true], [_("Nombre"),'1','nombre',true], [_("Estados anteriores"), '3_2', 'estado_padre_visualizacion'], [_("Inicial"), '1_3', 'primer_estado'],[_("Definición"), '1_3', 'formulacion'], [_("Ejecución"), '1_3', 'ejecucion'], [_("Aprobado"), '1_3', 'aprobado'], [_("Cerrado"), '1_3', 'cerrado'] ]
      when "grupo_dato_dinamico" then [[_("Nombre"), '1', 'nombre', true], [_("Orden"),'1_2','rango',true], [_("Seguimiento"),'1_2','seguimiento',true], [_("Cierre"),'1_2','cierre',true]]
      when "definicion_dato" then [[_("Nombre"),'1','nombre',true], [_("Rótulo"), '3_2', 'rotulo'], [_("Tipo"), '1_2', 'tipo'], [_("Grupo"), '1', 'grupo_dato_dinamico.nombre',true], [_("Orden"),'1_2','rango' ] ]
      when "estado" then[[_("Nombre"), '1', 'definicion_estado.nombre'], [_("Fecha inicio"), '3_4', 'fecha_inicio'], [_("Fecha cambio"), '3_4', 'fecha_fin'], [_("Cambiado por"), '1', 'usuario.nombre'] ]
      when "tarea" then
        if params[:seccion] == "inicio"
          [[_("Proyecto o Agente"), '2_3', 'nombre_objeto_relacionado', false], [_("Título"), '3_2', 'titulo', true], [_("Fecha inicio"), '1_2', 'fecha_inicio', true], [_("Fecha fin"), '1_2', 'fecha_fin', true], [_("Asignado a"), '1_2', 'usuario_asignado.nombre'], [_("Asignado por"), '1_2', 'usuario.nombre'], [_("Estado"), '1_2', 'estado_tarea.nombre', true] ]
        elsif params[:menu] == "configuracion"
          [[_("Título"), '3_2', 'titulo', true], [_("Fecha inicio"), '1_2', 'fecha_inicio', true], [_("Fecha fin"), '1_2', 'fecha_fin', true], [_("Asignado a"), '1_2', 'usuario_asignado.nombre'], [_("Estado"), '1_2', 'estado_tarea.nombre', true], ["%", '1_5', 'porcentage_implementacion'] ]
        else
          [[_("Título"), '2', 'titulo', true], [_("Fecha inicio"), '1_2', 'fecha_inicio', true], [_("Fecha fin"), '1_2', 'fecha_fin', true], [_("Asignado a"), '1_2', 'usuario_asignado.nombre'], [_("Asignado por"), '1_2', 'usuario.nombre'], [_("Estado"), '1_3', 'estado_tarea.nombre', true], ["%", '1_5', 'porcentage_implementacion'] ]
        end
      when "tipo_tarea" then[[_("Nombre"), '1', 'nombre',true], [_("De Proyecto"), '1_3', 'tipo_proyecto'], [_("De Agente"), '1_3', 'tipo_agente'], [_("Administ."), "1_3", "administracion"], [_("Config."), "1_3", "configuracion"], [_("Formulación técnica"), "1_2", "formulacion_tecnica"], [_("Formulación económica"), "1_2", "formulacion_economica"], [_("Seguimiento técnico"), "1_2", "seguimiento_tecnico"], [_("Seguimiento económico"), "1_2", "seguimiento_economico"], [_("Justificación final"), "1_3", "justificacion"] ]
      when "estado_tarea" then[[_("Nombre"), '1', 'nombre',true], [_("Descripción"), '2', 'descripcion'], [_("Seleccionable"), '1_2', 'seleccionable'], [_("Activo"), '1_2', 'activo']]
      when "comentario" then[[_("Comentario"), '3', 'texto'], [_("Fecha"), '1_2', 'created_at'], [_("Usuario"), '1_2', 'usuario.nombre']]
      when "transferencia" then [ [_("Fecha Envío"),"1_4", "fecha_enviado", true], [_("Enviado"),"1_2_td", "importe_enviado" ], ["&nbsp;".html_safe,"1_5", "moneda_enviada.abreviatura"], [_("Cuenta Origen"),"1", "libro_origen.nombre"], [_("Fecha Recepción"),"1_4", "fecha_recibido", true], [_("Ingresado"),"1_2_td", "importe_cambiado" ],["&nbsp;".html_safe,"1_5", "moneda_cambiada.abreviatura"], [_("Cuenta Destino"),"1", "libro_destino.nombre"], [_("Tipo"), "1_3", "tipo.capitalize"] ]

      when "partida_financiacion" then [[_("Código"),"1_2", 'codigo'],[_("Nombre"),"1", 'nombre'], [_("Descripción"),"1", 'descripcion'], [_("Tipo"),"1_3", 'tipo_mayusculas'], [_("% máximo"),"1_2_td", 'porcentaje_maximo_convertido'] ]
      when "proyecto_x_financiacion" then [[_("nombre del proyecto"), "1", 'proyecto.nombre'], [_("Nombre en financiacion"),"1",'nombre_en_financiacion'], [_("Título en financiacion"), "2", 'titulo_en_financiacion']]
      when "indicador_general" then [[_("Código"), "1_3", "codigo", true], [_("Nombre"), "1", "nombre", true], [_("Activo"), "1_5", "activo"], [_("Descripción"), "5_2", "descripcion"]]
      when "indicador_general_x_proyecto" then 
        if params[:menu] == "formulacion"
          [ [_("Nombre"), "1", "indicador_general.nombre"], [_("Descripción"), "2", "indicador_general.descripcion"],
            [_("Valor Base"), "1_2", "valor_base.valor"], [_("Valor Objetivo"), "1_2", "valor_objetivo.valor"] ]
        else
          [ [_("Nombre"), "1", "indicador_general.nombre"], [_("Descripción"), "2", "indicador_general.descripcion"],
            [_("Valor Base"), "1_2", "valor_base.valor"], [_("Valor Objetivo"), "1_2", "valor_objetivo.valor"], [_("Última medida"), "1_2", "ultimo_valor.valor"] ]
        end

      when "indicador" then 
        if params[:menu] == "formulacion"
          [[_("Código"), "1", 'codigo_completo'], [_("Descripción"), "5_2", 'descripcion']]
        else
          [[_("Código"), "1", 'codigo_completo'], [_("Descripción"), "5_2", 'descripcion'], [_("Porcentaje"), "1_4", 'porcentaje_actual']]
        end
      when "fuente_verificacion" then [ [_("Código"), "1_2", 'codigo'], [_("Descripción"), "5_2", 'descripcion'], [_("Indicador"), "1_3", "indicador.codigo"]]
      when "fuente_verificacion_seguimiento" then [ [_("Código"), "1_3", 'codigo'], [_("Descripción"), "3", 'descripcion'], [_("Objetivo/resultado"), "1", "objetivo_resultado"]]
      when "hipotesis" then [ [_("Descripción"), "3", 'descripcion'] ]
      when "cabezera_fuente" then [[_("Fuente de verificación"), "1", ""]]
      when "socio" then [ [_("Nombre"), "1", "nombre", true], [_("Apellido"), "1", "apellido1", true], [_("Activo"), "1_3","informacion_socio.activo"], [_("Naturaleza"), "1_2", "naturaleza_socio.naturaleza", true], [_("Sexo"), "1_4", "sexo", true],  [_("País"), "1_2", "pais", true], [_("Provincia"), "1_2", "provincia", true] ]
      when "informacion_socio" then [ [_("Fecha Alta"), "1", "fecha_alta", true], [_("Importe Cuota,"), "1", "importe_cuota,", true], [_("Activo"), "1_4", "activo", true], [_("Naturaleza Socio"), "1", "naturaleza_socio", true] ]
      when  "pago_socio" then [[_("Socio"), "1", "socio.nombre_completo", true], [_("Importe"), "1_2", "importe", true], [_("Concepto"), "3_2", "concepto", true], [_("Forma de Pago"), "1_2", "forma_pago_socio.forma_pago", true], [_("Fecha Pago"), "1_2", "fecha_pago", true], [_("Fecha Emisión"), "1_2", "fecha_emision", true]]
      when "etiqueta" then [[_("Etiqueta"), "2", "nombre", true], [_("Tipo"), "1_2", "tipo.capitalize", true], [_("Descripción"), "2", "descripcion"]]
      when "presupuesto_x_actividad" then [[_("Partida"),"3_4", "presupuesto.partida.codigo_nombre " + @proyecto.id.to_s, true], [_("Subpartida"),"1", "presupuesto.subpartida.nombre", true], [_("Concepto"),"1", "presupuesto.concepto", true], [_("Agente"), "1_2", "presupuesto.agente.nombre"], [_("Importe"),"1_2_td", "importe" ],["&nbsp;".html_safe,"1_4", "presupuesto.moneda.abreviatura"] ]
      when "pago" then [ [_("Fecha"),"1_2", "fecha", true], [_("Cuenta"),"1", "libro.nombre", true], [_("Importe"), "1_2_td", "importe", true],["&nbsp;".html_safe,"1_4", "gasto.moneda.abreviatura", true], [_("Forma de Pago"),"1_2", "forma_pago"], [_("Referencia"),"1_2", "referencia_pago"], [_("Observaciones"),"2_3", "observaciones", true] ] 
      when "factura_financiador" then [ [ _("Numeración factura financiador"), "2", "gasto_x_proyecto.first.orden_factura"], [_("Fecha"),"1_3", "fecha"], [_("Importe factura"), "1_2_td", "importe"], ["&nbsp;".html_safe,"1_4", "moneda.abreviatura"], [_("Factura"), "3_4", "numero_factura"], [_("Agente Implementador"), "2_3", "agente.nombre"] ]
      when "factura" then [ [ _("Nº"), "1_5", "numeracion_factura"], [ _("Numero factura completo"), "3_2", "numeracion_factura_completo", true], [ _("Numeración factura financiador"), "3_2", "gasto_x_proyecto.first.orden_factura", true], [_("Fecha"),"1_4", "fecha"], [_("Importe factura"), "1_2_td", "importe"], ["&nbsp;".html_safe,"1_4", "moneda.abreviatura"] , [_("Agente Implementador"), "2_3", "agente.nombre"] ] #[ [ _("Numeración factura"), "5_2", "numeracion_factura"], [_("Fecha"),"1_3", "fecha"], [_("Importe factura"), "1_2_td", "importe"], ["&nbsp;".html_safe,"1_4", "moneda.abreviatura"], [_("Agente Implementador"), "2_3", "agente.nombre"] ]
      when "variable_indicador" then 
        if params[:menu] == "formulacion"
           [ [ _("Variable de Indicador"), "3", "nombre" ], [ _("Valor Base"), "1_2", "valor_base.valor"], [ _("Valor Objetivo"), "1_2", "valor_objetivo.valor"] ]
        else
          [ [ _("Variable de Indicador"), "3", "nombre" ], [ _("Valor Base"), "1_2", "valor_base.valor"], [ _("Valor Objetivo"), "1_2", "valor_objetivo.valor"], [_("Última medida"), "1_2", "ultimo_valor.valor"] ]
        end
      when "valor_medido" then [ [_("Fecha"), "1_2", "fecha", true], [_("Valor"), "1_2_td", "valor"], [_("Comentario"), "2", "comentario"] ]
      when "actividad_x_etapa" then [["Actividad", "2", "actividad.codigo_descripcion"], [_("Realizada"), "1", "estado_actual.realizada"], [_("% realiz."), "1_4", 'porcentaje_actual']]
      when "subactividad" then 
        if params[:menu] == "formulacion"
          [ [_("Descripción"), "3", "descripcion"] ]
        else
          [ [_("Subactividad"), "3", "descripcion"], [_("Estado"), "1", "estado_actual.estado"], [_("Porcentaje"), "1_4", 'porcentaje_actual'] ]
        end
      when "valor_actividad" then [ [_("Fecha"), "1_2", "fecha", true], [_("Usuario"), "1_2", "usuario.nombre"], [_("Estado"), "1_2", "realizada"], [_("Porcentaje"), "1_4", "porcentaje"], ["&nbsp;".html_safe,"1_4","&nbsp;".html_safe], [_("Comentario"), "2", "comentario"] ]
      when "valor_subactividad" then [ [_("Fecha"), "1_2", "fecha", true], [_("Usuario"), "1_2", "usuario.nombre"], [_("Estado"), "1_2", "estado"], [_("Porcentaje"), "1_4", "porcentaje"], ["&nbsp;".html_safe,"1_4","&nbsp;".html_safe], [_("Comentario"), "2", "comentario"] ]
      when "valor_indicador" then [ [_("Fecha"), "1_2", "fecha", true], [_("Usuario"), "1_2", "usuario.nombre"], [_("% cumplimiento"), "1_4", "porcentaje"], ["&nbsp;".html_safe,"1_4","&nbsp;".html_safe], [_("Comentario"), "2", "comentario"] ]
      when "marcado" then [ [_("Nombre"), "3_4", "nombre"],  [_("Descripción"), "3_2", "descripcion"], [_("Color"), "1_2", "color"], [_("Marcado anterior"), "3_4", "marcado_padre.nombre"], [_("Primer estado"), "1_2", "primer_estado"], [_("Errores"), "1_3", "error"], [_("Automático"), "1_3", "automatico"] ]
      when "subtipo_movimiento" then [ [_("Nombre"), "1", "nombre", true], [_("Descripción"), "2", "descripcion"], [_("Tipo Asociado"), "1", "tipo_asociado.capitalize", true] ]
      when "definicion_estado_documento" then [[_("Nombre"), "1", "nombre", true], [_("Descripción"), "2", "descripcion"]]
      when "definicion_estado_tarea" then [[_("Título"), "1", "titulo", true], [_("Descripción"), "2", "descripcion"]]
      when "espacio" then [[_("Nombre"), "2", "nombre", true]]
      when "v_presupuesto_subpartida" then [[_("Partida"), "3_2", "partida.codigo_nombre", false], [_("Subpartida"), "3_2", "subpartida.nombre", true], [_("Importe"), "1_2_td", "importe", true]]
      when "v_gasto_subpartida" then [[_("Partida"), "3_2", "partida.codigo_nombre", false], [_("Subpartida"), "3_2", "subpartida.nombre", true], [_("Importe"), "1_2_td", "importe", true]]
      when "socio.informacion_socio.datos_tarjeta_socio" then [[_("Tipo Tarjeta"), "1", "tipo_tarjeta"], [_("Número Tarjeta"), "1", "numero_tarjeta"], [_("Fecha Caducidad"), "2_3", "fecha_caducidad"], [_("CVC"), "1_2", "codigo_verificacion"] ]
      when "periodo" then [[_("Nombre"), "1", "tipo_periodo.nombre", false], [_("Estado"), "1_2", "estado", false], [_("Inicio"), "1_2", "fecha_inicio", false], [_("Fin"), "1_2", "fecha_fin", false], [_("Tiempo transcurrido del periodo"), "3_4", "porcentaje_tiempo", false], [_("Informe"), "1_2", "fecha_informe", false], [_("Dias al informe"), "1_2", "tiempo_al_informe", false]]
      when "personal" then [[_("Tipo"), "1", "tipo_personal.nombre", true], [_("Nombre"), "2", "nombre", true], [_("Categoría"), "1", "categoria", true] ]
      when "plugin" then [["Plugin", "1_2", "clase"], [_("Nombre"), "3_2", "nombre"], [_("Descripcion"), "2", "descripcion"], [_("Activo"), "1_3", "activo"], [_("Disponible"), "1_3", "disponible"]]
      when "proveedor" then [[_("Nombre"), "2", "nombre", true], [_("NIF"), "1", "nif", true], [_("País"), "1", "pais.nombre"], [_("Activo"), "1_2", "activo"]]
      when "tipo_contrato" then [[_("Nombre"), "3_2", "nombre", true], [_("Descripción"), "2", "descripcion"], [_("Agente"), "1", "agente.nombre", true]]
      when "contrato" then
        if @proyecto
          [["Código", "1_2", "codigo", true], [_("Nombre"), "1", "nombre", "contrato.nombre"], [_("Agente"), "2_3", "agente.nombre"], [_("Estado"), "2_3", "workflow_contrato.nombre", true], [_("Proveedor"), "1", "proveedor.nombre", true]]
        else
          [["Código", "1_2", "codigo", true], [_("Nombre"), "1", "nombre", true], [_("Proyecto"), "2_3", "proyecto.nombre"], [_("Estado"), "2_3", "workflow_contrato.nombre", true], [_("Proveedor"), "1", "proveedor.nombre", true]]
        end
      when "estado_contrato" then[[_("Estado"), '3_2', 'workflow_contrato.nombre'], [_("Desde"), '3_4', 'fecha_inicio'], [_("Hasta"), '3_4', 'fecha_fin'], [_("Cambiado por"), '1', 'usuario.nombre'] ]
      when "campo_tipo_contrato" then [[_("Nombre"), "2_3", "nombre"], [_("Etiqueta"), "2", "etiqueta"], [_("Tipo"), "2_3", "tipo_campo"], [_("Activo"), "1_3", "activo"]]
      when "documento_tipo_contrato" then [[_("Nombre"), "2_3", "adjunto_file_name"], [_("Descripción"), "2", "descripcion"]]
      when "partida_ingreso" then [["Nombre", "3_2", "nombre", true], [_("Descripción"), "2", "descripcion"]]
      when "ingreso" then [ [_("Fecha"),"1_3", "fecha", true], [_("Importe"),"1_2_td", "importe", true],["&nbsp","1_4", "moneda.abreviatura", true], [_("Partida"),"3_4","partida_ingreso.codigo_nombre", true], [_("Concepto"),"5_2", "concepto", true] ]
      when "rol" then [ [_("Nombre"), "1", "nombre", true], [_("Sección"), "1", "nombre_seccion", true], [_("Descripción"), "2", "descripcion"], [_("Admin"), "1_3", "admin"] ]
      when "permiso_x_rol" then [ [_("Menú"), "1", "menu"], [_("Controlador"), "1", "controlador"], [_("Ver"), "1_3", "ver"], [_("Cambiar"), "1_3", "cambiar"] ]
      when "tipo_periodo" then [ [_("Tipo de Periodo"), "3_2", "nombre"], [_("Descripcion"), "2", "descripcion"], [_("T.Oficial"), "1_3", "oficial"], [_("Grupo de tipo de periodo"), "1_2", "nombre_grupo_tipo_periodo"] ]
      when "gasto_x_financiador" then
        campos = campos_listado("gasto") 
        campos[1] = ["Importe por Financiador", "1_2_td", "importe_x_financiador", true]
        campos
      when "empleado" then [ [_("Nombre"), "3_2", "nombre"] ]
      when "empleado_salario_hora" then [ [_("Fecha Inicio"), "3_4", "fecha_inicio"],[_("Fecha Fin"), "3_4", "fecha_fin"], [_("Salario hora"), "1_2_td", "salario_hora"], ["", "1_4", "empleado.agente.moneda_principal.abreviatura"]]
      else []
    end
    # Revisamos cada plugin para que incluya o elimine los campos que necesite
    Plugin.activos.each { |plugin| campos = eval(plugin.clase)::campos_listado(modelo, campos) if eval(plugin.clase).respond_to?('campos_listado') }
    return campos
  end

  # el array que devuelve el helper reponde al modelo : rotulo, ancho de columna (hasta 9_2, 4,5), atributo.
  def campos_info modelo, campos=[]
    campos += case modelo
      when "proyecto" then [[_("Fecha de Inicio"), "1", "fecha_de_inicio"], [_("Fecha de Fin"), "1", "fecha_de_fin"], [_("Moneda Justificación"), "1", "moneda_principal.nombre"], [_("Divisa"), "1", "moneda_intermedia.nombre"], [_("Monedas Usadas"), "1", "monedas_definidas"], [_("Sector Intervención"), "1", "sectores_intervencion_definidos"], [_("Area Actuación"), "1", "areas_actuacion_definidas"],[_("Sector Población"), "1", "sectores_poblacion_definidos"], [_("Tipo Convocatoria"), "1", "convocatoria.tipo_convocatoria.nombre"], [_("Fecha Convocatoria"), "1", "convocatoria.fecha_publicacion"], [_("Financiador principal"), "1", "agente.nombre"], [_("Identificador para Financiador"), "1", "identificador_financiador"] , [_("Cuenta Subvención"), "1", "libro_principal.nombre"], [_("Gestor Subvención"), "1", "gestor.nombre"] ]
      when "proyecto_ampliado" then [[_("Objetivo general"), "1", "objetivo_general.descripcion"], [_("Fecha de Inicio"), "1", "fecha_de_inicio"], [_("Fecha de Fin"), "1", "fecha_de_fin"], [_("Moneda Justificación"), "1", "moneda_principal.nombre"], [_("Divisa"), "1", "moneda_intermedia.nombre"], [_("Monedas Usadas"), "1", "monedas_definidas"], [_("Sector Intervención"), "1", "sectores_intervencion_definidos"], [_("Area Actuación"), "1", "areas_actuacion_definidas"],[_("Sector Población"), "1", "sectores_poblacion_definidos"], [_("Tipo Convocatoria"), "1", "convocatoria.tipo_convocatoria.nombre"], [_("Fecha Convocatoria"), "1", "convocatoria.fecha_publicacion"], [_("Financiador principal"), "1", "agente.nombre"], [_("Identificador para Financiador"), "1", "identificador_financiador"], [_("Otros Financiadores"), "1", "otros_financiadores_nombre"], [_("Importe Subvención Principal"), "1", "presupuesto_financiador_principal"], [_("Cuenta Subvención"), "1", "libro_principal.nombre"], [_("Gestor Subvención"), "1", "gestor.nombre"], [_("Otros Implementadores"), "1", "otros_implementadores_nombre"], [_("Presupuesto total"), "1", "presupuesto_total_con_tc"], [_("Total ejecutado"), "1", "gasto_total_con_tc"], [_("Periodos de Seguimiento"), "1", "periodo_seguimiento_financiador"], [_("Justificación final"), "1", "periodo_justificacion_financiador"], [_("Usuarios asignados"), "1", "usuarios_administradores"] ] 
      when "programa_marco" then [[_("Moneda"), "1", "moneda.nombre"], [_("Fecha de Inicio"), "1", "fecha_de_inicio"], [_("Fecha de Fin"), "1", "fecha_de_fin"], [_("Proyectos"), "1", "nombres_proyectos"], [_("Países"), "1", "nombres_paises"], [_("Financiadores"), "1", "nombres_financiadores"], [_("Implementadores"), "1", "nombres_implementadores"]]
      when "estado" then [[_("Descripción del Estado"), "1", "definicion_estado.descripcion"], [_("Observaciones"), "1", "observacion"] ]
      when "convocatoria" then [[_("Cerrada"), "1", "cerrado"], [_("Tipo"), "1", "tipo_convocatoria.nombre"], [_("Fecha Resol."), "1", "fecha_resolucion"], [_("Descripción"), "1", "descripcion"], [_("Observaciones"), "1", "observaciones"], [_("País"), "1_2", "paises"] ]
      when "agente" then [[_("País"), "1", "pais.nombre"], [_("NIF"), "1", "nif"], [_("Financiador Público"), "1", "publico"], [_("Socia Local"), "1", "socia_local"], [_("Moneda"), "1", "moneda_principal.nombre"], [_("Divisa"), "1", "moneda_intermedia.nombre"], [_("Tipo de Agente"), "1", "tipo_agente.nombre"]]
      when "subcuenta_contable" then [[_("Centro de Coste?"), "1", "centro_coste"], [_("Observaciones"), "1", "observaciones"]]
      when "actividad_x_etapa" then [[_("Resultado"), "2", "actividad.resultado.codigo_nombre"]]
      when "gasto" then [[_("N. Factura"), "1", "numeracion_factura"],  [_("N. Factura completo"), "1", "numeracion_factura_completo"], [_("Subpartida"), "1", "subpartida_proyecto_nombre " + @proyecto.id.to_s ], [_("Valorizado"), "1", "es_valorizado"], [_("País"), "1", "pais.nombre"], [_("Nº Factura"), "1_2", "numero_factura"], [_("Emisor Factura"), "1", "proveedor.nombre"], [_("NIF Emisor"), "1_2", "proveedor.nif"], [_("Tipo Partida"), "3_4", "partida.tipo"], [_("Observaciones"), "1", "observaciones"], [_("Referencia Contable"), "1", "ref_contable"], [_("Impuestos"), "1_2", "impuestos"], [_("T.Cambio"), "1_2_td", "tasa_cambio_proyecto " + @proyecto.id.to_s + ".tasa_cambio"],[_("Importe x TC"), "1_2_td", "importe_x_proyecto_en_base " + @proyecto.id.to_s], [_("Actividades"), "1", "importes_por_actividades " + @proyecto.id.to_s], [_("Financiadores"), "1", "importes_por_financiadores " + @proyecto.id.to_s], [_("Descargar"), "1", "enlace_nota_gasto_proyecto " + @proyecto.id.to_s] ] 
      when "gasto_x_financiador" then campos_info("gasto")
      when "gasto_cofinanciable" then [ [_("País"), "1", "pais.nombre"], [_("Nº Factura"), "1_2", "numero_factura"], [_("Emisor Factura"), "1", "proveedor.nombre"], [_("NIF Emisor"), "1_2", "proveedor.nif"], [_("Tipo Partida"), "3_4", "partida.tipo"], [_("Observaciones"), "1", "observaciones"], [_("Impuestos"), "1_2", "impuestos"], [_("T.Cambio"), "1_2_td", "tasa_cambio_proyecto " + @proyecto.id.to_s + ".tasa_cambio"],[_("Importe x TC"), "1_2_td", "importe_x_proyecto_en_base " + @proyecto.id.to_s], [_("TC a Divisa"), "1_2_td", "tasa_cambio_proyecto " + @proyecto.id.to_s + ".tasa_cambio_divisa"], [_("Importe en Divisa"), "1_2_td", "importe_x_proyecto_en_divisa " + @proyecto.id.to_s], [_("Proyectos"), "1", "importes_por_proyectos"] ]
      when "gasto_agentes" then [ [_("Tipo Partida"), "3_4", "partida.tipo"], [_("Subpartida"), "1", "subpartida_agente.nombre"], [_("Referencia Contable"), "1", "ref_contable"], [_("Valorizado"), "1", "es_valorizado"], [_("País"), "1", "pais.nombre"], [_("Orden Factura"), "3_4", "orden_factura_agente_completo"], [_("Nº Factura"), "1_2", "numero_factura"],[_("Emisor Factura"), "1", "proveedor.nombre"], [_("NIF Emisor"), "1_2", "proveedor.nif"], [_("Observaciones"), "1", "observaciones"], [_("Impuestos"), "1_2", "impuestos"], [_("T.Cambio"), "1_2_td", "tasa_cambio_agente.tasa_cambio"],[_("Importe x TC"), "1_2_td", "importe_implantador_en_base"], [_("Importe x TC Divisa"), "1_2_td", "importe_implantador_en_divisa"], [_("Proyectos"), "2", "importes_por_proyectos"] ]
      when "presupuesto" then [[_("Observaciones"), "1", "observaciones"], [_("Unidad"), "1_2", "unidad"], [_("Nº Unidades"), "1_2", "numero_unidades"], [_("C.Unitario"), "1_2_td", "coste_unitario"], [_("País"), "1", "pais.nombre"], [_("Etapa"), "1", "etapa.nombre"], [_("T.Cambio"), "1_2_td", "tasa_cambio"],[_("Importe x TC"), "1_2_td", "importe_en_base"],  [_("Actividades"), "1", "importes_por_actividades"], [_("Financiadores"), "1", "importes_por_financiadores"]]
      when "presupuesto_agentes" then [[_("Tipo Partida"), "1", "partida.tipo"], [_("Observaciones"), "1", "observaciones"], [_("Nº Unidades"), "1_2", "numero_unidades"], [_("C.Unitario"), "1_2_td", "coste_unitario"], [_("Etapa"), "1", "etapa.nombre"], [_("T.Cambio"), "1_2_td", "cadena_tasa_cambio"], [_("T.Cambio divisa"), "1_2_td", "cadena_tasa_cambio_divisa"], [_("Importe x TC"), "1_2_td", "importe_en_base"], [_("Importe (divisa)"), "1_2_td", "importe_en_divisa"]]
      when "presupuesto_ingresos" then [[_("Observaciones"), "1", "observaciones"], [_("Etapa"), "1", "etapa.nombre"], [_("T.Cambio"), "1_2_td", "cadena_tasa_cambio"], [_("T.Cambio divisa"), "1_2_td", "cadena_tasa_cambio_divisa"], [_("Importe x TC"), "1_2_td", "importe_en_base"], [_("Importe (divisa)"), "1_2_td", "importe_en_divisa"] ]
      when "presupuesto_ingresos_funcionamiento" then [[_("Observaciones"), "1", "observaciones"], [_("Etapa"), "1", "etapa.nombre"], [_("Importe Funcionamiento"), "1_2_td", "importe_funcionamiento"], [_("T.Cambio"), "1_2_td", "cadena_tasa_cambio"], [_("T.Cambio divisa"), "1_2_td", "cadena_tasa_cambio_divisa"], [_("Importe Funcionamiento x TC"), "1_2_td", "importe_funcionamiento_en_base"], [_("Importe Funcionamiento (divisa)"), "1_2_td", "importe_funcionamiento_en_divisa"], [_("Importe Ejecución x TC"), "1_2_td", "importe_en_base"], [_("Importe Ejecución (divisa)"), "1_2_td", "importe_en_divisa"] ]
      when "detalle_presupuestos_proyecto" then [[_("Proyecto"), "1", "proyecto_nombre"], [_("Partida"), "1", "partida_codigo"]]
      when "tasa_cambio" then [ [_("Tasa Cambio Divisa"), "1", "cadena_tasa_cambio_divisa"] ]
      when "tasa_cambio_gasto" then 
        if params[:seccion] == "proyectos"
         [[_("TC a Divisa"), "1_2_td", "tasa_cambio_proyecto " + @proyecto.id.to_s + ".tasa_cambio_divisa"], [_("Importe en Divisa"), "1_2_td", "importe_x_proyecto_en_divisa " + @proyecto.id.to_s]]
        else
         [[_("TC a Divisa"), "1_2_td", "tasa_cambio_agente.tasa_cambio_divisa"], [_("Importe en Divisa"), "1_2_td", "importe_implantador_en_divisa"]]
        end
      when "subactividad" then [[_("Detalle"), "1", "descripcion_detallada"], [_("Notas"), "1", "comentarios_ejecucion"], [_("Responsables"), "1", "responsables_ejecucion"]]
      when "beneficiarios" then [[_("Titulares de derecho directos hombres"), "3_2", "beneficiarios_directos_hombres"], [_("Titulares de derecho directos mujeres"), "3_2", "beneficiarios_directos_mujeres"], [_("Titulares de derecho directos sin especificar"), "3_2", "beneficiarios_directos_sin_especificar"], [_("Titulares de derecho indirectos hombres"), "3_2", "beneficiarios_indirectos_hombres"], [_("Titulares de derecho indirectos mujeres"), "3_2", "beneficiarios_indirectos_mujeres"], [_("Titulares de derecho indirectos sin especificar"), "3_2", "beneficiarios_indirectos_sin_especificar"]]
      when "variable_indicador" then [ [_("Herramienta de Medición"), "1", "herramienta_medicion"], [_("Fuente de Información"), "1", "fuente_informacion"], ["Contexto", "1", "contexto"], ["Fecha Valor Base", "1_3", "valor_base.fecha"], ["Comentario Valor Base", "1", "valor_base.comentario"], ["Fecha Valor Objetivo", "1_3", "valor_objetivo.fecha"], ["Comentario Valor Objetivo", "1", "valor_objetivo.comentario"] ]
      when "indicador_general" then [ [_("Unidad de Medida"), "1", "unidad"] ]
      when "indicador_general_x_proyecto" then [ [_("Unidad de Medida"), "1", "indicador_general.unidad"] ]
      when "transferencia" then [ [_("Subtipo"), "1_3", "subtipo_movimiento.nombre"], [_("Observaciones"), "1_3", "observaciones"], [_("T.Cambio"), "1_3", "tasa_cambio"], [_("Importe recibido"), "1_3", "importe_recibido_convertido"], [_("Proyecto"),"1_3", "proyecto.nombre"], [_("Financiadores"), "1", "importes_por_financiadores"] ]
      when "pago_socio" then [ [_("Fecha de Alta en Sistema"), "1_3", "fecha_alta_sistema"] ]
      when "documento" then [ [_("Modificado por"), "1", "usuario.nombre_completo"], [_("Etiquetas"), "1", "etiquetas"], [ _("Ubicación"), "1", "ruta_espacio_original" ], [ _("Vinculado en"), "1", "ruta_espacios_vinculados" ] ]
      when "libro" then [ [_("Ocultar"),"1_3", "oculto", true], [_("Descripción"), "1_3", "descripcion"], [_("Entidad"), "1_3", "entidad"], [_("SWIFT"), "1_3", "swift"], [_("IBAN"), "1_3", "iban"] ]
      when "partida_financiacion" then [[_("Partida tipo 'madre'"), "1_3", "padre"], [_("Partida 'madre'"), "1_3", "partida_financiacion_madre.codigo"] ]
      when "grupo_usuario_x" then [[_("Miembros"), "1_3", "grupo_usuario.miembros"]]
      when "factura" then [[_("Importe en el proyecto"),"1_2_td", "gasto_x_proyecto.first.importe"], ["Moneda","1_4", "moneda.abreviatura"], [_("Partida"),"3_4","partida.codigo_nombre " + (@proyecto ? @proyecto.id.to_s : "nil")], [_("Concepto"),"1", "concepto"], [_("Cambio"), "1_4", "updated_at"], [_("Subpartida"), "1", "subpartida_proyecto_nombre " + @proyecto.id.to_s ], [_("Valorizado"), "1", "es_valorizado"], [_("País"), "1", "pais.nombre"], [_("Nº Factura"), "1_2", "numero_factura"], [_("Emisor Factura"), "1", "proveedor.nombre"], [_("NIF Emisor"), "1_2", "proveedor.nif"], [_("Tipo Partida"), "3_4", "partida.tipo"], [_("Observaciones"), "1", "observaciones"], [_("Referencia Contable"), "1", "ref_contable"], [_("Impuestos"), "1_2", "impuestos"], [_("T.Cambio"), "1_2_td", "tasa_cambio_proyecto " + @proyecto.id.to_s + ".tasa_cambio"],[_("Importe x TC"), "1_2_td", "importe_x_proyecto_en_base " + @proyecto.id.to_s], [_("Actividades"), "1", "importes_por_actividades " + @proyecto.id.to_s], [_("Financiadores"), "1", "importes_por_financiadores " + @proyecto.id.to_s]] 
      when "personal" then [[_("Residencia"), "1", "residencia"], [_("Tipo de Contrato"), "2", "tipo_contrato"], [_("Horas/Semana Imputadas"), "1", "horas_imputadas"], [_("Salario Bruto Mensual"), "1", "salario_mensual"], [_("Meses"), "1", "meses"], [_("Salario Bruto Total"), "1", "salario_total"], [_("Moneda Salario"), "1_2", "moneda.nombre"] ]
      when "proveedor" then [[_("Entidad Bancaria"), "1", "entidad_bancaria"], [_("Cuenta Bancaria"), "1", "cuenta_bancaria"], [_("Descripción"), "1", "descripcion"], [_("Observaciones"), "2", "observaciones"], [_("Agente"), "1", "agente.nombre"]]
      when "workflow_contrato" then [ [_("Documentos necesarios"), "2", "etiqueta_nombre" ] ]
      when "tipo_contrato" then [ [_("Observaciones"), "2", "observaciones"], [_("Duración máxima (meses)"), "1", "duracion"] ]
      when "contrato" then [ [_("NIF Proveedor"), "1", "proveedor.nif"], [_("Importe total"), "1", "importe"], [_("Moneda"), "1", "moneda.nombre"], [_("Actividades"), "1", "importes_por_actividades"], [_("Fecha inicio"), "1", "fecha_inicio"], [_("Fecha fin"), "1", "fecha_fin"] ]
      when "estado_contrato" then [[_("Observaciones"), '2', 'observaciones'], [_("Documentos subidos"), '2', 'documento_nombre'], [_("Etiquetas documentales"), '2', 'etiqueta_nombre']]
      when "campo_tipo_contrato" then [[_("Descripción"), '2', 'descripcion'], [_("Condicion"), '1', 'tipo_condicion'], [_("Valor Condicion"), '1', 'valor_condicion']]
      when "ingreso" then [ [_("Observaciones"), "2", "observaciones"], [_("Proveedor"), "1", "proveedor.nombre"], [_("NIF Proveedor"), "1", "proveedor.nif"], [_("Número de documento"), "1", "numero_documento"], [_("Valorizado"), "1", "es_valorizado"], [_("Financiador"), "1", "financiador.nombre", true], [_("Proyecto"), "1", "proyecto.nombre"], [_("Referencia Contable"), "1", "ref_contable"], [_("T.Cambio"), "1_2_td", "tasa_cambio.tasa_cambio"],[_("Importe x TC"), "1_2_td", "importe_en_base"] ]
      when "plugin" then [[_("Versión"), "1", "version"]]
      when "periodo" then [[_("Gastos cerrados"), "1_2", "gastos_cerrados"], [_("Descripción"), "1_2", "descripcion" ]]
      else []
    end
    # Revisamos cada plugin para que incluya o elimine los campos que necesite
    Plugin.activos.each { |plugin| campos = eval(plugin.clase)::campos_info(modelo, campos) if eval(plugin.clase).respond_to?('campos_info') }
    return campos
  end

end

