# encoding: UTF-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)


# Monedas
if Moneda.count == 0
  Moneda.create :nombre => "Euro", :abreviatura => "EUR"
  Moneda.create :nombre => "US Dolar", :abreviatura => "USD"
  Moneda.create :nombre => "Real", :abreviatura => "BRL"
end

# Espacios para Gestión Documental
if Espacio.count == 0
  # Forzamos textos para traducir
  a = _("Proyectos")
  b = _("Agentes")
  # Espacios para Proyectos
  Espacio.create :nombre => "Proyectos", :descripcion => _("Espacio raiz de los espacios de proyecto. Este espacio no se puede modificar ni eliminar."), :modificable => false
  Espacio.create :nombre => "Plantillas Exportación", :descripcion => _("Espacio de plantillas"), :modificable => false
  Espacio.create :nombre => "Financiadores", :modificable => false, :descripcion => _("Espacio de financiadores.")
  Espacio.create :nombre => "Paises", :modificable => false, :descripcion => _("Espacio de los paises.")
  #Espacio.create :nombre => "Gastos", :definicion_espacio_proyecto => true, :gasto => true
  #Espacio.create :nombre => "Fuentes de verificación", :definicion_espacio_proyecto => true, :fuente_verificacion => true
  #Espacio.create :nombre => "Transferencias", :definicion_espacio_proyecto => true, :transferencia => true
  # Espacios para agentes
  #Espacio.create :nombre => "Agentes", :descripcion => _("Espacio base de los espacios de agente")
  #Espacio.create :nombre => "Transferencias", :definicion_espacio_agente => true, :transferencia => true
  #
end

# Pais y Area Geografica
if Pais.count == 0
  AreaGeografica.create :nombre => _("Europa")
  AreaGeografica.create :nombre => _("Sudamérica")
  Pais.create :nombre => _("España"), :area_geografica_id => AreaGeografica.find_by_nombre(_("Europa")).id, :codigo => "ESP"
  Pais.create :nombre => _("Brasil"), :area_geografica_id => AreaGeografica.find_by_nombre(_("Sudamérica")).id, :codigo => "BRA"
  MonedaXPais.create :pais_id => Pais.find_by_nombre(_("España")).id, :moneda_id => Moneda.find_by_nombre("Euro").id
  MonedaXPais.create :pais_id => Pais.find_by_nombre(_("Brasil")).id, :moneda_id => Moneda.find_by_nombre("Real").id
end

# Provincia.create([{ :nombre => 'Europa', :pais_id => '1' }]) if Provincia.count == 0
# Comunidad.create([{ :nombre => 'Madrid', :provincia_id => '1' }]) if Comunidad.count == 0
# Municipio.create([{ :nombre => 'Madrid', :comunidad_id => '1' }]) if Municipio.count == 0

# Categorias de Areas de Actuacion
if CategoriaAreaActuacion.count == 0
  CategoriaAreaActuacion.create nombre: _("Educación"), descripcion: _("Educación")
  CategoriaAreaActuacion.create nombre: _("Medio Ambiente"), descripcion: _("Medio Ambiente")
  CategoriaAreaActuacion.create nombre: _("Enfoque de Género"), descripcion: _("Enfoque de Género, inclusión y derechos humanos")
end

# Areas de Actuacion
if AreaActuacion.count == 0
  caa = CategoriaAreaActuacion.find_by_nombre _("Educación")
  AreaActuacion.create nombre: _("Educación para el Desarrollo Humano y Sostenible"),
                       descripcion: _("Educación para el Desarrollo Humano y Sostenible"),
                       categoria_area_actuacion_id: (caa ? caa.id : nil)
  AreaActuacion.create nombre: _("Mejora de la calidad educativa"),
                       descripcion: _("Mejora de la calidad educativa"),
                       categoria_area_actuacion_id: (caa ? caa.id : nil) 
  caa = CategoriaAreaActuacion.find_by_nombre _("Enfoque de Género")
  AreaActuacion.create nombre: _("Promoción de la mujer"),
                       descripcion: _("Promoción de la mujer"),
                       categoria_area_actuacion_id: (caa ? caa.id : nil)
  caa = CategoriaAreaActuacion.find_by_nombre _("Medio Ambiente")
  AreaActuacion.create nombre: _("Gestión del Hábitat"),
                       descripcion: _("Gestión del Hábitat"),
                       categoria_area_actuacion_id: (caa ? caa.id : nil)
  AreaActuacion.create nombre: _("Recuperación de Ecosistemas"),
                       descripcion: _("Recuperación de Ecosistemas"),
                       categoria_area_actuacion_id: (caa ? caa.id : nil)
end

# Categorias de Sectores de Intervencion (Corresponderian a los codigos CAD)
if CategoriaSectorIntervencion.count == 0
  CategoriaSectorIntervencion.create nombre: _("151 Gobierno y sociedad civil, general"),
      descripcion: _("Gobierno y sociedad civil, general")
  CategoriaSectorIntervencion.create nombre: _("160 Otros servicios e infraestructuras sociales"),
      descripcion: _("Legislación y administración sociales; fortalecimiento de instituciones y asesoramiento; seguridad socual y otros planes sociales; ...")
  CategoriaSectorIntervencion.create nombre: _("410 Protección general del medio ambiente"),
      descripcion:  _("Protección general del medio ambiente. Sin especificar sector.")
end
# Sectores de Intervencion (Corresponderian a los codigos CRS)
if SectorIntervencion.count == 0
  si = CategoriaSectorIntervencion.find_by_nombre _("151 Gobierno y sociedad civil, general")
  SectorIntervencion.create nombre: _("15112 Descentralización y apoyo a los gobiernos regionales y locales"),
                            categoria_sector_intervencion_id: si.id,
                            descripcion: _("Descentralización y apoyo a los gobiernos regionales y locales")
  SectorIntervencion.create nombre: _("15162 Derechos humanos"),
                            categoria_sector_intervencion_id: si.id,
                            descripcion: _("Derechos humanos")
  si = CategoriaSectorIntervencion.find_by_nombre _("160 Otros servicios e infraestructuras sociales")
  SectorIntervencion.create nombre: _("16050 Ayuda multisectorial para servicios sociales básicos"),
                            categoria_sector_intervencion_id: si.id,
                            descripcion: _("Ayuda multisectorial para servicios sociales básicos") if si
  si = CategoriaSectorIntervencion.find_by_nombre _("410 Protección general del medio ambiente")
  SectorIntervencion.create nombre: _("41020 Protección de la biosfera"),
                            categoria_sector_intervencion_id: si.id,
                            descripcion: _("Protección de la biosfera") if si
end

# Sectores Beneficiarios
if SectorPoblacion.count == 0
  SectorPoblacion.create :nombre => _("Infancia"), :descripcion => _("Infancia")
  SectorPoblacion.create :nombre => _("Juventud"), :descripcion => _("Juventud")
  SectorPoblacion.create :nombre => _("Comunidades campesinas"), :descripcion => _("Comunidades campesinas")
end


# Etiquetas (no hacemos comprobaciones porque el modelo impedira crear mas de una con el mismo nombre)
Etiqueta.create :nombre => "Exportacion Presupuesto", :descripcion => _("Exportación de Presupuesto"), :tipo => _("plantilla")
Etiqueta.create :nombre => "Exportacion Gasto", :descripcion => _("Exportación de Gastos"), :tipo => _("plantilla")
Etiqueta.create :nombre => "Exportacion Transferencia", :descripcion => _("Exportación de Transferencias"), :tipo => _("plantilla")

