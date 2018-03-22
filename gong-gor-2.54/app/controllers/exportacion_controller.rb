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
# Controlador encargado de la gestión de socio. Este controlador es utilizado desde las secciones:
# * Sección socio: exportar socio a 812 o a excel


class ExportacionController < ApplicationController
  require 'spreadsheet'
  
  TAMANO_MAXIMUM_COLUMNA = 40

  # en socio: exporta a 812 o excel
  def index
    # [["Matriz", "matriz"], ["Partidas","partidas"], ["Presupuesto","presupuesto"], ["Gastos","gasto"], ["Movimientos","transferencia"]]
    @opciones = []
    @opciones += [[_("Partidas") + " " + @proyecto.agente.nombre,"partida"]] if @proyecto && params[:menu] == "configuracion"
    @opciones += [[_("Subpartidas"), "subpartida"]] if @agente || (@proyecto && params[:menu] == "configuracion")
    @opciones += [[_("Matriz"),"matriz"]] if @proyecto && params[:menu] == "formulacion"
    @opciones += [[_("Presupuesto"),"presupuesto"]] if @agente || (@proyecto && params[:menu] == "formulacion")
    @opciones += [[_("Gastos"),"gasto"]] if @agente || (@proyecto && params[:menu] == "ejecucion_economica")
    @opciones += [[_("Movimientos"),"transferencia"]] if @agente || (@proyecto && params[:menu] == "ejecucion_economica")

    # Si recibimos un formulario...
    if params[:selector]
      # incialización de las variables
      parametro = ""
      tipo = params[:selector][:tipo]
      pais = params[:selector][:pais]
      cofinanciados = params[:selector][:cofinanciados] == "1"
      params[:selector][:fecha_inicio] = params[:selector]["fecha_inicio(1i)"] + "-" + params[:selector]["fecha_inicio(2i)"] + "-01"
      params[:selector][:fecha_fin] = params[:selector]["fecha_fin(1i)"] + "-" + params[:selector]["fecha_fin(2i)"] + "-01"
      @fecha_inicio = params[:selector][:fecha_inicio]
      @fecha_fin = params[:selector][:fecha_fin]
      @format_color = Spreadsheet::Format.new :pattern => 1, :pattern_fg_color => :aqua
      @no_repetido = Hash.new # el hash que no sirve para no repetir un atributo marcado en una columna

      # En el caso de que se haya escogido una plantilla la usamos, si no generamos una hoja nueva
      # Capturamos los errores en una excepcion por si no es una hoja de calculo buena
      begin
        fichero = Tempfile.new('exportacion_' + SecureRandom.hex + '.xls.')
        if params[:selector][:plantilla] && params[:selector][:plantilla] != ""
          libro = Spreadsheet.open Documento.find(params[:selector][:plantilla]).adjunto.path
          hoja = libro.worksheet 0
        else
          #libro = Spreadsheet::Workbook.new
          #hoja = libro.create_worksheet(:name => tipo.capitalize) if tipo != "matriz"
          libro = spreadsheet @proyecto||@agente, tipo
          hoja = libro.worksheet(0) if tipo != "matriz"
        end
      rescue Ole::Storage::FormatError
        @export_error = _("ERROR: La plantilla elegida no es una hoja de cálculo válida")
      rescue => ex
        logger.error ex.message
        logger.error ex.backtrace
        @export_error = _("Error Inesperado: Contacte con el administrador del sistema.")
      end

      if libro
        parametros = {fecha_inicio: @fecha_inicio, fecha_fin: @fecha_fin, pais: pais, cofinanciados: cofinanciados}
        case tipo
          when "matriz" then
            exportar_matriz( libro, parametros ) if params[:seccion] == "proyectos"
          when "presupuesto" then
            exportar_presupuesto_proyecto( hoja, parametros ) if params[:seccion] == "proyectos"
            exportar_presupuesto_agente( hoja, parametros ) if params[:seccion] == "agentes"
          when "gasto" then
            exportar_gasto_proyecto( hoja, parametros ) if params[:seccion] == "proyectos"
            exportar_gasto_agente( hoja, parametros ) if params[:seccion] == "agentes"
	  when "transferencia" then
	    exportar_transferencia( hoja, parametros )
          when "partida" then
            exportar_partidas( hoja, @proyecto ) if params[:seccion] == "proyectos"
          when "subpartida" then
            exportar_subpartidas( hoja, (@proyecto||@agente) )
        end

        buffer = StringIO.new
        libro.write buffer
        buffer.rewind

        # Comprueba que se haya generado el fichero de salida
        nom_fich = (@proyecto||@agente).nombre.gsub(' ','-') + "_" + tipo + "_" + Time.now.strftime("%Y-%m-%d") + ".xls"
        send_data buffer.read,
          :disposition => 'attachment',
          :type => "application/vnd.ms-excel",
          :encoding => 'utf8',
          :filename => nom_fich,
          :stream => false
      end
    end
  end

  #--
  # METODOS DE  FORMULARIO
  #++

  # ajax que devuelve un listado de los ficheros de plantilla segun el tipo de exportacion elegido 
  def plantillas
    etiqueta = Etiqueta.find_by_nombre("Exportacion Presupuesto") if params[:selector_tipo] == "presupuesto"
    etiqueta = Etiqueta.find_by_nombre("Exportacion Gasto") if params[:selector_tipo] == "gasto"
    etiqueta = Etiqueta.find_by_nombre("Exportacion Transferencia") if params[:selector_tipo] == "transferencia"
    espacio_plantillas =  Espacio.find_by_nombre "Plantillas Exportación"
      @plantillas = espacio_plantillas.documento.select {|d| d.etiqueta.include? etiqueta}  if etiqueta
      @plantillas = @plantillas.collect {|d| [d.adjunto_file_name,d.id ]  }  if etiqueta
    render :partial => "plantillas", :locals => { :tipo_plantilla => params[:selector_tipo] }
  end


