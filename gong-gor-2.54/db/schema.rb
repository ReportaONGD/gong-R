# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20170517104844) do

  create_table "actividad", :force => true do |t|
    t.string   "codigo"
    t.text     "descripcion"
    t.integer  "proyecto_id"
    t.integer  "resultado_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "actividad_convenio_id"
  end

  add_index "actividad", ["codigo"], :name => "index_actividad_on_codigo"
  add_index "actividad", ["id"], :name => "index_actividad_on_id", :unique => true
  add_index "actividad", ["proyecto_id"], :name => "index_actividad_on_proyecto_id"

  create_table "actividad_detallada", :force => true do |t|
    t.integer  "mes"
    t.integer  "etapa_id"
    t.integer  "actividad_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "seguimiento",  :default => false
  end

  create_table "actividad_x_etapa", :force => true do |t|
    t.integer  "actividad_id"
    t.integer  "etapa_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "actividad_x_etapa", ["actividad_id"], :name => "index_actividad_x_etapa_on_actividad_id"
  add_index "actividad_x_etapa", ["etapa_id"], :name => "index_actividad_x_etapa_on_etapa_id"
  add_index "actividad_x_etapa", ["id"], :name => "index_actividad_x_etapa_on_id", :unique => true

  create_table "actividad_x_etiqueta_tecnica", :force => true do |t|
    t.integer  "actividad_id"
    t.integer  "etiqueta_tecnica_id"
    t.decimal  "porcentaje",          :precision => 5, :scale => 4, :default => 0.0
    t.datetime "created_at",                                                         :null => false
    t.datetime "updated_at",                                                         :null => false
  end

  create_table "actividad_x_pais", :force => true do |t|
    t.integer  "actividad_id"
    t.integer  "pais_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "agente", :force => true do |t|
    t.string  "nombre"
    t.string  "nombre_completo"
    t.boolean "financiador",          :default => false
    t.boolean "implementador",        :default => false
    t.integer "moneda_id"
    t.integer "moneda_intermedia_id"
    t.integer "pais_id"
    t.boolean "socia_local",          :default => false
    t.boolean "sistema",              :default => false
    t.boolean "publico",              :default => false
    t.boolean "local"
    t.string  "nif",                  :default => ""
    t.integer "tipo_agente_id"
  end

  add_index "agente", ["id"], :name => "index_agente_on_id", :unique => true
  add_index "agente", ["nombre"], :name => "index_agente_on_nombre", :unique => true

  create_table "agente_x_moneda", :force => true do |t|
    t.integer  "moneda_id"
    t.integer  "agente_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "area_actuacion", :force => true do |t|
    t.string  "nombre"
    t.text    "descripcion"
    t.integer "categoria_area_actuacion_id"
  end

  create_table "area_geografica", :force => true do |t|
    t.string   "nombre"
    t.text     "descripcion"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "campo_tipo_contrato", :force => true do |t|
    t.integer  "tipo_contrato_id",                        :null => false
    t.string   "nombre",                                  :null => false
    t.string   "etiqueta",                                :null => false
    t.string   "descripcion"
    t.string   "tipo_campo",       :default => "boolean", :null => false
    t.string   "tipo_condicion"
    t.string   "valor_condicion"
    t.boolean  "activo",           :default => true,      :null => false
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
  end

  add_index "campo_tipo_contrato", ["id"], :name => "index_campo_tipo_contrato_on_id"
  add_index "campo_tipo_contrato", ["tipo_contrato_id"], :name => "index_campo_tipo_contrato_on_tipo_contrato_id"

  create_table "categoria_area_actuacion", :force => true do |t|
    t.string   "nombre",      :null => false
    t.string   "descripcion"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "categoria_sector_intervencion", :force => true do |t|
    t.string   "nombre",      :null => false
    t.string   "descripcion"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "comentario", :force => true do |t|
    t.integer  "usuario_id"
    t.text     "texto"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "elemento_type",                    :null => false
    t.integer  "elemento_id",                      :null => false
    t.boolean  "sistema",       :default => false
  end

  add_index "comentario", ["elemento_type", "elemento_id"], :name => "index_comentario_on_elemento_type_and_elemento_id"

  create_table "comunidad", :force => true do |t|
    t.string   "nombre"
    t.integer  "provincia_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "contrato", :force => true do |t|
    t.string   "codigo"
    t.string   "nombre",                                          :null => false
    t.decimal  "importe",          :precision => 24, :scale => 2, :null => false
    t.integer  "moneda_id",                                       :null => false
    t.text     "descripcion"
    t.text     "observaciones"
    t.date     "fecha_inicio",                                    :null => false
    t.date     "fecha_fin",                                       :null => false
    t.integer  "agente_id",                                       :null => false
    t.integer  "proyecto_id"
    t.integer  "proveedor_id"
    t.integer  "marcado_id"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.text     "objetivo"
    t.text     "justificacion"
    t.integer  "tipo_contrato_id"
  end

  add_index "contrato", ["agente_id"], :name => "index_contrato_on_agente_id"
  add_index "contrato", ["id"], :name => "index_contrato_on_id"

  create_table "contrato_x_actividad", :force => true do |t|
    t.integer  "contrato_id",                                                  :null => false
    t.integer  "actividad_id",                                                 :null => false
    t.decimal  "importe",      :precision => 24, :scale => 2, :default => 0.0, :null => false
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
  end

  add_index "contrato_x_actividad", ["actividad_id"], :name => "index_contrato_x_actividad_on_actividad_id"
  add_index "contrato_x_actividad", ["contrato_id"], :name => "index_contrato_x_actividad_on_contrato_id"

  create_table "contrato_x_campo_tipo_contrato", :force => true do |t|
    t.integer "campo_tipo_contrato_id", :null => false
    t.integer "contrato_id",            :null => false
    t.text    "valor_dato"
  end

  create_table "contrato_x_documento", :force => true do |t|
    t.integer  "estado_contrato_id", :null => false
    t.integer  "documento_id",       :null => false
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "contrato_x_documento", ["documento_id"], :name => "index_contrato_x_documento_on_documento_id"
  add_index "contrato_x_documento", ["estado_contrato_id"], :name => "index_contrato_x_documento_on_estado_contrato_id"
  add_index "contrato_x_documento", ["id"], :name => "index_contrato_x_documento_on_id"

  create_table "contrato_x_financiador", :force => true do |t|
    t.integer  "contrato_id",                                                 :null => false
    t.integer  "agente_id",                                                   :null => false
    t.decimal  "importe",     :precision => 24, :scale => 2, :default => 0.0, :null => false
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
  end

  add_index "contrato_x_financiador", ["contrato_id", "agente_id"], :name => "index_contrato_x_financiador_ids"

  create_table "convocatoria", :force => true do |t|
    t.string   "codigo",                                  :null => false
    t.string   "nombre",                                  :null => false
    t.text     "descripcion"
    t.text     "observaciones"
    t.integer  "agente_id",                               :null => false
    t.date     "fecha_publicacion"
    t.date     "fecha_presentacion"
    t.date     "fecha_resolucion"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.integer  "tipo_convocatoria_id"
    t.boolean  "cerrado",              :default => false, :null => false
  end

  add_index "convocatoria", ["agente_id"], :name => "index_convocatoria_on_agente_id"

  create_table "convocatoria_x_pais", :force => true do |t|
    t.integer  "convocatoria_id", :null => false
    t.integer  "pais_id",         :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "convocatoria_x_pais", ["convocatoria_id", "pais_id"], :name => "index_convocatoria_x_pais_on_convocatoria_id_and_pais_id"

  create_table "cuenta_contable", :force => true do |t|
    t.string   "codigo",                                    :null => false
    t.integer  "agente_id"
    t.integer  "elemento_contable_id"
    t.string   "elemento_contable_type"
    t.text     "descripcion"
    t.text     "observaciones"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "centro_coste",           :default => false
  end

  add_index "cuenta_contable", ["agente_id", "codigo"], :name => "index_cuenta_contable_on_agente_id_and_codigo"
  add_index "cuenta_contable", ["elemento_contable_id", "elemento_contable_type"], :name => "idx_cuenta_contable_elemento"

  create_table "dato_texto", :force => true do |t|
    t.text     "dato"
    t.integer  "proyecto_id"
    t.integer  "definicion_dato_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "datos_proyecto", :force => true do |t|
    t.integer "proyecto_id"
    t.integer "beneficiarios_directos_hombres",           :default => 0
    t.integer "beneficiarios_directos_mujeres",           :default => 0
    t.integer "beneficiarios_indirectos_hombres",         :default => 0
    t.integer "beneficiarios_indirectos_mujeres",         :default => 0
    t.integer "beneficiarios_directos_sin_especificar",   :default => 0
    t.integer "beneficiarios_indirectos_sin_especificar", :default => 0
    t.integer "poblacion_total_de_la_zona",               :default => 0
    t.integer "pais_id"
  end

  add_index "datos_proyecto", ["proyecto_id", "pais_id"], :name => "index_datos_proyecto_pais"

  create_table "datos_tarjeta_socio", :force => true do |t|
    t.integer  "informacion_socio_id"
    t.string   "tipo_tarjeta"
    t.string   "numero_tarjeta"
    t.date     "fecha_caducidad"
    t.integer  "numero_verificacion"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "definicion_dato", :force => true do |t|
    t.string   "nombre"
    t.string   "rotulo"
    t.string   "tipo"
    t.integer  "rango"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "grupo_dato_dinamico_id"
    t.boolean  "asignar_proyecto",       :default => false, :null => false
  end

  create_table "definicion_estado", :force => true do |t|
    t.string   "nombre"
    t.text     "descripcion"
    t.integer  "estado_padre_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "primer_estado",   :default => false, :null => false
    t.boolean  "formulacion",     :default => false, :null => false
    t.boolean  "aprobado",        :default => false, :null => false
    t.boolean  "cerrado",         :default => false, :null => false
    t.integer  "orden",           :default => 0,     :null => false
    t.boolean  "reporte",         :default => false, :null => false
    t.boolean  "ejecucion",       :default => false, :null => false
  end

  create_table "definicion_estado_tarea", :force => true do |t|
    t.text     "titulo"
    t.text     "descripcion"
    t.integer  "tipo_tarea_id"
    t.integer  "estado_tarea_id"
    t.integer  "definicion_estado_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "definicion_estado_x_definicion_estado", :force => true do |t|
    t.integer  "definicion_estado_padre_id"
    t.integer  "definicion_estado_hijo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "definicion_estado_x_etiqueta", :force => true do |t|
    t.integer  "definicion_estado_id"
    t.integer  "etiqueta_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documento", :force => true do |t|
    t.string   "adjunto_file_name"
    t.string   "adjunto_content_type"
    t.integer  "adjunto_file_size"
    t.text     "descripcion"
    t.string   "tipo"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "usuario_id"
    t.integer  "proyecto_id"
    t.integer  "agente_id"
    t.string   "adjunto_url"
  end

  create_table "documento_x_espacio", :force => true do |t|
    t.integer  "espacio_id"
    t.string   "documento_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "empleado", :force => true do |t|
    t.string   "nombre"
    t.boolean  "activo"
    t.integer  "agente_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "empleado_salario_hora", :force => true do |t|
    t.integer "empleado_id",                                 :null => false
    t.date    "fecha_inicio",                                :null => false
    t.date    "fecha_fin",                                   :null => false
    t.decimal "salario_hora", :precision => 24, :scale => 4
  end

  create_table "espacio", :force => true do |t|
    t.text     "nombre"
    t.text     "descripcion"
    t.integer  "espacio_padre_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "proyecto_id"
    t.boolean  "definicion_espacio_proyecto"
    t.integer  "definicion_espacio_proyecto_id"
    t.integer  "agente_id"
    t.boolean  "definicion_espacio_agente"
    t.integer  "definicion_espacio_agente_id"
    t.boolean  "ocultar"
    t.boolean  "modificable",                       :default => true
    t.boolean  "definicion_espacio_financiador",    :default => false
    t.integer  "definicion_espacio_financiador_id"
    t.integer  "pais_id"
    t.boolean  "definicion_espacio_pais",           :default => false
    t.integer  "definicion_espacio_pais_id"
    t.boolean  "definicion_espacio_socia",          :default => false
    t.integer  "definicion_espacio_socia_id"
    t.boolean  "espacio_contratos",                 :default => false, :null => false
  end

  create_table "estado", :force => true do |t|
    t.integer  "definicion_estado_id"
    t.integer  "proyecto_id"
    t.date     "fecha_inicio"
    t.date     "fecha_fin"
    t.text     "observacion"
    t.integer  "usuario_id"
    t.boolean  "estado_actual"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "estado", ["definicion_estado_id"], :name => "index_estado_on_definicion_estado_id"
  add_index "estado", ["proyecto_id", "estado_actual"], :name => "index_estado_definicion_estado_proyecto"

  create_table "estado_contrato", :force => true do |t|
    t.integer  "workflow_contrato_id",                    :null => false
    t.integer  "contrato_id",                             :null => false
    t.date     "fecha_inicio"
    t.date     "fecha_fin"
    t.text     "observaciones"
    t.integer  "usuario_id",                              :null => false
    t.boolean  "estado_actual",        :default => false, :null => false
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
  end

  add_index "estado_contrato", ["contrato_id"], :name => "index_estado_contrato_on_contrato_id"
  add_index "estado_contrato", ["workflow_contrato_id"], :name => "index_estado_contrato_on_workflow_contrato_id"

  create_table "estado_tarea", :force => true do |t|
    t.string   "nombre"
    t.text     "descripcion"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "activo"
    t.boolean  "seleccionable", :default => true
  end

  create_table "etapa", :force => true do |t|
    t.string  "nombre"
    t.date    "fecha_inicio"
    t.date    "fecha_fin"
    t.string  "descripcion"
    t.integer "proyecto_id"
    t.integer "agente_id"
    t.boolean "cerrada",                                                    :default => false
    t.boolean "saldos_transferidos",                                        :default => false
    t.decimal "importe_previsto_subvencion", :precision => 24, :scale => 2, :default => 0.0
    t.boolean "presupuestable",                                             :default => true,  :null => false
  end

  add_index "etapa", ["id"], :name => "index_etapa_on_id", :unique => true
  add_index "etapa", ["nombre"], :name => "index_etapa_on_nombre"

  create_table "etiqueta", :force => true do |t|
    t.string   "nombre"
    t.text     "descripcion"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tipo"
  end

  create_table "etiqueta_tecnica", :force => true do |t|
    t.string   "nombre"
    t.string   "descripcion"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "etiqueta_x_documento", :force => true do |t|
    t.integer "etiqueta_id",  :null => false
    t.integer "documento_id", :null => false
  end

  create_table "forma_pago_socio", :force => true do |t|
    t.string "forma_pago"
  end

  create_table "fuente_verificacion", :force => true do |t|
    t.string   "codigo"
    t.text     "descripcion"
    t.integer  "indicador_id"
    t.integer  "objetivo_especifico_id"
    t.integer  "resultado_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "completada",                      :default => false
    t.integer  "fuente_verificacion_convenio_id"
  end

  create_table "fuente_verificacion_x_documento", :force => true do |t|
    t.integer  "fuente_verificacion_id"
    t.integer  "documento_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gasto", :force => true do |t|
    t.decimal  "importe",                :precision => 24, :scale => 2
    t.decimal  "impuestos",              :precision => 24, :scale => 2, :default => 0.0
    t.integer  "partida_id"
    t.integer  "moneda_id"
    t.string   "observaciones"
    t.string   "numero_factura"
    t.date     "fecha"
    t.string   "concepto"
    t.date     "fecha_informe"
    t.integer  "agente_id"
    t.integer  "proyecto_origen_id"
    t.integer  "marcado_id"
    t.integer  "subpartida_agente_id"
    t.integer  "agente_tasa_cambio_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "orden_factura_agente"
    t.integer  "marcado_agente_id"
    t.integer  "pais_id"
    t.boolean  "es_valorizado",                                         :default => false, :null => false
    t.string   "ref_contable"
    t.integer  "proveedor_id"
    t.integer  "orden_factura_proyecto"
    t.integer  "empleado_id"
  end

  add_index "gasto", ["agente_id", "ref_contable"], :name => "idx_gasto_ref_contable"
  add_index "gasto", ["proyecto_origen_id", "agente_id"], :name => "index_orden_factura_proyecto"

  create_table "gasto_x_actividad", :force => true do |t|
    t.integer "gasto_id"
    t.integer "actividad_id"
    t.integer "proyecto_id"
    t.decimal "importe",      :precision => 24, :scale => 2, :default => 0.0
  end

  add_index "gasto_x_actividad", ["proyecto_id", "gasto_id", "actividad_id"], :name => "index_gxact_proyecto_gasto_actividad"

  create_table "gasto_x_agente", :force => true do |t|
    t.integer "agente_id"
    t.integer "gasto_id"
    t.integer "proyecto_id"
    t.decimal "importe",     :precision => 24, :scale => 2, :default => 0.0
  end

  add_index "gasto_x_agente", ["gasto_id", "proyecto_id", "agente_id"], :name => "index_gxagt_gasto_proyecto_agente"

  create_table "gasto_x_contrato", :force => true do |t|
    t.integer  "contrato_id", :null => false
    t.integer  "gasto_id",    :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "gasto_x_contrato", ["contrato_id", "gasto_id"], :name => "index_gasto_x_contrato_on_contrato_id_and_gasto_id"

  create_table "gasto_x_documento", :force => true do |t|
    t.integer  "gasto_id"
    t.integer  "documento_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gasto_x_proyecto", :force => true do |t|
    t.integer "proyecto_id"
    t.integer "gasto_id"
    t.string  "orden_factura"
    t.integer "subpartida_id"
    t.decimal "importe",             :precision => 24, :scale => 2, :default => 0.0
    t.integer "tasa_cambio_id"
    t.integer "marcado_proyecto_id"
  end

  add_index "gasto_x_proyecto", ["gasto_id", "proyecto_id"], :name => "index_gasto_x_proyecto_on_gasto_id_and_proyecto_id"

  create_table "gasto_x_transferencia", :force => true do |t|
    t.integer  "gasto_id"
    t.integer  "transferencia_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gor_config", :force => true do |t|
    t.string "name",        :null => false
    t.string "value"
    t.text   "description"
  end

  add_index "gor_config", ["name"], :name => "index_gor_config_on_name"

  create_table "grupo_dato_dinamico", :force => true do |t|
    t.string   "nombre"
    t.integer  "rango"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "seguimiento", :default => false
    t.boolean  "cierre",      :default => false, :null => false
  end

  create_table "grupo_usuario", :force => true do |t|
    t.string   "nombre"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.boolean  "ocultar_proyecto",        :default => false, :null => false
    t.integer  "asignar_proyecto_rol_id"
  end

  create_table "grupo_usuario_x_agente", :force => true do |t|
    t.integer "grupo_usuario_id"
    t.integer "agente_id"
    t.integer "rol_id",           :null => false
  end

  add_index "grupo_usuario_x_agente", ["grupo_usuario_id", "agente_id"], :name => "index_grupo_x_agente", :unique => true

  create_table "grupo_usuario_x_espacio", :force => true do |t|
    t.integer "grupo_usuario_id"
    t.integer "espacio_id"
  end

  add_index "grupo_usuario_x_espacio", ["grupo_usuario_id", "espacio_id"], :name => "index_grupo_x_espacio", :unique => true

  create_table "grupo_usuario_x_libro", :force => true do |t|
    t.integer "grupo_usuario_id"
    t.integer "libro_id"
  end

  add_index "grupo_usuario_x_libro", ["grupo_usuario_id", "libro_id"], :name => "index_grupo_x_libro", :unique => true

  create_table "grupo_usuario_x_proyecto", :force => true do |t|
    t.integer "grupo_usuario_id"
    t.integer "proyecto_id"
    t.integer "rol_id",           :null => false
  end

  add_index "grupo_usuario_x_proyecto", ["grupo_usuario_id", "proyecto_id"], :name => "index_grupo_x_proyecto", :unique => true

  create_table "hipotesis", :force => true do |t|
    t.text     "descripcion"
    t.integer  "objetivo_especifico_id"
    t.integer  "resultado_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "indicador", :force => true do |t|
    t.string   "codigo"
    t.text     "descripcion"
    t.integer  "objetivo_especifico_id"
    t.integer  "resultado_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "indicador_convenio_id"
  end

  create_table "indicador_general", :force => true do |t|
    t.string   "nombre",                        :null => false
    t.string   "descripcion"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.string   "codigo",                        :null => false
    t.boolean  "activo",      :default => true, :null => false
    t.string   "unidad"
  end

  add_index "indicador_general", ["id"], :name => "index_indicador_general_on_id"

  create_table "indicador_general_x_programa_marco", :force => true do |t|
    t.integer  "programa_marco_id",    :null => false
    t.integer  "indicador_general_id", :null => false
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "indicador_general_x_programa_marco", ["programa_marco_id", "indicador_general_id"], :name => "igxpm_idx"

  create_table "indicador_general_x_proyecto", :force => true do |t|
    t.integer  "proyecto_id",          :null => false
    t.integer  "indicador_general_id", :null => false
    t.string   "herramienta_medicion"
    t.string   "fuente_informacion"
    t.text     "contexto"
    t.integer  "valor_base_id"
    t.integer  "valor_objetivo_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "indicador_general_x_proyecto", ["proyecto_id", "indicador_general_id"], :name => "igxp_idx"

  create_table "informacion_socio", :force => true do |t|
    t.integer "socio_id"
    t.date    "fecha_alta"
    t.date    "fecha_baja"
    t.date    "fecha_alta_sistema"
    t.decimal "importe_cuota",             :precision => 24, :scale => 2, :default => 0.0
    t.string  "calendario_pagos"
    t.text    "motivo_baja"
    t.boolean "enviar_periodica"
    t.boolean "enviar_puntual"
    t.boolean "enviar_182"
    t.date    "fecha_carta_bienvenida"
    t.date    "fecha_envio_documentacion"
    t.date    "fecha_envio_carne"
    t.integer "origen_socio_id",                                          :default => 1
    t.text    "comentario_origen_socio"
    t.integer "forma_pago_socio_id",                                      :default => 1
    t.boolean "activo"
    t.integer "tipo_cuota_socio_id",                                      :default => 1
  end

  create_table "ingreso", :force => true do |t|
    t.decimal  "importe",            :precision => 24, :scale => 2,                    :null => false
    t.integer  "moneda_id",                                                            :null => false
    t.string   "concepto"
    t.string   "observaciones"
    t.integer  "partida_ingreso_id",                                                   :null => false
    t.date     "fecha",                                                                :null => false
    t.integer  "marcado_id"
    t.integer  "tasa_cambio_id"
    t.integer  "agente_id",                                                            :null => false
    t.string   "numero_documento"
    t.integer  "proveedor_id"
    t.integer  "financiador_id"
    t.integer  "proyecto_id"
    t.string   "ref_contable"
    t.boolean  "es_valorizado",                                     :default => false, :null => false
    t.datetime "created_at",                                                           :null => false
    t.datetime "updated_at",                                                           :null => false
  end

  add_index "ingreso", ["agente_id"], :name => "index_ingreso_on_agente_id"
  add_index "ingreso", ["id"], :name => "index_ingreso_on_id"

  create_table "item_contrato", :force => true do |t|
    t.integer  "contrato_id",                                   :null => false
    t.string   "nombre",                                        :null => false
    t.integer  "cantidad",                                      :null => false
    t.decimal  "coste_unitario", :precision => 24, :scale => 2, :null => false
    t.string   "descripcion"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
  end

  add_index "item_contrato", ["contrato_id"], :name => "index_item_contrato_on_contrato_id"

  create_table "libro", :force => true do |t|
    t.string  "nombre"
    t.integer "moneda_id"
    t.integer "agente_id"
    t.string  "cuenta"
    t.string  "descripcion"
    t.string  "tipo"
    t.integer "pais_id"
    t.string  "iban"
    t.string  "swift"
    t.boolean "bloqueado",   :default => false
    t.boolean "oculto",      :default => false
    t.string  "entidad",     :default => ""
  end

  create_table "libro_x_proyecto", :force => true do |t|
    t.integer "libro_id"
    t.integer "proyecto_id"
  end

  create_table "log_contabilidad", :force => true do |t|
    t.integer  "agente_id",                            :null => false
    t.integer  "usuario_id"
    t.string   "elemento",                             :null => false
    t.boolean  "finalizado_ok",     :default => false, :null => false
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.boolean  "running",           :default => false, :null => false
    t.boolean  "partial_execution", :default => false, :null => false
  end

  add_index "log_contabilidad", ["agente_id"], :name => "index_log_contabilidad_on_agente_id"

  create_table "marcado", :force => true do |t|
    t.text     "nombre"
    t.text     "descripcion"
    t.text     "color"
    t.boolean  "primer_estado"
    t.integer  "marcado_padre_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "automatico",       :default => false
    t.boolean  "error",            :default => false
  end

  create_table "moneda", :force => true do |t|
    t.string "nombre"
    t.string "abreviatura"
  end

  create_table "moneda_x_pais", :force => true do |t|
    t.integer  "moneda_id"
    t.integer  "pais_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "municipio", :force => true do |t|
    t.string   "nombre"
    t.integer  "comunidad_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "naturaleza_socio", :force => true do |t|
    t.string "naturaleza"
  end

  create_table "oauth_access_grants", :force => true do |t|
    t.integer  "resource_owner_id", :null => false
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.integer  "expires_in",        :null => false
    t.text     "redirect_uri",      :null => false
    t.datetime "created_at",        :null => false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  add_index "oauth_access_grants", ["token"], :name => "index_oauth_access_grants_on_token", :unique => true

  create_table "oauth_access_tokens", :force => true do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id"
    t.string   "token",             :null => false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        :null => false
    t.string   "scopes"
  end

  add_index "oauth_access_tokens", ["refresh_token"], :name => "index_oauth_access_tokens_on_refresh_token", :unique => true
  add_index "oauth_access_tokens", ["resource_owner_id"], :name => "index_oauth_access_tokens_on_resource_owner_id"
  add_index "oauth_access_tokens", ["token"], :name => "index_oauth_access_tokens_on_token", :unique => true

  create_table "oauth_applications", :force => true do |t|
    t.string   "name",         :null => false
    t.string   "uid",          :null => false
    t.string   "secret",       :null => false
    t.text     "redirect_uri", :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "oauth_applications", ["uid"], :name => "index_oauth_applications_on_uid", :unique => true

  create_table "objetivo_especifico", :force => true do |t|
    t.string   "codigo"
    t.text     "descripcion"
    t.integer  "proyecto_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "objetivo_general", :force => true do |t|
    t.text     "descripcion"
    t.integer  "proyecto_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "origen_socio", :force => true do |t|
    t.string "origen"
  end

  create_table "pago", :force => true do |t|
    t.decimal  "importe",         :precision => 24, :scale => 2, :default => 0.0
    t.date     "fecha"
    t.integer  "gasto_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "libro_id"
    t.string   "observaciones"
    t.string   "forma_pago"
    t.string   "referencia_pago"
    t.string   "ref_contable"
  end

  add_index "pago", ["gasto_id"], :name => "index_pago_on_gasto_id"

  create_table "pago_socio", :force => true do |t|
    t.string  "concepto"
    t.date    "fecha_emision"
    t.date    "fecha_pago"
    t.decimal "importe",             :precision => 24, :scale => 2, :default => 0.0
    t.text    "comentario"
    t.date    "fecha_alta_sistema"
    t.integer "socio_id"
    t.integer "forma_pago_socio_id"
  end

  create_table "pais", :force => true do |t|
    t.string  "nombre"
    t.integer "area_geografica_id"
    t.string  "codigo",             :default => "", :null => false
  end

  create_table "partida", :force => true do |t|
    t.string  "nombre"
    t.string  "codigo"
    t.string  "descripcion"
    t.string  "tipo"
    t.boolean "ocultar_agente"
    t.boolean "ocultar_proyecto", :default => false, :null => false
    t.boolean "tipo_empleado",    :default => false
  end

  add_index "partida", ["codigo"], :name => "index_partida_on_codigo", :unique => true
  add_index "partida", ["id"], :name => "index_partida_on_id", :unique => true

  create_table "partida_financiacion", :force => true do |t|
    t.string  "nombre"
    t.string  "codigo"
    t.string  "descripcion"
    t.integer "proyecto_id"
    t.string  "tipo"
    t.boolean "puede_ser_padre"
    t.integer "partida_financiacion_id"
    t.boolean "padre"
    t.integer "agente_id"
    t.decimal "porcentaje_maximo",       :precision => 5,  :scale => 4, :default => 0.0
    t.decimal "importe",                 :precision => 24, :scale => 2, :default => 0.0
  end

  add_index "partida_financiacion", ["proyecto_id"], :name => "index_partida_financiacion_on_proyecto_id"

  create_table "partida_financiacion_x_partida_financiacion", :force => true do |t|
    t.integer "partida_padre_id"
    t.integer "partida_hijo_id"
  end

  create_table "partida_ingreso", :force => true do |t|
    t.string   "nombre",                            :null => false
    t.string   "descripcion"
    t.boolean  "presupuestable", :default => true,  :null => false
    t.boolean  "proyecto",       :default => false, :null => false
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "partida_ingreso", ["id"], :name => "index_partida_ingreso_on_id"

  create_table "partida_x_partida_financiacion", :force => true do |t|
    t.integer "partida_financiacion_id"
    t.integer "partida_id"
  end

  add_index "partida_x_partida_financiacion", ["partida_id", "partida_financiacion_id"], :name => "index_partidas_x_financiacion"

  create_table "periodo", :force => true do |t|
    t.integer  "tipo_periodo_id",                    :null => false
    t.integer  "proyecto_id",                        :null => false
    t.date     "fecha_inicio",                       :null => false
    t.date     "fecha_fin",                          :null => false
    t.text     "descripcion"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.boolean  "gastos_cerrados", :default => false, :null => false
    t.date     "fecha_informe"
    t.boolean  "periodo_cerrado", :default => false
  end

  add_index "periodo", ["id", "tipo_periodo_id", "proyecto_id"], :name => "index_periodo_on_id_and_tipo_periodo_id_and_proyecto_id"

  create_table "periodo_contrato", :force => true do |t|
    t.integer  "contrato_id",                                                  :null => false
    t.decimal  "importe",      :precision => 24, :scale => 2, :default => 0.0, :null => false
    t.date     "fecha_inicio",                                                 :null => false
    t.date     "fecha_fin",                                                    :null => false
    t.string   "descripcion"
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
  end

  add_index "periodo_contrato", ["contrato_id"], :name => "index_periodo_contrato_on_contrato_id"
  add_index "periodo_contrato", ["id"], :name => "index_periodo_contrato_on_id"

  create_table "permiso_x_rol", :force => true do |t|
    t.integer  "rol_id",                         :null => false
    t.string   "menu",                           :null => false
    t.string   "controlador",                    :null => false
    t.boolean  "ver",         :default => true,  :null => false
    t.boolean  "cambiar",     :default => false, :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  create_table "personal", :force => true do |t|
    t.integer  "proyecto_id",                       :null => false
    t.string   "nombre",                            :null => false
    t.integer  "tipo_personal_id",                  :null => false
    t.string   "categoria"
    t.string   "residencia"
    t.string   "tipo_contrato",                     :null => false
    t.integer  "horas_imputadas",  :default => 0,   :null => false
    t.float    "salario_mensual",  :default => 0.0, :null => false
    t.float    "meses",            :default => 0.0, :null => false
    t.float    "salario_total",    :default => 0.0, :null => false
    t.integer  "moneda_id",                         :null => false
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "personal", ["id", "proyecto_id", "tipo_personal_id"], :name => "index_personal_on_id_and_proyecto_id_and_tipo_personal_id"

  create_table "plugin", :force => true do |t|
    t.string   "nombre",                           :null => false
    t.string   "codigo",                           :null => false
    t.string   "clase",                            :null => false
    t.string   "descripcion", :default => "",      :null => false
    t.string   "version",     :default => "0.0.0", :null => false
    t.integer  "peso",        :default => 10,      :null => false
    t.boolean  "disponible",  :default => true,    :null => false
    t.boolean  "activo",      :default => false,   :null => false
    t.boolean  "engine",      :default => true,    :null => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "plugin", ["clase"], :name => "index_plugin_on_clase"
  add_index "plugin", ["id"], :name => "index_plugin_on_id"

  create_table "presupuesto", :force => true do |t|
    t.decimal "importe",         :precision => 24, :scale => 2
    t.string  "concepto"
    t.string  "observaciones"
    t.integer "partida_id"
    t.integer "moneda_id"
    t.integer "agente_id"
    t.integer "libro_id"
    t.decimal "coste_unitario",  :precision => 24, :scale => 2
    t.decimal "numero_unidades", :precision => 24, :scale => 2
    t.integer "subpartida_id"
    t.string  "unidad"
    t.integer "proyecto_id"
    t.integer "etapa_id"
    t.integer "marcado_id"
    t.integer "tasa_cambio_id"
    t.integer "pais_id"
    t.integer "empleado_id"
  end

  add_index "presupuesto", ["agente_id"], :name => "index_presupuesto_on_agente_id"
  add_index "presupuesto", ["id"], :name => "index_presupuesto_on_id", :unique => true
  add_index "presupuesto", ["libro_id"], :name => "index_presupuesto_on_libro_id"
  add_index "presupuesto", ["moneda_id"], :name => "index_presupuesto_on_moneda_id"
  add_index "presupuesto", ["partida_id"], :name => "index_presupuesto_on_partida_id"
  add_index "presupuesto", ["proyecto_id"], :name => "index_presupuesto_on_proyecto_id"
  add_index "presupuesto", ["tasa_cambio_id"], :name => "index_presupuesto_on_tasa_cambio_id"

  create_table "presupuesto_detallado", :force => true do |t|
    t.integer "presupuesto_id"
    t.decimal "importe",        :precision => 24, :scale => 2
    t.date    "fecha_inicio"
    t.date    "fecha_fin"
    t.string  "nombre"
    t.integer "mes"
  end

  add_index "presupuesto_detallado", ["id"], :name => "index_presupuesto_detallado_on_id", :unique => true
  add_index "presupuesto_detallado", ["presupuesto_id"], :name => "index_presupuesto_detallado_on_presupuesto_id"

  create_table "presupuesto_ingreso", :force => true do |t|
    t.decimal  "importe",            :precision => 24, :scale => 2,                   :null => false
    t.decimal  "porcentaje",         :precision => 12, :scale => 11, :default => 0.0, :null => false
    t.string   "concepto"
    t.string   "observaciones"
    t.integer  "partida_ingreso_id",                                                  :null => false
    t.integer  "moneda_id",                                                           :null => false
    t.integer  "etapa_id",                                                            :null => false
    t.integer  "marcado_id"
    t.integer  "tasa_cambio_id"
    t.integer  "agente_id",                                                           :null => false
    t.integer  "proyecto_id"
    t.integer  "financiador_id"
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
  end

  add_index "presupuesto_ingreso", ["agente_id"], :name => "index_presupuesto_ingreso_on_agente_id"
  add_index "presupuesto_ingreso", ["id"], :name => "index_presupuesto_ingreso_on_id"

  create_table "presupuesto_ingreso_detallado", :force => true do |t|
    t.integer "presupuesto_ingreso_id",                                                 :null => false
    t.decimal "importe",                :precision => 24, :scale => 2, :default => 0.0, :null => false
    t.date    "fecha_inicio"
    t.date    "fecha_fin"
    t.string  "nombre"
    t.integer "mes"
  end

  add_index "presupuesto_ingreso_detallado", ["id"], :name => "index_presupuesto_ingreso_detallado_on_id"
  add_index "presupuesto_ingreso_detallado", ["presupuesto_ingreso_id"], :name => "index_presupuesto_ingreso_detallado_on_presupuesto_ingreso_id"

  create_table "presupuesto_x_actividad", :force => true do |t|
    t.integer "presupuesto_id"
    t.integer "actividad_id"
    t.decimal "importe",         :precision => 24, :scale => 2
    t.integer "numero_unidades"
  end

  add_index "presupuesto_x_actividad", ["actividad_id"], :name => "index_presupuesto_x_actividad_on_actividad_id"
  add_index "presupuesto_x_actividad", ["id"], :name => "index_presupuesto_x_actividad_on_id", :unique => true
  add_index "presupuesto_x_actividad", ["presupuesto_id"], :name => "index_presupuesto_x_actividad_on_presupuesto_id"

  create_table "presupuesto_x_agente", :force => true do |t|
    t.integer "agente_id"
    t.integer "presupuesto_id"
    t.decimal "importe",        :precision => 24, :scale => 2
  end

  add_index "presupuesto_x_agente", ["agente_id"], :name => "index_presupuesto_x_agente_on_agente_id"
  add_index "presupuesto_x_agente", ["presupuesto_id"], :name => "index_presupuesto_x_agente_on_presupuesto_id"

  create_table "presupuesto_x_proyecto", :force => true do |t|
    t.integer  "presupuesto_id"
    t.integer  "proyecto_id"
    t.decimal  "importe",        :precision => 24, :scale => 2, :null => false
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
  end

  create_table "programa_marco", :force => true do |t|
    t.string   "nombre",                             :null => false
    t.string   "objetivo_general",                   :null => false
    t.integer  "moneda_id",                          :null => false
    t.text     "descripcion"
    t.boolean  "activo",           :default => true, :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  create_table "proveedor", :force => true do |t|
    t.string   "nombre",                             :null => false
    t.string   "nif",                                :null => false
    t.string   "descripcion"
    t.text     "observaciones"
    t.integer  "agente_id",                          :null => false
    t.integer  "pais_id"
    t.boolean  "activo",           :default => true, :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "entidad_bancaria"
    t.string   "cuenta_bancaria"
  end

  add_index "proveedor", ["agente_id"], :name => "index_proveedor_on_agente_id"
  add_index "proveedor", ["id"], :name => "index_proveedor_on_id"

  create_table "provincia", :force => true do |t|
    t.string   "nombre"
    t.integer  "pais_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "proyecto", :force => true do |t|
    t.string   "nombre"
    t.text     "titulo"
    t.integer  "moneda_id"
    t.integer  "moneda_intermedia_id"
    t.integer  "convenio_id"
    t.string   "convenio_accion"
    t.integer  "libro_id"
    t.integer  "pais_principal_id"
    t.decimal  "importe_previsto_total",                             :precision => 24, :scale => 2, :default => 0.0
    t.decimal  "importe_previsto_subvencion",                        :precision => 24, :scale => 2, :default => 0.0
    t.integer  "convocatoria_id",                                                                                      :null => false
    t.integer  "gestor_id"
    t.string   "identificador_financiador",                                                         :default => "",    :null => false
    t.date     "fecha_limite_peticion_prorroga"
    t.date     "fecha_inicio_aviso_peticion_prorroga"
    t.boolean  "ocultar_gastos_otras_delegaciones",                                                 :default => false, :null => false
    t.date     "fecha_limite_peticion_prorroga_justificacion"
    t.date     "fecha_inicio_aviso_peticion_prorroga_justificacion"
    t.date     "fecha_inicio_aprobada_original"
    t.date     "fecha_fin_aprobada_original"
    t.integer  "programa_marco_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "proyecto", ["id"], :name => "index_proyecto_on_id", :unique => true
  add_index "proyecto", ["nombre"], :name => "index_proyecto_on_nombre", :unique => true

  create_table "proyecto_x_area_actuacion", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "area_actuacion_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "porcentaje",        :precision => 5, :scale => 4, :default => 0.0
  end

  create_table "proyecto_x_definicion_dato", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "definicion_dato_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "proyecto_x_financiador", :force => true do |t|
    t.integer "agente_id"
    t.integer "proyecto_id"
  end

  add_index "proyecto_x_financiador", ["agente_id"], :name => "index_proyecto_x_financiador_on_agente_id"
  add_index "proyecto_x_financiador", ["proyecto_id"], :name => "index_proyecto_x_financiador_on_proyecto_id"

  create_table "proyecto_x_implementador", :force => true do |t|
    t.integer "agente_id"
    t.integer "proyecto_id"
  end

  add_index "proyecto_x_implementador", ["agente_id"], :name => "index_proyecto_x_implementador_on_agente_id"
  add_index "proyecto_x_implementador", ["proyecto_id"], :name => "index_proyecto_x_implementador_on_proyecto_id"

  create_table "proyecto_x_moneda", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "moneda_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "proyecto_x_moneda", ["moneda_id"], :name => "index_proyecto_x_moneda_on_moneda_id"
  add_index "proyecto_x_moneda", ["proyecto_id"], :name => "index_proyecto_x_moneda_on_proyecto_id"

  create_table "proyecto_x_pais", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "pais_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "proyecto_x_proyecto", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "proyecto_cofinanciador_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "importe",                   :precision => 24, :scale => 2, :default => 0.0
    t.boolean  "financiacion_privada",                                     :default => false
    t.boolean  "financiacion_publica",                                     :default => false
  end

  add_index "proyecto_x_proyecto", ["proyecto_id", "proyecto_cofinanciador_id"], :name => "index_pxp_proyecto_cofinanciador"

  create_table "proyecto_x_sector_intervencion", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "sector_intervencion_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "porcentaje",             :precision => 5, :scale => 4, :default => 0.0
  end

  create_table "proyecto_x_sector_poblacion", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "sector_poblacion_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "porcentaje",          :precision => 5, :scale => 4, :default => 0.0
  end

  create_table "resultado", :force => true do |t|
    t.string   "codigo"
    t.text     "descripcion"
    t.integer  "proyecto_id"
    t.integer  "objetivo_especifico_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rol", :force => true do |t|
    t.string   "nombre",                         :null => false
    t.string   "seccion",                        :null => false
    t.string   "descripcion"
    t.boolean  "admin",       :default => false, :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  create_table "sector_intervencion", :force => true do |t|
    t.string  "nombre"
    t.text    "descripcion"
    t.integer "categoria_sector_intervencion_id"
  end

  create_table "sector_poblacion", :force => true do |t|
    t.string "nombre"
    t.text   "descripcion"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "simple_captcha_data", :force => true do |t|
    t.string   "key",        :limit => 40
    t.string   "value",      :limit => 6
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "simple_captcha_data", ["key"], :name => "idx_key"

  create_table "socio", :force => true do |t|
    t.string  "nombre"
    t.string  "apellido1"
    t.string  "apellido2"
    t.string  "tratamiento"
    t.string  "NIF"
    t.string  "NIF_representante"
    t.string  "sexo"
    t.date    "fecha_nacimiento"
    t.string  "direccion"
    t.string  "localidad"
    t.string  "codigo_postal"
    t.string  "provincia",               :default => ""
    t.string  "comunidad"
    t.string  "municipio"
    t.string  "codigo_provincia_fiscal"
    t.string  "pais"
    t.string  "email"
    t.string  "telefono_fijo"
    t.string  "telefono_movil"
    t.text    "comentarios"
    t.integer "naturaleza_socio_id",     :default => 1
  end

  create_table "subactividad", :force => true do |t|
    t.integer  "actividad_id"
    t.text     "descripcion"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "responsables_ejecucion"
    t.text     "descripcion_detallada"
    t.text     "comentarios_ejecucion"
  end

  create_table "subactividad_detallada", :force => true do |t|
    t.integer  "mes"
    t.integer  "etapa_id"
    t.integer  "subactividad_id"
    t.boolean  "seguimiento",     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subpartida", :force => true do |t|
    t.string   "nombre"
    t.integer  "proyecto_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "numero"
    t.integer  "agente_id"
    t.integer  "partida_id"
  end

  create_table "subtipo_movimiento", :force => true do |t|
    t.string   "nombre"
    t.string   "descripcion"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tipo_asociado"
  end

  create_table "tarea", :force => true do |t|
    t.string   "titulo"
    t.text     "descripcion"
    t.integer  "tipo_tarea_id"
    t.integer  "proyecto_id"
    t.integer  "usuario_id"
    t.integer  "usuario_asignado_id"
    t.date     "fecha_inicio"
    t.date     "fecha_fin"
    t.integer  "porcentage_implementacion"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "estado_tarea_id"
    t.date     "fecha_prevista"
    t.integer  "horas_empleadas"
    t.integer  "agente_id"
    t.integer  "periodo_id"
    t.integer  "definicion_estado_tarea_id"
  end

  create_table "tasa_cambio", :force => true do |t|
    t.integer  "etapa_id"
    t.date     "fecha_inicio"
    t.date     "fecha_fin"
    t.boolean  "tasa_fija",                                         :default => true
    t.string   "objeto",                                            :default => "presupuesto"
    t.integer  "moneda_id"
    t.decimal  "tasa_cambio",        :precision => 15, :scale => 8
    t.decimal  "tasa_cambio_divisa", :precision => 15, :scale => 8, :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "agente_id"
    t.integer  "pais_id"
  end

  add_index "tasa_cambio", ["etapa_id", "moneda_id", "pais_id", "objeto"], :name => "index_tasa_cambio_pais_moneda"

  create_table "tipo_agente", :force => true do |t|
    t.string   "nombre",     :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "tipo_agente", ["id"], :name => "index_tipo_agente_on_id"

  create_table "tipo_contrato", :force => true do |t|
    t.string   "nombre",        :null => false
    t.string   "descripcion"
    t.text     "observaciones"
    t.integer  "duracion"
    t.integer  "agente_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "tipo_contrato", ["agente_id"], :name => "index_tipo_contrato_on_agente_id"
  add_index "tipo_contrato", ["id"], :name => "index_tipo_contrato_on_id"

  create_table "tipo_contrato_x_documento", :force => true do |t|
    t.integer  "tipo_contrato_id", :null => false
    t.integer  "documento_id",     :null => false
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "tipo_contrato_x_documento", ["tipo_contrato_id", "documento_id"], :name => "index_tipo_contrato_x_documento_ids"

  create_table "tipo_convocatoria", :force => true do |t|
    t.string   "nombre",     :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "tipo_convocatoria", ["id"], :name => "index_tipo_convocatoria_on_id"

  create_table "tipo_cuota_socio", :force => true do |t|
    t.string  "tipo_cuota"
    t.integer "meses",      :default => 1
  end

  create_table "tipo_periodo", :force => true do |t|
    t.string   "nombre",                                :null => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.text     "descripcion"
    t.boolean  "oficial",            :default => false
    t.boolean  "no_borrable",        :default => false
    t.string   "grupo_tipo_periodo"
  end

  add_index "tipo_periodo", ["id"], :name => "index_tipo_periodo_on_id"

  create_table "tipo_personal", :force => true do |t|
    t.string   "codigo",     :null => false
    t.string   "nombre",     :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "tipo_personal", ["id"], :name => "index_tipo_personal_on_id"

  create_table "tipo_tarea", :force => true do |t|
    t.string   "nombre"
    t.text     "descripcion"
    t.boolean  "tipo_proyecto"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tipo_agente",             :default => false
    t.boolean  "administracion",          :default => false
    t.boolean  "configuracion",           :default => false
    t.boolean  "formulacion_economica",   :default => false
    t.boolean  "formulacion_tecnica",     :default => false
    t.boolean  "seguimiento_economico",   :default => false
    t.boolean  "seguimiento_tecnico",     :default => false
    t.boolean  "justificacion",           :default => false
    t.string   "dias_aviso_finalizacion"
  end

  create_table "transferencia", :force => true do |t|
    t.integer "proyecto_id"
    t.string  "observaciones"
    t.string  "iban"
    t.decimal "tasa_cambio",           :precision => 15, :scale => 8, :default => 0.0
    t.string  "tipo"
    t.string  "numero_cheque"
    t.boolean "remanente",                                            :default => false
    t.integer "subtipo_movimiento_id"
    t.date    "fecha_enviado"
    t.decimal "importe_enviado",       :precision => 24, :scale => 2
    t.integer "libro_origen_id"
    t.date    "fecha_recibido"
    t.decimal "importe_recibido",      :precision => 24, :scale => 2
    t.decimal "importe_cambiado",      :precision => 24, :scale => 2
    t.integer "libro_destino_id"
    t.string  "ref_contable_enviado"
    t.string  "ref_contable_recibido"
    t.integer "marcado_id"
  end

  create_table "transferencia_x_agente", :force => true do |t|
    t.integer  "transferencia_id"
    t.integer  "agente_id"
    t.decimal  "importe",          :precision => 24, :scale => 2, :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transferencia_x_documento", :force => true do |t|
    t.integer  "transferencia_id"
    t.integer  "documento_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "usuario", :force => true do |t|
    t.string   "nombre"
    t.string   "contrasena"
    t.string   "nombre_completo"
    t.string   "correoe"
    t.boolean  "administracion"
    t.boolean  "proyectos"
    t.boolean  "agentes"
    t.boolean  "cuadromando"
    t.boolean  "socios"
    t.boolean  "documentos"
    t.boolean  "informes_aecid",  :default => false, :null => false
    t.string   "external_id"
    t.boolean  "bloqueado",       :default => false, :null => false
    t.integer  "agente_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "skype_id"
    t.boolean  "programas_marco", :default => false, :null => false
  end

  create_table "usuario_x_agente", :force => true do |t|
    t.integer "usuario_id"
    t.integer "agente_id"
    t.integer "grupo_usuario_id"
    t.integer "rol_id",           :null => false
  end

  create_table "usuario_x_espacio", :force => true do |t|
    t.integer  "espacio_id"
    t.integer  "usuario_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "grupo_usuario_id"
  end

  create_table "usuario_x_grupo_usuario", :force => true do |t|
    t.integer "usuario_id"
    t.integer "grupo_usuario_id"
  end

  add_index "usuario_x_grupo_usuario", ["usuario_id", "grupo_usuario_id"], :name => "index_usuario_x_grupo", :unique => true

  create_table "usuario_x_libro", :force => true do |t|
    t.integer "libro_id"
    t.integer "usuario_id"
    t.integer "grupo_usuario_id"
  end

  create_table "usuario_x_proyecto", :force => true do |t|
    t.integer "usuario_id"
    t.integer "proyecto_id"
    t.boolean "notificar_comentario"
    t.integer "grupo_usuario_id"
    t.integer "rol_id",               :null => false
    t.boolean "notificar_estado"
    t.boolean "notificar_usuario"
  end

  add_index "usuario_x_proyecto", ["usuario_id", "proyecto_id"], :name => "index_usuario_x_proyecto_on_usuario_id_and_proyecto_id"

  create_table "valor_intermedio_x_actividad", :force => true do |t|
    t.integer  "actividad_x_etapa_id"
    t.date     "fecha"
    t.decimal  "porcentaje",           :precision => 5, :scale => 4
    t.boolean  "realizada",                                          :default => false
    t.text     "comentario"
    t.integer  "usuario_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "valor_intermedio_x_indicador", :force => true do |t|
    t.integer  "indicador_id"
    t.date     "fecha"
    t.decimal  "porcentaje",   :precision => 5, :scale => 4
    t.string   "comentario"
    t.integer  "usuario_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "valor_intermedio_x_subactividad", :force => true do |t|
    t.integer  "subactividad_id"
    t.date     "fecha"
    t.decimal  "porcentaje",      :precision => 5, :scale => 4
    t.text     "estado"
    t.string   "comentario"
    t.integer  "usuario_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "valor_variable_indicador", :force => true do |t|
    t.string   "valor",                 :null => false
    t.date     "fecha",                 :null => false
    t.text     "comentario"
    t.integer  "variable_indicador_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "valor_x_indicador_general", :force => true do |t|
    t.integer  "indicador_general_x_proyecto_id"
    t.date     "fecha",                                          :null => false
    t.integer  "valor",                           :default => 0, :null => false
    t.text     "comentario"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
  end

  add_index "valor_x_indicador_general", ["indicador_general_x_proyecto_id"], :name => "vxig_idx"

  create_table "variable_indicador", :force => true do |t|
    t.string   "nombre",               :null => false
    t.string   "herramienta_medicion"
    t.string   "fuente_informacion"
    t.text     "contexto"
    t.integer  "indicador_id",         :null => false
    t.integer  "valor_base_id"
    t.integer  "valor_objetivo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "version_contrato", :force => true do |t|
    t.integer  "contrato_id",                                       :null => false
    t.integer  "estado_contrato_id",                                :null => false
    t.decimal  "importe",            :precision => 24, :scale => 2, :null => false
    t.integer  "moneda_id",                                         :null => false
    t.text     "observaciones"
    t.date     "fecha_inicio",                                      :null => false
    t.date     "fecha_fin",                                         :null => false
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
  end

  add_index "version_contrato", ["contrato_id"], :name => "index_version_contrato_on_contrato_id"
  add_index "version_contrato", ["id"], :name => "index_version_contrato_on_id"

  create_table "workflow_contrato", :force => true do |t|
    t.string   "nombre",        :default => "0"
    t.text     "descripcion"
    t.boolean  "primer_estado", :default => false, :null => false
    t.boolean  "formulacion",   :default => false, :null => false
    t.boolean  "aprobado",      :default => false, :null => false
    t.boolean  "cerrado",       :default => false, :null => false
    t.integer  "orden",         :default => 0,     :null => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.boolean  "ejecucion",     :default => false, :null => false
  end

  add_index "workflow_contrato", ["id"], :name => "index_workflow_contrato_on_id"

  create_table "workflow_contrato_x_etiqueta", :force => true do |t|
    t.integer  "workflow_contrato_id", :null => false
    t.integer  "etiqueta_id",          :null => false
    t.integer  "agente_id",            :null => false
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  create_table "workflow_contrato_x_workflow_contrato", :force => true do |t|
    t.integer  "workflow_contrato_padre_id", :null => false
    t.integer  "workflow_contrato_hijo_id",  :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "workflow_contrato_x_workflow_contrato", ["workflow_contrato_hijo_id"], :name => "wf_contrato_x_wf_contrato_hijo_id"
  add_index "workflow_contrato_x_workflow_contrato", ["workflow_contrato_padre_id"], :name => "wf_contrato_x_wf_contrato_padre_id"

end