# Sube el documento ejemplo de contrato 
etiqueta_contrato = Etiqueta.find_or_create_by_nombre_and_tipo :nombre => "Contrato", :tipo => _("plantilla")
etiqueta_contrato.update_attribute(:descripcion, _("Plantillas de generación de contrato")) if etiqueta_contrato && etiqueta_contrato.descripcion.nil?
if etiqueta_contrato && etiqueta_contrato.id && EtiquetaXDocumento.find_by_etiqueta_id(etiqueta_contrato.id).nil?
  f = Rails.root.join('public', 'system', 'contrato.docx')
  if File.exists? f
    plantilla = Documento.new :descripcion => "Plantilla de Contrato"
    file = File.open(f)
    plantilla.adjunto = file
    file.close
    plantilla.save
    if plantilla.errors.empty? && (esp = Espacio.find_by_nombre_and_modificable("Plantillas Exportación", false))
      DocumentoXEspacio.create :espacio_id => esp.id, :documento_id => plantilla.id
      EtiquetaXDocumento.create :etiqueta_id => etiqueta_contrato.id, :documento_id => plantilla.id
    end
  end
end
# Sube el documento ejemplo de pago de contrato 
etiqueta_pago = Etiqueta.find_or_create_by_nombre_and_tipo :nombre => "Pago de Contrato", :tipo => _("plantilla")
etiqueta_pago.update_attribute(:descripcion, _("Plantillas de generación de notas de pago para hitos de contrato")) if etiqueta_pago && etiqueta_pago.descripcion.nil?
if etiqueta_pago && etiqueta_pago.id && EtiquetaXDocumento.find_by_etiqueta_id(etiqueta_pago.id).nil?
  f = Rails.root.join('public', 'system', 'nota_de_pago_contrato.docx')
  if File.exists? f
    plantilla = Documento.new :descripcion => "Nota de Pago para Contratos"
    file = File.open(f)
    plantilla.adjunto = file
    file.close
    plantilla.save
    if plantilla.errors.empty? && (esp = Espacio.find_by_nombre_and_modificable("Plantillas Exportación", false))
      DocumentoXEspacio.create :espacio_id => esp.id, :documento_id => plantilla.id
      EtiquetaXDocumento.create :etiqueta_id => etiqueta_pago.id, :documento_id => plantilla.id
    end
  end
end
# Sube el documento ejemplo de nota de gasto
etiqueta_nota = Etiqueta.find_or_create_by_nombre_and_tipo :nombre => "Nota de Gasto", :tipo => _("plantilla")
etiqueta_nota.update_attribute(:descripcion, _("Plantillas de generación de notas de gasto para proyectos")) if etiqueta_nota && etiqueta_nota.descripcion.nil?
if etiqueta_nota && etiqueta_nota.id && EtiquetaXDocumento.find_by_etiqueta_id(etiqueta_nota.id).nil?
  f = Rails.root.join('public', 'system', 'nota_de_gasto.docx')
  if File.exists? f
    plantilla = Documento.new :descripcion => "Nota de Gasto para Proyectos"
    file = File.open(f)
    plantilla.adjunto = file
    file.close
    plantilla.save
    if plantilla.errors.empty? && (esp = Espacio.find_by_nombre_and_modificable("Plantillas Exportación", false))
      DocumentoXEspacio.create :espacio_id => esp.id, :documento_id => plantilla.id
      EtiquetaXDocumento.create :etiqueta_id => etiqueta_nota.id, :documento_id => plantilla.id
    end
  end
end
# Sube el documento ejemplo de Ficha Resumen
etiqueta_nota = Etiqueta.find_or_create_by_nombre_and_tipo :nombre => "Ficha Resumen", :tipo => _("plantilla")
etiqueta_nota.update_attribute(:descripcion, _("Ficha Resumen de Proyecto")) if etiqueta_nota && etiqueta_nota.descripcion.nil?
if etiqueta_nota && etiqueta_nota.id && EtiquetaXDocumento.find_by_etiqueta_id(etiqueta_nota.id).nil?
  f = Rails.root.join('public', 'system', 'ficha_resumen.docx')
  if File.exists? f
    plantilla = Documento.new :descripcion => "Ficha Resumen de Proyecto"
    file = File.open(f)
    plantilla.adjunto = file
    file.close
    plantilla.save
    if plantilla.errors.empty? && (esp = Espacio.find_by_nombre_and_modificable("Plantillas Exportación", false))
      DocumentoXEspacio.create :espacio_id => esp.id, :documento_id => plantilla.id
      EtiquetaXDocumento.create :etiqueta_id => etiqueta_nota.id, :documento_id => plantilla.id
    end
  end
end

# Marcado
if Marcado.count == 0
  Marcado.create :nombre => _('Revisar'), :descripcion => _("Elemento a revisar"), :color => 'amarillo', primer_estado: true, :marcado_padre_id => 3, :automatico => true
  Marcado.create :nombre => _('Validado'), :descripcion => _("Elemento Comprobado"), :color => 'verde', primer_estado: false, :marcado_padre_id => 1, :automatico => false 
  Marcado.create :nombre => _('Corregir'), :descripcion => _("Elemento a corregir"), :color => 'rosa', primer_estado: false, :marcado_padre_id => 1, :automatico => false
  Marcado.create :nombre => _('Error'), :descripcion => _("Elemento con errores"), :color => 'rojo', primer_estado: false, :automatico => false, :error => true
end

# Introducimos un marcado especifico para la revisión del presupuesto y gasto de empleado
unless Marcado.find_by_nombre("Error dato empleado")
  Marcado.create :nombre => _('Error dato empleado'), :descripcion => _("Error en el gasto o el presupuesto de empleado"), :color => 'azul', primer_estado: false, :automatico => false, :error => false
end


# Etiquetas Tecnicas
if EtiquetaTecnica.count == 0
  EtiquetaTecnica.create :nombre => _('Construcción'), :descripcion => _('Actividades de Construcción')
  EtiquetaTecnica.create :nombre => _('Formación'), :descripcion => _('Actividades de Formación')
  EtiquetaTecnica.create :nombre => _('Sensibilización'), :descripcion => _('Actividades de Sensibilización')
  EtiquetaTecnica.create :nombre => _('Seguimiento'), :descripcion => _('Actividades de Coordinación, Gestión y Seguimiento')
  EtiquetaTecnica.create :nombre => _('Otras'), :descripcion => _('Otras Actividades')
end

# Socios
if TipoCuotaSocio.count == 0
  TipoCuotaSocio.create :tipo_cuota => _('Mensual'), :meses => 1
  TipoCuotaSocio.create :tipo_cuota => _('Bimensual'), :meses => 2
  TipoCuotaSocio.create :tipo_cuota => _('Trimestral'), :meses => 3
  TipoCuotaSocio.create :tipo_cuota => _('Semestral'), :meses => 6
  TipoCuotaSocio.create :tipo_cuota => _('Anual'), :meses => 12
end

OrigenSocio.create([{ :origen => 'Otro' }]) if OrigenSocio.count == 0

if FormaPagoSocio.count == 0
  FormaPagoSocio.create :forma_pago => _('Efectivo')
  FormaPagoSocio.create :forma_pago => _('Cheque')
  FormaPagoSocio.create :forma_pago => _('Transferencia Bancaria')
  FormaPagoSocio.create :forma_pago => _('Domiciliación Bancaria')
  FormaPagoSocio.create :forma_pago => _('Tarjeta')
  FormaPagoSocio.create :forma_pago => _('Otro')
