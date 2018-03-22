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
# Controlador encargado de la importacion y sincronizacion de la matriz, gastos y presupuestos de un proyecto. Este controlador es utilizado desde las seccion de proyectos. Tiene 3 grupos de metodos: 
# * Los encargados de la importacion de matriz.
# * Los encargados de la importación de presupuesto.
# * Los metodos encargados de la importación de gasto.

class ImportacionController < BaseImportacionController

  #before_filter :verificar_estado_formulacion, :only => [ ]
  #before_filter :verificar_estado_ejecucion, :only => [ ]
  before_filter :inicializa_controlador

  def inicializa_controlador
    @opciones  = []
    @opciones += [[_("Partidas") + " " + @proyecto.agente.nombre,"partida"]] if @proyecto && @permitir_configuracion
    @opciones += [[_("Subpartidas"),"subpartida"]] if (@proyecto && @permitir_configuracion) || @agente
    @opciones += [[_("Matriz"),"matriz"]] if @proyecto && @permitir_formulacion
    @opciones += [[_("Presupuesto"),"presupuesto"]] if (@proyecto && @permitir_formulacion) || @agente
    @opciones += [[_("Gastos"),"gasto"]] if (@proyecto && @permitir_ejecucion) || @agente 
    @opciones += [[_("Movimientos"),"transferencia"]] if (@proyecto && @permitir_ejecucion) || @agente
    @opciones ||= []

    @proyectos = [[_("Sin proyecto"),nil]] + ProyectoXImplementador.find(:all, :conditions => { :agente_id => @agente.id }).collect { |pxi| [pxi.proyecto.nombre, pxi.proyecto_id] } if params[:seccion] == "agentes"
    if params[:seccion] == "proyectos"
      # Si el proyecto tiene configurada visibilidad limitada, exportamos tan solo los gastos de implementadores
      # asociados al usuario a no ser que el usuario sea un admin
      if @proyecto.ocultar_gastos_otras_delegaciones && !@proyecto.usuario_admin?(@usuario_identificado)
        agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado)
      else
        agentes_permitidos = @proyecto.implementador
      end
      @agentes = [[_("Todos"),nil]] + agentes_permitidos.collect {|imp| [imp.nombre, imp.id] }
    end
    @etapas = @proyecto ? [[_("Todas"),nil]] + @proyecto.etapa.sort{ |a, b| a.fecha_inicio <=> b.fecha_inicio }.collect{ |e| [e.nombre, e.id] } : 
		@agente.etapa.collect {|e| [e.nombre + " ( " + e.fecha_inicio.to_s + "  "+ e.fecha_fin.to_s + " ) ", e.id]} 
  end

  def index
  end

  def anadir_importacion
    if params[:selector] && params[:selector][:fichero]
      begin
        tmp = params[:selector][:fichero].tempfile
        Spreadsheet.client_encoding = 'UTF-8'

        book = Spreadsheet.open tmp.path 
        carga_total = params[:selector][:total]=="1" ? true : false
        etapa = (carga_total && params[:etapa]) ? Etapa.find_by_id(params[:etapa][:id]) : nil
        proyecto = (carga_total && params[:proyecto]) ? Proyecto.find_by_id(params[:proyecto][:id]) : nil
        agente = (carga_total && params[:agente]) ? Agente.find_by_id(params[:agente][:id]) : nil

        case params[:selector][:tipo]
          # Partida tiene 1 hoja
          when "partida" then
            importa_partidas_proyecto book.worksheet(0), true if params[:seccion] == "proyectos"
          # Subpartida tiene 1 hoja
          when "subpartida" then
            importa_subpartidas book.worksheet(0), true
          # Transferencia tiene 1 hoja
          when "transferencia" then
            importa_transferencias book.worksheet(0), carga_total, etapa, proyecto
          # Presupuesto tiene 1 hoja
          when "presupuesto" then 
            importa_presupuestos_proyecto book.worksheet(0), carga_total, etapa, agente if params[:seccion] == "proyectos"
            importa_presupuestos_agente book.worksheet(0), carga_total, etapa if params[:seccion] == "agentes"
          # Gasto tiene 1 hoja
          when "gasto" then 
            importa_gastos_proyecto book.worksheet(0), carga_total, params[:selector][:id_gasto] == "1", etapa, agente if params[:seccion] == "proyectos"
            importa_gastos_agente book.worksheet(0), carga_total, etapa, proyecto if params[:seccion] == "agentes"
          # Matriz tiene 3 hojas
          when "matriz" then 
            if params[:seccion] == "proyectos"
              if book.worksheets.length < 3
                importacion_error _("ERROR: La hoja de cálculo a importar no es de Matriz")
              else
                importa_matriz( true, book.worksheet(0), book.worksheet(1), book.worksheet(2), (book.worksheets.length > 3 ? book.worksheet(3) : nil) )
              end
            else
              importacion_error _("No se puede importar la matriz desde la seccion Agentes")
            end
        end
        @import_error ||= ""
      rescue Ole::Storage::FormatError
        importacion_error _("ERROR: El documento no es una hoja de cálculo válida")
      rescue => ex
        logger.error ex.message
        logger.error ex.backtrace
        importacion_error _("Error inesperado: Contacte con el administrador del sistema.")
      end
    end
    render :index
  end

  #--
  # METODOS DE IMPORTACIÓN
  #++

  # Importa una hoja de partidas de proyecto 
  def importa_partidas_proyecto hoja, carga_total=true, etapa=nil
    # El orden de las columnas es:
    # simples ->        id | codigo | nombre | tipo | puede_ser_padre | padre | partida_financiacion_id
    # multiples ->	partida.codigo | partida.nombre
    columnas = [ "codigo", "nombre", "descripcion", "tipo", "puede_ser_padre", "padre", "partida_financiacion_codigo", "porcentaje", "partida.codigo"]
    indice = Hash[*columnas.each_with_index.to_a.flatten]
    partida = nil

    # Metemos todo en una transaccion para hacer rollback si es carga total y ha habido algun problema
    PartidaFinanciacion.transaction do
      # Si es una carga total, deberiamos eliminar todos los elementos relacionados
      PartidaFinanciacion.find(:all, :conditions => {"proyecto_id" => @proyecto.id}).each { |t| t.destroy } if carga_total
      # Itera cada fila 
      hoja.each_with_index do |fila,numero_fila|
        limpia_fila fila
        # Si existe alguno de los datos basicos, es una fila nueva => obtenemos la transferencia 
        partida = actualiza_partida_proyecto(indice, fila) if fila[indice['codigo']] && fila[indice['nombre']] && numero_fila > 0
        if ( partida )
          actualiza_partida_proyecto_sistema partida, indice, fila if fila[indice['partida.codigo']]
        end
      end
      # Si hubo algun error y seleccionamos carga total, deshacemos los cambios
      raise(ActiveRecord::Rollback, "Hacemos un rollback") if @import_error != ""
    end
  end

  # Importa una linea de partidas de proyecto
  def actualiza_partida_proyecto indice, fila
    partida = PartidaFinanciacion.new(:proyecto_id => @proyecto.id)

    # Si acabamos de crear la partida o existia...
    if partida
      partida.codigo = fila[indice['codigo']]
      partida.nombre = fila[indice['nombre']]
      partida.descripcion = fila[indice['descripcion']]
      partida.tipo = fila[indice['tipo']]
      partida.puede_ser_padre = fila[indice['puede_ser_padre']]
      partida.padre = (fila[indice['padre']] == "SI")
      if fila[indice['padre']] != "SI"
        partida_madre = @proyecto.partida_financiacion.find_by_codigo(fila[indice['partida_financiacion_codigo']])
        partida.partida_financiacion_id = partida_madre.id if partida_madre 
      end
      partida.porcentaje_maximo = fila[indice['porcentaje']]
      partida.save
      importacion_error partida, _("Partida") + " " + fila[indice['codigo']] + " (" + fila[indice['nombre']] + ")"
      partida = nil unless partida.errors.empty?
      puts "No tenemos ninguna partida... se han producido errores!!!!" unless partida
      # Limpia las partidas de sistema vinculadas para poder importarlas luego y que no esten duplicadas
      partida.partida_x_partida_financiacion.destroy_all if partida && partida.errors.empty? 
    # Si no se ha encontrado o no se ha podido crear la transferencia 
    else
      importacion_error "<br>" + _("Se produjeron errores procesando Partida ") + fila[indice['codigo']] + " (" + fila[indice['nombre']] + ")" 
      importacion_error _("Fué imposible crear la partida.")
    end

    return partida 
  end

  # Actualiza una vinculacion entre partida de sistema y de proyecto
  def actualiza_partida_proyecto_sistema partida, indice, fila
    partida_sistema = Partida.find_by_codigo fila[indice['partida.codigo']]
    #puts "Vamos a vincular la partida de financiador " + partida.id.to_s  

    # Si ha podido encontrar la partida de sistema a vincular... 
    if partida && partida_sistema
      pxp = PartidaXPartidaFinanciacion.new(:partida_id => partida_sistema.id, :partida_financiacion_id => partida.id)
      pxp.save
      importacion_error pxp, _("Partida de Sistema") + " '" + partida_sistema.codigo + "' " + _("en la Partida con Código") + " '" + partida.codigo + "'" 
    else
      importacion_error "<br>" + (_("Se produjeron errores asociando la Partida con Código '%{partida}': La Partida de Sistema '%{partida_sistema}' no existe." % {:partida => partida.codigo, :partida_sistema => fila[indice['partida.codigo']]}) )
    end
  end

  # Importa una hoja de subpartidas
  def importa_subpartidas hoja, carga_total = true
    # El orden de las columnas es:
    # simples ->        nombre | partida_relacionada
    columnas = [ "nombre", "partida.codigo_nombre" ]
    indice = Hash[*columnas.each_with_index.to_a.flatten]
    subpartida = nil
     
    # Metemos todo en una transaccion para hacer rollback si es carga total y ha habido algun problema
    Subpartida.transaction do
      # Eliminamos todas las subpartidas que no esten en la hoja (para evitar desvinculaciones)
      nombres = hoja.collect {|fila| fila[indice['nombre']]}
      condiciones = ["nombre NOT IN (?)",nombres]
      (@proyecto || @agente).subpartida.all(:conditions => condiciones).each { |t| t.destroy } if carga_total
      # Itera cada fila 
      hoja.each_with_index do |fila,numero_fila|
        limpia_fila fila
        # Si existe alguno de los datos basicos, es una fila nueva => obtenemos la subpartida 
        subpartida = actualiza_subpartida(indice, fila) if fila[indice['nombre']] && numero_fila > 0
      end
      # Si hubo algun error y seleccionamos carga total, deshacemos los cambios
      raise(ActiveRecord::Rollback, "Hacemos un rollback") if @import_error != ""
    end
  end

  # Importa una linea de subpartidas
  def actualiza_subpartida indice, fila

    subpartida = (@proyecto || @agente).subpartida.find_by_nombre( fila[indice['nombre']] ) || (@proyecto || @agente).subpartida.new(:nombre => fila[indice['nombre']])

    # Obtiene la partida vinculada
    fila[indice['partida.codigo_nombre']] =~ /(.+)\s-\s(.+)/
    partida_codigo = $1
    partida_nombre = $2
    partida = Partida.find_by_codigo(partida_codigo.upcase) if partida_codigo

    # Si acabamos de crear la subpartida o existia...
    if subpartida && (!fila[indice['partida.codigo_nombre']] || partida) 
      subpartida.partida_id = partida.id if partida
      subpartida.save
      importacion_error subpartida, _("Subpartida") + " " + fila[indice['nombre']]
      subpartida = nil unless subpartida.errors.empty?
      logger.info "----------------> No tenemos ninguna subpartida... se han producido errores!!!!" unless subpartida
    # Si no se ha encontrado o no se ha podido crear la transferencia 
    else
      importacion_error "<br>" + _("Se produjeron errores procesando Subpartida ") + fila[indice['nombre']].to_s
      importacion_error _("No se pudo encontrar la partida relacionada.") if fila[indice['partida.codigo_nombre']]
      importacion_error _("Fué imposible crear la subpartida.") unless fila[indice['partida.codigo_nombre']]
    end

    return subpartida
  end

  # Importa una hoja de transferencia
  def importa_transferencias hoja, carga_total=false, etapa=nil, proyecto_total=nil
    # El orden de las columnas es:
    # simples ->	id | fecha_enviado | importe_enviado | moneda_enviada | libro_origen | 
    #                   fecha_recibido | importe_recibido | importe_cambiado | moneda_cambiada | libro_destino |
    #                   tasa_cambio | tipo | subtipo | iban | numero_cheque | observaciones
    #			proyecto_nombre
    # multiples ->	transferencia_x_agente.agente.nombre | transferencia_x_agente.importe
    columnas = [ "id", "fecha_enviado", "importe_enviado", "moneda_enviada", "libro_origen", "fecha_recibido", "importe_recibido", "importe_cambiado", "moneda_cambiada", "libro_destino", "tasa_cambio", "tipo", "subtipo", "iban", "numero_cheque", "observaciones", "proyecto_nombre", "transferencia_x_agente.agente.nombre", "transferencia_x_agente.importe"]

    indice = Hash[*columnas.each_with_index.to_a.flatten]
    transferencia = nil

    # Condiciones para la limpieza en carga total
    if params[:seccion] == "proyectos"
      condiciones = "proyecto_id = " + @proyecto.id.to_s
      if @proyecto.ocultar_gastos_otras_delegaciones && !@proyecto.usuario_admin?(@usuario_identificado)
        agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado)
        agentes_id_permitidos = agentes_permitidos.collect{|a| a.id}.join(",")
        condiciones += " AND (libro.agente_id IN (" + agentes_id_permitidos + ") OR libro_destinos_transferencia.agente_id IN (" + agentes_id_permitidos + ") )"
      end
    else
      agentes_permitidos = @agente
      condiciones  = "(libro.agente_id = " + @agente.id.to_s + " OR libro_destinos_transferencia.agente_id = " + @agente.id.to_s + ")"
      condiciones += " AND proyecto_id " + (proyecto_total ? "= " + proyecto_total.id.to_s : "IS NULL" ) if carga_total 
      # Aqui hay que incluir un filtro que evite las transferencias de remanentes de pacs
    end
    # Evita las transferencias de remanentes
    condiciones += " AND NOT remanente"
    # Y le aplica fechas
    condiciones += " AND ( ((fecha_enviado >= '" + etapa.fecha_inicio.to_s(:db) + "' AND fecha_enviado <= '" + etapa.fecha_fin.to_s(:db) + "' ) OR fecha_enviado IS NULL) AND ((fecha_recibido >= '" + etapa.fecha_inicio.to_s(:db) + "' AND fecha_recibido <= '" + etapa.fecha_fin.to_s(:db) + "') OR fecha_recibido IS NULL) )" if etapa

    # Metemos todo en una transaccion para hacer rollback si es carga total y ha habido algun problema
    Transferencia.transaction do
      # Si es una carga total, deberiamos eliminar todos los elementos relacionados
      Transferencia.find(:all, :include => [:libro_origen,:libro_destino], :conditions => condiciones).each { |t| t.destroy } if carga_total
      # Itera cada fila 
      hoja.each_with_index do |fila,numero_fila|
        limpia_fila fila
        # Si existe alguno de los datos basicos, es una fila nueva => obtenemos la transferencia 
        transferencia = actualiza_transferencia(indice, fila, etapa, proyecto_total, agentes_permitidos) if numero_fila > 0 && ((fila[indice['libro_origen']] && fila[indice['libro_origen']].to_s != "") || (fila[indice['libro_destino']] && fila[indice['libro_destino']].to_s != ""))
        # Actualiza el importe por financiador de la transferencia
        if ( transferencia && transferencia.proyecto )
          actualiza_transferencia_financiador(transferencia, indice, fila) if fila[indice['transferencia_x_agente.agente.nombre']]
        end
      end
      # Si hubo algun error y seleccionamos carga total, deshacemos los cambios
      raise(ActiveRecord::Rollback, "Hacemos un rollback") if @import_error != ""
    end
  end

  def actualiza_transferencia indice, fila, etapa, proyecto_total, agentes_permitidos
    transferencia = nil
    proyecto = fila[indice['proyecto_nombre']] ? Proyecto.find_by_nombre(fila[indice['proyecto_nombre']]) : @proyecto

    # Obtiene el tipo de transferencia
    tipo = fila[indice['tipo']].to_s.downcase
    # Comprueba que el tipo de transferencia sea correcto
    tipo = nil unless tipo =~ /transferencia|cambio|retirada|ingreso|intereses|subvencion|reintegro|iva|adelanto/

    # Obtiene el subtipo
    subtipo = SubtipoMovimiento.find_by_nombre( fila[indice['subtipo']].to_s.upcase )

    # Solo coge datos de libros y cuentas si estemas en un proyecto y coincide con lo importado o estamos en un agente y no hay proyecto o es implementador de el
    if ( (proyecto.nil? && fila[indice['proyecto_nombre']].nil?) ||
         (proyecto && ( @proyecto || proyecto.implementador.find_by_id(@agente.id) )) )
      # Obtiene las cuentas 
      libro_origen = (proyecto || @agente).libro.find_by_nombre fila[indice['libro_origen']]
      libro_destino = (proyecto || @agente).libro.find_by_nombre fila[indice['libro_destino']]
      # Podemos estar importando transferencias de un proyecto desde agentes en el que ninguna de las cuentas son nuestras
      libro_origen = libro_destino = nil if @agente && (libro_origen.nil? || libro_origen.agente_id != @agente.id) && (libro_destino.nil? || libro_destino.agente_id != @agente.id)
      # Obtiene las fechas
      fecha_enviado = fecha(fila[indice['fecha_enviado']])
      fecha_recibido = fecha(fila[indice['fecha_recibido']])
      # Obtiene los importes
      importe_enviado = numero fila[indice['importe_enviado']]
      importe_recibido = numero fila[indice['importe_recibido']]
      importe_cambiado = numero fila[indice['importe_cambiado']]
    end

    if	(@proyecto.nil? || proyecto == @proyecto) &&
	(proyecto_total.nil? || proyecto == proyecto_total) &&
        tipo && (subtipo || fila[indice['subtipo']].nil?) && (libro_origen || libro_destino) &&
	(fecha_enviado.nil? || etapa.nil? || etapa.fecha_inicio <= fecha_enviado) && 
        (fecha_recibido.nil? || etapa.nil? || etapa.fecha_fin >= fecha_recibido) 
      # Obtiene la transferencia
      if fila[indice['id']]
        condiciones = "NOT remanente"
        # Si hay proyecto buscamos la transferencia en el
        if proyecto
          transferencia = proyecto.transferencia.find_by_id(fila[indice['id']], :conditions => condiciones)
        # Si no lo hay es que tenemos agente
        else
          condiciones += " AND (libro.agente_id = " + @agente.id.to_s + " OR libro_destinos_transferencia.agente_id = " + @agente.id.to_s + ")"
          transferencia = Transferencia.find_by_id(fila[indice['id']], :include => [:libro_origen,:libro_destino], :conditions => condiciones)
        end
      # Es una transferencia nueva
      else
        transferencia = Transferencia.new
      end
      # Si acabamos de crear la transferencia o existia...
      if transferencia
        # Sanea los datos: Solo podemos tener fechas e importes en un libro si es nuestro
        fecha_enviado = importe_enviado = nil unless @usuario_identificado.libro.include?(libro_origen)
        fecha_recibido = importe_recibido = importe_cambiado = nil unless @usuario_identificado.libro.include?(libro_destino)
        # Sustituye valores
        transferencia.proyecto = proyecto
        transferencia.libro_origen = libro_origen
        transferencia.libro_destino = libro_destino
        transferencia.fecha_enviado = fecha_enviado if fecha_enviado
        transferencia.fecha_recibido = fecha_recibido if fecha_recibido
        transferencia.importe_enviado = importe_enviado if importe_enviado && importe_enviado > 0
        transferencia.importe_recibido = importe_recibido if importe_recibido && importe_recibido > 0
        transferencia.importe_cambiado = importe_cambiado if importe_cambiado && importe_cambiado > 0
        transferencia.iban = fila[indice['iban']]
        transferencia.tipo = tipo
        transferencia.subtipo_movimiento = subtipo
        transferencia.numero_cheque = fila[indice['numero_cheque']]
        transferencia.observaciones = fila[indice['observaciones']]
        transferencia.save
        importacion_error transferencia, _("Transferencia") + " " + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "'" : "nueva")
        #puts "-------------------> " + transferencia.inspect unless transferencia.errors.empty?
        # Limpia transferencia_x_agente para poder importarlo luego y que no esten duplicados
        transferencia.transferencia_x_agente.destroy_all if transferencia.errors.empty?
        transferencia = nil unless transferencia.errors.empty?
      else
        importacion_error "<br>" + _("Se produjeron errores procesando Transferencia ") + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "':" : _("nueva:"))
        importacion_error _("La transferencia no existe.<br>Si es una transferencia nueva, elimine el ID para crearla.") unless transferencia
      end
    else
      importacion_error "<br>" + _("Se produjeron errores procesando Transferencia ") + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "':" : _("nueva:"))
      importacion_error _("Proyecto") + " '" + (fila[indice['proyecto_nombre']]||"") + "' " + _("no válido") unless (proyecto_total.nil? || proyecto == proyecto_total)
      importacion_error _("Proyecto") + " '" + fila[indice['proyecto_nombre']] + "' " + _("no válido") unless (@proyecto.nil? || proyecto == @proyecto)
      importacion_error _("Tipo") + " '" + (fila[indice['tipo']].to_s||"") + "' " + _("no válido.") unless tipo
      importacion_error _("Subtipo") + " '" + (fila[indice['subtipo']].to_s||"") + "' " + _("no válido.") unless (subtipo || fila[indice['subtipo']].nil?)
      importacion_error _("Fecha de envío") + " '" + fecha_enviado.to_s + "' " + _("está fuera de la etapa.") unless (fecha_enviado.nil? || etapa.nil? || etapa.fecha_inicio <= fecha_enviado)
      importacion_error _("Fecha de recepción") + " '" + fecha_recibido.to_s + "' " + _("está fuera de la etapa.") unless (fecha_recibido.nil? || etapa.nil? || etapa.fecha_inicio <= fecha_recibido)
      importacion_error _("Libro Origen") + " '" + (fila[indice['libro_origen']].to_s||"") + "' " + _("no encontrado o no válido.") unless libro_origen
      importacion_error _("Libro Destino") + " '" + (fila[indice['libro_destino']].to_s||"") + "' " + _("no encontrado o no válido.") unless libro_destino
    end

    return transferencia
  end

  # Actualiza los financiadores de una transferencia
  def actualiza_transferencia_financiador transferencia, indice, fila
    financiador = transferencia.proyecto.financiador.find_by_nombre(fila[indice['transferencia_x_agente.agente.nombre']].upcase)

    if financiador
      txf = transferencia.transferencia_x_agente.new(:transferencia_id => transferencia.id, :agente_id => financiador.id)
      txf.importe = numero fila[indice['transferencia_x_agente.importe']]
      txf.save
      importacion_error txf, _("Financiador") + " '" + financiador.nombre + "' " + _("en la transferencia") + _("con ID") + " '" + transferencia.id.to_s
    else
      importacion_error "<br>" + _("Se produjeron errores asignando Financiador a la Transferencia") + " " + _("con ID") + " '" + transferencia.id.to_s + "':"
      importacion_error _("Financiador") + " '" + fila[indice['transferencia_x_agente.agente.nombre']] + "' " + _("no es válido para el proyecto.")
    end
  end


  #--
  # METODOS DE IMPORTACIÓN GASTOS
  #++

  # Importa una hoja de gasto para un agente
  def importa_gastos_agente hoja, carga_total=false, etapa=nil, proyecto=nil
    # El orden de las columnas es:
    # simples ->        id | libro.nombre | fecha | impuestos | importe | moneda | partida.codigo | concepto | subpartida | observaciones
    # multiples ->      actividad.codigo | actividad.importe | actividad.unidades
    # multiples ->      financiador.nombre | financiador.importe
    columnas = [ 'id','agente.nombre','fecha','importe','moneda','impuestos','partida.codigo','subpartida','concepto','numero_factura','proveedor_nombre','proveedor_nif',
		 'observaciones','proyecto.nombre','proyecto.importe','pago.fecha','pago.libro','pago.importe','pago.observaciones','pago.forma_pago','pago.referencia_pago', 'es_valorizado' ,'ref_contable', 'empleado.nombre' ]
    indice = Hash[*columnas.each_with_index.to_a.flatten]
    gasto = nil

    # Metemos todo en una transaccion para hacer rollback si es carga total y ha habido algun problema
    Gasto.transaction do
      # Si es una carga total, deberiamos eliminar todos los elementos relacionados
      if carga_total
        condiciones = Hash.new
        condiciones[:agente_id] = @agente.id
        condiciones[:proyecto_origen_id] = nil
        condiciones["gasto_x_proyecto.proyecto_id"] = proyecto.id if proyecto
        condiciones[:fecha] = etapa.fecha_inicio..etapa.fecha_fin
        Gasto.all(:include => [:gasto_x_proyecto], :conditions => condiciones).each { |g| g.destroy }
      end
      # Itera cada fila 
      hoja.each_with_index do |fila,numero_fila|
        limpia_fila fila
        # Si existe alguno de los datos basicos, es una fila nueva => obtenemos el gasto 
        if ( (fila[indice['agente.nombre']] && fila[indice['agente.nombre']].to_s != "") || (fila[indice['moneda']] && fila[indice['moneda']].to_s != "") || (fila[indice['partida.codigo']] && fila[indice['partida.codigo']].to_s != "")) && numero_fila > 0
          # Si existe un gasto previo, actualiza su marcado
          gasto.marcado_errores if gasto && gasto.id
          # Carga el nuevo gasto
          gasto = actualiza_gasto_agente(indice, fila, etapa, proyecto)
        end
        if ( gasto )
          actualiza_gasto_agente_proyecto gasto, indice, fila, proyecto if fila[indice['proyecto.importe']]
          actualiza_gasto_pago gasto, indice, fila if fila[indice['pago.fecha']]
        end
      end
      # Si existe un gasto previo, actualiza su marcado
      gasto.marcado_errores if gasto && gasto.id
      # Si hubo algun error y seleccionamos carga total, deshacemos los cambios
      raise(ActiveRecord::Rollback, "Hacemos un rollback") if @import_error != ""
    end
  end

  def actualiza_gasto_agente indice, fila, etapa, proyecto
    gasto = nil
    #libro = @agente.libro.find_by_nombre fila[indice['libro.nombre']]
    agente = @agente unless @agente.nombre != fila[indice['agente.nombre']]
    #mon = Moneda.find_by_abreviatura fila[indice['moneda']] 
    #moneda = mon if mon && !@agente.moneda.find_by_moneda_id(mon.id).nil?
    moneda = @agente.moneda.find_by_abreviatura(fila[indice['moneda']])
    if fila[indice['empleado.nombre']] != nil
      empleado = @agente.empleado.find_by_nombre(fila[indice['empleado.nombre']])
      importacion_error _("Empleado") + " '" + (fila[indice['empleado']]||"") + "' " + _("no encontrado o no válido.") unless empleado
    end
    partida = Partida.find_by_codigo fila[indice['partida.codigo']]
    fecha_saneada = fecha fila[indice['fecha']]
    fecha_gasto = fecha_saneada if etapa.nil? || (fecha_saneada >= etapa.fecha_inicio && fecha_saneada <= etapa.fecha_fin)
    subpartida = Subpartida.first(:conditions => {:agente_id => @agente.id, :partida_id => partida.id, :nombre => fila[indice['subpartida']]}) unless partida.nil? || fila[indice['subpartida']].nil?
    # En el caso de que sea una importacion total, comprobamos que el gasto este asignado a un proyecto
    comprobar_proyecto = proyecto ? fila[indice['proyecto.nombre']] == proyecto.nombre : true

    if agente && moneda && partida && fecha_gasto && comprobar_proyecto && ( subpartida || fila[indice['subpartida']].nil?)
      gasto = fila[indice['id']] ? Gasto.find_by_id(fila[indice['id']]) : Gasto.new
      gasto = nil if fila[indice['id']] && gasto && ( gasto.agente_id != agente.id || gasto.proyecto_origen_id != nil )
      # Si acabamos de crear el gasto o ya existia
      if gasto
        gasto.agente_id = agente.id
        gasto.fecha = fecha_gasto 
        gasto.importe = numero fila[indice['importe']]
        gasto.moneda_id = moneda.id
        gasto.impuestos = numero fila[indice['impuestos']]
        gasto.partida_id = partida.id
	      gasto.subpartida_agente_id = fila[indice['subpartida']] ? subpartida.id : nil
        if fila[indice['empleado.nombre']] != nil
          partidas_empleado_ids = Partida.all(:order => "codigo", :conditions => {"ocultar_agente" => false, "tipo_empleado" => true} ).collect(&:id)
          if partidas_empleado_ids.include? gasto.partida_id
          # .select {|p| p.tipo_empleado }
            gasto.empleado_id = empleado ? empleado.id : nil
          else
            importacion_error _("Partida") + " '" + (fila[indice['partida.codigo']]||"") + "' " + _("no es una partida de empleado.")
          end
        end
        gasto.concepto = fila[indice['concepto']].to_s
        gasto.observaciones = fila[indice['observaciones']].to_s
        gasto.ref_contable = fila[indice['ref_contable']].to_s
        gasto.es_valorizado = fila[indice['es_valorizado']].to_s.upcase == _("SI") ? true : false
        gasto.numero_factura = fila[indice['numero_factura']].to_s
        gasto.proveedor_nombre = fila[indice['proveedor_nombre']].to_s
        gasto.proveedor_nif = fila[indice['proveedor_nif']].to_s
        gasto.save
        importacion_error gasto, _("Gasto") + " (" + fila[indice['fecha']].to_s + " - " + fila[indice['concepto']].to_s + ") " + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "'" : "nuevo")
        # Limpia gasto_x_proyecto y pagos para poder importarlo luego y que no esten duplicados
	gasto.gasto_x_proyecto.destroy_all if gasto.errors.empty?
        gasto.pago.destroy_all if gasto.errors.empty?
        gasto = nil unless gasto.errors.empty?
      else
        importacion_error "<br>" + _("Se produjeron errores procesando Gasto") + " (" + fila[indice['fecha']].to_s + " - " + fila[indice['concepto']].to_s + ") " + _("con ID") + " '" + fila[indice['id']].to_s + "':"
        importacion_error _("No se ha encontrado el gasto con ese ID para el Agente.") 
      end
    else
      importacion_error "<br>" + _("Se produjeron errores procesando Gasto") + " (" + fila[indice['fecha']].to_s + " - " + fila[indice['concepto']].to_s + ") " + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "':" : _("nuevo:"))
      importacion_error _("Implementador") + " '" + (fila[indice['agente.nombre']].to_s||"") + "' " + _("no encontrado o no válido.") unless agente 
      importacion_error _("Moneda") + " '" + (fila[indice['moneda']]||"") + "' " + _("no encontrada o no válida.") unless moneda
      importacion_error _("Partida") + " '" + (fila[indice['partida.codigo']].to_s||"") + "' " + _("no encontrada o no válida.") unless partida
      importacion_error _("Subpartida") + " '" + (fila[indice['subpartida']].to_s||"") + "' " + _("no encontrada o no válida.") unless subpartida || fila[indice['subpartida']].nil?
      importacion_error _("Fecha") + " '" + (fecha_saneada ? fecha_saneada.to_s : "") + "' " + _("no válida para la etapa.") unless fecha_gasto
      importacion_error _("Proyecto no definido o no válido.") unless comprobar_proyecto
    end

    return gasto
  end

  def actualiza_gasto_agente_proyecto gasto, indice, fila, total_proyecto
    #proyecto=gasto.libro.proyecto.find_by_nombre fila[indice['proyecto.nombre']]
    proyecto = Proyecto.find_by_nombre fila[indice['proyecto.nombre']] if fila[indice['proyecto.nombre']]
    # Se asegura que el agente sea implementador del proyecto o no sea distinto total_proyecto del encontrado
    proyecto = nil if (proyecto && ProyectoXImplementador.find_by_proyecto_id_and_agente_id(proyecto.id,@agente.id).nil?) ||
			(total_proyecto && fila[indice['proyecto.nombre']] != total_proyecto.nombre)
    proyecto_id = proyecto ? proyecto.id : nil
    importe = numero fila[indice['proyecto.importe']]
    if (proyecto || (fila[indice['proyecto.nombre']].nil? && importe)) && gasto
      gxp = gasto.gasto_x_proyecto.find_by_proyecto_id proyecto_id 
      gxp = gasto.gasto_x_proyecto.new(:proyecto_id => proyecto_id) if gxp.nil?
      gxp.importe = importe 
      gxp.save
      importacion_error gxp, (proyecto ? _("Proyecto") + " '" + proyecto.nombre + "'" : _("Imputado a delegación")) + " " + _("en el Gasto") + " (" + gasto.concepto + ") " + _("con ID") + " '" + gasto.id.to_s
    else
      importacion_error "<br>" + _("Se produjeron errores asignando el Gasto") + " (" + gasto.concepto + ") " + _("con ID") + " '" + gasto.id.to_s + "' " + _("a") + " '" + fila[indice['proyecto.nombre']] + "':"
      importacion_error _("Proyecto no válido para el agente") unless total_proyecto && fila[indice['proyecto.nombre']] != total_proyecto.nombre 
      importacion_error _("El proyecto no coincide con el seleccionado para importacion") if total_proyecto && fila[indice['proyecto.nombre']] != total_proyecto.nombre
    end
  end

  # Importa una hoja de gasto para un proyecto
  def importa_gastos_proyecto hoja, carga_total=false, orden_factura=false, etapa=nil, agente=nil
    # El orden de las columnas es:
    # simples ->        id | agente.nombre | fecha | impuestos | importe | moneda | partida.codigo | concepto | subpartida | observaciones
    # multiples ->      actividad.codigo | actividad.importe | actividad.unidades
    # multiples ->      financiador.nombre | financiador.importe
    # multiples ->	pago.fecha | pago.libro.nombre | pago.importe
    columnas = [ 'id','agente.nombre','pais', 'fecha','impuestos','importe','moneda','partida.codigo','subpartida','concepto','numero_factura','proveedor_nombre','proveedor_nif','observaciones',  'actividad.codigo','actividad.importe','financiador.nombre','financiador.importe','pago.fecha','pago.libro','pago.importe','pago.observaciones','pago.forma_pago','pago.referencia_pago', 'es_valorizado' ,'ref_contable' ]
    indice = Hash[*columnas.each_with_index.to_a.flatten]
    gasto = nil

    # Metemos todo en una transaccion para hacer rollback si es carga total y ha habido algun problema
    Gasto.transaction do
      # Si el proyecto tiene configurada visibilidad limitada o el usuario es un admin
      if @proyecto.ocultar_gastos_otras_delegaciones && !@proyecto.usuario_admin?(@usuario_identificado)
        agentes_permitidos = @proyecto.implementadores_autorizados(@usuario_identificado)
      else
        agentes_permitidos = @proyecto.implementador
      end
      # Si es una carga total, borramos todos los gastos del proyecto
      if carga_total
        condiciones = {:proyecto_origen_id => @proyecto.id}
        if agente
          agente_importar = agentes_permitidos.find_by_id(agente.id) || Agente.new
          importacion_error _("ERROR: Se está tratando de importar información de un implementador no autorizado") if agente_importar.id.nil?
        # Si no se ha especificado agente, se escogen solo los permitidos
        else
          agente_importar = agentes_permitidos
        end
        condiciones[:agente_id] = agente_importar if agente_importar
        condiciones[:fecha] = etapa.fecha_inicio..etapa.fecha_fin if etapa 
        @proyecto.gasto.find(:all, :conditions => condiciones).each { |eliminar_gasto| eliminar_gasto.destroy }
      end
      # Itera cada fila 
      hoja.each_with_index do |fila,numero_fila|
        limpia_fila fila
        # Si existe alguno de los datos basicos, es una fila nueva => obtenemos el gasto
        if ((fila[indice['agente.nombre']] && fila[indice['agente.nombre']].to_s != "") || (fila[indice['moneda']] && fila[indice['moneda']].to_s != "") || (fila[indice['partida.codigo']] && fila[indice['partida.codigo']].to_s != "")) && numero_fila > 0
          # Si existe un gasto previo, actualiza su marcado
          gasto.marcado_errores if gasto && gasto.id

          # Si estamos importando usando los numeros de orden de facturas, comprueba que el gasto tenga ID
          if orden_factura && !fila[indice['id']]
            importacion_error _("El gasto de la fila %{fila} no contiene número de orden de factura.") % {:fila => numero_fila.to_s}
          else
            # Carga el nuevo gasto
            gasto = actualiza_gasto_proyecto indice, fila, etapa, agente, orden_factura, agentes_permitidos
          end
        end
        if ( gasto )
          actualiza_gasto_actividad gasto, indice, fila, numero_fila+1 if fila[indice['actividad.codigo']]
          actualiza_gasto_financiador gasto, indice, fila if fila[indice['financiador.nombre']]
          actualiza_gasto_pago gasto, indice, fila if fila[indice['pago.fecha']] || fila[indice['pago.libro']] || fila[indice['pago.importe']]
        end
      end
      # Si existe un gasto previo, actualiza su marcado
      gasto.marcado_errores if gasto && gasto.id
      # Si hubo algun error y seleccionamos carga total, deshacemos los cambios
      raise(ActiveRecord::Rollback, "Hacemos un rollback") if @import_error != ""
    end
  end

  def actualiza_gasto_proyecto indice, fila, etapa, agente_total, orden_factura, agentes_permitidos
    gasto = nil
    agente = agentes_permitidos.find_by_nombre fila[indice['agente.nombre']]
    # Se asegura de que el agente sea el mismo que el implantador seleccionado (cuando hay carga total)
    agente = nil if agente_total && agente != agente_total

    pais_tmp = Pais.find_by_nombre fila[indice['pais']]
    # Si no se ha definido ningun pais
    if (fila[indice['pais']].nil? || fila[indice['pais']]=="")
      # Le asignamos el del proyecto si solo hay uno
      pais = @proyecto.pais.first if @proyecto.pais.count == 1
      # Lo dejamos en regional si hay mas de uno
      pais = "REGIONAL" unless @proyecto.pais.count == 1
    else
      # Le asignamos el pais elegido si esta incluido en el proyecto
      pais = pais_tmp if @proyecto.pais_gasto.include?(pais_tmp)
    end

    moneda = @proyecto.moneda.find_by_abreviatura fila[indice['moneda']]
    partida = Partida.find_by_codigo fila[indice['partida.codigo']] 
    subpartida = Subpartida.first(:conditions => {:proyecto_id => @proyecto.id, :partida_id => partida.id, :nombre => fila[indice['subpartida']]}) unless partida.nil? || fila[indice['subpartida']].nil?
    fecha_saneada = fecha(fila[indice['fecha']])
    fecha_gasto = etapa ? (fecha_saneada if fecha_saneada.class.name == "DateTime" && fecha_saneada >= etapa.fecha_inicio && fecha_saneada <= etapa.fecha_fin) : fecha_saneada

    if agente && moneda && pais && partida && fecha_gasto && ( subpartida || fila[indice['subpartida']].nil?)
      # Cuando tratamos el gasto segun su numero de orden, buscamos primero el gasto_x_proyecto
      if orden_factura
        condiciones = {"orden_factura_proyecto" => fila[indice['id']],
                       "agente_id" => agente.id,
                       "gasto_x_proyecto.proyecto_id" => @proyecto.id }
        joins = [:gasto_x_proyecto]
        gasto = Gasto.first(:joins => joins, :conditions => condiciones) || Gasto.new(:proyecto_origen_id => @proyecto.id, :orden_factura_proyecto => fila[indice['id']])
        # Lo cargamos otra vez por que la busqueda con join hace que sea readonly
        gasto = Gasto.find_by_id(gasto.id) unless gasto.new_record?
        gxp = gasto.new_record? ? GastoXProyecto.new(:proyecto_id => @proyecto.id) : gasto.gasto_x_proyecto.first(:conditions => {:proyecto_id => @proyecto.id})
      # Para gastos identificados por el id 
      else
        gasto = fila[indice['id']] ? @proyecto.gasto.find_by_id(fila[indice['id']]) : Gasto.new(:proyecto_origen_id => @proyecto.id)
        gxp = (fila[indice['id']] ? gasto.gasto_x_proyecto.find_by_proyecto_id(@proyecto) : GastoXProyecto.new(:proyecto_id => @proyecto.id)) if gasto
      end
      # Si acabamos de crear el gasto o existia creado por este proyecto...
      if gasto && (gasto.proyecto_origen_id == @proyecto.id || gasto.id.nil?)
        gasto.agente_id = agente.id
        gasto.fecha = fecha_gasto
        gasto.importe = numero fila[indice['importe']]
        gasto.impuestos = numero fila[indice['impuestos']]
        gasto.moneda_id = moneda.id
        gasto.pais = pais unless pais=="REGIONAL"
        gasto.partida_id = partida.id
        gasto.concepto = fila[indice['concepto']].to_s
        gasto.observaciones = fila[indice['observaciones']].to_s
        gasto.numero_factura = fila[indice['numero_factura']].to_s
        gasto.proveedor_nombre = fila[indice['proveedor_nombre']].to_s
        gasto.proveedor_nif = fila[indice['proveedor_nif']].to_s
        gasto.ref_contable = fila[indice['ref_contable']].to_s
        gasto.es_valorizado = fila[indice['es_valorizado']].to_s.upcase == _("SI") ? true : false

        gxp.importe = gasto.importe
        gxp.subpartida_id = fila[indice['subpartida']] ? subpartida.id : nil
        gasto.save  
        importacion_error gasto, _("Gasto") + " (" + fila[indice['fecha']].to_s + " - " + fila[indice['concepto']].to_s + ") " + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "'" : "nuevo") 
        if gasto.errors.empty?
          #gasto.gasto_x_proyecto << gxp unless fila[indice['id']]
          #gxp.orden_factura = fila[indice['id']] if orden_factura
          gxp.gasto_id = gasto.id
          gxp.save
	  importacion_error gxp, _("Gasto") + " (" + fila[indice['fecha']].to_s + " - " + fila[indice['concepto']].to_s + ") " + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "'" : "nuevo")
        else
          
          logger.info "-------------------> ERROR al importar un gasto: " + gasto.errors.inspect
        end
        # Limpia pagos, actividades y financiadores para poder importarlos luego y que no esten duplicados
        gasto.pago.destroy_all if gasto.errors.empty? || gxp.errors.empty?
        gasto.actividad(@proyecto).each { |gxa| gxa.destroy } if gasto.errors.empty? || gxp.errors.empty?
        gasto.financiador(@proyecto).each { |gxf| gxf.destroy } if gasto.errors.empty? || gxp.errors.empty?
        gasto = nil unless gasto.errors.empty? || gxp.errors.empty?
      # Si no se ha encontrado el gasto o esta compartido por varios proyectos...
      else
        gasto = nil # ! es correcto esto?
        importacion_error "<br>" + _("Se produjeron errores procesando Gasto") + " (" + fila[indice['fecha']].to_s + " - " + fila[indice['concepto']].to_s + ") " + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "':" : _("nuevo:"))
        #if gasto_fuera_etapa
        #  importacion_error _("No se encuentra dentro de las Etapas del proyecto") 
        #else
        importacion_error _("El gasto no existe en este proyecto.<br>Si es un gasto nuevo, elimine el ID para crearlo.") unless gasto
        importacion_error _("El gasto está compartido por varios proyectos. Solo puede modificarse desde la sección Agentes o desde el Proyecto origen.") if gasto
        #end
      end
    else
      importacion_error "<br>" + _("Se produjeron errores procesando Gasto") + " (" + fila[indice['fecha']].to_s + " - " + fila[indice['concepto']].to_s + ") " + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "':" : _("nuevo:"))
      importacion_error _("Implementador") + " '" + (fila[indice['agente.nombre']].to_s||"") + "' " + _("no encontrado o no válido.") unless agente 
      importacion_error _("Moneda") + " '" + (fila[indice['moneda']].to_s || "") + "' " + _("no encontrada o no válida.") unless moneda
      importacion_error _("País") + " '" + (fila[indice['pais']].to_s || "") + "' " + _("no encontrado o no válido.") unless pais 
      importacion_error _("Partida") + " '" + (fila[indice['partida.codigo']].to_s||"") + "' " + _("no encontrada o no válida.") unless partida
      importacion_error _("Fecha") + " '" + (fecha_saneada ? fecha_saneada.to_s : "") + "' " + _("no válida para la etapa.") unless fecha_gasto
      importacion_error _("Subpartida") + " '" + (fila[indice['subpartida']].to_s||"") + "' " + _("no encontrada o no válida.") unless subpartida || fila[indice['subpartida']].nil? 
    end

    return gasto
  end

  def actualiza_gasto_actividad gasto, indice, fila, num_fila 
    # Obtiene el importe total de la linea
    importe = numero fila[indice['actividad.importe']]
    if gasto && importe && fila[indice['actividad.codigo']]
      #logger.info "------------> Para " + fila[indice['actividad.codigo']] + " tenemos un importe de: " + importe.inspect
      # Desglosa las actividades segun sus codigos.
      # Puede haber mas de un codigo por celda separados por comas, incluyendo:
      #     RES@COD => Resultado con codigo COD
      #     OE@COD => OE con codigo COD
      actividades = []
      fila[indice['actividad.codigo']].split(/\s*,\s*/).each do |codigo|
        # Para Todos 
        if codigo == "###"
          actividades = @proyecto.actividad
        # Para OE
        elsif codigo.match(/^OE#\S+/)
          codigo = codigo[3..-1]
          objetivo = @proyecto.objetivo_especifico.find_by_codigo codigo
          actividades += @proyecto.actividad.includes("resultado").where("resultado.objetivo_especifico_id" => objetivo.id) if objetivo
          importacion_error "<br>" + _("Fila %{num}")%{:num => num_fila} + ": " + _("Objetivo Específico") + " '" + codigo + "' " + _("no encontrado o no válido.") unless objetivo
        # Para Resultados
        elsif codigo.match(/^RE#\S+/)
          codigo = codigo[3..-1]
          resultado = @proyecto.resultado.find_by_codigo codigo
          actividades += resultado.actividad if resultado
          importacion_error "<br>" + _("Fila %{num}")%{:num => num_fila} + ": " + _("Resultado") + " '" + codigo + "' " + _("no encontrado o no válido.") unless resultado
        # Para Actividades
        else
          actividad = @proyecto.actividad.find_by_codigo codigo
          actividades.push(actividad) if actividad
          importacion_error( "<br>" + _("Fila %{num}")%{:num => num_fila} + ": " + _("Actividad") + " '" + codigo + "' " + _("no encontrada o no válida.") ) unless actividad
        end
      end if fila[indice['actividad.codigo']].class == String

      # Elimina duplicados si los hubiere
      actividades.uniq!

      # Calculamos importe_x_actividad y resto
      if actividades.size > 0
        importe_x_actividad, resto_importe = (importe*100).divmod(actividades.size)
        importe_x_actividad = importe_x_actividad.to_f / 100
        resto_importe = resto_importe / 100
      end
      # Recorremos todas las actividades asignando el gasto_x_actividad correspondiente
      actividades.each do |actividad|
        unless gxa=GastoXActividad.find_by_proyecto_id_and_gasto_id_and_actividad_id(@proyecto.id, gasto.id, actividad.id)
          gxa = GastoXActividad.new :proyecto_id => @proyecto.id, :gasto_id => gasto.id, :actividad_id => actividad.id
        end
        gxa.importe = importe_x_actividad unless actividad == actividades.last
        # A la ultima actividad le suma el resto
        gxa.importe = (importe_x_actividad + resto_importe) if actividad == actividades.last
        gxa.save
        importacion_error gxa, _("Actividad") + " '" + actividad.codigo + "' " + _("en el Gasto con ID") + " '" + gasto.id.to_s + "' (" + gasto.concepto + ")"
      end
    else
      importacion_error( "<br>" + _("Fila %{num}")%{:num => num_fila} + ": " + _("El importe de la actividad '%{act}' no es válido.")%{:act => fila[indice['actividad.codigo']] } ) unless gasto.nil? || fila[indice['actividad.codigo']].nil?
    end
  end

  def actualiza_gasto_financiador gasto, indice, fila
    agente = @proyecto.financiador.find_by_nombre fila[indice['financiador.nombre']]
    if agente && gasto
      if ! ( gxf = GastoXAgente.find :first, :conditions => { :agente_id => agente.id, :gasto_id => gasto.id, :proyecto_id => @proyecto.id } )
        gxf = GastoXAgente.new :gasto_id => gasto.id, :agente_id => agente.id, :proyecto_id => @proyecto.id
      end
      gxf.importe = numero fila[indice['financiador.importe']]
      gxf.save
      importacion_error gxf, "Financiador '" + agente.nombre + "' " + _("en el Gasto con ID") + " '" + gasto.id.to_s + "' (" + gasto.concepto + ")"
    elsif fila[indice['financiador.nombre']]
      importacion_error "<br>" + _("Financiador") + " " + fila[indice['financiador.nombre']].to_s + " " + _("no encontrado o no válido.")
    end
  end

  def actualiza_gasto_pago gasto, indice, fila
    # 'pago.fecha','pago.libro','pago.importe','pago.observaciones'
    libro = (@proyecto||@agente).libro.find_by_nombre fila[indice['pago.libro']]
    if libro && gasto
      pago = gasto.pago.new( :fecha => fecha(fila[indice['pago.fecha']]), :libro_id => libro.id, :importe => fila[indice['pago.importe']], :observaciones => fila[indice['pago.observaciones']], :forma_pago => fila[indice['pago.forma_pago']], :referencia_pago => fila[indice['pago.referencia_pago']] )
      pago.save
      importacion_error pago, _("Pago en el Gasto con ID") + " '" + gasto.id.to_s + "' (" + gasto.concepto + ")"
    else
      importacion_error "<br>" + _("Cuenta asociada al Pago") + " '" + (fila[indice['pago.libro']]||"")  + "' " + _("no encontrada o no válida.")
    end
  end

  #--
  # METODOS DE IMPORTACIÓN PRESUPUESTOS
  #++

 # Importa una hoja de presupuesto para un agente
  def importa_presupuestos_agente hoja, carga_total=false, etapa=nil
    # El orden de las columnas es:
    # simples ->        id | etapa | unidad | numero_unidades | coste_unitario | importe | moneda.abreviatura | partida.codigo | subpartida | concepto | observ.
    columnas = [ 'id','etapa.nombre','unidad','numero_unidades','coste_unitario','importe','moneda.abreviatura','partida.codigo','subpartida','concepto','observaciones' ]
    indice=Hash[*columnas.each_with_index.to_a.flatten]

    presupuesto = nil

    # Metemos todo en una transaccion para hacer rollback si es carga total y ha habido algun problema
    Presupuesto.transaction do
      # Si es una carga total borramos todos los presupuestos del proyecto y el agente
      Presupuesto.find( :all, :conditions => { :proyecto_id => nil, :etapa_id => etapa.id , :agente_id => @agente.id } ).each { |p| p.destroy } if carga_total
      # Itera cada fila 
      hoja.each_with_index do |fila,numero_fila|
        limpia_fila fila
        # Si existe alguno de los datos basicos => obtenemos el presupuesto 
        presupuesto = actualiza_presupuesto_agente indice, fila, etapa if ( (fila[indice['concepto']] && fila[indice['concepto']].to_s != "") || (fila[indice['importe']] && fila[indice['importe']].to_s != "") ) && numero_fila > 0
      end
      raise(ActiveRecord::Rollback, "Hacemos un rollback") if @import_error != ""
    end
  end

  def actualiza_presupuesto_agente indice, fila, etapa_total
    presupuesto = nil
    # Para importacion total, se asegura de que la etapa sea la indicada
    etapa = @agente.etapa.find_by_nombre fila[indice['etapa.nombre']] if etapa_total.nil? || etapa_total.nombre == fila[indice['etapa.nombre']]
    # Se asegura que el agente sea implementador del proyecto
    concepto = fila[indice['concepto']].to_s
    importe = numero fila[indice['importe']]
    mon = Moneda.find_by_abreviatura fila[indice['moneda.abreviatura']]
    moneda = mon if mon && !@agente.agente_x_moneda.find_by_moneda_id(mon.id).nil?
    numero_unidades = numero fila[indice['numero_unidades']]
    partida = Partida.find_by_codigo fila[indice['partida.codigo']]

    if moneda && partida && etapa 
      # como ya hemos filtrado proyecto no necesitamos afinar en la busqueda de presupuesto
      presupuesto = fila[indice['id']] ? Presupuesto.find_by_id(fila[indice['id']], :conditions => { :proyecto_id => nil, :agente_id => @agente.id}) : Presupuesto.new( :proyecto_id => nil, :agente_id => @agente.id )
      if !presupuesto.nil?
        presupuesto.etapa_id = etapa.id
        presupuesto.unidad = fila[indice['unidad']]
        presupuesto.numero_unidades = numero fila[indice['numero_unidades']]
        presupuesto.coste_unitario = fila[indice['coste_unitario']]
        presupuesto.importe = numero fila[indice['importe']]
        presupuesto.moneda = moneda
        presupuesto.partida = partida
        presupuesto.subpartida_nombre = fila[indice['subpartida']]
        presupuesto.concepto = fila[indice['concepto']].to_s
        presupuesto.observaciones = fila[indice['observaciones']].to_s
        presupuesto.save
        importacion_error presupuesto, _("Presupuesto") + " " + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "'" : "nuevo")
        presupuesto = nil unless presupuesto.errors.empty?
        # Dividimos el presupuesto por meses solo si existe y no es nuevo (id => nil)
        presupuesto.dividir_por_mes unless presupuesto.nil? || fila[indice['id']].nil?
      # Si no se ha encontrado el presupuesto para este agente...
      else
        importacion_error "<br>" + _("Se produjeron errores procesando línea de Presupuesto") + " " + _("con ID") + " '" + fila[indice['id']].to_s + ":"
        importacion_error _("Línea de presupuesto no encontrada o no válida para el agente") 
      end
    else
      importacion_error "<br>" + _("Se produjeron errores procesando línea de Presupuesto") + " " + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "':" : "nuevo:")
      importacion_error _("Moneda") + " '" + (fila[indice['moneda.abreviatura']].to_s||"") + "' " + _("no encontrada o no válida.") unless moneda
      importacion_error _("Partida") + " '" + (fila[indice['partida.codigo']].to_s||"") + "' " + _("no encontrada o no válida.") unless partida
      importacion_error _("Etapa") + " '" + (fila[indice['etapa.nombre']].to_s||"") + "' " + _("no valida") unless etapa
      #importacion_error _("Fecha de Inicio") + " '" + (fila[indice['fecha_inicio']].to_s||"") + "' " + _("no válida para la etapa.") unless fecha_inicio
      #importacion_error _("Fecha de Fin") + " '" + (fila[indice['fecha_fin']].to_s||"") + "' " + _("no válida para la etapa.") unless fecha_fin
    end

    return presupuesto
  end

  # Importa una hoja de presupuesto para un proyecto
  def importa_presupuestos_proyecto hoja, carga_total=false, etapa=nil, agente=nil
    # El orden de las columnas es:
    # simples ->	id | agente.nombre | etapa.nombre | unidades | coste_unitario | importe | partida.nombre | moneda.abreviatura | concepto | subpartida | observ.
    # multiples ->	actividad.codigo | actividad.importe | actividad.unidades
    # multiples ->	financiador.nombre | financiador.importe
    columnas = [ 'id','agente.nombre','etapa.nombre','unidad','numero_unidades','coste_unitario','importe','moneda.abreviatura','partida.codigo','subpartida','pais','concepto','observaciones','actividad.codigo','actividad.importe','actividad.unidades','financiador.nombre','financiador.importe' ]
    indice=Hash[*columnas.each_with_index.to_a.flatten]

    presupuesto = nil
    # Metemos todo en una transaccion para hacer rollback si es carga total y ha habido algun problema
    Presupuesto.transaction do
      # Si es una carga total borramos todos los presupuestos del proyecto
      if carga_total
        condiciones = Hash.new 
        condiciones[:agente_id] = agente.id if agente
        condiciones[:etapa_id] = etapa.id if etapa
        @proyecto.presupuesto.all(:conditions => condiciones).each { |p| p.destroy }
      end
      # Itera cada fila 
      hoja.each_with_index do |fila,numero_fila|
        limpia_fila fila
        # Si existe alguno de los datos basicos, es una fila nueva => obtenemos el presupuesto 
        presupuesto = actualiza_presupuesto_proyecto indice, fila, etapa, agente if ((fila[indice['concepto']] && fila[indice['concepto']].to_s != "") || (fila[indice['importe']] && fila[indice['importe']].to_s != "")) && numero_fila > 0
        if ( presupuesto )
          actualiza_presupuesto_actividad presupuesto, indice, fila, numero_fila+1 if fila[indice['actividad.codigo']]
          actualiza_presupuesto_financiador presupuesto, indice, fila if fila[indice['financiador.nombre']]
        end
      end
      # Si hubo algun error y seleccionamos carga total, deshacemos los cambios
      raise(ActiveRecord::Rollback, "Hacemos un rollback") if @import_error != ""
    end
  end

  def actualiza_presupuesto_proyecto indice, fila, etapa_total, agente_total
    presupuesto = nil
    agente = @proyecto.implementador.find_by_nombre fila[indice['agente.nombre']]

    pais_tmp = Pais.find_by_nombre fila[indice['pais']]
    # Si no se ha definido ningun pais
    if (fila[indice['pais']].nil? || fila[indice['pais']]=="")
      # Le asignamos el del proyecto si solo hay uno
      pais = @proyecto.pais.first if @proyecto.pais.count == 1
      # Lo dejamos en regional si hay mas de uno
      pais = "REGIONAL" unless @proyecto.pais.count == 1 
    else
      # Le asignamos el pais elegido si esta incluido en el proyecto
      pais = pais_tmp if @proyecto.pais_gasto.include?(pais_tmp)
    end

    # Para importacion total, se asegura de importar solo si el agente es el indicado
    agente = nil if agente && agente_total && agente.id != agente_total.id
    # Para importacion total, se asegura de que la etapa sea la indicada
    etapa = @proyecto.etapa.find_by_nombre fila[indice['etapa.nombre']] if etapa_total.nil? || etapa_total.nombre == fila[indice['etapa.nombre']]

    moneda = @proyecto.moneda.find_by_abreviatura fila[indice['moneda.abreviatura']]
    partida = Partida.find_by_codigo fila[indice['partida.codigo']]
    #fecha_inicio = etapa ? (fecha fila[indice['fecha_inicio']] if fila[indice['fecha_inicio']] >= etapa.fecha_inicio) : fecha(fila[indice['fecha_inicio']])
    #fecha_fin = etapa ? (fecha fila[indice['fecha_fin']] if fila[indice['fecha_fin']] <= etapa.fecha_fin) : fecha(fila[indice['fecha_fin']])

    #if agente && moneda && partida && fecha_inicio && fecha_fin
    if agente && moneda && partida && etapa && pais
      presupuesto = fila[indice['id']] ? @proyecto.presupuesto.find_by_id(fila[indice['id']]) : Presupuesto.new
      # Si acabamos de crear el presupuesto o esta asignado unicamente al proyecto
      if presupuesto
        presupuesto.proyecto_id = @proyecto.id if presupuesto.id.nil?
        presupuesto.agente = agente 
        presupuesto.concepto = fila[indice['concepto']].to_s 
        presupuesto.importe = numero fila[indice['importe']] 
        presupuesto.moneda = moneda
        presupuesto.pais = pais unless pais == "REGIONAL"
        presupuesto.unidad = fila[indice['unidad']]
        presupuesto.numero_unidades = numero fila[indice['numero_unidades']] 
        presupuesto.coste_unitario = fila[indice['coste_unitario']]
        presupuesto.partida = partida
        presupuesto.subpartida_nombre = fila[indice['subpartida']]
        presupuesto.etapa_id = etapa.id
        presupuesto.observaciones = fila[indice['observaciones']].to_s
        presupuesto.save
        importacion_error presupuesto, _("Presupuesto") + " " + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "'" : "nuevo")
        # Limpia actividades y financiadores para poder importarlos luego y que no esten duplicados
        presupuesto.presupuesto_x_actividad.each { |pxa| pxa.destroy } if presupuesto.errors.empty?
        presupuesto.presupuesto_x_agente.each { |pxf| pxf.destroy } if presupuesto.errors.empty?
        # Elimina el presupuesto si tiene errores
        presupuesto = nil unless presupuesto.errors.empty?
        # Dividimos el presupuesto por meses solo si existe y no es nuevo (id => nil)
        presupuesto.dividir_por_mes unless presupuesto.nil? || fila[indice['id']].nil?

      # Si no se ha encontrado el presupuesto o esta compartido por varios proyectos...
      else
        importacion_error "<br>" + _("Se produjeron errores procesando línea de Presupuesto") + " " + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "':" : "nuevo:")
        importacion_error _("El presupuesto no existe en este proyecto.<br>Si es un presupuesto nuevo, elimine el ID para crearlo.")
      end
    else
      importacion_error "<br>" + _("Se produjeron errores procesando línea de Presupuesto ") + (fila[indice['id']] ? _("con ID") + " '" + fila[indice['id']].to_s + "':" : "nuevo:")
      importacion_error _("Agente") + " '" + (fila[indice['agente.nombre']].to_s||"") + "' " + _("no encontrado o no válido.") unless agente
      importacion_error _("Moneda") + " '" + (fila[indice['moneda.abreviatura']].to_s||"") + "' " + _("no encontrada o no válida.") unless moneda
      importacion_error _("Partida") + " '" + (fila[indice['partida.codigo']].to_s||"") + "' " + _("no encontrada o no válida.") unless partida
      importacion_error _("Etapa") + " '" + (fila[indice['etapa.nombre']].to_s||"") + "' " + _("no valida") unless etapa
      importacion_error _("País") + " '" + (fila[indice['pais']].to_s || "") + "' " + _("no encontrado o no válido.") unless pais
      #importacion_error _("Fecha de Inicio") + " '" + (fila[indice['fecha_inicio']].to_s||"") + "' " + _("no válida para la etapa.") unless fecha_inicio
      #importacion_error _("Fecha de Fin") + " '" + (fila[indice['fecha_fin']].to_s||"") + "' " + _("no válida para la etapa.") unless fecha_fin
    end

    return presupuesto 
  end

  #def actualiza_presupuesto_actividad presupuesto, indice, fila, num_fila
  #  actividad = Actividad.find_by_codigo fila[indice['actividad.codigo']], :conditions => { :proyecto_id => @proyecto.id }
  #  if actividad && presupuesto
  #    if ! (presupuesto.presupuesto_x_actividad && (pxa = presupuesto.presupuesto_x_actividad.find_by_actividad_id actividad.id))
  #      pxa = PresupuestoXActividad.new :presupuesto_id => presupuesto.id, :actividad_id => actividad.id
  #    end
  #    pxa.importe = numero fila[indice['actividad.importe']]
  #    pxa.numero_unidades = numero fila[indice['actividad.unidades']]
  #    pxa.save
  #    importacion_error pxa, _("Actividad") + " '" + actividad.codigo + "' " + _("en la línea de Presupuesto") + " " + _("con ID") + " '" + presupuesto.id.to_s + "'"
  #  elsif fila[indice['actividad.codigo']]
  #    importacion_error "<br>" + _("Actividad") + " '" + fila[indice['actividad.codigo']].to_s + "' " + _("no encontrada o no válida.")
  #  end
  #end

  def actualiza_presupuesto_actividad presupuesto, indice, fila, num_fila
    if presupuesto
      # Obtiene el importe total de la linea y el numero de unidades
      importe = numero fila[indice['actividad.importe']]
      num_unidades = numero fila[indice['actividad.unidades']]
      # Si el importe de la linea es == 0, recoge el importe total del presupuesto
      importe = presupuesto.importe if importe.nil? || importe == 0
      num_unidades = presupuesto.numero_unidades if num_unidades.nil? || num_unidades == 0
      # Desglosa las actividades segun sus codigos.
      # Puede haber mas de un codigo por celda separados por comas, incluyendo:
      #     RES@COD => Resultado con codigo COD
      #     OE@COD => OE con codigo COD
      actividades = []
      fila[indice['actividad.codigo']].split(/\s*,\s*/).each do |codigo|
        # Para todas las actividades de la etapa
        if codigo == "###"
          actividades = presupuesto.etapa.actividad
        # Para OE
        elsif codigo.match(/^OE#\S+/)
          codigo = codigo[3..-1]
          objetivo = @proyecto.objetivo_especifico.find_by_codigo codigo
          actividades += @proyecto.actividad.includes("resultado").where("resultado.objetivo_especifico_id" => objetivo.id) if objetivo
          importacion_error "<br>" + _("Fila %{num}")%{:num => num_fila} + ": " + _("Objetivo Específico") + " '" + codigo + "' " + _("no encontrado o no válido.") unless objetivo
        # Para Resultados
        elsif codigo.match(/^RE#\S+/)
          codigo = codigo[3..-1]
          resultado = @proyecto.resultado.find_by_codigo codigo
          actividades += resultado.actividad if resultado
          importacion_error "<br>" + _("Fila %{num}")%{:num => num_fila} + ": " + _("Resultado") + " '" + codigo + "' " + _("no encontrado o no válido.") unless resultado
        # Para Actividades
        else
          actividad = @proyecto.actividad.find_by_codigo codigo
          actividades.push(actividad) if actividad
          importacion_error( "<br>" + _("Fila %{num}")%{:num => num_fila} + ": " + _("Actividad") + " '" + codigo + "' " + _("no encontrada o no válida.") ) unless actividad
        end
      end if fila[indice['actividad.codigo']].class == String

      # Elimina duplicados si los hubiere
      actividades.uniq!

      # Calculamos importe_x_actividad y resto
      if actividades.size > 0
        importe_x_actividad, resto_importe = (importe*100).divmod(actividades.size)
        importe_x_actividad = importe_x_actividad.to_f / 100
        resto_importe = resto_importe / 100
        num_unidades_x_actividad, resto_num_unidades = num_unidades.divmod(actividades.size)
      end
      # Recorremos todas las actividades asignando el presupuesto_x_actividad correspondiente
      actividades.each do |actividad|
        unless pxa=PresupuestoXActividad.find_by_presupuesto_id_and_actividad_id(presupuesto.id, actividad.id)
          pxa = PresupuestoXActividad.new :presupuesto_id => presupuesto.id, :actividad_id => actividad.id
        end
        # A la ultima actividad le suma el resto
        if actividad == actividades.last
          pxa.numero_unidades = num_unidades_x_actividad + resto_num_unidades
          pxa.importe = importe_x_actividad + resto_importe
        else
          pxa.numero_unidades = num_unidades_x_actividad 
          pxa.importe = importe_x_actividad
        end
        pxa.save
        importacion_error pxa, _("Actividad") + " '" + actividad.codigo + "' " + _("en la línea de Presupuesto") + " " + _("con ID") + " '" + presupuesto.id.to_s + "'"
      end
    end
  end

  def actualiza_presupuesto_financiador presupuesto, indice, fila
    agente = @proyecto.financiador.find_by_nombre fila[indice['financiador.nombre']]
    if agente && @proyecto 
      if ! (presupuesto.presupuesto_x_agente && (pxf = presupuesto.presupuesto_x_agente.find_by_agente_id agente.id) )
        pxf = PresupuestoXAgente.new :presupuesto_id => presupuesto.id, :agente_id => agente.id
      end
      pxf.importe = numero fila[indice['financiador.importe']]
      pxf.save
      importacion_error pxf, _("Financiador") + " '" + agente.nombre + "' " + _("en línea de Presupuesto con ID") + " '" + presupuesto.id.to_s + "'"
    elsif fila[indice['financiador.nombre']]
      importacion_error "<br>" + _("Financiador") + " " + fila[indice['financiador.nombre']].to_s + " " + _("no encontrado o no válido.")
    end
  end

  #--
  # METODOS DE IMPORTACIÓN MATRIZ
  #++

  # Importa las hojas de la matriz
  def importa_matriz carga_total, hoja_objetivos, hoja_resultados, hoja_actividades, hoja_variables
    # Metemos todo en una transaccion para hacer rollback si es carga total y ha habido algun problema
    Actividad.transaction do
      # Si es una carga total borramos todos los presupuestos del proyecto y el agente
      Actividad.find( :all, :conditions => { :proyecto_id => @proyecto.id } ).each do |a|
        r = a.resultado
        a.destroy
        importacion_error a, _("Borrado de actividad con código '%{codigo}'")%{:codigo => a.codigo}
        if r
          oe = r.objetivo_especifico
          r.destroy
          importacion_error r, _("Borrado de resultado con código '%{codigo}'")%{:codigo => oe.codigo}
          oe.destroy
          importacion_error oe, _("Borrado de objetivo específico con código '%{codigo}'")%{:codigo => oe.codigo}
        end
      end if carga_total
      if @import_error.nil? || @import_error == ""
        # Itera cada fila
        importa_matriz_objetivos hoja_objetivos
        importa_matriz_resultados hoja_resultados
        importa_matriz_actividades hoja_actividades
        # La hoja de variables no es obligatoria, si no esta no pasa nada
        importa_matriz_variables(hoja_variables) if hoja_variables
      end
      raise(ActiveRecord::Rollback, "Hacemos un rollback") if @import_error != ""
    end
  end

  # Importa una hoja de objetivos para la matriz
  def importa_matriz_objetivos hoja
    # El orden de las columnas es:
    # simples ->        codigo | descripcion 
    # multiples ->      hipotesis.descripcion 
    # multiples ->      iov.codigo | iov.descripcion
    # multiples ->	fv.codigo | fv.descripcion | fv.iov.codigo
    columnas = [ 'codigo','descripcion', 'iov.codigo','iov.descripcion','fv.codigo','fv.descripcion', 'fv.indicador', 'hipotesis.descripcion' ]
    indice=Hash[*columnas.each_with_index.to_a.flatten]

    oe = nil
    # Itera cada fila 
    hoja.each_with_index do |fila,numero_fila|
      limpia_fila fila
      # Si existe alguno de los datos basicos, es una fila nueva => obtenemos el oe 
      oe = actualiza_oe indice, fila if (fila[indice['codigo']] || fila[indice['descripcion']] ) && numero_fila > 0
      if ( oe )
        actualiza_hipotesis oe, indice, fila if fila[indice['hipotesis.descripcion']]
        actualiza_indicador oe, indice, fila if fila[indice['iov.codigo']] || fila[indice['iov.descripcion']]
        actualiza_fuente oe, indice, fila if fila[indice['fv.codigo']] || fila[indice['fv.descripcion']] || fila[indice['fv.indicador']]
      end
    end
  end

  # Actualiza un objetivo especifico
  def actualiza_oe indice, fila
    oe = nil
    if fila[indice['codigo']]
      oe = @proyecto.objetivo_especifico.find_by_codigo(fila[indice['codigo']]) || ObjetivoEspecifico.new
      oe.codigo = fila[indice['codigo']].to_s if oe.id.nil?
      oe.proyecto_id = @proyecto.id if oe.id.nil?
      oe.descripcion = fila[indice['descripcion']].to_s if !fila[indice['descripcion']].nil? || oe.id.nil?
      oe.save
      importacion_error oe, _("Objetivo Especifico") + " " + _("con código") + " '" + fila[indice['codigo']].to_s + "'"
      # Limpia hipotesis para poder importarlo luego y que no esten duplicadas
      oe.hipotesis.destroy_all if oe.errors.empty?
      oe = nil unless oe.errors.empty?
    else
      importacion_error "<br>" + _("Se produjeron errores procesando Objetivo Especifico")
      importacion_error _("Objetivo Especifico debe tener un código")
    end
    return oe
  end

  # Importa una hoja de resultados para la matriz
  def importa_matriz_resultados hoja
    # El orden de las columnas es:
    # simples ->        oe.codigo | codigo | descripcion 
    # multiples ->      hipotesis.descripcion 
    # multiples ->      iov.codigo | iov.descripcion
    # multiples ->      fv.codigo | fv.descripcion | fv.iov.codigo
    columnas = [ 'oe.codigo', 'codigo','descripcion','iov.codigo','iov.descripcion','fv.codigo','fv.descripcion', 'fv.indicador', 'hipotesis.descripcion' ]
    indice=Hash[*columnas.each_with_index.to_a.flatten]

    resultado = nil
    # Itera cada fila 
    hoja.each_with_index do |fila,numero_fila|
      limpia_fila fila
      # Si existe alguno de los datos basicos, es una fila nueva => obtenemos el oe 
      resultado = actualiza_resultado indice, fila if (fila[indice['oe.codigo']]) && numero_fila > 0
      if ( resultado )
        actualiza_hipotesis resultado, indice, fila if fila[indice['hipotesis.descripcion']]
        actualiza_indicador resultado, indice, fila if fila[indice['iov.codigo']] || fila[indice['iov.descripcion']]
        actualiza_fuente resultado, indice, fila if fila[indice['fv.codigo']] || fila[indice['fv.descripcion']] || fila[indice['fv.indicador']]
      end
    end
  end

  # Actualiza un resultado
  def actualiza_resultado indice, fila
    resultado=nil
    oe = @proyecto.objetivo_especifico.find_by_codigo(fila[indice['oe.codigo']])
    if oe && fila[indice['codigo']]
      resultado = oe.resultado.find_by_codigo(fila[indice['codigo']]) || Resultado.new
      resultado.objetivo_especifico_id = oe.id if resultado.id.nil?
      resultado.codigo = fila[indice['codigo']].to_s if resultado.id.nil?
      resultado.descripcion = fila[indice['descripcion']].to_s
      resultado.proyecto_id = @proyecto.id
      resultado.save
      importacion_error resultado, _("Resultado") + " '" + fila[indice['codigo']].to_s + "' " + _("del Objetivo Especifico") + " '" + fila[indice['oe.codigo']].to_s + "'"
      resultado = nil unless resultado.errors.empty?
      # Limpia hipotesis para poder importarlo luego y que no esten duplicadas
      resultado.hipotesis.destroy_all if resultado && resultado.errors.empty?
    else
      importacion_error "<br>" + _("Se produjeron errores procesando Resultado") + " " + (!fila[indice['codigo']].nil? ? "<br>" + _("El Resultado debe tener un código") :  _("con código") + " '" + fila[indice['codigo']].to_s + "'")
      importacion_error _("Objetivo Especifico") + " '" + fila[indice['oe.codigo']].to_s + "' " + _("no encontrado o no válido.") if oe.nil?
    end
    return resultado
  end

  # Importa una hoja de actividades para la matriz
  def importa_matriz_actividades hoja
    # El orden de las columnas es:
    # simples ->        resultado.codigo
    # multiples ->      codigo | descripcion 
    columnas = [ 'resultado.codigo', 'codigo', 'descripcion', 'pais.nombre', 'etapa.nombre' ]
    columnas.push('actividad_relacionada.codigo') if @proyecto.convenio_id
    indice=Hash[*columnas.each_with_index.to_a.flatten]

    actividad = nil
    # Itera cada fila 
    hoja.each_with_index do |fila,numero_fila|
      limpia_fila fila
      # Si existe el código de actividad, eliminamos el resultado para que no herede el anterior
      resultado = nil if numero_fila > 0 && fila[indice['codigo']]
      # Si existe alguno de los datos basicos, es una fila nueva => obtenemos el resultado
      resultado = resultado_para_actividad indice, fila if (fila[indice['resultado.codigo']]) && numero_fila > 0
      logger.warn "----> No tenemos resultado para la actividad " + fila[indice['codigo']] + "!!!" if resultado.nil? && (numero_fila > 0 && !fila[indice['resultado.codigo']]) && fila[indice['codigo']]
      if resultado || (numero_fila > 0 && !fila[indice['resultado.codigo']])
        actividad = actualiza_actividad resultado, indice, fila if fila[indice['codigo']] || fila[indice['descripcion']]
        if ( actividad )
          actualiza_pais_actividad actividad, indice, fila if fila[indice['pais.nombre']]
          actualiza_etapa_actividad actividad, indice, fila if fila[indice['etapa.nombre']]
        end
      end
    end
  end

  def resultado_para_actividad indice, fila
    resultado = @proyecto.resultado.find_by_codigo fila[indice['resultado.codigo']]
    if resultado.nil?
      importacion_error "<br>" + _("Se produjeron errores procesando hoja de Actividad")
      importacion_error _("Resultado") + " '" + (fila[indice['resultado.codigo']].to_s) + "' " + _("no encontrado o no válido.")
    end
    return resultado
  end

  def actualiza_actividad resultado, indice, fila
    #puts "-------------> Estamos en actualiza_actividad " + fila[indice['codigo']]
    if fila[indice['codigo']]
      actividad = @proyecto.actividad.find_by_codigo(fila[indice['codigo']]) || Actividad.new
      actividad.codigo = fila[indice['codigo']].to_s if actividad.id.nil?
      actividad.resultado_id = resultado.id if resultado 
      actividad.descripcion = fila[indice['descripcion']].to_s
      actividad.proyecto_id = @proyecto.id
      # En los pacs, importa la actividad relacionada si existe: 'actividad_relacionada.codigo'
      if @proyecto.convenio && fila[indice['actividad_relacionada.codigo']]
        actividad_relacionada = @proyecto.convenio.actividad.find_by_codigo fila[indice['actividad_relacionada.codigo']]
        actividad.actividad_convenio_id = actividad_relacionada.id if actividad_relacionada
        importacion_error( _("Para la actividad '%{codigo}' no se encontró la actividad relacionada '%{codigo_relacionado}' en la matriz general del Convenio")%{:codigo => fila[indice['codigo']], :codigo_relacionado => fila[indice['actividad_relacionada.codigo']]}) unless actividad_relacionada
      end
      actividad.save
      importacion_error( actividad, _("Actividad") + " '" + fila[indice['codigo']].to_s + "' " + _("en Resultado con código") + " '" + resultado.codigo + "'") if resultado
      importacion_error( actividad, _("Actividad") + _("Global") + " '" + fila[indice['codigo']].to_s + "' ") unless resultado
      # Limpia paises y etapas para poder importarlos luego
      actividad.actividad_x_pais.destroy_all if actividad.errors.empty?
      actividad.actividad_x_etapa.destroy_all if actividad.errors.empty?
      actividad = nil unless actividad.errors.empty?
    else
      importacion_error( _("Actividad debe tener un código en hoja de Actividad") + " " + _("para Resultado con código") + " '" + fila[indice['resultado.codigo']].to_s + "'") if resultado
      importacion_error( _("Actividad debe tener un código en hoja de Actividad") + " " + _("Global")) unless resultado
    end
    return actividad
  end

  def actualiza_pais_actividad actividad, indice, fila
    pais = @proyecto.pais.find_by_nombre fila[indice['pais.nombre']]
    if pais
      axp = actividad.pais.find_by_id(pais.id) || ActividadXPais.create(:actividad_id => actividad.id, :pais_id => pais.id)
      importacion_error axp, _("País") + " '" + fila[indice['etapa.nombre']].to_s + "' " + _("en Actividad con código") + " '" + actividad.codigo + "'"
    else
      importacion_error _("País") + " '" + fila[indice['pais.nombre']] + "' " + _("no encontrado o no válido.")
    end
  end

  def actualiza_etapa_actividad actividad, indice, fila
    etapa = @proyecto.etapa.find_by_nombre fila[indice['etapa.nombre']]
    if etapa 
      axe = actividad.etapa.find_by_id(etapa.id) || ActividadXEtapa.create(:actividad_id => actividad.id, :etapa_id => etapa.id) 
      importacion_error axe, _("Etapa") + " '" + fila[indice['etapa.nombre']].to_s + "' " + _("en Actividad con código") + " '" + actividad.codigo + "'"
    else
      importacion_error _("Etapa") + " '" + fila[indice['etapa.nombre']] + "' " + _("no encontrada o no válida.")
    end
  end

  # Importa una hoja de variables de indicadores para la matriz
  def importa_matriz_variables hoja
    # El orden de las columnas es:
    # simples ->	indicador.codigo | indicador es de resultado? | nombre | herramienta_medicion | fuente_informacion | contexto
    # simples ->	valor_base.valor | valor_base.fecha | valor_base.comentario
    # simples ->	valor_objetivo.valor | valor_objetivo.fecha | valor_objetivo.comentario
    # multiples ->	valor_medido.valor | valor_medido.fecha | valor_medido.comentario

    columnas = [ 'indicador.codigo', 'indicador_de_resultado', 'nombre', 'herramienta_medicion', 'fuente_informacion', 'contexto', 'valor_base.valor', 'valor_base.fecha', 'valor_base.comentario', 'valor_objetivo.valor', 'valor_objetivo.fecha', 'valor_objetivo.comentario', 'valor_medido.valor', 'valor_medido.fecha', 'valor_medido.comentario' ]

    indice=Hash[*columnas.each_with_index.to_a.flatten]

    # Ponemos un rollback por si las moscas
    VariableIndicador.transaction do
      # Nos cargamos todas las variables
      Indicador.find(	:all, :include=>["objetivo_especifico","resultado"],
			:conditions=>["objetivo_especifico.proyecto_id=? OR resultado.proyecto_id=?",@proyecto.id,@proyecto.id]).each do |ind|
        ind.variable_indicador.each { |variable| variable.destroy }
      end

      variable = nil
      # Itera cada fila 
      hoja.each_with_index do |fila,numero_fila|
        limpia_fila fila
        # Si existe alguno de los datos basicos, es una fila nueva => obtenemos el resultado 
        variable = actualiza_variable indice, fila if fila[indice['indicador.codigo']] && fila[indice['nombre']] && numero_fila > 0
        actualiza_variable_valor_medido variable, indice, fila if variable && fila[indice['valor_medido.valor']] && fila[indice['valor_medido.fecha']]
      end
      # Si hubo algun error y seleccionamos carga total, deshacemos los cambios
      raise(ActiveRecord::Rollback, "Hacemos un rollback") if @import_error != ""
    end
  end

  def actualiza_variable indice, fila
    variable = nil
    condiciones_indicador = fila[indice['indicador_de_resultado']].upcase==_("SI") ? "resultado.proyecto_id=?" : "objetivo_especifico.proyecto_id=?"
    indicador = Indicador.find_by_codigo( fila[indice['indicador.codigo']], :include=>["objetivo_especifico","resultado"],
                        :conditions=>[condiciones_indicador, @proyecto.id])
    if indicador
      variable = VariableIndicador.new(	:nombre => fila[indice['nombre']], :herramienta_medicion => fila[indice['herramienta_medicion']],
					:fuente_informacion => fila[indice['fuente_informacion']], :contexto => fila[indice['contexto']],
					:indicador_id => indicador.id )
      variable.valor_base = ValorVariableIndicador.new(
		:valor => fila[indice['valor_base.valor']], :fecha => fecha(fila[indice['valor_base.fecha']]), :comentario => fila[indice['valor_base.comentario']] )
      variable.valor_objetivo = ValorVariableIndicador.new(
		:valor => fila[indice['valor_objetivo.valor']], :fecha => fecha(fila[indice['valor_objetivo.fecha']]), :comentario => fila[indice['valor_objetivo.comentario']] )
      variable.save
      importacion_error variable, _("Variable de Indicador") + " '" + fila[indice['nombre']].to_s + "'" 
      variable = nil unless variable.errors.empty?
    else
      importacion_error "<br>" + _("Se produjeron errores procesando Variable") + " '" + fila[indice['nombre']].to_s + "'" + ":<br/>"
      importacion_error _("Indicador") + " '" + fila[indice['indicador.codigo']].to_s + "' " + _("no encontrado o no válido.") if indicador.nil?
    end

    return variable
  end

  def actualiza_variable_valor_medido variable, indice, fila
    fecha_saneada = fecha(fila[indice['valor_medido.fecha']])
    valor_medido = ValorVariableIndicador.new( :variable_indicador_id => variable.id, :valor => fila[indice['valor_medido.valor']],
                :fecha => fecha_saneada, :comentario => fila[indice['valor_medido.comentario']] )
    valor_medido.save
    importacion_error valor_medido, _("Valor Medido") + " '" + fila[indice['valor_medido.valor']].to_s + " el " + (fecha_saneada ? fecha_saneada.to_s : "") + "' " + _("para Variable de Indicador") + _("con nombre") + " '" + variable.nombre + "'" 
  end

  def actualiza_hipotesis objeto, indice, fila
    if objeto.hipotesis.find_by_descripcion(fila[indice['hipotesis.descripcion']]).nil?
      hipotesis=Hipotesis.new
      hipotesis.descripcion = fila[indice['hipotesis.descripcion']].to_s
      objeto.hipotesis << hipotesis
      hipotesis.save
      importacion_error hipotesis, _("Hipotesis") + " '" + fila[indice['hipotesis.descripcion']].to_s + "' en " + objeto.class.name + " " + _("con código") + " '" + objeto.codigo + "'"
    end
  end

  def actualiza_indicador objeto, indice, fila
    # El indicador deberia tener un codigo, pero el modelo permite que no lo tenga...
    # de momento lo dejamos asi, pero tendremos que tocar las validaciones del modelo
    if fila[indice['iov.codigo']]
      indicador = objeto.indicador.find_by_codigo(fila[indice['iov.codigo']]) || Indicador.new
      indicador.codigo = fila[indice['iov.codigo']].to_s if indicador.id.nil?
      objeto.indicador << indicador if indicador.id.nil? 
      indicador.descripcion = fila[indice['iov.descripcion']].to_s
      indicador.save
      importacion_error indicador, _("Indicador") + " '" + fila[indice['iov.codigo']].to_s + "' en " + objeto.class.name + " " + _("con código") + " '" + objeto.codigo + "'"
    else
      importacion_error _("En ") + objeto.class.name + " " + _("con código") + " " + objeto.codigo + " " + _("hay un Indicador que debería tener código.")
    end
  end

  def actualiza_fuente objeto, indice, fila
    indicador = objeto.indicador.find_by_codigo(fila[indice['fv.indicador']]) if fila[indice['fv.indicador']]
    # El indicador deberia tener un codigo, pero el modelo permite que no lo tenga...
    # de momento lo dejamos asi, pero tendremos que tocar las validaciones del modelo
    if fila[indice['fv.codigo']]
      fv = objeto.fuente_verificacion.find_by_codigo(fila[indice['fv.codigo']]) || FuenteVerificacion.new
      fv.codigo = fila[indice['fv.codigo']].to_s if fv.id.nil?
      fv.indicador_id = indicador.id if indicador
      objeto.fuente_verificacion << fv if fv.id.nil?
      fv.descripcion = fila[indice['fv.descripcion']].to_s
      fv.save
      importacion_error fv, _("Fuente de verificación") + " '" + fila[indice['fv.codigo']].to_s + "' en " + objeto.class.name + " " + _("con código") + " '" + objeto.codigo + "'"
      importacion_error _("Indicador") + " '" + fila[indice['fv.indicador']].to_s + "' " + _("relacionado a la Fuente de Verificación") + " '" + fila[indice['fv.codigo']].to_s + "' " + "' en " + objeto.class.name + " " + _("con código") + " '" + objeto.codigo + "' " + _("no encontrado o no válido.") if ( indicador.nil? && fila[indice['fv.indicador']] )
    else
      importacion_error _("En ") + objeto.class.name + " " + _("con código") + " " + objeto.codigo + " " + _("hay una Fuente de Verificación que debería tener código.")
    end
  end

end