private

  #--
  # METODOS DE EXPORTACION
  #++

  def exportar_presupuesto_proyecto hoja, parametros={}
    condiciones = "proyecto_id = '" + @proyecto.id.to_s + "'"

    # De momento pasamos de fechas
    #if( parametros )
    #  condiciones << " and fecha_inicio >=  '" + parametros[:fecha_inicio] + "'" unless ( parametros[:fecha_inicio].nil? or parametros[:fecha_inicio].empty?)
    #  condiciones << " and fecha_fin <=  '" + parametros[:fecha_fin] + "'" unless ( parametros[:fecha_fin].nil? or parametros[:fecha_fin].empty?)
    #end

    # Cada campo tiene 1) su rotulo, 2) su atributo (anidado con puntos si hay subatributos. Igual que en el helper
    campos_presupuestos = [	["Id", "id"], ["Agente Nombre", "agente.nombre"], ["Etapa", "etapa.nombre"],
				["Unidad", "unidad"], ["NºUnidades", "numero_unidades"], ["Coste Unitario", "coste_unitario"], ["Importe", "importe"],
				["Moneda Abreviatura", "moneda.abreviatura"], ["Partida Codigo", "partida.codigo"], ["Subpartida", "subpartida.nombre"],
				["País","pais.nombre"], ["Concepto", "concepto"], ["Observaciones", "observaciones"],
				["Actividad", "presupuesto_x_actividad", [[ "Actividad Código","actividad.codigo"], ["Actividad Importe", "importe"], ["Actividad Unidades", "numero_unidades"]]],
				["Financiador", "presupuesto_x_agente", [["Financiador Nombre", "agente.nombre"], ["Financiador Importe", "importe"]]]
				]
    linea_presupuesto = 0
    # PREPARACIÓN DE LA CABEZERA DE PRESUPUESTO
    @tamano_columnas_presupuestos = []
    linea_presupuesto = preparar_cabecera(linea_presupuesto, hoja, campos_presupuestos, "presupuestos")
   
    color = true 
    @presupuestos = Presupuesto.find(:all, :conditions => condiciones).each do |presupuesto|
      linea_presupuesto = inscribir_datos(linea_presupuesto, presupuesto, campos_presupuestos, hoja, @tamano_columnas_presupuestos, color)
      color = !color
    end
  end

  def exportar_presupuesto_agente hoja, parametros={}
    condiciones = { "agente_id" => @agente.id, "proyecto_id" => nil }

    # De momento pasamos de fechas
    #if( parametros )
    #  condiciones << " and fecha_inicio >=  '" + parametros[:fecha_inicio] + "'" unless ( parametros[:fecha_inicio].nil? or parametros[:fecha_inicio].empty?)
    #  condiciones << " and fecha_fin <=  '" + parametros[:fecha_fin] + "'" unless ( parametros[:fecha_fin].nil? or parametros[:fecha_fin].empty?)
    #end

    # Cada campo tiene 1) su rotulo, 2) su atributo (anidado con puntos si hay subatributos. Igual que en el helper
    campos_presupuestos = [     ["Id", "id"], ["Etapa", "etapa.nombre"],
                                ["Unidad", "unidad"], ["NºUnidades", "numero_unidades"], ["Coste Unitario", "coste_unitario"], ["Importe", "importe"],
                                ["Moneda Abreviatura", "moneda.abreviatura"], ["Partida Codigo", "partida.codigo"], ["Subpartida", "subpartida.nombre"],
                                ["Concepto", "concepto"], ["Observaciones", "observaciones"],
                                ]
    linea_presupuesto = 0
    # PREPARACIÓN DE LA CABEZERA DE PRESUPUESTO
    @tamano_columnas_presupuestos = []
    linea_presupuesto = preparar_cabecera(linea_presupuesto, hoja, campos_presupuestos, "presupuestos")

    color = true
    @presupuestos = Presupuesto.find(:all, :conditions => condiciones).each do |presupuesto|
      linea_presupuesto = inscribir_datos(linea_presupuesto, presupuesto, campos_presupuestos, hoja, @tamano_columnas_presupuestos, color)
      color = !color
    end
  end

  def exportar_gasto_proyecto hoja, parametros={}
    condiciones = { "gasto_x_proyecto.proyecto_id" => @proyecto.id }
    condiciones["proyecto_origen_id"] = @proyecto.id unless parametros[:cofinanciados]
    # Si el proyecto tiene configurada visibilidad limitada, exportamos tan solo los gastos de implementadores
    # asociados al usuario a no ser que el usuario sea un admin
    if @proyecto.ocultar_gastos_otras_delegaciones && !@proyecto.usuario_admin?(@usuario_identificado)
      agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado)
      condiciones["gasto.agente_id"] = agentes_permitidos
    end

    # De momento pasamos de fechas
    #if( parametros )
    #  condiciones << " and fecha >=  '" + parametros[:fecha_inicio] + "'" unless ( parametros[:fecha_inicio].nil? or parametros[:fecha_inicio].empty?)
    #  condiciones << " and fecha <=  '" + parametros[:fecha_fin] + "'" unless ( parametros[:fecha_fin].nil? or parametros[:fecha_fin].empty?)
    #end

    # cada campo tiene 1) su rotulo, 2) su atributo (anidado con puntos si hay subatributos). Igual que en el helper 
    #campos_gastos = [	["Id", "id"], ["Libro Nombre", "libro.nombre"], ["Fecha", "fecha"] , ["Impuestos", "impuestos"], ["Importe", "importe"],
    campos_gastos = [	["Id", "id"], ["Implementador", "agente.nombre"], ["Pais", "pais.nombre"], ["Fecha", "fecha"],
                        ["Impuestos", "impuestos"], ["Importe", "gasto_x_proyecto.first.importe"], ["Moneda", "moneda.abreviatura"],
			["Partida Codigo", "partida.codigo"], ["Subpartida", "subpartida_proyecto_nombre " + @proyecto.id.to_s],
			["Concepto", "concepto"], ["Num.Factura", "numero_factura"], ["Emisor", "proveedor_nombre"], ["NIF Emisor", "proveedor_nif"],
			["Observaciones", "observaciones"],
			["Actividad", "actividad " + @proyecto.id.to_s, [[ "Actividad Código","actividad.codigo"], ["Actividad Importe", "importe"]]],
			["Financiador", "financiador " + @proyecto.id.to_s, [["Financiador Nombre", "agente.nombre"], ["Financiador Importe", "importe"]]],
			["Pago", "pago", [["Fecha de Pago","fecha"], ["Cuenta de Pago","libro.nombre"], ["Importe Pagado","importe"], ["Observaciones","observaciones"],
                          ["Forma de Pago", "forma_pago"],["Referencia del Pago","referencia_pago"]] ],
      ["Gasto Valorizado", "es_valorizado"],["Ref. Contable", "ref_contable"]
      ]
    campos_gastos.push(["Proyecto Origen", "proyecto_origen"]) if parametros[:cofinanciados]

    linea_gasto = 0
    # PREPARACIÓN DE LA CABECERA DE GASTO
    @tamano_columnas_gastos = []
    linea_gasto = preparar_cabecera(linea_gasto, hoja, campos_gastos, "gastos")
    
    @gastos = Gasto.find(:all, :include => :gasto_x_proyecto, :conditions => condiciones)

    color=true
    @gastos.each do |gasto|
      #puts "----------> " + gasto.inspect
      #puts "----------> " + campos_gastos.inspect
      linea_gasto = inscribir_datos(linea_gasto, gasto, campos_gastos, hoja, @tamano_columnas_gastos,color)
      color = !color
    end
  end

  def exportar_gasto_agente hoja, parametros={}
    # De momento pasamos de fechas
    #if( parametros )
    #  condiciones << " and fecha >=  '" + parametros[:fecha_inicio] + "'" unless ( parametros[:fecha_inicio].nil? or parametros[:fecha_inicio].empty?)
    #  condiciones << " and fecha <=  '" + parametros[:fecha_fin] + "'" unless ( parametros[:fecha_fin].nil? or parametros[:fecha_fin].empty?)
    #end

    # cada campo tiene 1) su rotulo, 2) su atributo (anidado con puntos si hay subatributos). Igual que en el helper 
    campos_gastos = [   ["Id", "id"], ["Implementador", "agente.nombre"], ["Fecha", "fecha"], ["Importe", "importe"], ["Moneda", "moneda.abreviatura"],
                        ["Impuestos", "impuestos"], ["Partida Codigo", "partida.codigo"], ["Subpartida", "subpartida_agente.nombre"], ["Concepto", "concepto"],
			["Num.Factura", "numero_factura"], ["Emisor", "proveedor_nombre"], ["NIF Emisor", "proveedor_nif"],
                        ["Observaciones", "observaciones"],
			["Proyecto", "gasto_x_proyecto", [["Proyecto", "proyecto.nombre"], ["Importe", "importe"]]],
			["Pago", "pago", [["Fecha de Pago","fecha"], ["Cuenta de Pago","libro.nombre"], ["Importe Pagado","importe"], ["Observaciones","observaciones"],
                          ["Forma de Pago", "forma_pago"],["Referencia del Pago","referencia_pago"]] ],
      ["Gasto Valorizado", "es_valorizado"],  ["Ref. Contable", "ref_contable"], ["Empleado", "empleado.nombre"]
      ]

    linea_gasto = 0
    # PREPARACIÓN DE LA CABEZERA DE GASTO
    @tamano_columnas_gastos = []
    linea_gasto = preparar_cabecera(linea_gasto, hoja, campos_gastos, "gastos")

    @gastos = Gasto.find(:all, :conditions => {:agente_id => @agente.id, :proyecto_origen_id => nil} )

    color=true
    @gastos.each do |gasto|
      linea_gasto = inscribir_datos(linea_gasto, gasto, campos_gastos, hoja, @tamano_columnas_gastos,color)
      color = !color
    end
  end

  def exportar_transferencia hoja, parametros={}

    if params[:seccion] == "proyectos"
      condiciones = "proyecto_id = " + @proyecto.id.to_s
      # Si el proyecto define que filtremos gastos de otras oficinas y el usuario no es administrador del proyecto
      if @proyecto.ocultar_gastos_otras_delegaciones && !@proyecto.usuario_admin?(@usuario_identificado)
        agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado)
        agentes_id_permitidos = agentes_permitidos.collect{|a| a.id}.join(",")
        condiciones += " AND (libro.agente_id IN (" + agentes_id_permitidos + ") OR libro_destinos_transferencia.agente_id IN (" + agentes_id_permitidos + ") )"
      end
    else
      condiciones = "(libro.agente_id = " + @agente.id.to_s + " OR libro_destinos_transferencia.agente_id = " + @agente.id.to_s + ")"
      # Aqui hay que incluir un filtro que evite las transferencias de remanentes de pacs
    end
    # Evita las transferencias de remanentes entre pacs
    condiciones += " AND NOT remanente"

    # De momento pasamos de fechas
    #if( parametros )
    #  condiciones << " and fecha_inicio >=  '" + parametros[:fecha_inicio] + "'" unless ( parametros[:fecha_inicio].nil? or parametros[:fecha_inicio].empty?)
    #  condiciones << " and fecha_fin <=  '" + parametros[:fecha_fin] + "'" unless ( parametros[:fecha_fin].nil? or parametros[:fecha_fin].empty?)
    #end

    # Cada campo tiene 1) su rotulo, 2) su atributo (anidado con puntos si hay subatributos. Igual que en el helper
    campos_transferencia = [	["Id", "id"], [_("Fecha Envío"), "fecha_enviado"], [_("Importe Enviado"), "importe_enviado"],
				[_("Moneda enviada"), "libro_origen.moneda.abreviatura"], [_("Cuenta Origen"), "libro_origen.nombre"],
                                [_("Fecha Recepción"), "fecha_recibido"], [_("Importe Recibido"), "importe_recibido"], [_("Importe Obtenido"), "importe_cambiado"],
				[_("Moneda obtenida"), "libro_destino.moneda.abreviatura"], [_("Cuenta Destino"), "libro_destino.nombre"],
				[_("Tasa Cambio"), "tasa_cambio"], [_("Tipo"), "tipo"], [_("Subtipo"), "subtipo_movimiento.nombre"],
                                [_("IBAN"),"iban"],[_("Número de Cheque"),"numero_cheque"], [_("Observaciones"), "observaciones"],
				[_("Proyecto"), "proyecto.nombre"],
				[_("Financiador"), "transferencia_x_agente", [[_("Financiador"), "agente.nombre"], [_("Importe enviado"), "importe"]] ],
                                ]
    linea_transferencia = 0
    # PREPARACIÓN DE LA CABEZERA DE PRESUPUESTO
    @tamano_columnas_transferencias = []
    linea_transferencia = preparar_cabecera(linea_transferencia, hoja, campos_transferencia, "transferencias")

    color = true
    @transferencias = Transferencia.find(:all, :include => [:libro_origen,:libro_destino], :conditions => condiciones).each do |transferencia|
      linea_transferencia = inscribir_datos(linea_transferencia, transferencia, campos_transferencia, hoja, @tamano_columnas_transferencias, color)
      color = !color
    end
  end

  def exportar_partidas hoja, objeto 

    # Cada campo tiene 1) su rotulo, 2) su atributo (anidado con puntos si hay subatributos. Igual que en el helper
    campos_partida = [		["Codigo", "codigo"], ["Nombre", "nombre"], ["Descripcion","descripcion"], ["Tipo", "tipo"],
				["Puede Ser Madre", "puede_ser_padre"] , ["Es Partida Madre", "padre"], ["Partida Madre", "partida_financiacion_madre.codigo"],
				["Porcentaje Máximo", "porcentaje_maximo"],
				["Partida Sistema", "partida", [["Codigo Partida Sistema", "codigo"]]]
				]
    linea_partida = 0
    # PREPARACIÓN DE LA CABEZERA DE PRESUPUESTO
    @tamano_columnas_partidas = []
    linea_partida = preparar_cabecera(linea_partida, hoja, campos_partida, "partidas")

    color = true
    @partidas = objeto.partida_financiacion.each do |partida|
      linea_partida = inscribir_datos(linea_partida, partida, campos_partida, hoja, @tamano_columnas_partidas, color)
      color = !color
    end
  end

  def exportar_subpartidas hoja, objeto

    # Cada campo tiene 1) su rotulo, 2) su atributo (anidado con puntos si hay subatributos. Igual que en el helper
    campos_subpartida = [          ["Nombre", "nombre"], ["Partida Relacionada","partida.codigo_nombre"] ]
    linea_subpartida = 0
    # PREPARACIÓN DE LA CABEZERA DE PRESUPUESTO
    @tamano_columnas_subpartidas = []
    linea_subpartida = preparar_cabecera(linea_subpartida, hoja, campos_subpartida, "subpartidas")

    color = true
    @partidas = objeto.subpartida.all(:order => 'nombre').each do |subpartida|
      linea_subpartida = inscribir_datos(linea_subpartida, subpartida, campos_subpartida, hoja, @tamano_columnas_subpartidas, color)
      color = !color
    end
  end

  def exportar_matriz libro, parametros={}
    campos_objetivos = [	["Código", "codigo"], ["Descripcion", "descripcion"],
				["IOV", "indicador", [["IOV Código", "codigo"], ["IOV Descripcion", "descripcion"]]],
				["FV", "fuente_verificacion", [["FV Código","codigo"], ["FV Descripcion","descripcion"], ["FV Indicador Relacionado","indicador.codigo"] ] ],
				["Hipotesis", "hipotesis", [["Hipotesis Descripción","descripcion"]]]
				]

    campos_resultados = [	["Código", "objetivo_especifico.codigo"], ["Resultado Código", "codigo"], ["Resultado Descripcion", "descripcion"],
				["RIOV", "indicador", [["RIOV Código","codigo"], ["RIOV Descripcion", "descripcion"]]],
				["RFV", "fuente_verificacion", [["RFV Código", "codigo"], ["RFV Descripcion", "descripcion"], ["RFV Indicador Relacionado", "indicador.codigo"] ] ],
				["RH", "hipotesis", [["RH Descripción","descripcion"]]]
				]

    campos_actividades = [	["Resultado Código", "resultado.codigo", true], ["Actividad Código", "codigo"], ["Actividad Descripcion", "descripcion"],
				["Pais", "pais", [["Pais","nombre"]]], ["Etapa", "etapa", [["Etapa", "nombre"]]]
				]

    campos_actividades.push( ["Actividad de Convenio Relacionada", "actividad_convenio.codigo"] ) if @proyecto.convenio_id

    campos_variables = [	["Indicador", "indicador.codigo"], ["Indicador de Resultado?", "indicador.objetivo_especifico.nil?"], ["Variable", "nombre"],
				["Herramienta de Medición", "herramienta_medicion"], ["Fuente de Información", "fuente_informacion"], ["Contexto", "contexto"],
				["Valor Base", "valor_base.valor"], ["Fecha Base", "valor_base.fecha"], ["Comentario Valor Base", "valor_base.comentario"],
				["Valor Objetivo", "valor_objetivo.valor"], ["Fecha Objetivo", "valor_objetivo.fecha"], ["Comentario Valor Objetivo", "valor_objetivo.comentario"],
				["Valor", "valor_medido", [["Valor Medido","valor"], ["Fecha Medición","fecha"],["Comentario a la Medición","comentario"]]]
				]

    linea_objetivo = linea_resultado = linea_actividad = linea_variable = 0
    # PREPARACIÓN CABECERA DE OBJETIVOS
    @tamano_columnas_objetivos = []
    page_objetivos = libro.create_worksheet :name => "Objetivos Especificos"
    linea_objetivo = preparar_cabecera(linea_objetivo, page_objetivos, campos_objetivos, "objetivos")

    # PREPARACIÓN CABECERA DE RESULTADOS
    @tamano_columnas_resultados = []
    page_resultados = libro.create_worksheet :name => "Resultados"
    linea_resultado = preparar_cabecera(linea_resultado, page_resultados, campos_resultados, "resultados")

    # PREPARACIÓN CABECERA DE ACTIVIDADES
    @tamano_columnas_actividades = []
    page_actividades = libro.create_worksheet :name => "Actividades"
    linea_actividad = preparar_cabecera(linea_actividad, page_actividades, campos_actividades, "actividades")

    # PREPARACIÓN CABECERA DE VARIABLES
    @tamano_columnas_variables = []
    page_variables = libro.create_worksheet :name => "Variables de Indicadores"
    linea_variable = preparar_cabecera(linea_variable, page_variables, campos_variables, "variables")

    objetivos = []
    color = true 
    ObjetivoEspecifico.find_all_by_proyecto_id(@proyecto.id).each do |objetivo|
      unless objetivos.include?(objetivo.codigo)
        linea_objetivo = inscribir_datos(linea_objetivo, objetivo, campos_objetivos, page_objetivos, @tamano_columnas_objetivos,color)
        objetivos += [objetivo.codigo]
        color = !color
      end
    end

    resultados = []
    color = true 
    Resultado.find_all_by_proyecto_id(@proyecto.id).each do |resultado|
      unless resultados.include?(resultado.codigo)
        linea_resultado = inscribir_datos(linea_resultado, resultado, campos_resultados, page_resultados, @tamano_columnas_resultados,color)
        resultados += [resultado.codigo]
        color = !color
      end
    end

    color = true 
    Actividad.find_all_by_proyecto_id(@proyecto.id).each do |actividad|
      linea_actividad = inscribir_datos(linea_actividad, actividad, campos_actividades, page_actividades, @tamano_columnas_actividades,color)
      color = !color
    end

    color = true
    Indicador.find(:all,:include=>["objetivo_especifico","resultado"],:conditions=>["objetivo_especifico.proyecto_id=? OR resultado.proyecto_id=?",@proyecto.id,@proyecto.id]).each do |indicador|
      indicador.variable_indicador.each do |variable|
        linea_variable = inscribir_datos(linea_variable, variable, campos_variables, page_variables, @tamano_columnas_variables, color)
        color = !color
      end
    end
  end
  

  def preparar_cabecera(linea, page, campos, objeto)
    numero_de_columna = 0
    campos.each do |campo|
      if campo[2] and campo[2].class.to_s == "Array"
        campo[2].each do |c|
          page[linea,numero_de_columna] = c[0]
          eval("@tamano_columnas_" + objeto)[numero_de_columna] = c[0].length
          page.column(numero_de_columna).width = eval("@tamano_columnas_" + objeto)[numero_de_columna] + 1
          numero_de_columna = numero_de_columna + 1
        end
      else
        page[linea,numero_de_columna] = campo[0]
        eval("@tamano_columnas_" + objeto)[numero_de_columna] = campo[0].length
        page.column(numero_de_columna).width = eval("@tamano_columnas_" + objeto)[numero_de_columna] + 1
        numero_de_columna = numero_de_columna + 1
      end
    end
    format = Spreadsheet::Format.new :weight => :bold
    page.row(0).default_format = format
    return linea + 1
  end

  def inscribir_datos(linea_objeto, objeto, campos, page, tamano_columnas, color=false)
    # Eliminamos el listado en "pijama"
    color=false

    linea_max = 0 # linea de altura max alcazada por un array en una linea de objeto
    numero_de_columna = 0
    linea = linea_objeto # posición inicial
    #puts "------------> Vamos a procesar en la linea " + linea_objeto.to_s + " los campos de " + campos.inspect
    campos.each do |campo|
      if campo[2].class.to_s == "Array" # ej. campo[2] => [["IOV Código", "codigo"], ["IOV Descripcion", "descripcion"]]
        campo[2].each do |c| # ej. c => ["IOV Código", "codigo"]
          # se inicia una columna a cada miembro del array
          linea_objeto = linea # volvemos a la posición inicial a iniciar una columna
          objeto_atribu_1 = ( campo[1] =~ /(\S+)\s(\S+)/ ? objeto.send($1,$2) : objeto.send(campo[1]) )
          objeto_atribu_1.each do |obj| # obtenemos un array por ej. resultado.indicador
            #logger.info "             Linea(array) es: " + linea_objeto.inspect + " y numero de columna: " + numero_de_columna.inspect
            # por cada miembro de array suplementario linea_objeto tiene que ser incrementada
            page[linea_objeto, numero_de_columna] = obtiene_valor(obj, c[1])
            tamano_columnas[numero_de_columna] = ajusta_celda page, linea_objeto, numero_de_columna, tamano_columnas[numero_de_columna], color
            linea_max = ((linea_objeto - linea) > linea_max) ? linea_objeto - linea : linea_max
            linea_objeto += 1
          end
          linea_objeto = linea + 1
          numero_de_columna += 1
        end
      elsif campo[2].class.to_s == "String"
        valor_campo_actual = obtiene_valor objeto, campo[1]
        if campo[3]
          @no_repetido["cadena-" + campo[1] + campo[2]] = "" unless @no_repetido["cadena-" + campo[1] + campo[2]]
          page[linea, numero_de_columna] = valor_campo_actual == @no_repetido["cadena-" + campo[1] + campo[2]] ? "" : valor_campo_actual
          @no_repetido["cadena-" + campo[1] + campo[2]] = valor_campo_actual
        else
          page[linea, numero_de_columna] = valor_campo_actual
        end
        tamano_columnas[numero_de_columna] = ajusta_celda page, linea, numero_de_columna, tamano_columnas[numero_de_columna], color
        numero_de_columna += 1
      else
        page[linea, numero_de_columna] = obtiene_valor(objeto, campo[1])
        #logger.info "----------------------> " + campo[1] + ": " + page[linea_objeto, numero_de_columna].inspect
        tamano_columnas[numero_de_columna] = ajusta_celda page, linea, numero_de_columna, tamano_columnas[numero_de_columna], color
        numero_de_columna += 1
      end
    end
    return linea += linea_max + 1
  end

  # Hacemos ajustes de tamaño
  def ajusta_celda page, linea, columna, tamano, color
    if( page[linea, columna] and page[linea, columna].to_s.length > tamano and page[linea, columna].to_s.length <= TAMANO_MAXIMUM_COLUMNA )
      tamano = page[linea, columna].to_s.length
      page.column(columna).width = tamano
    end 
    page.row(linea_objeto).default_format = @format_color if color
    return tamano
  end

  # Obtiene el valor a meter en la celda
  def obtiene_valor objeto, campos
    campos.split('.').each do |metodo|
      if objeto || metodo == "nil?"
        if objeto.class.name == "Array" && !objeto.respond_to?(metodo)
          objeto = objeto.collect{ |obj| obj.send(metodo) }
        else
          objeto = ( metodo =~ /(\S+)\s(\S+)/ ? objeto.send($1,$2) : objeto.send(metodo) )
        end
      end
    end
    # La conversion de BigDecimal a Float la hacemos por un bug en spreadsheet
    return (objeto.class==FalseClass || objeto.class==TrueClass) ? (objeto && _("SI"))||_("NO") : (objeto.class==BigDecimal ? objeto.to_f : objeto)
  end

  # Obtenemos la plantilla de gasto para proyectos si existe
  def spreadsheet objeto=nil, tipo="gasto"
    fichero = Tempfile.new('exportacion_' + SecureRandom.hex + '.xls.')
    objeto ||= @proyecto
    seccion = objeto.class.name.downcase
    datos = {	"proyecto" => {
                  "presupuesto" => [ "implementador.nombre", "etapa.nombre", "moneda.abreviatura", "partidas_mapeadas.codigo",
                                     "partidas_mapeadas.nombre", "codigos_oe_resultados_y_actividades", "financiador.nombre","pais_gasto.nombre"],
                  "gasto" => [	"implementador.nombre", "moneda.abreviatura",
                                "partidas_mapeadas.codigo", "partidas_mapeadas.nombre", "partidas_mapeadas_financiador.codigo", "partidas_mapeadas_financiador.nombre",
                                "codigos_oe_resultados_y_actividades", "nombres_oe_resultados_y_actividades", "financiador_gasto.nombre", "libro.nombre", "pais_gasto.nombre",
                                "formas_de_pago", "subpartida.partida.codigo", "subpartida.nombre" ],
                  "transferencia" => [ "moneda.abreviatura", "libro.nombre", "nombre", "financiador_gasto.nombre" ],
                },
		"agente" => {
		  "presupuesto" => [ "etapa.nombre", "moneda.abreviatura", "partida.codigo", "partida.nombre" ],
		  "gasto" => [ "nombre", "moneda.abreviatura", "partida.codigo", "partida.nombre", "proyectos_ejecucion.nombre", "libro.nombre", "empleado.nombre" ],
		  "transferencia" => [ "moneda.abreviatura", "libro.nombre", "proyectos_ejecucion.nombre" ],
		},
	    }
    if File.exists?"public/system/plantilla_" + seccion + "_" + tipo + ".xls"
      # Primero lo copiamos
      FileUtils.cp "public/system/plantilla_" + seccion + "_" + tipo + ".xls", fichero
      # Y luego lo abrimos
      Spreadsheet.client_encoding = 'UTF-8'
      book = Spreadsheet.open fichero
      sheet = book.worksheet(1)
      col = 0
      # Recorre todos los campos a rellenar
      datos[seccion][tipo].each do |campo|
        # Obtiene los valores de cada uno de ellos
        element = obtiene_valor(objeto, campo)
        # Si no es un array, pasamos a array
        element = [ element.to_s ] unless element.class.name == "Array"
        # Y los mete en la hoja
        row = 1
        element.each do |e|
          sheet[row,col] = e.to_s
          row += 1
        end
        col += 1
      end
    else
      book = Spreadsheet::Workbook.new
      book.create_worksheet(:name => tipo.capitalize) if tipo != "matriz"
    end
    return book
  end
end