end 

NaturalezaSocio.create([{ :naturaleza => _('Otro') }]) if NaturalezaSocio.count == 0

# Usuario Administrador
if Usuario.count == 0
  Usuario.create([{ :nombre => 'admin', :nombre_completo => 'Admin', :contrasena => Digest::SHA1.hexdigest('admin'), :correoe => 'gong@ejemplo.org', :administracion => true, :proyectos=> true, :agentes => true, :cuadromando => true, :socios => true, :documentos => true}])
end

# Crea el grupo de administradores
if GrupoUsuario.count == 0
  gu=GrupoUsuario.create(:nombre => 'Admins')
  Usuario.all(:conditions => {:administracion => true}).each do |u|
    UsuarioXGrupoUsuario.create(:usuario_id => u.id, :grupo_usuario_id => gu.id)
  end if gu
end

# Estados de los Proyectos (WorkFlow)
if DefinicionEstado.count == 0
  contacto = DefinicionEstado.create nombre: _("Contacto"), orden: 0, primer_estado: true
  identificacion = DefinicionEstado.create nombre: _("Identificación"), orden: 1, primer_estado: false, formulacion: true
  formulacion = DefinicionEstado.create nombre: _("Formulación"), orden: 2, primer_estado: false, formulacion: true
  rechazado = DefinicionEstado.create nombre: _("Rechazado"), orden: 3, primer_estado: false, cerrado: true
  ejecucion = DefinicionEstado.create nombre: _("Ejecución"), orden: 4, primer_estado: false, aprobado: true, ejecucion: true
  reformulacion = DefinicionEstado.create nombre: _("Reformulación"), orden: 4, primer_estado: false, formulacion: true, aprobado: true, ejecucion: true
  cierre = DefinicionEstado.create nombre: _("Cerrado"), orden: 5, primer_estado: false, aprobado: true, cerrado: true

  # Ojo con este orden... es importante para que no se embucle el script de formacion
  DefinicionEstadoXDefinicionEstado.create(:definicion_estado_padre_id => contacto.id, :definicion_estado_hijo_id => identificacion.id) if contacto && identificacion
  DefinicionEstadoXDefinicionEstado.create(:definicion_estado_padre_id => identificacion.id, :definicion_estado_hijo_id => formulacion.id) if formulacion && identificacion
  DefinicionEstadoXDefinicionEstado.create(:definicion_estado_padre_id => rechazado.id, :definicion_estado_hijo_id => formulacion.id) if formulacion && rechazado
  DefinicionEstadoXDefinicionEstado.create(:definicion_estado_padre_id => formulacion.id, :definicion_estado_hijo_id => ejecucion.id) if formulacion && ejecucion
  DefinicionEstadoXDefinicionEstado.create(:definicion_estado_padre_id => formulacion.id, :definicion_estado_hijo_id => rechazado.id) if formulacion && rechazado
  DefinicionEstadoXDefinicionEstado.create(:definicion_estado_padre_id => ejecucion.id, :definicion_estado_hijo_id => reformulacion.id) if ejecucion && reformulacion
  DefinicionEstadoXDefinicionEstado.create(:definicion_estado_padre_id => reformulacion.id, :definicion_estado_hijo_id => ejecucion.id) if ejecucion && reformulacion
  DefinicionEstadoXDefinicionEstado.create(:definicion_estado_padre_id => ejecucion.id, :definicion_estado_hijo_id => cierre.id) if ejecucion && cierre
end

# Tipos de Tarea
if TipoTarea.count == 0
  TipoTarea.create(:nombre =>  _("Datos proyecto"), :tipo_proyecto => true)
  TipoTarea.create(:nombre =>  _("Documentación"), :tipo_proyecto => true)
  TipoTarea.create(:nombre =>  _("Formulación Técnica"), :tipo_proyecto => true)
  TipoTarea.create(:nombre =>  _("Presupuesto"), :tipo_proyecto => true)
  TipoTarea.create(:nombre =>  _("Seguimiento Técnico"), :tipo_proyecto => true)
  TipoTarea.create(:nombre =>  _("Seguimiento Económico"), :tipo_proyecto => true, :tipo_agente => true)
end

# Estados de las Tareas
if EstadoTarea.count == 0
  EstadoTarea.create( :nombre => _("En curso"), :descripcion => _("Tarea en la cual se trabaja actualmente"), :activo => true)
  EstadoTarea.create( :nombre => _("En espera"), :descripcion => _("Tarea que todavía no ha comenzado"), :activo => true)
  EstadoTarea.create( :nombre => _("Resuelta (pendiente de confirmación)"), :descripcion => _("Tarea que ya está finalizada"), :activo => true)
  EstadoTarea.create( :nombre => _("Resuelta (confirmada y cerrada)"), :descripcion => _("Tarea que ya está resuelta y confirmada"), :seleccionable => false, :activo => false)
end

# Grupos de Datos Basicos
if GrupoDatoDinamico.count == 0
  gdf1=GrupoDatoDinamico.create( :nombre => _("Identificación"), :rango => 1 )
  gdf2=GrupoDatoDinamico.create( :nombre => _("Contexto"), :rango => 0 )
  gdf3=GrupoDatoDinamico.create( :nombre => _("Objetivos"), :rango => 2 )
end
if GrupoDatoDinamico.where(:seguimiento => true).empty?
  gds1=GrupoDatoDinamico.create( :nombre => _("Primer Informe Seguimiento"), :rango => 0, :seguimiento => true )
  gds2=GrupoDatoDinamico.create( :nombre => _("Segundo Informe Seguimiento"), :rango => 1, :seguimiento => true )
  gds3=GrupoDatoDinamico.create( :nombre => _("Último Informe Seguimiento"), :rango => 2, :seguimiento => true )
end

# Datos Basicos de Formulacion
if gdf1 && gdf1.definicion_dato.empty?
  i = 0
  [   ["Codigo de la Organización", "codigo_de_la_organizacion"],
      ["Codigo del Financiador", "codigo_del_financiador"],
      ["Breve Descripción", "breve_descripcion"],
      ["Descripción Extensa", "descripcion_extensa"],
      ["Análisis razonado de la acción", "analisis_razonado_de_la_accion"],
      ["Contenidos e ideas que difunde el proyecto", "contenidos_e_ideas_que_difunde_el_proyecto"],
      ["Adecuación a los principios horizontales", "adecuacion_a_los_principios_horizontales"],
      ["Descripción de la metodología", "descripcion_de_la_metodologia"],
      ["Plan de Difusión", "plan_de_difusion"],
      ["Materiales y soportes", "materiales_y_soportes"]].each do |d|
        DefinicionDato.create( :nombre => d[1], :rotulo => d[0], :tipo => "Texto", :grupo_dato_dinamico_id => gdf1.id, :rango => i )
        i += 1
    end
