# encoding: UTF-8
class CreateGongTables < ActiveRecord::Migration
 def up

  create_table "actividad", :force => true do |t|
    t.string   "codigo"
    t.text     "descripcion"
    t.integer  "proyecto_id"
    t.integer  "resultado_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "actividad_convenio_id"
  end unless table_exists? :actividad

  add_index( "actividad", ["codigo"], :name => "index_actividad_on_codigo") unless index_exists?("actividad", ["codigo"], :name => "index_actividad_on_codigo")
  add_index( "actividad", ["id"], :name => "index_actividad_on_id", :unique => true) unless index_exists?("actividad", ["id"], :name => "index_actividad_on_id")
  add_index( "actividad", ["proyecto_id"], :name => "index_actividad_on_proyecto_id") unless index_exists?("actividad", ["proyecto_id"], :name => "index_actividad_on_proyecto_id")

  create_table "actividad_detallada", :force => true do |t|
    t.integer  "mes"
    t.integer  "etapa_id"
    t.integer  "actividad_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "seguimiento",  :default => false
  end unless table_exists? :actividad_detallada

  create_table "actividad_x_etapa", :force => true do |t|
    t.integer  "actividad_id"
    t.integer  "etapa_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :actividad_x_etapa

  add_index( "actividad_x_etapa", ["actividad_id"], :name => "index_actividad_x_etapa_on_actividad_id") unless index_exists?("actividad_x_etapa", ["actividad_id"], :name => "index_actividad_x_etapa_on_actividad_id")
  add_index( "actividad_x_etapa", ["etapa_id"], :name => "index_actividad_x_etapa_on_etapa_id") unless index_exists?("actividad_x_etapa", ["etapa_id"], :name => "index_actividad_x_etapa_on_etapa_id")
  add_index( "actividad_x_etapa", ["id"], :name => "index_actividad_x_etapa_on_id", :unique => true) unless index_exists?("actividad_x_etapa", ["id"], :name => "index_actividad_x_etapa_on_id")

  create_table "actividad_x_etiqueta_tecnica", :force => true do |t|
    t.integer  "actividad_id"
    t.integer  "etiqueta_tecnica_id"
    t.decimal  "porcentaje",          :precision => 5, :scale => 4, :default => 0.0
    t.datetime "created_at",                                                         :null => false
    t.datetime "updated_at",                                                         :null => false
  end unless table_exists? :actividad_x_etiqueta_tecnica

  create_table "actividad_x_pais", :force => true do |t|
    t.integer  "actividad_id"
    t.integer  "pais_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :actividad_x_pais

  create_table "agente", :force => true do |t|
    t.string  "nombre"
    t.string  "nombre_completo"
    t.boolean "financiador"
    t.boolean "implementador"
    t.integer "moneda_id"
    t.integer "moneda_intermedia_id"
    t.integer "pais_id"
    t.boolean "socia_local",          :default => false
    t.boolean "sistema"
    t.boolean "publico"
    t.boolean "local"
  end unless table_exists? :agente

  add_index( "agente", ["id"], :name => "index_agente_on_id", :unique => true) unless index_exists?("agente", ["id"], :name => "index_agente_on_id")
  add_index( "agente", ["nombre"], :name => "index_agente_on_nombre", :unique => true) unless index_exists?("agente", ["nombre"], :name => "index_agente_on_nombre")

  create_table "agente_x_moneda", :force => true do |t|
    t.integer  "moneda_id"
    t.integer  "agente_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :agente_x_moneda

  create_table "area_actuacion", :force => true do |t|
    t.string "nombre"
    t.text   "descripcion"
  end unless table_exists? :area_actuacion

  create_table "area_geografica", :force => true do |t|
    t.string   "nombre"
    t.text     "descripcion"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :area_geografica

  create_table "comentario", :force => true do |t|
    t.integer  "tarea_id"
    t.integer  "documento_id"
    t.integer  "usuario_id"
    t.text     "texto"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subactividad_id"
    t.integer  "gasto_id"
    t.integer  "presupuesto_id"
    t.integer  "actividad_id"
    t.integer  "indicador_id"
    t.integer  "fuente_verificacion_id"
    t.integer  "objetivo_especifico_id"
    t.integer  "resultado_id"
  end unless table_exists? :comentario

  create_table "comunidad", :force => true do |t|
    t.string   "nombre"
    t.integer  "provincia_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :comunidad

  create_table "dato_texto", :force => true do |t|
    t.text     "dato"
    t.integer  "proyecto_id"
    t.integer  "definicion_dato_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :dato_texto

  create_table "datos_proyecto", :force => true do |t|
    t.integer "proyecto_id"
    t.integer "beneficiarios_directos_hombres"
    t.integer "beneficiarios_directos_mujeres"
    t.integer "beneficiarios_indirectos_hombres"
    t.integer "beneficiarios_indirectos_mujeres"
    t.integer "beneficiarios_directos_sin_especificar"
    t.integer "beneficiarios_indirectos_sin_especificar"
    t.integer "poblacion_total_de_la_zona"
  end unless table_exists? :datos_proyecto

  create_table "datos_tarjeta_socio", :force => true do |t|
    t.integer  "informacion_socio_id"
    t.string   "tipo_tarjeta"
    t.string   "numero_tarjeta"
    t.date     "fecha_caducidad"
    t.integer  "numero_verificacion"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :datos_tarjeta_socio

  create_table "definicion_dato", :force => true do |t|
    t.string   "nombre"
    t.string   "rotulo"
    t.string   "tipo"
    t.integer  "rango"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "grupo_dato_dinamico_id"
  end unless table_exists? :definicion_dato

  create_table "definicion_estado", :force => true do |t|
    t.string   "nombre"
    t.text     "descripcion"
    t.integer  "estado_padre_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "primer_estado"
    t.boolean  "formulacion"
    t.boolean  "aprobado"
    t.boolean  "cerrado"
    t.integer  "orden"
  end unless table_exists? :definicion_estado

  create_table "definicion_estado_tarea", :force => true do |t|
    t.text     "titulo"
    t.text     "descripcion"
    t.integer  "tipo_tarea_id"
    t.integer  "estado_tarea_id"
    t.integer  "definicion_estado_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :definicion_estado_tarea

  create_table "definicion_estado_x_definicion_estado", :force => true do |t|
    t.integer  "definicion_estado_padre_id"
    t.integer  "definicion_estado_hijo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :definicion_estado_x_definicion_estado

  create_table "definicion_estado_x_etiqueta", :force => true do |t|
    t.integer  "definicion_estado_id"
    t.integer  "etiqueta_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :definicion_estado_x_etiqueta

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
  end unless table_exists? :documento

  create_table "documento_x_espacio", :force => true do |t|
    t.integer  "espacio_id"
    t.string   "documento_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :documento_x_espacio

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
  end unless table_exists? :espacio

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
  end unless table_exists? :estado

  add_index( "estado", ["definicion_estado_id"], :name => "index_estado_on_definicion_estado_id") unless index_exists?("estado", ["definicion_estado_id"], :name => "index_estado_on_definicion_estado_id")

  create_table "estado_tarea", :force => true do |t|
    t.string   "nombre"
    t.text     "descripcion"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "activo"
    t.boolean  "seleccionable", :default => true
  end unless table_exists? :estado_tarea

  create_table "etapa", :force => true do |t|
    t.string  "nombre"
    t.date    "fecha_inicio"
    t.date    "fecha_fin"
    t.string  "descripcion"
    t.integer "proyecto_id"
    t.integer "agente_id"
    t.boolean "cerrada",             :default => false
    t.boolean "saldos_transferidos", :default => false
  end unless table_exists? :etapa

  add_index( "etapa", ["id"], :name => "index_etapa_on_id", :unique => true) unless index_exists?("etapa", ["id"], :name => "index_etapa_on_id")
  add_index( "etapa", ["nombre"], :name => "index_etapa_on_nombre") unless index_exists?("etapa", ["nombre"], :name => "index_etapa_on_nombre")

  create_table "etiqueta", :force => true do |t|
    t.string   "nombre"
    t.text     "descripcion"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tipo"
  end unless table_exists? :etiqueta

  create_table "etiqueta_tecnica", :force => true do |t|
    t.string   "nombre"
    t.string   "descripcion"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end unless table_exists? :etiqueta_tecnica

  create_table "etiqueta_x_documento", :force => true do |t|
    t.integer "etiqueta_id",  :null => false
    t.integer "documento_id", :null => false
  end unless table_exists? :etiqueta_x_documento

  create_table "forma_pago_socio", :force => true do |t|
    t.string "forma_pago"
  end unless table_exists? :forma_pago_socio

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
  end unless table_exists? :fuente_verificacion

  create_table "fuente_verificacion_x_documento", :force => true do |t|
    t.integer  "fuente_verificacion_id"
    t.integer  "documento_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :fuente_verificacion_x_documento

  create_table "gasto", :force => true do |t|
    t.decimal  "importe",               :precision => 24, :scale => 2
    t.decimal  "impuestos",             :precision => 24, :scale => 2, :default => 0.0
    t.integer  "partida_id"
    t.integer  "moneda_id"
    t.string   "observaciones"
    t.string   "numero_factura"
    t.string   "emisor_factura"
    t.date     "fecha"
    t.string   "concepto"
    t.string   "dni_emisor"
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
  end unless table_exists? :gasto

  create_table "gasto_x_actividad", :force => true do |t|
    t.integer "gasto_id"
    t.integer "actividad_id"
    t.integer "proyecto_id"
    t.decimal "importe",      :precision => 24, :scale => 2, :default => 0.0
  end unless table_exists? :gasto_x_actividad

  create_table "gasto_x_agente", :force => true do |t|
    t.integer "agente_id"
    t.integer "gasto_id"
    t.integer "proyecto_id"
    t.decimal "importe",     :precision => 24, :scale => 2, :default => 0.0
  end unless table_exists? :gasto_x_agente

  create_table "gasto_x_documento", :force => true do |t|
    t.integer  "gasto_id"
    t.integer  "documento_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :gasto_x_documento

  create_table "gasto_x_proyecto", :force => true do |t|
    t.integer "proyecto_id"
    t.integer "gasto_id"
    t.string  "orden_factura"
    t.integer "subpartida_id"
    t.decimal "importe",             :precision => 24, :scale => 2, :default => 0.0
    t.integer "tasa_cambio_id"
    t.integer "marcado_proyecto_id"
  end unless table_exists? :gasto_x_proyecto

  create_table "gasto_x_transferencia", :force => true do |t|
    t.integer  "gasto_id"
    t.integer  "transferencia_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :gasto_x_transferencia

  create_table "grupo_dato_dinamico", :force => true do |t|
    t.string   "nombre"
    t.integer  "rango"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "seguimiento", :default => false
  end unless table_exists? :grupo_dato_dinamico

  create_table "hipotesis", :force => true do |t|
    t.text     "descripcion"
    t.integer  "objetivo_especifico_id"
    t.integer  "resultado_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :hipotesis

  create_table "indicador", :force => true do |t|
    t.string   "codigo"
    t.text     "descripcion"
    t.integer  "objetivo_especifico_id"
    t.integer  "resultado_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "indicador_convenio_id"
  end unless table_exists? :indicador

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
  end unless table_exists? :informacion_socio

  create_table "ingreso", :force => true do |t|
    t.decimal "importe",       :precision => 24, :scale => 2, :default => 0.0
    t.integer "proyecto_id"
    t.integer "libro_id"
    t.integer "moneda_id"
    t.integer "agente_id"
    t.string  "tipo"
    t.string  "observaciones"
    t.date    "fecha"
  end unless table_exists? :ingreso

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
  end unless table_exists? :libro

  create_table "libro_x_proyecto", :force => true do |t|
    t.integer "libro_id"
    t.integer "proyecto_id"
  end unless table_exists? :libro_x_proyecto

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
  end unless table_exists? :marcado

  create_table "moneda", :force => true do |t|
    t.string "nombre"
    t.string "abreviatura"
  end unless table_exists? :moneda

  create_table "moneda_x_pais", :force => true do |t|
    t.integer  "moneda_id"
    t.integer  "pais_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :moneda_x_pais

  create_table "municipio", :force => true do |t|
    t.string   "nombre"
    t.integer  "comunidad_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :municipio

  create_table "naturaleza_socio", :force => true do |t|
    t.string "naturaleza"
  end unless table_exists? :naturaleza_socio

  create_table "objetivo_especifico", :force => true do |t|
    t.string   "codigo"
    t.text     "descripcion"
    t.integer  "proyecto_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :objetivo_especifico

  create_table "objetivo_general", :force => true do |t|
    t.text     "descripcion"
    t.integer  "proyecto_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end unless table_exists? :objetivo_general

  create_table "origen_socio", :force => true do |t|
    t.string "origen"
  end unless table_exists? :origen_socio

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
  end unless table_exists? :pago

  create_table "pago_socio", :force => true do |t|
    t.string  "concepto"
    t.date    "fecha_emision"
    t.date    "fecha_pago"
    t.decimal "importe",             :precision => 24, :scale => 2, :default => 0.0
    t.text    "comentario"
    t.date    "fecha_alta_sistema"
    t.integer "socio_id"
    t.integer "forma_pago_socio_id"
  end unless table_exists? :pago_socio

  create_table "pais", :force => true do |t|
    t.string  "nombre"
    t.integer "area_geografica_id"
  end unless table_exists? :pais

  create_table "partida", :force => true do |t|
    t.string  "nombre"
    t.string  "codigo"
    t.string  "descripcion"
    t.string  "tipo"
    t.boolean "ocultar_agente"
  end unless table_exists? :partida

  add_index( "partida", ["codigo"], :name => "index_partida_on_codigo", :unique => true) unless index_exists?("partida", ["codigo"], :name => "index_partida_on_codigo")
  add_index( "partida", ["id"], :name => "index_partida_on_id", :unique => true) unless index_exists?("partida", ["id"], :name => "index_partida_on_id")

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
  end unless table_exists? :partida_financiacion

  create_table "partida_financiacion_x_partida_financiacion", :force => true do |t|
    t.integer "partida_padre_id"
    t.integer "partida_hijo_id"
  end unless table_exists? :partida_financiacion_x_partida_financiacion

  create_table "partida_x_partida_financiacion", :force => true do |t|
    t.integer "partida_financiacion_id"
    t.integer "partida_id"
  end unless table_exists? :partida_x_partida_financiacion

  create_table "presupuesto", :force => true do |t|
    t.decimal "importe",         :precision => 24, :scale => 2
    t.string  "concepto"
    t.string  "observaciones"
    t.integer "partida_id"
    t.integer "moneda_id"
    t.integer "agente_id"
    t.integer "libro_id"
    t.decimal "coste_unitario",  :precision => 24, :scale => 2
    t.integer "numero_unidades"
    t.integer "subpartida_id"
    t.string  "unidad"
    t.integer "proyecto_id"
    t.integer "etapa_id"
    t.integer "marcado_id"
    t.integer "tasa_cambio_id"
  end unless table_exists? :presupuesto

  add_index( "presupuesto", ["agente_id"], :name => "index_presupuesto_on_agente_id") unless index_exists?("presupuesto", ["agente_id"], :name => "index_presupuesto_on_agente_id")
  add_index( "presupuesto", ["id"], :name => "index_presupuesto_on_id", :unique => true) unless index_exists?("presupuesto", ["id"], :name => "index_presupuesto_on_id")
  add_index( "presupuesto", ["libro_id"], :name => "index_presupuesto_on_libro_id") unless index_exists?("presupuesto", ["libro_id"], :name => "index_presupuesto_on_libro_id")
  add_index( "presupuesto", ["moneda_id"], :name => "index_presupuesto_on_moneda_id") unless index_exists?("presupuesto", ["moneda_id"], :name => "index_presupuesto_on_moneda_id")
  add_index( "presupuesto", ["partida_id"], :name => "index_presupuesto_on_partida_id") unless index_exists?("presupuesto", ["partida_id"], :name => "index_presupuesto_on_partida_id")
  add_index( "presupuesto", ["proyecto_id"], :name => "index_presupuesto_on_proyecto_id") unless index_exists?("presupuesto", ["proyecto_id"], :name => "index_presupuesto_on_proyecto_id")
  add_index( "presupuesto", ["tasa_cambio_id"], :name => "index_presupuesto_on_tasa_cambio_id") unless index_exists?("presupuesto", ["tasa_cambio_id"], :name => "index_presupuesto_on_tasa_cambio_id")

  create_table "presupuesto_detallado", :force => true do |t|
    t.integer "presupuesto_id"
    t.decimal "importe",        :precision => 24, :scale => 2
    t.date    "fecha_inicio"
    t.date    "fecha_fin"
    t.string  "nombre"
    t.integer "mes"
  end unless table_exists? :presupuesto_detallado

  add_index( "presupuesto_detallado", ["id"], :name => "index_presupuesto_detallado_on_id", :unique => true) unless index_exists?("presupuesto_detallado", ["id"], :name => "index_presupuesto_detallado_on_id")
  add_index( "presupuesto_detallado", ["presupuesto_id"], :name => "index_presupuesto_detallado_on_presupuesto_id") unless index_exists?("presupuesto_detallado", ["presupuesto_id"], :name => "index_presupuesto_detallado_on_presupuesto_id")

  create_table "presupuesto_x_actividad", :force => true do |t|
    t.integer "presupuesto_id"
    t.integer "actividad_id"
    t.decimal "importe",         :precision => 24, :scale => 2
    t.integer "numero_unidades"
  end unless table_exists? :presupuesto_x_actividad

  add_index( "presupuesto_x_actividad", ["actividad_id"], :name => "index_presupuesto_x_actividad_on_actividad_id") unless index_exists?("presupuesto_x_actividad", ["actividad_id"], :name => "index_presupuesto_x_actividad_on_actividad_id")
  add_index( "presupuesto_x_actividad", ["id"], :name => "index_presupuesto_x_actividad_on_id", :unique => true) unless index_exists?("presupuesto_x_actividad", ["id"], :name => "index_presupuesto_x_actividad_on_id")
  add_index( "presupuesto_x_actividad", ["presupuesto_id"], :name => "index_presupuesto_x_actividad_on_presupuesto_id") unless index_exists?("presupuesto_x_actividad", ["presupuesto_id"], :name => "index_presupuesto_x_actividad_on_presupuesto_id")

  create_table "presupuesto_x_agente", :force => true do |t|
    t.integer "agente_id"
    t.integer "presupuesto_id"
    t.decimal "importe",        :precision => 24, :scale => 2
  end unless table_exists? :presupuesto_x_agente

  add_index( "presupuesto_x_agente", ["agente_id"], :name => "index_presupuesto_x_agente_on_agente_id") unless index_exists?("presupuesto_x_agente", ["agente_id"], :name => "index_presupuesto_x_agente_on_agente_id")
  add_index( "presupuesto_x_agente", ["presupuesto_id"], :name => "index_presupuesto_x_agente_on_presupuesto_id") unless index_exists?("presupuesto_x_agente", ["presupuesto_id"], :name => "index_presupuesto_x_agente_on_presupuesto_id")

  create_table "provincia", :force => true do |t|
    t.string   "nombre"
    t.integer  "pais_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :provincia

  create_table "proyecto", :force => true do |t|
    t.string  "nombre"
    t.text    "titulo"
    t.integer "agente_id"
    t.integer "moneda_id"
    t.integer "moneda_intermedia_id"
    t.integer "convenio_id"
    t.string  "convenio_accion"
    t.integer "libro_id"
    t.date    "fecha_convocatoria"
    t.integer "pais_principal_id"
  end unless table_exists? :proyecto

  add_index( "proyecto", ["id"], :name => "index_proyecto_on_id", :unique => true) unless index_exists?("proyecto", ["id"], :name => "index_proyecto_on_id")
  add_index( "proyecto", ["nombre"], :name => "index_proyecto_on_nombre", :unique => true) unless index_exists?("proyecto", ["nombre"], :name => "index_proyecto_on_nombre")

  create_table "proyecto_x_area_actuacion", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "area_actuacion_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "porcentaje",        :precision => 5, :scale => 4, :default => 0.0
  end unless table_exists? :proyecto_x_area_actuacion

  create_table "proyecto_x_definicion_dato", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "definicion_dato_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :proyecto_x_definicion_dato

  create_table "proyecto_x_financiador", :force => true do |t|
    t.integer "agente_id"
    t.integer "proyecto_id"
  end unless table_exists? :proyecto_x_financiador

  add_index( "proyecto_x_financiador", ["agente_id"], :name => "index_proyecto_x_financiador_on_agente_id") unless index_exists?("proyecto_x_financiador", ["agente_id"], :name => "index_proyecto_x_financiador_on_agente_id")
  add_index( "proyecto_x_financiador", ["proyecto_id"], :name => "index_proyecto_x_financiador_on_proyecto_id") unless index_exists?("proyecto_x_financiador", ["proyecto_id"], :name => "index_proyecto_x_financiador_on_proyecto_id")

  create_table "proyecto_x_implementador", :force => true do |t|
    t.integer "agente_id"
    t.integer "proyecto_id"
  end unless table_exists? :proyecto_x_implementador

  add_index( "proyecto_x_implementador", ["agente_id"], :name => "index_proyecto_x_implementador_on_agente_id") unless index_exists?("proyecto_x_implementador", ["agente_id"], :name => "index_proyecto_x_implementador_on_agente_id")
  add_index( "proyecto_x_implementador", ["proyecto_id"], :name => "index_proyecto_x_implementador_on_proyecto_id") unless index_exists?("proyecto_x_implementador", ["proyecto_id"], :name => "index_proyecto_x_implementador_on_proyecto_id")

  create_table "proyecto_x_moneda", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "moneda_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :proyecto_x_moneda

  add_index( "proyecto_x_moneda", ["moneda_id"], :name => "index_proyecto_x_moneda_on_moneda_id") unless index_exists?("proyecto_x_moneda", ["moneda_id"], :name => "index_proyecto_x_moneda_on_moneda_id")
  add_index( "proyecto_x_moneda", ["proyecto_id"], :name => "index_proyecto_x_moneda_on_proyecto_id") unless index_exists?("proyecto_x_moneda", ["proyecto_id"], :name => "index_proyecto_x_moneda_on_proyecto_id")

  create_table "proyecto_x_pais", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "pais_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :proyecto_x_pais

  create_table "proyecto_x_proyecto", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "proyecto_cofinanciador_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "importe",                   :precision => 24, :scale => 2, :default => 0.0
    t.boolean  "financiacion_privada",                                     :default => false
    t.boolean  "financiacion_publica",                                     :default => false
  end unless table_exists? :proyecto_x_proyecto

  create_table "proyecto_x_sector_intervencion", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "sector_intervencion_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :proyecto_x_sector_intervencion

  create_table "proyecto_x_sector_poblacion", :force => true do |t|
    t.integer  "proyecto_id"
    t.integer  "sector_poblacion_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :proyecto_x_sector_poblacion

  create_table "resultado", :force => true do |t|
    t.string   "codigo"
    t.text     "descripcion"
    t.integer  "proyecto_id"
    t.integer  "objetivo_especifico_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :resultado

  create_table "sector_intervencion", :force => true do |t|
    t.string "nombre"
    t.text   "descripcion"
  end unless table_exists? :sector_intervencion

  create_table "sector_poblacion", :force => true do |t|
    t.string "nombre"
    t.text   "descripcion"
  end unless table_exists? :sector_poblacion

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end unless table_exists? :sessions

  add_index( "sessions", ["session_id"], :name => "index_sessions_on_session_id") unless index_exists?("sessions", ["session_id"], :name => "index_sessions_on_session_id")
  add_index( "sessions", ["updated_at"], :name => "index_sessions_on_updated_at") unless index_exists?("sessions", ["updated_at"], :name => "index_sessions_on_updated_at")

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
  end unless table_exists? :socio

  create_table "subactividad", :force => true do |t|
    t.integer  "actividad_id"
    t.text     "descripcion"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "responsables_ejecucion"
    t.text     "descripcion_detallada"
    t.text     "comentarios_ejecucion"
  end unless table_exists? :subactividad

  create_table "subactividad_detallada", :force => true do |t|
    t.integer  "mes"
    t.integer  "etapa_id"
    t.integer  "subactividad_id"
    t.boolean  "seguimiento",     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :subactividad_detallada

  create_table "subpartida", :force => true do |t|
    t.string   "nombre"
    t.integer  "proyecto_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "numero"
    t.integer  "agente_id"
    t.integer  "partida_id"
  end unless table_exists? :subpartida

  create_table "subtipo_movimiento", :force => true do |t|
    t.string   "nombre"
    t.string   "descripcion"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tipo_asociado"
  end unless table_exists? :subtipo_movimiento

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
  end unless table_exists? :tarea

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
  end unless table_exists? :tasa_cambio

  create_table "tipo_cuota_socio", :force => true do |t|
    t.string  "tipo_cuota"
    t.integer "meses",      :default => 1
  end unless table_exists? :tipo_cuota_socio

  create_table "tipo_tarea", :force => true do |t|
    t.string   "nombre"
    t.text     "descripcion"
    t.boolean  "tipo_proyecto"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tipo_agente",   :default => false
  end unless table_exists? :tipo_tarea

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
  end unless table_exists? :transferencia

  create_table "transferencia_x_agente", :force => true do |t|
    t.integer  "transferencia_id"
    t.integer  "agente_id"
    t.decimal  "importe",          :precision => 24, :scale => 2, :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :transferencia_x_agente

  create_table "transferencia_x_documento", :force => true do |t|
    t.integer  "transferencia_id"
    t.integer  "documento_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :transferencia_x_documento

  create_table "usuario", :force => true do |t|
    t.string  "nombre"
    t.string  "contrasena"
    t.string  "nombre_completo"
    t.string  "correoe"
    t.boolean "administracion"
    t.boolean "proyectos"
    t.boolean "agentes"
    t.boolean "cuadromando"
    t.boolean "socios"
    t.boolean "documentos"
  end unless table_exists? :usuario

  create_table "usuario_x_agente", :force => true do |t|
    t.integer "usuario_id"
    t.integer "agente_id"
  end unless table_exists? :usuario_x_agente

  create_table "usuario_x_espacio", :force => true do |t|
    t.integer  "espacio_id"
    t.integer  "usuario_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :usuario_x_espacio

  create_table "usuario_x_libro", :force => true do |t|
    t.integer "libro_id"
    t.integer "usuario_id"
  end unless table_exists? :usuario_x_libro

  create_table "usuario_x_proyecto", :force => true do |t|
    t.integer "usuario_id"
    t.integer "proyecto_id"
    t.string  "rol"
    t.boolean "notificar",   :default => true
  end unless table_exists? :usuario_x_proyecto

  create_table "valor_intermedio_x_actividad", :force => true do |t|
    t.integer  "actividad_x_etapa_id"
    t.date     "fecha"
    t.decimal  "porcentaje",           :precision => 5, :scale => 4
    t.boolean  "realizada",                                          :default => false
    t.text     "comentario"
    t.integer  "usuario_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :valor_intermedio_x_actividad

  create_table "valor_intermedio_x_indicador", :force => true do |t|
    t.integer  "indicador_id"
    t.date     "fecha"
    t.decimal  "porcentaje",   :precision => 5, :scale => 4
    t.string   "comentario"
    t.integer  "usuario_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :valor_intermedio_x_indicador

  create_table "valor_intermedio_x_subactividad", :force => true do |t|
    t.integer  "subactividad_id"
    t.date     "fecha"
    t.decimal  "porcentaje",      :precision => 5, :scale => 4
    t.text     "estado"
    t.string   "comentario"
    t.integer  "usuario_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :valor_intermedio_x_subactividad

  create_table "valor_variable_indicador", :force => true do |t|
    t.decimal  "valor",                 :precision => 24, :scale => 4, :null => false
    t.date     "fecha",                                                :null => false
    t.text     "comentario"
    t.integer  "variable_indicador_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end unless table_exists? :valor_variable_indicador

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
  end unless table_exists? :variable_indicador

 end

 def down
 end
end

