class Fakeout
  #DatosTarjetaSocio
  MODELS_1 = %w[Provincia PartidaIngreso Comunidad Municipio DefinicionEstadoTarea DefinicionEstadoXDefinicionEstado DefinicionEstadoXEtiqueta Empleado EmpleadoSalarioHora NaturalezaSocio OrigenSocio Socio InformacionSocio].freeze
  MODELS_2 = %w[Actividad CuentaContable ObjetivoEspecifico Indicador Resultado FuenteVerificacion Subpartida Proveedor Gasto GastoXActividad GastoXAgente Hipotesis ProgramaMarco Ingreso LogContabilidad PartidaFinanciacion Personal ProyectoXDefinicionDato ProyectoXMoneda Subactividad ValorIntermedioXSubactividad].freeze
  MODELS_3 = %w[ActividadDetallada ActividadXEtapa ActividadXEtiquetaTecnica DatoTexto].freeze
  MODELS_4 = %w[PeriodoContrato Presupuesto PresupuestoDetallado PresupuestoIngreso PresupuestoIngresoDetallado PresupuestoXAgente PresupuestoXActividad PresupuestoXProyecto CampoTipoContrato ContratoXActividad ContratoXCampoTipoContrato GastoXContrato IndicadorGeneral VariableIndicador ValorVariableIndicador FuenteVerificacionXDocumento GastoXDocumento Transferencia GastoXTransferencia IndicadorGeneralXProyecto ItemContrato Pago PagoSocio ProyectoXAreaActuacion ProyectoXProyecto ProyectoXSectorIntervencion SubactividadDetallada TransferenciaXAgente ValorIntermedioXActividad ValorXIndicadorGeneral VersionContrato].freeze

  attr_accessor :size, :output

  def tiny
    1
  end

  def small
    25 + rand(50)
  end

  def medium
    250 + rand(250)
  end

  def large
    1000 + rand(500)
  end

  def initialize(size)
    self.size = size
    self.output = open("fakeout.log", 'w')
  end

  def fakeout
    begin
      self.output.write "Faking it ... (#{size})\n"
      Fakeout.disable_mailers

      process(MODELS_1)
      proyecto
      process(MODELS_2)
      libro_agente_moneda_pais
      self.output.write "libro_agente_moneda_pais\n"
      documento_proyecto
      self.output.write "documento_proyecto\n"
      proyecto_estado_ejecucion
      self.output.write "proyecto_estado_ejecucion\n"
      documento_contrato
      self.output.write "documento_contrato\n"
      datos_proyecto
      self.output.write "datos_proyecto\n"
      # partida_x_partida_financiacion ##Esta no funciona
      etapa_proyecto
      self.output.write "etapa_proyecto\n"
      contrato_proyecto
      self.output.write "contrato_proyecto\n"
      grupo_usuario_x_espacio
      self.output.write "grupo_usuario_x_espacio\n"
      grupo_usuario_x_libro
      self.output.write "grupo_usuario_x_libro\n"
      ##grupo_usuario_x_agente
      grupo_usuario_x_proyecto
      proyecto_x_pais
      self.output.write "proyecto_x_pais\n"
      proyecto_sector_poblacion
      self.output.write "proyecto_sector_poblacion\n"
      pais_actividad
      self.output.write "pais_actividad\n"
      ##partida_x_partida_financiacion
      proyecto_x_implementador
      self.output.write "proyecto_x_implementador\n"
      #agente_grupo_usuario
      convocatoria_x_pais
      self.output.write "convocatoria_x_pais\n"
      #workflow_contrato_etiqueta_agente
      #puts "workflow_contrato_etiqueta_agente"
      proyecto_x_sector_poblacion
      self.output.write "proyecto_x_sector_poblacion\n"
      valor_intermedio_x_indicador
      self.output.write "valor_intermedio_x_indicador\n"
      process(MODELS_3)
      actualiza_definicion_estado
      self.output.write "actualiza_definicion_estado\n"
      objetivo_general_proyecto
      self.output.write "objetivo_general_proyecto\n"
      tipo_contrato_x_documento
      self.output.write "tipo_contrato_x_documento\n"
      transferencia_x_documento
      self.output.write "transferencia_x_documento\n"
      contrato_x_financiador
      self.output.write "contrato_x_financiador\n"
      estado_contrato
      self.output.write "estado_contrato\n"
      process(MODELS_4)
      periodo_proyecto
      self.output.write "periodo_proyecto\n"
      indicador_general_x_programa_marco
      self.output.write "indicador_general_x_programa_marco\n"

      #Hay que mirar que hacer con los proyectos para hacerlos convenios.
    end
    self.output.close
  end

  def process(models)
    models.each do |model|
      unless respond_to?("build_#{model.downcase}")
        self.output.write "  * #{model.pluralize}: **warning** I couldn't find a build_#{model.downcase} method\n"
        next
      end
      1.upto(send(size)) do
        begin
          attributes = send("build_#{model.downcase}")
          if attributes && !attributes.empty?
            m = model.constantize.new(attributes)
            save_models(m)
          end
        rescue StandardError => e
          self.output.write "Error build_#{model.downcase}\n"
          self.output.write "#{e}\n"
        end
      end
      self.output.write "  * #{model.pluralize}: #{model.constantize.count(:all)}\n"
    end
  end


  def proyecto
    1.upto(send(size)) do
      attributes = build_proyecto
      begin
        if attributes && !attributes.empty?
          p = Proyecto.new(attributes)
          save_models(p)
        end
      end
    end
  end

  def proyecto_estado_ejecucion
    user = UserInfo.current_user
    user_id = user ? user.id : nil
    Proyecto.all.each do |proyecto|
      e = Estado.new definicion_estado_id: 5,
                     proyecto_id: proyecto.id,
                     usuario_id: user_id,
                     estado_actual: true,
                     fecha_inicio: proyecto.fecha_de_inicio
      save_models(e)
    end
  end

  def contrato_x_financiador
    Contrato.all.each do |contrato|
      Agente.all.each do |agente|
        contrato_x_financiador = ContratoXFinanciador.new(build_contratoxfinanciador(contrato, agente))
        save_models(contrato_x_financiador)
      end
    end
  end

  def libro_agente_moneda_pais
    Agente.all.each do |agente|
      Moneda.all.each do |moneda|
        Pais.all.each do |pais|
          libro = Libro.new(build_libro(agente, moneda, pais))
          save_models(libro)
        end
      end
    end
  end


  # GrupoUsuarioXLibro GrupoUsuarioXProyecto
  def grupo_usuario_x_libro
    Libro.all.each do |libro|
      libro.grupo_usuario = GrupoUsuario.all
    end
  end

  def grupo_usuario_x_proyecto
    # Proyecto.all.each do |proyecto|
    #   proyecto.grupo_usuario = GrupoUsuario.all
    # end
  end

  def grupo_usuario_x_agente
    Agente.all.each do |agente|
      agente.grupo_usuario = GrupoUsuario.all
    end
  end

  def proyecto_x_pais
    Pais.all.each do |pais|
      pais.proyecto = Proyecto.all
    end
  end

  def proyecto_sector_poblacion
    SectorPoblacion.all.each do |sector|
      sector.proyecto = Proyecto.all
    end
  end

  # def empleado_salario_hora
  # 	EmpleadoSalarioHora

  # 	Empleado.all.each do |empleado|
  # 		empleado.empleado_salario_hora
  # 	end
  # end

  def valor_intermedio_x_indicador
    Indicador.all.each do |indicador|
      fecha_inicio = indicador.proyecto.fecha_de_inicio
      fecha_fin = indicador.proyecto.fecha_de_fin
      if fecha_inicio && fecha_fin
        fecha = random_date(fecha_inicio.to_datetime.to_f, fecha_fin.to_datetime)
        valor_intermedio_x_indicador = ValorIntermedioXIndicador.new(build_valorintermedioxindicador(indicador, fecha))
        save_models(valor_intermedio_x_indicador)
      end
    end
  end

  def objetivo_general_proyecto
    Proyecto.all.each do |proyecto|
      og = ObjetivoGeneral.new(build_objetivogeneral(proyecto))
      save_models(og)
    end
  end

  def partida_x_partida_financiacion
    Partida.all.each do |partida|
      partida.partida_financiacion = PartidaFinanciacion.all
    end
  end

  def proyecto_x_implementador
    Proyecto.all.each do |proyecto|
      proyecto.implementador = Agente.all
    end
  end

  def workflow_contrato_etiqueta_agente
    WorkflowContrato.all.each do |workflow_contrato|
      Etiqueta.all.each do |etiqueta|
        Agente.all.each do |agente|
          wcxe = WorkflowContratoXEtiqueta.new(build_workflowcontratoxetiqueta(workflow_contrato, etiqueta, agente))
          save_models(wcxe)
        end
      end
    end
  end

  def grupo_usuario_x_espacio
    Espacio.all.each do |espacio|
      espacio.grupo_usuario = GrupoUsuario.all
    end
  end

  def pais_actividad
    Pais.all.each do |pais|
      pais.actividad =	Actividad.all
    end
  end

  def convocatoria_x_pais
    Convocatoria.all.each {|convocatoria|
      Pais.all.each {|pais|
        c_x_p = ConvocatoriaXPais.new(build_convocatoriaxpais(convocatoria,pais))
        save_models(c_x_p)
      }
    }
  end

  def etapa_proyecto
    Proyecto.all.each do |proyecto|
      fecha_inicio = (proyecto.fecha_inicio_aprobada_original || random_datetime).to_datetime
      fecha_fin = fecha_inicio.to_datetime + (rand(9) + 1).day
      1.upto(rand(9)) do |_i|
        etapa = Etapa.new(build_etapa(proyecto, fecha_inicio, fecha_fin))
        save_models(etapa)
        fecha_inicio = fecha_fin + 1.day
        fecha_fin = fecha_inicio + (rand(9) + 1).day
      end
    end
  end


  def periodo_proyecto
    Proyecto.all.each do |proyecto|
      proyecto.etapa.each do |etapa|
        periodo = Periodo.new(build_periodo(proyecto, etapa.fecha_inicio, etapa.fecha_fin))
        save_models(periodo)
      end
    end
  end


  def contrato_proyecto
    Proyecto.all.each do |proyecto|
      fecha_inicio = proyecto.fecha_de_inicio
      fecha_fin = proyecto.fecha_de_fin

      next unless fecha_inicio && fecha_fin

      contrato = Contrato.new(build_contrato(proyecto, fecha_inicio, fecha_fin))
      save_models(contrato)

      # save_models(contrato) do
      #   create_estado_contrato(contrato)
      # end

      # ContratoXActividad ContratoXCampoTipoContrato ContratoXFinanciador GastoXContrato
    end
  end

  def partida_x_partida_financiacion
    Partida.all.each do |partida|
      PartidaFinanciacion.all.each do |partida_financiacion|
        PartidaXPartidaFinanciacion.create!(build_partidaxpartidafinanciacion(partida, partida_financiacion))
      end
    end
  end

  def documento_proyecto
    Proyecto.all.each do |proyecto|
      file = Tempfile.new('test')
      begin
        file.write("PRUEBA")

        documento = Documento.new(build_documento(proyecto, file))
        save_models(documento) do
          etiqueta_documento(documento)
        end
      end
      file.close
      file.unlink
    end
  end

  def documento_contrato
    Proyecto.all.each do |proyecto|
      proyecto.contrato.each do |contrato|
        contrato.estado_contrato.each do |estado_contrato|
          proyecto.documento.each do |documento|
            contrato_x_documento = ContratoXDocumento.new(build_contratoxdocumento(estado_contrato, documento ))
            save_models(contrato_x_documento)
          end
        end
      end
    end
  end

  def tipo_contrato_x_documento
    TipoContrato.all.each do |tipo_contrato|
      Documento.all.each do |documento|
        TipoContratoXDocumento.create!(build_tipocontratoxdocumento(tipo_contrato,documento))
      end
    end
  end

  def transferencia_x_documento
    Transferencia.all.each do |transferencia|
      Documento.all.each do |documento|
        TransferenciaXDocumento.create!(build_transferenciaxdocumento(transferencia,documento))
      end
    end
  end

  def etiqueta_documento(documento)
    documento.etiqueta = Etiqueta.all
  end

  def proyecto_x_sector_poblacion
    Proyecto.all.each do |proyecto|
      proyecto.sector_poblacion = SectorPoblacion.all
    end
  end

  def create_estado_contrato(contrato)
    estado_contrato = EstadoContrato.new(build_estadocontrato(contrato))
    save_models(estado_contrato)
  end

  def agente_grupo_usuario
    Agente.all.each do |agente|
      agente.grupo_usuario = GrupoUsuario.all
    end
  end

  def actualiza_definicion_estado
    DefinicionEstado.update_all(reporte: true)
  end

  def datos_proyecto
    Proyecto.all.each do |proyecto|
      Pais.all.each do |pais|
        save_models(DatosProyecto.new build_datosproyecto(proyecto,pais))
      end
    end
  end


  def estado_contrato
    Contrato.all.each do |contrato|
      #Estado Incial
      e_c = EstadoContrato.new(build_estadocontrato(contrato,true))
      save_models(e_c)
      # #Estado Ejcucion
      # e_c = EstadoContrato.new(build_estadocontrato(contrato))
      # save_models(e_c)
    end
  end

  def convocatoria_x_pais
    Convocatoria.all.each {|convocatoria|
      Pais.all.each {|pais|
        c_x_p = ConvocatoriaXPais.new(build_convocatoriaxpais(convocatoria,pais))
        save_models(c_x_p)
      }
    }
  end


  def indicador_general_x_programa_marco
    IndicadorGeneral.all.each {|indicador|
      ProgramaMarco.all.each {|programa|
        i = IndicadorGeneralXProgramaMarco.new(build_indicadorgeneralxprogramamarco(indicador,programa))
        save_models(i)
      }
    }
  end

  def save_models(model)
    if model.valid?
      model.save
      yield if block_given?
    else
      self.output.write "Error #{model}\n"
      self.output.write "#{model.errors.to_yaml}\n"
    end
  rescue StandardError => e
    self.output.write "#{model.to_yaml}\n"
    self.output.write "#{e}\n"
  end

  # by default, all mailings are disabled on faking out
  def self.disable_mailers
    ActionMailer::Base.perform_deliveries = false
  end

  def build_plugin
    {
        nombre: random_string(255, 0),
        codigo: random_string(255, 0),
        clase: random_string(255, 0),
        descripcion: random_string(255, 0),
        version: random_string(255, 0),
        peso: random_integer(4, 0),
        disponible: random_boolean,
        activo: random_boolean,
        engine: random_boolean

    }
  end

  def build_proyecto
    fecha_inicio_aprobada_original = Time.now
    fecha_fin_aprobada_original = Time.now + 2.year

    fecha_limite_peticion_prorroga = fecha_fin_aprobada_original - 6.month
    fecha_inicio_aviso_peticion_prorroga = fecha_fin_aprobada_original - 6.month
    fecha_limite_peticion_prorroga_justificacion = fecha_fin_aprobada_original - 8.month
    fecha_inicio_aviso_peticion_prorroga_justificacion = fecha_fin_aprobada_original - 8.month

    {
        nombre: random_string(255, 0),
        titulo: random_text,
        moneda_principal: pick_random(Moneda),
        moneda_intermedia: pick_random(Moneda),
        convenio: nil ,
        convenio_accion: random_string(255, 0),
        libro_principal: pick_random(Libro),
        pais_principal: pick_random(Pais),
        importe_previsto_total: random_decimal(11, 2),
        importe_previsto_subvencion: random_decimal(11, 2),
        convocatoria: pick_random(Convocatoria),
        gestor: pick_random(Agente),
        identificador_financiador: random_string(255, 0),
        fecha_limite_peticion_prorroga: fecha_limite_peticion_prorroga.strftime('%Y/%m/%d'),
        fecha_inicio_aviso_peticion_prorroga: fecha_inicio_aviso_peticion_prorroga.strftime('%Y/%m/%d'),
        ocultar_gastos_otras_delegaciones: random_boolean,
        fecha_limite_peticion_prorroga_justificacion: fecha_limite_peticion_prorroga_justificacion.strftime('%Y/%m/%d'),
        fecha_inicio_aviso_peticion_prorroga_justificacion: fecha_inicio_aviso_peticion_prorroga_justificacion.strftime('%Y/%m/%d'),
        fecha_inicio_aprobada_original: fecha_inicio_aprobada_original.strftime('%Y/%m/%d'),
        fecha_fin_aprobada_original: fecha_fin_aprobada_original.strftime('%Y/%m/%d'),
        programa_marco: pick_random(ProgramaMarco),
        created_at: Time.now,
        updated_at: Time.now
    }
  end

  def build_actividad
    {
        codigo: random_string(255, 0),
        descripcion: random_text,
        proyecto: pick_random(Proyecto),
        resultado: pick_random(Resultado),
        actividad_convenio: nil
    }
  end

  def build_agente
    {
        nombre: random_string(255, 0),
        nombre_completo: random_string(255, 0),
        financiador: random_boolean,
        implementador: random_boolean,
        moneda_principal: pick_random(Moneda),
        moneda_intermedia: pick_random(Moneda),
        pais: pick_random(Pais),
        socia_local: random_boolean,
        sistema: random_boolean,
        publico: random_boolean,
        local: random_boolean,
        nif: random_string(255, 0),
        tipo_agente: pick_random(TipoAgente)
    }
  end

  def build_comentario
    {
        usuario: pick_random(Usuario),
        texto: random_text,
        elemento_type: random_string(255, 0),
        elemento: pick_random(PeriodoContrato),
        sistema: random_boolean
    }
  end

  def build_contrato(proyecto, fecha_inicio, fecha_fin)
    # fecha_inicio = random_datetime
    # fecha_fin = random_datetime(fecha_inicio.to_f)
    {
        codigo: random_string(255, 0),
        nombre: random_string(255, 0),
        importe: random_decimal(11, 2),
        moneda: pick_random(Moneda),
        descripcion: random_text,
        observaciones: random_text,
        fecha_inicio: fecha_inicio.strftime('%Y/%m/%d'),
        fecha_fin: fecha_fin.strftime('%Y/%m/%d'),
        agente: pick_random(Agente),
        proyecto: proyecto,
        proveedor: pick_random(Proveedor),
        marcado: pick_random(Marcado),
        objetivo: random_text,
        justificacion: random_text,
        tipo_contrato: pick_random(TipoContrato)
    }
  end

  def build_convocatoria
    {
        codigo: random_string(255, 0),
        nombre: random_string(255, 0),
        descripcion: random_text,
        observaciones: random_text,
        agente: pick_random(Agente),
        fecha_publicacion: random_date,
        fecha_presentacion: random_date,
        fecha_resolucion: random_date,
        tipo_convocatoria: pick_random(TipoConvocatoria),
        cerrado: random_boolean
    }
  end

  def build_datosproyecto(proyecto,pais)
    {
        proyecto: proyecto,
        beneficiarios_directos_hombres: random_integer(4, 0),
        beneficiarios_directos_mujeres: random_integer(4, 0),
        beneficiarios_indirectos_hombres: random_integer(4, 0),
        beneficiarios_indirectos_mujeres: random_integer(4, 0),
        beneficiarios_directos_sin_especificar: random_integer(4, 0),
        beneficiarios_indirectos_sin_especificar: random_integer(4, 0),
        poblacion_total_de_la_zona: random_integer(4, 0),
        pais: pais
    }
  end

  def build_definicionestado
    {
        nombre: random_string(255, 0),
        descripcion: random_text,
        estado_padre_id: random_integer(4, 0),
        primer_estado: random_boolean,
        formulacion: random_boolean,
        aprobado: random_boolean,
        cerrado: random_boolean,
        orden: random_integer(4, 0),
        reporte: random_boolean,
        ejecucion: random_boolean
    }
  end

  def build_documento(proyecto,file)
    {
        # adjunto_file_name: random_string(255, 0),
        # adjunto_content_type: random_string(255, 0),
        # adjunto_file_size: random_integer(4, 0),
        adjunto: file,
        descripcion: random_text,
        tipo: random_string(255, 0),
        usuario: pick_random(Usuario),
        proyecto: proyecto,
        agente: pick_random(Agente)
        # adjunto_url: random_string(255, 0)
    }
  end

  def build_empleado
    {
        nombre: random_string(255, 0),
        activo: random_boolean,
        agente: pick_random(Agente)
    }
  end

  def build_espacio
    {
        nombre: random_text,
        descripcion: random_text,
        espacio_padre: pick_random(Espacio),
        proyecto: pick_random(Proyecto),
        definicion_espacio_proyecto: random_boolean,
        definicion_proyecto: pick_random(Espacio),
        agente: pick_random(Agente),
        definicion_espacio_agente: random_boolean,
        definicion_agente: pick_random(Espacio),
        ocultar: random_boolean,
        modificable: random_boolean,
        definicion_espacio_financiador: random_boolean,
        definicion_financiador: pick_random(Espacio),
        pais: pick_random(Pais),
        definicion_espacio_pais: random_boolean,
        definicion_pais: pick_random(Espacio),
        definicion_espacio_socia: random_boolean,
        definicion_socia: pick_random(Espacio),
        espacio_contratos: random_boolean
    }
  end

  def build_estadocontrato(contrato = pick_random(Contrato), estado_inicial = false)
    fecha_inicio = contrato.fecha_inicio
    # fecha_fin = random_datetime(fecha_inicio.to_f)
    fecha_fin = contrato.fecha_fin
    if estado_inicial
      workflow_contrato = WorkflowContrato.where(primer_estado: true).first
    else
      workflow_contrato = WorkflowContrato.where(ejecucion: true).first
    end

    {
        workflow_contrato: workflow_contrato ,
        #:contrato => pick_random(Contrato),
        contrato: contrato,
        fecha_inicio: fecha_inicio,
        fecha_fin: fecha_fin,
        observaciones: random_text,
        usuario: pick_random(Usuario),
        estado_actual: true

    }
  end

  def build_estado
    fecha_inicio = random_datetime
    fecha_fin = random_datetime(fecha_inicio.to_f)
    {
        definicion_estado: pick_random(DefinicionEstado),
        proyecto: pick_random(Proyecto),
        fecha_inicio: random_date,
        fecha_fin: random_date,
        observacion: random_text,
        usuario: pick_random(Usuario),
        estado_actual: random_boolean

    }
  end

  def build_etiqueta
    {
        nombre: random_string(255, 0),
        descripcion: random_text,
        tipo: random_string(255, 0)
    }
  end

  def build_fuenteverificacion
    {
        codigo: random_string(255, 0),
        descripcion: random_text,
        indicador: pick_random(Indicador),
        objetivo_especifico: pick_random(ObjetivoEspecifico),
        resultado: pick_random(Resultado),
        completada: random_boolean,
        fuente_verificacion_convenio: nil # De momento nil
    }
  end

  def build_grupousuario
    {
        nombre: random_string(255, 0),
        ocultar_proyecto: random_boolean,
        proyecto_rol: pick_random(Rol)
    }
  end

  def build_indicador
    {
        codigo: random_string(255, 0),
        descripcion: random_text,
        objetivo_especifico: pick_random(ObjetivoEspecifico),
        resultado: pick_random(Resultado),
        indicador_convenio: nil # De momento nil
    }
  end

  def build_ingreso
    {
        importe: random_decimal(11, 2),
        moneda: pick_random(Moneda),
        concepto: random_string(255, 0),
        observaciones: random_string(255, 0),
        partida_ingreso: pick_random(PartidaIngreso),
        fecha: random_date,
        marcado: pick_random(Marcado),
        tasa_cambio: pick_random(TasaCambio),
        agente: pick_random(Agente),
        numero_documento: random_string(255, 0),
        proveedor: pick_random(Proveedor),
        financiador: pick_random(Agente),
        proyecto: pick_random(Proyecto),
        ref_contable: random_string(255, 0),
        es_valorizado: random_boolean

    }
  end

  def build_libro(agente, moneda, pais)
    {
        nombre: random_string(255, 0),
        moneda: moneda,
        agente: agente,
        cuenta: random_string(255, 0),
        descripcion: random_string(255, 0),
        tipo: random_string(255, 0),
        pais: pais,
        iban: random_string(255, 0),
        swift: random_string(255, 0),
        bloqueado: false,
        oculto: random_boolean,
        entidad: random_string(255, 0)
    }
  end

  def build_marcado
    {
        nombre: random_text,
        descripcion: random_text,
        color: random_text,
        primer_estado: random_boolean,
        marcado_padre: pick_random(Marcado),
        automatico: random_boolean,
        error: random_boolean
    }
  end

  def build_pago
    #Buscar un pago cuyo agente sea igual que el del libro
    libro = Libro.where(bloqueado: false).first
    gasto = Gasto.where(agente_id: libro.agente_id, moneda_id: libro.moneda_id).first

    {
        importe: random_decimal(11, 2),
        fecha: random_date,
        gasto: gasto,
        libro: libro,
        observaciones: random_string(255, 0),
        forma_pago: random_string(255, 0),
        referencia_pago: random_string(255, 0),
        ref_contable: random_string(255, 0)
    }
  end

  def build_pagosocio
    {
        concepto: random_string(255, 0),
        fecha_emision: random_date,
        fecha_pago: random_date,
        importe: random_decimal(11, 2),
        comentario: random_text,
        fecha_alta_sistema: random_date,
        socio: pick_random(Socio),
        forma_pago_socio: pick_random(FormaPagoSocio)
    }
  end

  def build_partidafinanciacion
    {
        nombre: random_string(255, 0),
        codigo: random_string(255, 0),
        descripcion: random_string(255, 0),
        proyecto: pick_random(Proyecto),
        tipo: random_string(255, 0),
        puede_ser_padre: random_boolean,
        partida_financiacion_madre: pick_random(PartidaFinanciacion),
        padre: random_boolean,
        agente: pick_random(Agente),
        porcentaje_maximo: random_decimal(1, 2),
        importe: random_decimal(11, 2)
    }
  end

  def build_personal
    {
        proyecto: pick_random(Proyecto),
        nombre: random_string(255, 0),
        tipo_personal: pick_random(TipoPersonal),
        categoria: random_string(255, 0),
        residencia: random_string(255, 0),
        tipo_contrato: random_string(255, 0),
        horas_imputadas: random_integer(4, 0),
        salario_mensual: random_decimal(11, 2),
        meses: random_decimal(11, 2),
        salario_total: random_decimal(11, 2),
        moneda: pick_random(Moneda)

    }
  end

  def build_presupuestodetallado
    fecha_inicio = random_datetime
    fecha_fin = random_datetime(fecha_inicio.to_f)

    {
        presupuesto: pick_random(Presupuesto),
        importe: random_decimal(11, 2),
        fecha_inicio: fecha_inicio,
        fecha_fin: fecha_fin,
        nombre: random_string(255, 0),
        mes: random_integer(4, 0)
    }
  end

  def build_presupuestoingreso
    {
        importe: random_decimal(11, 2),
        porcentaje: random_decimal(1, 2),
        concepto: random_string(255, 0),
        observaciones: random_string(255, 0),
        partida_ingreso: pick_random(PartidaIngreso),
        moneda: pick_random(Moneda),
        etapa: pick_random(Etapa),
        marcado: pick_random(Marcado),
        tasa_cambio: pick_random(TasaCambio),
        agente: pick_random(Agente),
        proyecto: pick_random(Proyecto),
        financiador: pick_random(Agente)
    }
  end

  def build_programamarco
    {
        nombre: random_string(255, 0),
        objetivo_general: random_string(255, 0),
        moneda: pick_random(Moneda),
        descripcion: random_text,
        activo: true

    }
  end

  def build_proveedor
    {
        nombre: random_string(255, 0),
        nif: random_string(255, 0),
        descripcion: random_string(255, 0),
        observaciones: random_text,
        agente: pick_random(Agente),
        pais: pick_random(Pais),
        activo: random_boolean,
        entidad_bancaria: random_string(255, 0),
        cuenta_bancaria: random_string(255, 0)
    }
  end

  def build_rol
    {
        nombre: random_string(255, 0),
        seccion: random_string(255, 0),
        descripcion: random_string(255, 0),
        admin: random_boolean

    }
  end

  def build_socio
    {
        nombre: random_string(255, 0),
        apellido1: random_string(255, 0),
        apellido2: random_string(255, 0),
        tratamiento: random_string(255, 0),
        NIF: random_string(255, 0),
        NIF_representante: random_string(255, 0),
        sexo: random_string(255, 0),
        fecha_nacimiento: random_date,
        direccion: random_string(255, 0),
        localidad: random_string(255, 0),
        codigo_postal: random_string(255, 0),
        provincia: random_string(255, 0),
        comunidad: random_string(255, 0),
        municipio: random_string(255, 0),
        codigo_provincia_fiscal: random_string(255, 0),
        pais: random_string(255, 0),
        email: random_string(255, 0),
        telefono_fijo: random_string(255, 0),
        telefono_movil: random_string(255, 0),
        comentarios: random_text,
        naturaleza_socio: pick_random(NaturalezaSocio)
    }
  end

  def build_subpartida
    {
        nombre: random_string(255, 0),
        proyecto: pick_random(Proyecto),

        numero: random_integer(4, 0),
        agente: pick_random(Agente),
        partida: pick_random(Partida)
    }
  end

  def build_tarea
    fecha_inicio = random_datetime
    fecha_fin = random_datetime(fecha_inicio.to_f)

    {
        titulo: random_string(255, 0),
        descripcion: random_text,
        tipo_tarea: pick_random(TipoTarea),
        proyecto: pick_random(Proyecto),
        usuario: pick_random(Usuario),
        usuario_asignado: pick_random(Usuario),
        fecha_inicio: fecha_inicio,
        fecha_fin: fecha_fin,
        porcentage_implementacion: random_integer(4, 0),
        estado_tarea: pick_random(EstadoTarea),
        fecha_prevista: random_date,
        horas_empleadas: random_integer(4, 0),
        agente: pick_random(Agente),
        periodo: pick_random(Periodo),
        definicion_estado_tarea: pick_random(DefinicionEstadoTarea)
    }
  end

  def build_tasacambio
    fecha_inicio = random_datetime
    fecha_fin = random_datetime(fecha_inicio.to_f)

    {
        etapa: pick_random(Etapa),
        fecha_inicio: random_date,
        fecha_fin: random_date,
        tasa_fija: random_boolean,
        objeto: random_string(255, 0),
        moneda: pick_random(Moneda),
        tasa_cambio: random_decimal(11, 2),
        tasa_cambio_divisa: random_decimal(11, 2),

        agente: pick_random(Agente),
        pais: pick_random(Pais)
    }
  end

  def build_tipoagente
    {
        nombre: random_string(255, 0)

    }
  end

  def build_tipocontrato
    {
        nombre: random_string(255, 0),
        descripcion: random_string(255, 0),
        observaciones: random_text,
        duracion: random_integer(4, 0),
        agente: pick_random(Agente)

    }
  end

  def build_tipoconvocatoria
    {
        nombre: random_string(255, 0)
    }
  end

  def build_transferencia
    fecha_enviado = random_datetime
    fecha_recibido = random_datetime(fecha_enviado.to_f)

    {
        proyecto: pick_random(Proyecto),
        observaciones: random_string(255, 0),
        iban: random_string(255, 0),
        tasa_cambio: random_decimal(11, 2),
        tipo: random_string(255, 0),
        numero_cheque: random_string(255, 0),
        remanente: random_boolean,
        subtipo_movimiento: pick_random(SubtipoMovimiento),
        fecha_enviado: fecha_enviado.strftime('%Y/%m/%d'),
        importe_enviado: random_decimal(11, 2),
        libro_origen: pick_random(Libro),
        fecha_recibido: fecha_recibido.strftime('%Y/%m/%d'),
        importe_recibido: random_decimal(11, 2),
        importe_cambiado: random_decimal(11, 2),
        libro_destino: pick_random(Libro),
        ref_contable_enviado: random_string(255, 0),
        ref_contable_recibido: random_string(255, 0),
        marcado: pick_random(Marcado)
    }
  end

  def build_usuario
    {
        nombre: random_string(255, 0),
        contrasena: random_string(255, 0),
        nombre_completo: random_string(255, 0),
        correoe: random_string(255, 0),
        administracion: random_boolean,
        proyectos: random_boolean,
        agentes: random_boolean,
        cuadromando: random_boolean,
        socios: random_boolean,
        documentos: random_boolean,
        informes_aecid: random_boolean,
        external_id: random_string(255, 0),
        bloqueado: random_boolean,
        agente_id: random_integer(4, 0),
        skype_id: random_string(255, 0),
        programas_marco: random_boolean
    }
  end

  def build_workflowcontrato
    {
        nombre: random_string(255, 0),
        descripcion: random_text,
        primer_estado: random_boolean,
        formulacion: random_boolean,
        aprobado: random_boolean,
        cerrado: false,
        orden: random_integer(4, 0),
        ejecucion: true
    }
  end

  def build_actividaddetallada
    {
        mes: random_integer(4, 0),
        etapa: pick_random(Etapa),
        actividad: pick_random(Actividad),
        seguimiento: random_boolean
    }
  end

  def build_actividadxetapa
    {
        actividad: pick_random(Actividad),
        etapa: pick_random(Etapa)
    }
  end

  def build_actividadxetiquetatecnica
    {
        actividad: pick_random(Actividad),
        etiqueta_tecnica: pick_random(EtiquetaTecnica),
        porcentaje: random_decimal(1, 2)
    }
  end

  def build_actividadxpais(actividad, pais)
    {
        actividad: actividad,
        pais: pais
    }
  end

  def build_agentexmoneda
    {
        moneda: pick_random(Moneda),
        agente: pick_random(Agente)
    }
  end

  def build_areaactuacion
    {
        nombre: random_string(255, 0),
        descripcion: random_text,
        categoria_area_actuacion: pick_random(CategoriaAreaActuacion)
    }
  end

  def build_areageografica
    {
        nombre: random_string(255, 0),
        descripcion: random_text
    }
  end

  def build_campotipocontrato
    {
        tipo_contrato: pick_random(TipoContrato),
        nombre: random_string(255, 0),
        etiqueta: random_string(255, 0),
        descripcion: random_string(255, 0),
        tipo_campo: 'text',
        tipo_condicion: '',
        valor_condicion: '',
        activo: random_boolean
    }
  end

  def build_categoriaareaactuacion
    {
        nombre: random_string(255, 0),
        descripcion: random_string(255, 0)
    }
  end

  def build_categoriasectorintervencion
    {
        nombre: random_string(255, 0),
        descripcion: random_string(255, 0)
    }
  end

  def build_comunidad
    {
        nombre: random_string(255, 0),
        provincia: pick_random(Provincia)
    }
  end

  def build_contratoxactividad
    {
        contrato: pick_random(Contrato),
        actividad: pick_random(Actividad),
        importe: random_decimal(11, 2)
    }
  end

  def build_contratoxcampotipocontrato
    {
        campo_tipo_contrato: pick_random(CampoTipoContrato),
        contrato: pick_random(Contrato),
        valor_dato: random_text
    }
  end

  def build_contratoxdocumento(estado_contrato, documento)
    {
        estado_contrato: estado_contrato,
        documento: documento
    }
  end

  def build_contratoxfinanciador(contrato,agente)
    {
        contrato: contrato,
        agente: agente,
        importe: random_decimal(11, 2)
    }
  end

  def build_convocatoriaxpais(convocatoria,pais)
    {
        convocatoria: convocatoria,
        pais: pais
    }
  end

  def build_cuentacontable
    {
        codigo: random_string(255, 0),
        delegacion: pick_random(Agente),
        elemento_contable: nil, # De momento esta a nil hasta saber como se guarda esto
        elemento_contable_type: random_string(255, 0),
        descripcion: random_text,
        observaciones: random_text,
        centro_coste: random_boolean
    }
  end

  def build_datotexto
    {
        dato: random_text,
        proyecto: pick_random(Proyecto),
        definicion_dato: pick_random(DefinicionDato)
    }
  end

  def build_datostarjetasocio
    {
        informacion_socio: pick_random(InformacionSocio),
        tipo_tarjeta: random_string(255, 0),
        #:numero_tarjeta => "#{random_integer(4,0).to_s.rjust(4, '0')}-#{random_integer(4,0).to_s.rjust(4, '0')}-#{random_integer(4,0).to_s.rjust(4, '0')}-#{random_integer(4,0).to_s.rjust(4, '0')}",
        numero_tarjeta: random_integer(11, 0).to_s.ljust(4, '0'),
        fecha_caducidad: Time.now + 2.years,
        numero_verificacion: random_integer(4, 0)
    }
  end

  def build_definiciondato
    {
        nombre: random_string(255, 0),
        rotulo: random_string(255, 0),
        tipo: random_string(255, 0),
        rango: random_integer(4, 0),
        grupo_dato_dinamico: pick_random(GrupoDatoDinamico),
        proyecto: random_boolean
    }
  end

  def build_definicionestadotarea
    {
        titulo: random_text,
        descripcion: random_text,
        tipo_tarea: pick_random(TipoTarea),
        estado_tarea_id: random_integer(4, 0),
        definicion_estado: pick_random(DefinicionEstado)
    }
  end

  def build_definicionestadoxdefinicionestado
    {
        definicion_estado_padre: pick_random(DefinicionEstado),
        definicion_estado_hijo: pick_random(DefinicionEstado)
    }
  end

  def build_definicionestadoxetiqueta
    {
        definicion_estado: pick_random(DefinicionEstado),
        etiqueta: pick_random(Etiqueta)
    }
  end

  def build_documentoxespacio
    {
        espacio: pick_random(Espacio),
        documento: pick_random(Documento)
    }
  end

  def build_empleadosalariohora
    empleado = pick_random(Empleado)
    empleado_salario_hora = empleado.empleado_salario_hora.last

    fecha_inicio = if !empleado_salario_hora
                     random_datetime
                   else
                     empleado_salario_hora.fecha_fin + 1.day
                   end

    fecha_fin = fecha_inicio + 2.day

    {
        empleado: pick_random(Empleado),
        fecha_inicio: fecha_inicio.strftime('%Y/%m/%d'),
        fecha_fin: fecha_fin.strftime('%Y/%m/%d'),
        salario_hora: random_decimal(2, 2)
    }
  end

  def build_estadotarea
    {
        nombre: random_string(255, 0),
        descripcion: random_text,
        activo: random_boolean,
        seleccionable: random_boolean
    }
  end

  def build_etapa(proyecto, fecha_inicio, fecha_fin)
    {
        nombre: random_string(255, 0),
        fecha_inicio: fecha_inicio.strftime('%Y/%m/%d'),
        fecha_fin: fecha_fin.strftime('%Y/%m/%d'),
        descripcion: random_string(255, 0),
        agente: pick_random(Agente),
        proyecto: proyecto,
        cerrada: false, # La ponemos a false
        saldos_transferidos: random_boolean,
        importe_previsto_subvencion: random_decimal(11, 2),
        presupuestable: true # lo ponemos a false
    }
  end

  def build_etiquetatecnica
    {
        nombre: random_string(255, 0),
        descripcion: random_string(255, 0)

    }
  end

  def build_etiquetaxdocumento
    {
        etiqueta: pick_random(Etiqueta),
        documento: create_documento
    }
  end

  def build_formapagosocio
    {
        forma_pago: random_string(255, 0)
    }
  end

  def build_fuenteverificacionxdocumento
    {
        fuente_verificacion: pick_random(FuenteVerificacion),
        documento: pick_random(Documento)
    }
  end

  def build_gasto
    proyecto = pick_random(Proyecto)

    fecha_inicio = if proyecto.fecha_de_inicio
                     proyecto.fecha_de_inicio.to_datetime
                   else
                     random_datetime
                   end
    fecha_fin = if proyecto.fecha_de_fin
                  proyecto.fecha_de_fin.to_datetime
                else
                  random_datetime(fecha_inicio.to_f)
                end
    {
        importe: random_decimal(5, 2),
        impuestos: random_decimal(5, 2),
        partida: pick_random(Partida),
        moneda: pick_random(Moneda),
        observaciones: random_string(255, 0),
        numero_factura: random_string(255, 0),
        fecha: random_date( fecha_inicio.to_f, fecha_fin ),
        concepto: random_string(255, 0),
        fecha_informe: random_date,
        agente: pick_random(Agente),
        proyecto_origen_id: proyecto,
        marcado: pick_random(Marcado),
        subpartida_agente: pick_random(Subpartida),
        tasa_cambio_agente: pick_random(TasaCambio),
        orden_factura_agente: random_integer(4, 0),
        marcado_agente: pick_random(Marcado),
        pais: pick_random(Pais),
        es_valorizado: random_boolean,
        ref_contable: random_string(255, 0),
        proveedor: pick_random(Proveedor),
        orden_factura_proyecto: random_integer(4, 0),
        empleado: pick_random(Empleado)
    }
  end

  def build_gastoxactividad
    {
        gasto: pick_random(Gasto),
        actividad: pick_random(Actividad),
        proyecto: pick_random(Proyecto),
        importe: random_decimal(11, 2)
    }
  end

  def build_gastoxagente
    {
        agente: pick_random(Agente),
        gasto: pick_random(Gasto),
        proyecto: pick_random(Proyecto),
        importe: random_decimal(11, 2)
    }
  end

  def build_gastoxcontrato
    contrato = pick_random(Contrato)
    # gasto = Gasto.where(gasto_id: contrato.gasto_x_contrato.first.gasto_id)
    gasto = pick_random(Gasto)
    {
        contrato: contrato,
        gasto: gasto
    }
  end

  def build_gastoxdocumento
    {
        gasto: pick_random(Gasto),
        documento: pick_random(Documento)
    }
  end

  def build_gastoxproyecto(proyecto)
    {
        proyecto: proyecto,
        gasto: pick_random(Gasto),
        orden_factura: random_string(255, 0),
        subpartida: pick_random(Subpartida),
        importe: random_decimal(4, 2),
        tasa_cambio_proyecto: pick_random(TasaCambio),
        marcado: pick_random(Marcado)
    }
  end

  def build_gastoxtransferencia
    {
        gasto: pick_random(Gasto),
        transferencia: pick_random(Transferencia)
    }
  end

  def build_grupodatodinamico
    {
        nombre: random_string(255, 0),
        rango: random_integer(4, 0),
        seguimiento: random_boolean,
        cierre: random_boolean
    }
  end

  def build_grupousuarioxagente(agente, grupo_usuario)
    {
        grupo_usuario: grupo_usuario,
        agente: agente,
        rol_asignado: pick_random(Rol)
    }
  end

  def build_grupousuarioxespacio
    {
        grupo_usuario: pick_random(GrupoUsuario),
        espacio: pick_random(Espacio)
    }
  end

  def build_grupousuarioxlibro
    {
        grupo_usuario: pick_random(GrupoUsuario),
        libro: pick_random(Libro)
    }
  end

  def build_grupousuarioxproyecto
    {
        grupo_usuario: pick_random(GrupoUsuario),
        proyecto: pick_random(Proyecto),
        rol_asignado: pick_random(Rol)
    }
  end

  def build_hipotesis
    {
        descripcion: random_text,
        objetivo_especifico: pick_random(ObjetivoEspecifico),
        resultado: pick_random(Resultado)

    }
  end

  def build_indicadorgeneral
    {
        nombre: random_string(255, 0),
        descripcion: random_string(255, 0),
        codigo: random_string(255, 0),
        activo: random_boolean,
        unidad: random_string(255, 0)
    }
  end

  def build_indicadorgeneralxprogramamarco(indicador,programa)
    {
        programa_marco: programa,
        indicador_general: indicador
    }
  end

  def build_indicadorgeneralxproyecto
    {
        proyecto: pick_random(Proyecto),
        indicador_general: pick_random(IndicadorGeneral),
        herramienta_medicion: random_string(255, 0),
        fuente_informacion: random_string(255, 0),
        contexto: random_text,
        valor_base_id: random_integer(4, 0),
        valor_objetivo_id: random_integer(4, 0)
    }
  end

  def build_informacionsocio
    {
        socio: pick_random(Socio),
        fecha_alta: random_date,
        fecha_baja: random_date,
        fecha_alta_sistema: random_date,
        importe_cuota: random_decimal(11, 2),
        calendario_pagos: random_string(255, 0),
        motivo_baja: random_text,
        enviar_periodica: random_boolean,
        enviar_puntual: random_boolean,
        enviar_182: random_boolean,
        fecha_carta_bienvenida: random_date,
        fecha_envio_documentacion: random_date,
        fecha_envio_carne: random_date,
        origen_socio: pick_random(OrigenSocio),
        comentario_origen_socio: random_text,
        forma_pago_socio: pick_random(FormaPagoSocio),
        activo: random_boolean,
        tipo_cuota_socio: pick_random(TipoCuotaSocio)
    }
  end

  def build_itemcontrato
    {
        contrato: pick_random(Contrato),
        nombre: random_string(255, 0),
        cantidad: random_integer(4, 0),
        coste_unitario: random_decimal(11, 2),
        descripcion: random_string(255, 0)
    }
  end

  def build_libroxproyecto
    {
        libro: pick_random(Libro),
        proyecto: pick_random(Proyecto)
    }
  end

  def build_logcontabilidad
    {
        agente: pick_random(Agente),
        usuario: pick_random(Usuario),
        elemento: random_string(255, 0),
        finalizado_ok: random_boolean,
        running: random_boolean,
        partial_execution: random_boolean
    }
  end

  def build_moneda
    {
        nombre: random_string(255, 0),
        abreviatura: random_string(255, 0)
    }
  end

  def build_monedaxpais
    {
        moneda: pick_random(Moneda),
        pais: pick_random(Pais)
    }
  end

  def build_municipio
    {
        nombre: random_string(255, 0),
        comunidad: pick_random(Comunidad)
    }
  end

  def build_naturalezasocio
    {
        naturaleza: random_string(255, 0)
    }
  end

  def build_objetivoespecifico
    {
        codigo: random_string(255, 0),
        descripcion: random_text,
        proyecto: pick_random(Proyecto)
    }
  end

  def build_objetivogeneral(proyecto)
    {
        descripcion: random_text,
        proyecto: proyecto
    }
  end

  def build_origensocio
    {
        origen: random_string(255, 0)
    }
  end

  def build_pais
    {
        nombre: random_string(255, 0),
        area_geografica: pick_random(AreaGeografica),
        codigo: random_string(255, 0)
    }
  end

  def build_partida
    {
        nombre: random_string(255, 0),
        codigo: random_string(255, 0),
        descripcion: random_string(255, 0),
        tipo: random_string(255, 0),
        ocultar_agente: random_boolean,
        ocultar_proyecto: random_boolean,
        tipo_empleado: random_boolean
    }
  end

  def build_partidaingreso
    {
        nombre: random_string(255, 0),
        descripcion: random_string(255, 0),
        presupuestable: random_boolean,
        proyecto: random_boolean
    }
  end

  def build_partidaxpartidafinanciacion(partida, partida_financiacion)
    {
        partida_financiacion: partida_financiacion,
        partida: partida
    }
  end

  def build_periodo(proyecto, fecha_inicio, fecha_fin)
    {
        tipo_periodo: pick_random(TipoPeriodo),
        proyecto: proyecto,
        fecha_inicio: fecha_inicio,
        fecha_fin: fecha_fin,
        descripcion: random_text,
        gastos_cerrados: random_boolean,
        fecha_informe: fecha_fin + 1.days,
        periodo_cerrado: false
    }
  end

  def build_periodocontrato
    contrato = pick_random(Contrato)

    fecha_inicio = contrato.fecha_inicio
    fecha_fin = contrato.fecha_fin

    {
        contrato: contrato,
        importe: random_decimal(3, 2),
        fecha_inicio: fecha_inicio,
        fecha_fin: fecha_fin,
        descripcion: random_string(255, 0)
    }
  end

  def build_permisoxrol
    {
        rol: pick_random(Rol),
        menu: random_string(255, 0),
        controlador: random_string(255, 0),
        ver: random_boolean,
        cambiar: random_boolean

    }
  end

  def build_presupuesto
    {
        importe: random_decimal(11, 2),
        concepto: random_string(255, 0),
        observaciones: random_string(255, 0),
        partida: pick_random(Partida),
        moneda: pick_random(Moneda),
        agente: pick_random(Agente),
        libro: pick_random(Libro),
        coste_unitario: random_decimal(11, 2),
        numero_unidades: random_decimal(4, 2),
        subpartida: pick_random(Subpartida),
        unidad: random_string(255, 0),
        proyecto: pick_random(Proyecto),
        etapa: pick_random(Etapa),
        marcado: pick_random(Marcado),
        tasa_cambio: pick_random(TasaCambio),
        pais: pick_random(Pais),
        empleado_id: random_integer(4, 0)
    }
  end

  def build_presupuestoingresodetallado
    fecha_inicio = random_datetime
    fecha_fin = random_datetime(fecha_inicio.to_f)

    {
        presupuesto_ingreso: pick_random(PresupuestoIngreso),
        importe: random_decimal(11, 2),
        fecha_inicio: fecha_inicio,
        fecha_fin: fecha_fin,
        nombre: random_string(255, 0),
        mes: random_integer(4, 0)
    }
  end

  def build_presupuestoxactividad
    presupuesto = pick_random(Presupuesto)
    actividad = presupuesto.etapa.actividad.first

    {
        presupuesto: presupuesto,
        actividad: actividad,
        importe: random_decimal(11, 2),
        numero_unidades: random_integer(4, 0)
    }
  end

  def build_presupuestoxagente
    {
        agente: pick_random(Agente),
        presupuesto: pick_random(Presupuesto),
        importe: random_decimal(11, 2)
    }
  end

  def build_presupuestoxproyecto
    {
        presupuesto: pick_random(Presupuesto),
        proyecto: pick_random(Proyecto),
        importe: random_decimal(11, 2)
    }
  end

  def build_provincia
    {
        nombre: random_string(255, 0),
        pais: pick_random(Pais)

    }
  end

  def build_proyectoxareaactuacion
    {
        proyecto: pick_random(Proyecto),
        area_actuacion: pick_random(AreaActuacion),
        porcentaje: 0.1
    }
  end

  def build_proyectoxdefiniciondato
    {
        proyecto: pick_random(Proyecto),
        definicion_dato: pick_random(DefinicionDato)
    }
  end

  def build_proyectoxfinanciador
    {
        agente: pick_random(Agente),
        proyecto: pick_random(Proyecto)
    }
  end

  def build_proyectoximplementador
    {
        agente: pick_random(Agente),
        proyecto: pick_random(Proyecto)
    }
  end

  def build_proyectoxmoneda
    {
        proyecto: pick_random(Proyecto),
        moneda: pick_random(Moneda)
    }
  end

  def build_proyectoxpais(proyecto, pais22)
    {
        proyecto: pick_random(Proyecto),
        pais: pick_random(Pais)
    }
  end

  def build_proyectoxproyecto
    {
        proyecto_cofinanciado: pick_random(Proyecto),
        proyecto_cofinanciador: pick_random(Proyecto),
        importe: random_decimal(11, 2),
        financiacion_privada: random_boolean,
        financiacion_publica: random_boolean
    }
  end

  def build_proyectoxsectorintervencion
    {
        proyecto: pick_random(Proyecto),
        sector_intervencion: pick_random(SectorIntervencion),
        porcentaje: 0.1
    }
  end

  def build_proyectoxsectorpoblacion
    {
        proyecto: pick_random(Proyecto),
        sector_poblacion: pick_random(SectorPoblacion),
        porcentaje: 0.1
    }
  end

  def build_resultado
    {
        codigo: random_string(255, 0),
        descripcion: random_text,
        proyecto: pick_random(Proyecto),
        objetivo_especifico: pick_random(ObjetivoEspecifico)
    }
  end

  def build_sectorintervencion
    {
        nombre: random_string(255, 0),
        descripcion: random_text,
        categoria_sector_intervencion: pick_random(CategoriaSectorIntervencion)
    }
  end

  def build_sectorpoblacion
    {
        nombre: random_string(255, 0),
        descripcion: random_text
    }
  end

  def build_subactividad
    {
        actividad: pick_random(Actividad),
        descripcion: random_text,
        responsables_ejecucion: random_text,
        descripcion_detallada: random_text,
        comentarios_ejecucion: random_text
    }
  end

  def build_subactividaddetallada
    {
        mes: random_integer(4, 0),
        etapa: pick_random(Etapa),
        subactividad: pick_random(Subactividad),
        seguimiento: random_boolean
    }
  end

  def build_subtipomovimiento
    {
        nombre: random_string(255, 0),
        descripcion: random_string(255, 0),
        tipo_asociado: random_string(255, 0)
    }
  end

  def build_tipocontratoxdocumento(tipo_contrato, documento)
    {
        tipo_contrato: tipo_contrato,
        documento: documento
    }
  end

  def build_tipocuotasocio
    {
        tipo_cuota: random_string(255, 0),
        meses: random_integer(4, 0)
    }
  end

  def build_tipoperiodo
    {
        nombre: random_string(255, 0),
        descripcion: random_text,
        oficial: random_boolean,
        no_borrable: random_boolean,
        grupo_tipo_periodo: random_string(255, 0)
    }
  end

  def build_tipopersonal
    {
        codigo: random_string(255, 0),
        nombre: random_string(255, 0)
    }
  end

  def build_tipotarea
    {
        nombre: random_string(255, 0),
        descripcion: random_text,
        tipo_proyecto: random_boolean,
        tipo_agente: random_boolean,
        administracion: random_boolean,
        configuracion: random_boolean,
        formulacion_economica: random_boolean,
        formulacion_tecnica: random_boolean,
        seguimiento_economico: random_boolean,
        seguimiento_tecnico: random_boolean,
        justificacion: random_boolean,
        dias_aviso_finalizacion: random_string(255, 0)
    }
  end

  def build_transferenciaxagente
    {
        transferencia: pick_random(Transferencia),
        agente: pick_random(Agente),
        importe: random_decimal(11, 2)
    }
  end

  def build_transferenciaxdocumento(transferencia, documento)
    {
        transferencia: transferencia,
        documento: documento

    }
  end

  def build_usuarioxagente
    {
        usuario: pick_random(Usuario),
        agente: pick_random(Agente),
        grupo_usuario: pick_random(GrupoUsuario),
        rol_asignado: pick_random(Rol)
    }
  end

  def build_usuarioxespacio
    {
        espacio: pick_random(Espacio),
        usuario: pick_random(Usuario),

        grupo_usuario_id: random_integer(4, 0)
    }
  end

  def build_usuarioxgrupousuario
    {
        usuario: pick_random(Usuario),
        grupo_usuario: pick_random(GrupoUsuario)
    }
  end

  def build_usuarioxlibro
    {
        libro: pick_random(Libro),
        usuario: pick_random(Usuario),
        grupo_usuario: pick_random(GrupoUsuario)
    }
  end

  def build_usuarioxproyecto
    {
        usuario: pick_random(Usuario),
        proyecto: pick_random(Proyecto),
        notificar_comentario: random_boolean,
        grupo_usuario: pick_random(GrupoUsuario),
        rol_asignado: pick_random(Rol),
        notificar_estado: random_boolean,
        notificar_usuario: random_boolean
    }
  end

  def build_valorintermedioxactividad
    actividad_x_etapa = pick_random(ActividadXEtapa)
    fecha_inicio = (actividad_x_etapa.etapa ? actividad_x_etapa.etapa.fecha_inicio + 1.day : random_datetime )
    {
        actividad_x_etapa: actividad_x_etapa,
        fecha: fecha_inicio,
        porcentaje: random_decimal(1, 2),
        realizada: random_boolean,
        comentario: random_text,
        usuario: pick_random(Usuario)
    }
  end

  def build_valorintermedioxindicador(indicador, fecha)
    {
        indicador: indicador,
        fecha: fecha,
        porcentaje: random_decimal(1, 2),
        comentario: random_string(255, 0),
        usuario: pick_random(Usuario)
    }
  end

  def build_valorintermedioxsubactividad
    {
        subactividad: pick_random(Subactividad),
        fecha: random_date,
        porcentaje: random_decimal(1, 2),
        estado: random_text,
        comentario: random_string(255, 0),
        usuario: pick_random(Usuario)
    }
  end

  def build_valorvariableindicador
    valor_indicador = pick_random(VariableIndicador)
    fecha = valor_indicador.indicador.proyecto.fecha_de_inicio + 1.day

    {
        valor: random_string(255, 0),
        fecha: fecha,
        comentario: random_text,
        variable_indicador: valor_indicador
    }
  end

  def build_valorxindicadorgeneral
    indicador_general_x_proyecto = pick_random(IndicadorGeneralXProyecto)
    proyecto = indicador_general_x_proyecto.proyecto

    fecha_inicio = if proyecto.fecha_de_inicio
                     proyecto.fecha_de_inicio.to_datetime
                   else
                     random_datetime
                   end
    fecha_fin = if proyecto.fecha_de_fin
                  proyecto.fecha_de_fin.to_datetime
                else
                  random_datetime(fecha_inicio.to_f)
                end
    {
        indicador_general_x_proyecto: indicador_general_x_proyecto,
        fecha: random_date(fecha_inicio.to_datetime.to_f, fecha_fin.to_datetime),
        valor: random_integer(4, 0),
        comentario: random_text
    }
  end

  def build_variableindicador
    {
        nombre: random_string(255, 0),
        herramienta_medicion: random_string(255, 0),
        fuente_informacion: random_string(255, 0),
        contexto: random_text,
        indicador: pick_random(Indicador),
        valor_base: pick_random(ValorVariableIndicador),
        valor_objetivo: pick_random(ValorVariableIndicador)
    }
  end

  def build_versioncontrato
    fecha_inicio = random_date
    fecha_fin = random_date(fecha_inicio.to_f)
    contrato = pick_random(Contrato)
    estado_contrato = contrato.estado_actual
    {
        contrato: contrato,
        estado_contrato: estado_contrato,
        importe: random_decimal(11, 2),
        moneda: pick_random(Moneda),
        observaciones: random_text,
        fecha_inicio: fecha_inicio,
        fecha_fin: fecha_fin
    }
  end

  def build_workflowcontratoxetiqueta(workflow_contrato, etiqueta, agente)
    {
        workflow_contrato: workflow_contrato,
        etiqueta: etiqueta,
        agente: agente
    }
  end

  def build_workflowcontratoxworkflowcontrato
    {
        workflow_contrato_padre_id: random_integer(4, 0),
        workflow_contrato_hijo_id: random_integer(4, 0)
    }
  end

  private

  def pick_random(model, optional = false)
    return nil if optional && (rand(2) > 0)
    ids = ActiveRecord::Base.connection.select_all("SELECT id FROM #{model.to_s.tableize}")
    model.find(ids[rand(ids.length)]['id'].to_i) unless ids.blank?
  end

  def association(model, column)
    result = nil
    associations = model.reflect_on_all_associations
    associations = associations.select { |a| a.macro == :belongs_to }
    association = associations.select { |a| a.foreign_key == column	}

    result = association.first.class_name unless association.empty?

    result
  end

  def max_value(length, precision = 0)
    max_val = ''
    1.upto(length + precision) do |i|
      max_val += '.' if i == length + 1 && precision > 0
      max_val += '9'
    end

    max_val = if precision > 0
                max_val.to_f
              else
                max_val.to_i
              end

    max_val
  end

  def max_value2(length, precision = 0)
    max_val = Array.new(length + precision, 9)

    max_val.insert(length, '.') if precision > 0

    max_val.join
  end

  def random_string(length, _precision = 0)
    [*('a'..'z'), *('A'..'Z'), *('0'..'9')].shuffle[0, length].join
  end

  def random_text(length = 65_535, _precision = 0)
    [*('a'..'z'), *('A'..'Z'), *('0'..'9')].shuffle[0, length].join
  end

  def random_integer(length, precision = 0)
    prng = Random.new
    max_val = max_value(length, precision)

    prng.rand(max_val)
  end

  # He probado las dos funciones y con numeros pequeños la primera es mas rapida
  # Pero con numeros grandes lo otra es mas rapida

  # 11,2
  #              user     system      total        real
  # max_value:  0.000000   0.000000   0.000000 (  0.000008)
  # max_value2:  0.000000   0.000000   0.000000 (  0.000014)

  # 1000,5
  #              user     system      total        real
  # max_value:  0.000000   0.000000   0.000000 (  0.000306)
  # max_value2:  0.000000   0.000000   0.000000 (  0.000178)
  # prng = Random.new

  # Benchmark.bm(7) do |x|
  # 	a1 = prng.rand(1000)
  # 	a2 = prng.rand(5)
  # 	x.report("max_value:") { max_value(a1,a2) }
  # 	x.report("max_value2:") { max_value2(a1,a2) }
  # end

  def random_decimal(length, precision = 0)
    prng = Random.new
    prng.rand(max_value(length, precision)).round(precision)
  end

  def random_boolean
    [true, false].sample
  end

  def random_date(from = 0.0, to = Time.now)
    Time.at(from + rand * (to.to_f - from.to_f)).strftime('%Y/%m/%d')
  end

  def random_datetime(from = 0.0, to = Time.now)
    Time.at(from + rand * (to.to_f - from.to_f))
  end

  def random_value(type, length, precision)
    case type
      when 'string' then random_string(length)
      when 'text' then random_text(65_535)
      when 'integer' then random_integer(11)
      when 'decimal' then random_decimal(length, precision)
      when 'boolean' then random_boolean
      when 'datetime' then random_datetime
      when 'date' then random_date
      else 'Unknown'
    end
  end
end

# the tasks, hook to class above - use like so;
# rake fakeout:clean
# rake fakeout:small[noprompt] - no confirm prompt asked, useful for heroku or non-interactive use
# rake fakeout:medium RAILS_ENV=bananas
# .. etc.
namespace :fakeout do
  desc 'fake out a tiny dataset'
  task tiny: :environment do |_t, _args|
    Fakeout.new(:tiny).fakeout
  end

  desc 'fake out a small dataset'
  task small: :environment do |_t, _args|
    Fakeout.new(:small).fakeout
  end

  desc 'fake out a medium dataset'
  task medium: :environment do |_t, _args|
    Fakeout.new(:medium).fakeout
  end

  desc 'fake out a large dataset'
  task large: :environment do |_t, _args|
    Fakeout.new(:large).fakeout
  end
end