end
if gdf2 && gdf2.definicion_dato.empty?
  i=0
  [   ["Descripción Población beneficiaria", "descripcion_poblacion_beneficiaria"],
      ["Ubicación detallada de la zona de Proyecto", "ubicacion_detallada_de_la_zona_de_proyecto"],
      ["Principales problemas comunes detectados", "principales_problemas_comunes_detectados"],
      ["Principales problemas específicos detectados", "principales_problemas_especificos_detectados"],
      ["Experiencia de la ONG y contrapartes en la zona/s y en el sector/es", "experiencia_de_la_ong_y_contrapartes"],
      ["Normativa Relativa a ONGD de obligado cumplimiento en el País de implementación", "normativa_relativa_a_ongd_de_obligado_cumplimiento"],
      ["Grado de Participación de Beneficiarios Directos en la formulación", "grado_de_participacion_de_beneficiarios_directos"],
      ["Complementariedad y sinergia con la política española de cooperación", "complementariedad_y_sinergia"],
      ["Organismos Públicos o privados implicados", "organismos_publicos_o_privados_implicados"],
      ["Socios Locales", "socios_locales"],
      ["Población beneficiaria", "poblacion_beneficiaria"],
      ["Acuerdos y compromisos firmados", "acuerdos_y_compromisos_firmados"]].each do |d|
        DefinicionDato.create( :nombre => d[1], :rotulo => d[0], :tipo => "Texto", :grupo_dato_dinamico_id => gdf2.id, :rango => i )
        i += 1
  end
end
if gdf3 && gdf3.definicion_dato.empty?
  i=0
  [   ["Objetivos que se abordan", "objetivos_que_se_abordan"],
      ["Justificación de la Estrategia de Intervención", "justificacion_de_la_estrategia_de_intervencion"],
      ["Objetivo de desarrollo. Resumen Descriptivo", "objetivo_de_desarrollo_resumen_descriptivo"],
      ["Objetivo de desarrollo. Factores de riesgo e hipótesis Personal", "objetivo_de_desarrollo_factores_de_riesgo_e_hipotesis_personal"],
      ["Factores de Desarrollo. Políticas de Apoyo", "factores_de_desarrollo_politicas_de_apoyo"],
      ["Factores de Desarrollo. Aspectos institucionales", "factores_de_desarrollo_aspectos_institucionales"],
      ["Factores de Desarrollo. Aspectos Socioculturales", "factores_de_desarrollo_aspectos_socioculturales"],
      ["Factores de Desarrollo. Enfoque de Género", "factores_de_desarrollo_enfoque_de_genero"],
      ["Factores de Desarrollo. Factores Medioambientales", "factores_de_desarrollo_factores_medioambientales"],
      ["Factores de Desarrollo. Factores Económico Financieros", "factores_de_desarrollo_factores_economico_financieros"],
      ["Sostenibilidad de la Intervención y Procedimiento de Transferencia previstos", "sostenibilidad_de_la_intervencion"]].each do |d|
        DefinicionDato.create( :nombre => d[1], :rotulo => d[0], :tipo => "Texto", :grupo_dato_dinamico_id => gdf3.id, :rango => i )
        i += 1
  end
end
# Datos Basicos de Seguimiento
if gds1 && gds1.definicion_dato.empty?
  i=0
  [   ["Justificación de Objetivos Específicos", "justificacion_objetivos_1"],
      ["Justificación de Resultados", "justificacion_resultados_1"],
      ["Justificación de Actividades", "justificacion_actividades_1"],
      ["Sobre la Coordinación del Proyecto", "coordinacion_1"],
      ["Otras Valoraciones", "otras_valoraciones_1"]].each do |d|
        DefinicionDato.create( :nombre => d[1], :rotulo => d[0], :tipo => "Texto", :grupo_dato_dinamico_id => gds1.id, :rango => i )
        i += 1
  end
end
if gds2 && gds2.definicion_dato.empty?
  i=0
  [   ["Justificación de Objetivos Específicos", "justificacion_objetivos_2"],
      ["Justificación de Resultados", "justificacion_resultados_2"],
      ["Justificación de Actividades", "justificacion_actividades_2"],
      ["Sobre la Coordinación del Proyecto", "coordinacion_2"],
      ["Otras Valoraciones", "otras_valoraciones_2"]].each do |d|
        DefinicionDato.create( :nombre => d[1], :rotulo => d[0], :tipo => "Texto", :grupo_dato_dinamico_id => gds2.id, :rango => i )
        i += 1
  end
end
if gds3 && gds3.definicion_dato.empty?
  i=0
  [   ["Justificación de Objetivos Específicos", "justificacion_objetivos"],
      ["Justificación de Resultados", "justificacion_resultados"],
      ["Justificación de Actividades", "justificacion_actividades"],
      ["Sobre las Comunidades y los Beneficiarios", "comunidades_y_beneficiarios"],
      ["Sobre la Coordinación del Proyecto", "coordinacion"],
      ["Impacto de Género", "impacto_genero"],
      ["Impacto Medioambiental", "impacto_medioambiental"],
      ["Sostenibilidad Económico Financiera", "sostenibilidad_economica"],
      ["Cierre del Proyecto", "cierre_proyecto"],                     
      ["Otras Valoraciones", "otras_valoraciones"]].each do |d|
        DefinicionDato.create( :nombre => d[1], :rotulo => d[0], :tipo => "Texto", :grupo_dato_dinamico_id => gds3.id, :rango => i )
        i += 1
  end
end

# Define los roles de usuario por defecto
Rake::Task["permisos:asigna"].invoke

if TipoAgente.count == 0
  TipoAgente.create nombre: _("Fundación Privada")
  TipoAgente.create nombre: _("Agencia Nacional de Cooperación Internacional")
  TipoAgente.create nombre: _("Ayuntamiento")
end

# Agente
if Agente.count == 0
  pais = Pais.find_by_nombre(_("España"))
  Agente.create :nombre => "AECID", :financiador => true, :pais_id => pais.id
  agente = Agente.create :nombre => "ONG-INT", :financiador => true, :implementador => true, :pais_id => pais.id, :moneda_id => Moneda.find_by_nombre("Euro").id
  rol = Rol.find_by_nombre_and_seccion "Coordinador", "agentes"
  if (admin=Usuario.find_by_nombre("admin")) && agente && rol
    UsuarioXAgente.create :usuario_id => admin.id, :agente_id => agente.id, :rol_id => rol.id
  end
end

if TipoConvocatoria.count == 0
  TipoConvocatoria.create :nombre => _("Cooperación")
  TipoConvocatoria.create :nombre => _("Ayuda Humanitaria")
end

if Convocatoria.count == 0
  tipo_convocatoria = TipoConvocatoria.first
  agt = Agente.find_by_nombre_and_financiador("AECID", true)
  agt ||= Agente.find_by_financiador_and_sistema(true, false)
  if agt
    nombre = agt.nombre + "-2014"
    Convocatoria.create(:codigo => nombre, :nombre => nombre, :agente_id => agt.id, :tipo_convocatoria_id => tipo_convocatoria ? tipo_convocatoria.id : nil)
    nombre = agt.nombre + "-" + _("General")
    Convocatoria.create(:codigo => nombre, :nombre => nombre, :agente_id => agt.id, :tipo_convocatoria_id => tipo_convocatoria ? tipo_convocatoria.id : nil)
  end
end

# Tipos de Contrato
if TipoContrato.count == 0
  TipoContrato.create nombre: "Obra mayor", descripcion: "Contrato de obra mayor", duracion: 36
  TipoContrato.create nombre: "Suministro", descripcion: "Contrato de suministro de bienes", duracion: 12
end

# Workflow de contratos
if WorkflowContrato.count == 0
  e1 = WorkflowContrato.create nombre: "Creación de TdR", descripcion: "Elaboración de Términos de Referencia", primer_estado: true, formulacion: true, orden: 1
  e2 = WorkflowContrato.create nombre: "Publicación del TdR", descripcion: "Publicación de TdR y elección de ofertas", formulacion: false, orden: 2
  e3 = WorkflowContrato.create nombre: "Aprobación de TdR", descripcion: "Aprobación de la oferta de proveedor y firma del contrato", orden: 3
  e4 = WorkflowContrato.create nombre: "Redefinición de TdR", descripcion: "Rechazo y redefinición de los Términos de Referencia", formulacion: true, aprobado: true, orden: 4
  e5 = WorkflowContrato.create nombre: "Cancelación de TdR", descripcion: "Cancelación de los Términos de Referencia", cerrado: true, orden: 5
  e6 = WorkflowContrato.create nombre: "Ejecución del Contrato", descripcion: "Puesta en marcha de la ejecución del contrato", aprobado: true, ejecucion: true, orden: 6
  e7 = WorkflowContrato.create nombre: "Finalización del Contrato", descripcion: "Cierre del contrato por finalización", aprobado: true, cerrado: true, orden: 7
  e8 = WorkflowContrato.create nombre: "Cancelación del Contrato", descripcion: "Cancelación del contrato por incumplimiento", aprobado: true, cerrado: true, orden: 8
  # Paso de "Creacion de TdR" a "Publicacion de TdR"
  WorkflowContratoXWorkflowContrato.create workflow_contrato_padre_id: e1.id, workflow_contrato_hijo_id: e2.id
  # Paso de "Publicación de TdR" a "Aprobación"
  WorkflowContratoXWorkflowContrato.create workflow_contrato_padre_id: e2.id, workflow_contrato_hijo_id: e3.id
  # PAso de "Publicación de TdR" a "Redefinición"
  WorkflowContratoXWorkflowContrato.create workflow_contrato_padre_id: e2.id, workflow_contrato_hijo_id: e4.id
  # Paso de "Redefinicion" a "Publicacion de TdR"
  WorkflowContratoXWorkflowContrato.create workflow_contrato_padre_id: e4.id, workflow_contrato_hijo_id: e2.id
  # Paso de "Creacion de TdR" a "Cancelacion de TdR"
  WorkflowContratoXWorkflowContrato.create workflow_contrato_padre_id: e1.id, workflow_contrato_hijo_id: e5.id
  # PAso de "Publicación de TdR" a "Cancelación de TdR"
  WorkflowContratoXWorkflowContrato.create workflow_contrato_padre_id: e2.id, workflow_contrato_hijo_id: e5.id
  # Paso de "Redefinicion" a "Cancelacion de TdR"
  WorkflowContratoXWorkflowContrato.create workflow_contrato_padre_id: e4.id, workflow_contrato_hijo_id: e5.id
  # Paso de "Aprobacion de TdR" a "Ejecucion de Contrato"
  WorkflowContratoXWorkflowContrato.create workflow_contrato_padre_id: e3.id, workflow_contrato_hijo_id: e6.id
  # Paso de "Ejecucion de Contrato" a "Finalizacion de Contrato"
  WorkflowContratoXWorkflowContrato.create workflow_contrato_padre_id: e6.id, workflow_contrato_hijo_id: e7.id
  # Paso de "Ejecucion de Contrato" a "Cancelacion de Contrato"
  WorkflowContratoXWorkflowContrato.create workflow_contrato_padre_id: e6.id, workflow_contrato_hijo_id: e8.id
end

# Comprueba/crea los financiadores de sistema
# Financiador publico local
unless Agente.find_by_financiador_and_sistema_and_publico_and_local(true,true,true,true) 
  nombre = _("OTRAS FINANCIACIONES PÚBLICAS LOCALES")
  Agente.create(:financiador => true, :sistema => true, :nombre => nombre, :nombre_completo => nombre, :publico => true, :local => true)
end
# Financiador privado local
unless Agente.find_by_financiador_and_sistema_and_publico_and_local(true,true,false,true) 
  nombre = _("OTRAS FINANCIACIONES PRIVADAS LOCALES") 
  Agente.create(:financiador => true, :sistema => true, :nombre => nombre, :nombre_completo => nombre, :publico => false, :local => true)
end
# Financiador publico exterior 
unless Agente.find_by_financiador_and_sistema_and_publico_and_local(true,true,true,false) 
  nombre = _("OTRAS FINANCIACIONES PÚBLICAS EXTERIORES") 
  Agente.create(:financiador => true, :sistema => true, :nombre => nombre, :nombre_completo => nombre, :publico => true, :local => false)
end
# Financiador privado exterior
unless Agente.find_by_financiador_and_sistema_and_publico_and_local(true,true,false,false) 
  nombre = _("OTRAS FINANCIACIONES PRIVADAS EXTERIORES") 
  Agente.create(:financiador => true, :sistema => true, :nombre => nombre, :nombre_completo => nombre, :publico => true, :local => false)
end

# Cuenta
if Libro.count == 0
  libro = Libro.create :nombre => "2014-GONG-AECID", :moneda_id => 1, :agente_id => Agente.find_by_nombre("ONG-INT").id, :cuenta => "1111 0351 34 0000123457", :tipo => "banco", :pais_id => 1
  UsuarioXLibro.create( :usuario_id => 1, :libro_id => libro.id) if libro 
end

# Proyectos de Ejemplo
if Proyecto.count == 0
  agt = Agente.find_by_nombre("AECID")
  implementador = Agente.find_by_nombre("ONG-INT")
  libro = implementador ? implementador.libro.first : nil
  if agt && libro
    proyecto = Proyecto.create :nombre => "2014-GONG", :titulo => _("Proyecto para la implantación en nuestra ONG de GONG"), :moneda_id => Moneda.find_by_nombre("Euro").id, :pais_principal_id => Pais.find_by_nombre(_("España")).id, :convocatoria_id => Convocatoria.where(:agente_id => agt.id).first.id, :libro_id => libro.id, :gestor_id => implementador.id
    puts "-------> Error creando proyecto: " + proyecto.errors.inspect unless proyecto.errors.empty?
  else
    proyecto = nil
    puts "-------> No se creo el proyecto. No existe el agente AECID" unless agt
    puts "-------> No se creo el proyecto. No existe el libro" unless libro
  end

  # Si existe el administrador le asigna todo a el
  if (admin=Usuario.find_by_nombre("admin")) && proyecto
    #Estado.create :proyecto_id => proyecto.id, :fecha_inicio => Date.today, :usuario_id => admin.id, :definicion_estado_id => DefinicionEstado.find_by_primer_estado(true).id, :estado_actual => true
    rol = Rol.find_by_nombre_and_seccion "Coordinador", "proyectos"
    UsuarioXProyecto.create :usuario_id => admin.id, :proyecto_id => proyecto.id, :rol_id => rol.id

    # Tareas para el Usuario Admin
    Tarea.create(:titulo => _("Dar de alta etapas del proyecto"), :proyecto_id => proyecto.id, :usuario_asignado_id => admin.id, :fecha_inicio => Date.today, :tipo_tarea_id =>  TipoTarea.find_by_nombre(_("Datos proyecto")).id, :estado_tarea_id => EstadoTarea.find_by_nombre(_("En espera")).id)
    Tarea.create(:titulo => _("Cambiar estado proyecto"), :proyecto_id => proyecto.id, :usuario_asignado_id => admin.id, :fecha_inicio => Date.today, :tipo_tarea_id =>  TipoTarea.find_by_nombre(_("Datos proyecto")).id, :estado_tarea_id => EstadoTarea.find_by_nombre(_("En espera")).id)
    Tarea.create(:titulo => _("Dar de alta relaciones proyecto"), :descripcion => _("Se necesita dar de alta las entidades en administracion"), :proyecto_id => proyecto.id, :usuario_asignado_id => admin.id, :fecha_inicio => Date.today, :tipo_tarea_id =>  TipoTarea.find_by_nombre(_("Datos proyecto")).id, :estado_tarea_id => EstadoTarea.find_by_nombre(_("En espera")).id)
    Tarea.create(:titulo => _("Dar de alta el presupuesto"), :proyecto_id => proyecto.id, :usuario_asignado_id => admin.id, :fecha_inicio => Date.today, :tipo_tarea_id =>  TipoTarea.find_by_nombre(_("Presupuesto")).id, :estado_tarea_id => EstadoTarea.find_by_nombre(_("En espera")).id)
    #Tarea.create(:titulo => _("Dar de alta la matriz"), :proyecto_id => proyecto.id, :usuario_asignado_id => admin.id, :fecha_inicio => Date.today, :tipo_tarea_id =>  TipoTarea.find_by_nombre(_("Matriz")).id, :estado_tarea_id => EstadoTarea.find_by_nombre(_("En espera")).id)
  end
end

# Subtipos de Movimiento
if SubtipoMovimiento.count == 0
  SubtipoMovimiento.create :nombre => _("COSTES INDIRECTOS"), :descripcion => "Costes indirectos"
  SubtipoMovimiento.create :nombre => _("EXPATRIADO/A"), :descripcion => "Expatriado/a"
  SubtipoMovimiento.create :nombre => _("DONACIÓN"), :descripcion => "Donación", :tipo_asociado => "adelanto"
  SubtipoMovimiento.create :nombre => _("ADELANTO"), :descripcion => "Adelanto", :tipo_asociado => "adelanto"
  SubtipoMovimiento.create :nombre => _("APORTACIONES EXTERNAS"), :descripcion => "Aportaciones Externas", :tipo_asociado => "adelanto"
  SubtipoMovimiento.create :nombre => _("DEVOLUCIÓN DE ADELANTO"), :descripcion => "Devolución de Adelanto", :tipo_asociado => "devolucion"
end

# Partidas del Sistema
if Partida.count == 0
  Partida.create :nombre => "Identificación Sede", :codigo => "01", :descripcion => "Gastos del periodo de Identificación realizados en Sede", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Identificación Terreno", :codigo => "02", :descripcion => "Gastos del periodo de Identificación realizados en Terreno", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Evaluaciones Sede", :codigo => "03", :descripcion => "Gastos de evaluación contratada en sede (euros)", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Evaluaciones Terreno", :codigo => "04", :descripcion => "Gastos de evaluación contratada en terreno", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Auditoría", :codigo => "05", :descripcion => "Gastos de auditoría", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Terrenos", :codigo => "06", :descripcion => "Gastos asociados a terrenos", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Valorización local Terrenos", :codigo => "07", :descripcion => "Imputación de terrenos valorizados", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Inmuebles", :codigo => "08", :descripcion => "Gastos asociados a inmuebles (alquileres, etc)", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Valorización local Inmuebles", :codigo => "09", :descripcion => "Imputación de valoraciones asociadas a inmuebles", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Vivienda Expatriado", :codigo => "10", :descripcion => "Gastos de alquiler de vivienda del expatriado", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Construcción", :codigo => "11", :descripcion => "Gastos asociados a construcción", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Reformas", :codigo => "12", :descripcion => "Gastos asociados a reformas", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Suministros", :codigo => "13", :descripcion => "Gastos asociados a suministros", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Valorización local suministros", :codigo => "14", :descripcion => "Imputaciones de valoraciones de suministros", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Equipos y Materiales inventariables", :codigo => "15", :descripcion => "Gastos asociados a compra de equipos y materiales inventariables", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Valorización local  de equipos y Materiales", :codigo => "16", :descripcion => "Imputaciones de valoraciones de equipos y materiales", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Personal Local", :codigo => "17", :descripcion => "Costes de personal local", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Valorización local Personal Local", :codigo => "18", :descripcion => "Imputaciones de valorizaciones de Personal Local", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Personal Expatriado", :codigo => "19", :descripcion => "Costes de personal expatriado", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Personal Expatriado Residente", :codigo => "20", :descripcion => "Costes de personal expatriado que reside en nuestro país", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Personal de Sede", :codigo => "21", :descripcion => "Costes de personal sede", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Servicios Tecnicos Terreno", :codigo => "22", :descripcion => "Gastos asociados a servicios técnicos prestados en terreno", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Servicios Tecnicos Sede", :codigo => "23", :descripcion => "Gastos asociados a servicios técnicos prestados en sede", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Valorización servicios Técnicos Terreno", :codigo => "24", :descripcion => "Imputaciones de valorizaciones de servicios técnicos prestados en terreno", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Valorización servicios Técnicos Sede", :codigo => "25", :descripcion => "Imputaciones de valorizaciones de servicios técnicos prestados en sede", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Fondo Rotatorio", :codigo => "26", :descripcion => "Gastos asociados al Fondo rotatorio (prestamos, etc)", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Fondo Rotatorio en Especies", :codigo => "27", :descripcion => "Gastos asociados al Fondo en especies (se compran materiales, equipos, etc.)", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Funcionamiento Terreno", :codigo => "28", :descripcion => "Gastos asociados a funcionamiento en terreno", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Funcionamiento Sede", :codigo => "29", :descripcion => "Gastos asociados a funcionamiento en sede", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Viajes, alojamientos y dietas Personal Sede", :codigo => "30", :descripcion => "Gastos asociados a viajes, alojamientos y dietas de personal de Sede", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Viajes, alojamientos y dietas Personal Terreno", :codigo => "31", :descripcion => "Gastos asociados a viajes, alojamientos y dietas de personal en Terreno", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Viajes, alojamientos y dietas Beneficiarios", :codigo => "32", :descripcion => "Gastos asociados a viajes, alojamientos y dietas de beneficiarios", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Gastos financieros Sede", :codigo => "33", :descripcion => "Gastos financieros generados en sede", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Gastos financieros Terreno", :codigo => "34", :descripcion => "Gastos financieros generados en terreno", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "(EpD) Seminarios y Talleres en Sede,...", :codigo => "35", :descripcion => "Gastos asociados a actividades de Educación para el Desarrollo de Seminarios y Talleres en Sede,... ", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "(EpD) Valorización Seminarios y Talleres", :codigo => "36", :descripcion => "Gastos asociados a actividades de Educación para el Desarrollo de Valorización Seminarios y Talleres en Sede", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "(EpD) Difusión", :codigo => "37", :descripcion => "Gastos asociados a actividades de EpD de difusión en Educación para el Desarrollo en Sede", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "(EpD) Valorización Materiales de Difusión", :codigo => "38", :descripcion => "Imputaciones de valorizaciones de actividades de difusión en Educación para el Desarrollo", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Otras difusiones (GdC, etc)", :codigo => "39", :descripcion => "Gastos asociados a otras difusiones distintas a las de Educación para el Desarrollo", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Gastos indirectos Sede (CERTIFICADOS)", :codigo => "40", :descripcion => "Gastos indirectos de Sede justificados con certificados", :tipo => "indirecto", :ocultar_agente => false
  Partida.create :nombre => "Gastos indirectos Sede (JUSTIFICADOS)", :codigo => "41", :descripcion => "Gastos indirectos de Sede justificados con facturas", :tipo => "indirecto", :ocultar_agente => false
  Partida.create :nombre => "Gastos indirectos ONGD Local", :codigo => "42", :descripcion => "Gastos indirectos del socio local", :tipo => "indirecto", :ocultar_agente => false
  Partida.create :nombre => "Gastos indirectos para Identificación", :codigo => "43", :descripcion => "Gastos indirectos imputados en el periodo de identificación", :tipo => "indirecto", :ocultar_agente => false
  Partida.create :nombre => "Gastos indirectos para Evaluación", :codigo => "44", :descripcion => "Gastos indirectos imputados utilizados para realización de evaluaciones", :tipo => "indirecto", :ocultar_agente => false
  Partida.create :nombre => "Personal Voluntario", :codigo => "45", :descripcion => "Gastos asociados a personal voluntario", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Estudios técnicos asociados a construcción, ingeniería, licitaciones, etc", :codigo => "46", :descripcion => "Gastos de estudios técnicos asociados a construccion, ingenieria, licitaciones, etc", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Arrendamiento de equipos", :codigo => "48", :descripcion => "Gastos asociados a los alquileres y arrendamientos de equipos", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Equipos y Materiales NO inventariables", :codigo => "47", :descripcion => "Gastos asociados a compras y equipos y materiales no inventariables", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Arrendamiento de inmuebles", :codigo => "50", :descripcion => "Gastos asociados a los alquileres y arrendamientos de inmuebles", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Arrendamiento de terrenos", :codigo => "49", :descripcion => "Gastos asociados al arrendamiento de terrenos", :tipo => "directo", :ocultar_agente => false
  Partida.create :nombre => "Estudios técnicos asociados a reformas", :codigo => "51", :descripcion => "Gastos de estudios técnicos asociados a reforma", :tipo => "directo", :ocultar_agente => false
end


# Creamos los tipos de periodos si no existen
#
if TipoPeriodo.count == 0
  TipoPeriodo.create nombre: _("Seguimiento mensual"),
                     descripcion: _("Periodo de seguimiento mensual interno de la propia organización"),
                     grupo_tipo_periodo: "seguimiento"
  TipoPeriodo.create nombre: _("Seguimiento trimestral"),
                     descripcion: _("Periodo de seguimiento trimestral interno de la propia organización"),
                     grupo_tipo_periodo: "seguimiento"
  TipoPeriodo.create nombre: _("Seguimiento anual"),
                     descripcion: _("Periodo de seguimiento anual interno de la propia organización"),
                     grupo_tipo_periodo: "seguimiento"
  TipoPeriodo.create nombre: _("Informe Intermedio"),
                     descripcion: _("Periodo intermedio al que corresponde un informe parcial requerido por el financiador"),
                     oficial: true, :grupo_tipo_periodo => "seguimiento"
end
# Tipos de periodo de justificacion final
if TipoPeriodo.where(no_borrable: true, grupo_tipo_periodo: "final").empty?
  TipoPeriodo.create nombre: _("Informe Final"),
                     descripcion: _("Periodo completo de ejecución del proyecto al que corresponde el informe final"),
                     oficial: true, no_borrable: true, grupo_tipo_periodo: "final"
end
# Tipos de periodo de prórrogas
if TipoPeriodo.where(no_borrable: true, grupo_tipo_periodo: "prorroga").empty?
  TipoPeriodo.create nombre: _("Prorroga"),
                     descripcion: _("Prorroga al periodo de ejecución de un proyecto. Requiere autorización del financiador"),
                     oficial: true, no_borrable: true, grupo_tipo_periodo: "prorroga"
end
# Tipos de periodo de prórrogas de justificacion final
if TipoPeriodo.where(no_borrable: true, grupo_tipo_periodo: "prorroga_justificacion").empty?
  TipoPeriodo.create nombre: _("Prorroga Justificación Final"),
                     descripcion: _("Prorroga a la justificación final de un proyecto. Requiere autorización del financiador"),
                     oficial: true, no_borrable: true, grupo_tipo_periodo: "prorroga_justificacion"
end
# Tipos de periodo de formulacion
if TipoPeriodo.where(no_borrable: true, grupo_tipo_periodo: "formulacion").empty?
  TipoPeriodo.create nombre: _("Periodo de formulación"),
                     descripcion: _("Periodo de formulación. La fecha de presentación del informe se corresponde con la oficial marcada por el financiador"),
                     oficial: true, no_borrable: true, grupo_tipo_periodo: "formulacion"
end

if TipoPersonal.count == 0
  TipoPersonal.create :codigo => "PL", :nombre => _("Personal Local")
  TipoPersonal.create :codigo => "PE", :nombre => _("Personal Expatriado")
  TipoPersonal.create :codigo => "PS", :nombre => _("Personal Sede")
  TipoPersonal.create :codigo => "PV", :nombre => _("Personal Voluntario") 
end

# Indicadores Generales
if IndicadorGeneral.count == 0
  IndicadorGeneral.create codigo: "ESC", nombre: "Escuelas Construidas", descripcion: "Número de escuelas construidas", unidad: "escuelas"
  IndicadorGeneral.create codigo: "ALM", nombre: "Alumnos Matriculados", descripcion: "Número de alumnos matriculados", unidad: "alumnos"
  IndicadorGeneral.create codigo: "ALG", nombre: "Alumnos Graduados", descripcion: "Número de alumnos graduados", unidad: "alumnos"
end

GorConfig.create( name: "URL_PROTOCOL", value: "http",
                  description: "Protocolo utilizado en la web (http ó https)" ) unless GorConfig.find_by_name "URL_PROTOCOL"
GorConfig.create( name: "URL_HOST", value: (ENV['GOR_SITEID'] || "localhost:3000"),
                  description: "Dominio y puerto bajo el que está instalado GONG" ) unless GorConfig.find_by_name "URL_HOST"
GorConfig.create( name: "EMAIL_FROM", value: ENV['GOR_EMAIL']||("no-reply@" + (ENV['GOR_SITEID'] || "gong.org.es")),
                  description: "Dirección de correo para emails de notificación" ) unless GorConfig.find_by_name "EMAIL_FROM"
GorConfig.create( name: "APP_NAME", value: ENV['GOR_APPNAME']||"GONG",
                  description: "Nombre utilizado como nombre de la aplicación" ) unless GorConfig.find_by_name "APP_NAME"
GorConfig.create( name: "APP_TITLE", value: "",
                  description: "Nombre utilizado como título de la aplicación" ) unless GorConfig.find_by_name "APP_TITLE"
GorConfig.create( name: "NEW_PROJECT_GROUP_SEND_MAIL", value: "",
                  description: "Nombre del grupo al que se le notificará la creación de un nuevo proyecto desde la seccion de agentes" ) unless GorConfig.find_by_name "NEW_PROJECT_GROUP_SEND_MAIL"
GorConfig.create( name: "AUTO_ASIGN_SYSTEM_AGENTS", value: "TRUE",
                  description: "Asignar automáticamente 'OTROS FINANCIADORES' a los proyectos recién creados (TRUE/FALSE)" ) unless GorConfig.find_by_name "AUTO_ASIGN_SYSTEM_AGENTS"
GorConfig.create( name: "VALIDATE_GRANT_ACCOUNT_ON_APPROVED_PROJECT", value: "TRUE",
                  description: "Validar que existe una cuenta de subvención cuando un proyecto pasa a estado aprobado (TRUE/FALSE)" ) unless GorConfig.find_by_name "VALIDATE_GRANT_ACCOUNT_ON_APPROVED_PROJECT"
GorConfig.create( name: "VALIDATE_REPORTING_PERIOD_ON_APPROVED_PROJECT", value: "FALSE",
                  description: "Validar que el proyecto tiene un periodo de justificación definido cuando pasa a estado aprobado (TRUE/FALSE)" ) unless GorConfig.find_by_name "VALIDATE_REPORTING_PERIOD_ON_APPROVED_PROJECT"
GorConfig.create( name: "VALIDATE_CRS_CODE_ON_APPROVED_PROJECT", value: "FALSE",
                  description: "Validar que el sector de intervención de un proyecto está definido al 100% cuando se pasa a estado aprobado (TRUE/FALSE)" ) unless GorConfig.find_by_name "VALIDATE_CRS_CODE_ON_APPROVED_PROJECT"
GorConfig.create( name: "VALIDATE_AREA_OF_ACTION_ON_APPROVED_PROJECT", value: "FALSE",
                  description: "Validar que el área de actuación de un proyecto está definido al 100% cuando se pasa a estado aprobado (TRUE/FALSE)" ) unless GorConfig.find_by_name "VALIDATE_AREA_OF_ACTION_ON_APPROVED_PROJECT"
GorConfig.create( name: "VALIDATE_POPULATION_SECTOR_ON_APPROVED_PROJECT", value: "FALSE",
                  description: "Validar que el sector de población de un proyecto está definido al 100% cuando se pasa a estado aprobado (TRUE/FALSE)" ) unless GorConfig.find_by_name "VALIDATE_POPULATION_SECTOR_ON_APPROVED_PROJECT"
GorConfig.create( name: "VALIDATE_MATRIX_ON_APPROVED_PROJECT", value: "FALSE",
                  description: "Validar que la matriz de un proyecto está correctamente construida cuando se pasa a estado aprobado (TRUE/FALSE)" ) unless GorConfig.find_by_name "VALIDATE_MATRIX_ON_APPROVED_PROJECT"
GorConfig.create( name: "VALIDATE_BUDGET_ON_APPROVED_PROJECT", value: "FALSE",
                                   description: "Validar que el prespuesto de un proyecto no tiene errores cuando se pasa a estado aprobado (TRUE/FALSE)" ) unless GorConfig.find_by_name "VALIDATE_BUDGET_ON_APPROVED_PROJECT"
GorConfig.create( name: "VALIDATE_STAGES_DATES_IN_PROJECT_EXPENSES", value: "TRUE",
                  description: "Validar que los gastos de un proyecto estén dentro de las fechas de sus etapas (TRUE/FALSE)" ) unless GorConfig.find_by_name "VALIDATE_STAGES_DATES_IN_PROJECT_EXPENSES"
GorConfig.create( name: "UPDATE_STAGE_ENDING_DATE_WHEN_EXTENSION_IS_APPROVED", value: "FALSE",
                  description: "Modificar fecha de última etapa de proyecto cuando se aprueba una prórroga (TRUE/FALSE)" ) unless GorConfig.find_by_name "UPDATE_STAGE_ENDING_DATE_WHEN_EXTENSION_IS_APPROVED"
GorConfig.create( name: "SHOW_ONLY_PERIODS_TO_BE_ACCEPTED", value: "TRUE",
                  description: "En los listados de periodos de home y proyectos, mostrar solo los pendientes de ser aceptados (TRUE/FALSE)" ) unless GorConfig.find_by_name "SHOW_ONLY_PERIODS_TO_BE_ACCEPTED"

# Configuracion para comportamiento de programas marco
GorConfig.create( name: "ALLOW_ASSIGN_CLOSED_PROJECTS_ON_FRAMEWORK_PROGRAMS", value: "FALSE",
                  description: "Permitir asignar proyectos cerrados a los Programas Marco (TRUE/FALSE)" ) unless GorConfig.find_by_name "ALLOW_ASSIGN_CLOSED_PROJECTS_ON_FRAMEWORK_PROGRAMS"

# Configuracion para la gestion de empleados y la relacion entre gasto y presupuesto
GorConfig.create( name: "CHECK_EMPLOYED_BUDGET_ON_EXPENSES", value: "FALSE",
                  description: "En el alta de nuevos gastos de empleados comprueba su relacion con el presupuesto y añade alertas (TRUE/FALSE)" ) unless GorConfig.find_by_name "CHECK_EMPLOYED_BUDGET_ON_EXPENSES"

GorConfig.create( name: "MARKED_EMPLOYED_BUDGET_ON_EXPENSES_ERRORS", value: "",
                  description: "Marcado para  errores en el alta de nuevos gastos de empleados en relacion con el presupuesto." ) unless GorConfig.find_by_name "MARKED_EMPLOYED_BUDGET_ON_EXPENSES_ERRORS"

# Confiuracion para la gestión de empleados, y la relacion entre gastos y transferencias
GorConfig.create( name: "ACCOUNT_FOR_EMPLOYED_PAYMENTS", value: "",
                  description: "Cuenta desde la que se realizan los pagos de los empleados. Si esta configurada y existe dicha cuenta, en el alta de nuevos gastos de empleados comprueba su relacion con transferencias y añade nuevas si fuese necesario.  " ) unless GorConfig.find_by_name "ACCOUNT_FOR_EMPLOYED_PAYMENTS"

GorConfig.create( name: "ACCOUNT_FOR_EMPLOYED_PAYMENTS_WITHOUT_PROJECT", value: "",
                  description: "Cuenta desde la que se realizan los pagos de los empleados no asignados a proyectos. " ) unless GorConfig.find_by_name "ACCOUNT_FOR_EMPLOYED_PAYMENTS_WITHOUT_PROJECT"

GorConfig.create( name: "MARKED_FOR_AUTOMATIC_EMPLOYED_PAYMENTS", value: "",
                  description: "Marcado del sistema para las transferencias creadas automaticamente relacionados con los gastos de empleados" ) unless GorConfig.find_by_name "MARKED_FOR_AUTOMATIC_EMPLOYED_PAYMENTS"
        
GorConfig.create( name: "CLOSE_EXPENSES_FORM_ON_ACTIVITIES_ERRORS", value: "TRUE",
                  description: "Cerrar el formulario de gastos aunque haya errores de distribución por actividades (formulario de proyectos" ) unless GorConfig.find_by_name "CLOSE_EXPENSES_FORM_ON_ACTIVITIES_ERRORS"

GorConfig.create( name: "CLOSE_EXPENSES_FORM_ON_FINANCIERS_ERRORS", value: "FALSE",
                  description: "Cerrar el formulario de gastos aunque haya errores de distribución por financiadores (formulario de proyectos)" ) unless GorConfig.find_by_name "CLOSE_EXPENSES_FORM_ON_FINANCIAERS_ERRORS"

GorConfig.create( name: "CLOSE_EXPENSES_FORM_ON_PROJECTS_ERRORS", value: "FALSE",
                  description: "Cerrar el formulario de gastos aunque haya errores de distribución por proyectos (formulario de agentes)" ) unless GorConfig.find_by_name "CLOSE_EXPENSES_FORM_ON_PROJECTS_ERRORS"
