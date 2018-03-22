CREATE TABLE `actividad` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `proyecto_id` int(11) DEFAULT NULL,
  `resultado_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `actividad_convenio_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_actividad_on_id` (`id`),
  KEY `index_actividad_on_codigo` (`codigo`),
  KEY `index_actividad_on_proyecto_id` (`proyecto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `actividad_detallada` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `mes` int(11) DEFAULT NULL,
  `etapa_id` int(11) DEFAULT NULL,
  `actividad_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `seguimiento` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `actividad_x_etapa` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `actividad_id` int(11) DEFAULT NULL,
  `etapa_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_actividad_x_etapa_on_id` (`id`),
  KEY `index_actividad_x_etapa_on_actividad_id` (`actividad_id`),
  KEY `index_actividad_x_etapa_on_etapa_id` (`etapa_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `actividad_x_etiqueta_tecnica` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `actividad_id` int(11) DEFAULT NULL,
  `etiqueta_tecnica_id` int(11) DEFAULT NULL,
  `porcentaje` decimal(5,4) DEFAULT '0.0000',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `actividad_x_pais` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `actividad_id` int(11) DEFAULT NULL,
  `pais_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `agente` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `nombre_completo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `financiador` tinyint(1) DEFAULT '0',
  `implementador` tinyint(1) DEFAULT '0',
  `moneda_id` int(11) DEFAULT NULL,
  `moneda_intermedia_id` int(11) DEFAULT NULL,
  `pais_id` int(11) DEFAULT NULL,
  `socia_local` tinyint(1) DEFAULT '0',
  `sistema` tinyint(1) DEFAULT '0',
  `publico` tinyint(1) DEFAULT '0',
  `local` tinyint(1) DEFAULT NULL,
  `nif` varchar(255) COLLATE utf8_unicode_ci DEFAULT '',
  `tipo_agente_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_agente_on_id` (`id`),
  UNIQUE KEY `index_agente_on_nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `agente_x_moneda` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `moneda_id` int(11) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `area_actuacion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `categoria_area_actuacion_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `area_geografica` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `campo_tipo_contrato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tipo_contrato_id` int(11) NOT NULL,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `etiqueta` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tipo_campo` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'boolean',
  `tipo_condicion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `valor_condicion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_campo_tipo_contrato_on_id` (`id`),
  KEY `index_campo_tipo_contrato_on_tipo_contrato_id` (`tipo_contrato_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `categoria_area_actuacion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `categoria_sector_intervencion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `comentario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) DEFAULT NULL,
  `texto` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `elemento_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `elemento_id` int(11) NOT NULL,
  `sistema` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_comentario_on_elemento_type_and_elemento_id` (`elemento_type`,`elemento_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `comunidad` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `provincia_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `contrato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `importe` decimal(24,2) NOT NULL,
  `moneda_id` int(11) NOT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `observaciones` text COLLATE utf8_unicode_ci,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `agente_id` int(11) NOT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `proveedor_id` int(11) DEFAULT NULL,
  `marcado_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `objetivo` text COLLATE utf8_unicode_ci,
  `justificacion` text COLLATE utf8_unicode_ci,
  `tipo_contrato_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_contrato_on_id` (`id`),
  KEY `index_contrato_on_agente_id` (`agente_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `contrato_x_actividad` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contrato_id` int(11) NOT NULL,
  `actividad_id` int(11) NOT NULL,
  `importe` decimal(24,2) NOT NULL DEFAULT '0.00',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_contrato_x_actividad_on_contrato_id` (`contrato_id`),
  KEY `index_contrato_x_actividad_on_actividad_id` (`actividad_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `contrato_x_campo_tipo_contrato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `campo_tipo_contrato_id` int(11) NOT NULL,
  `contrato_id` int(11) NOT NULL,
  `valor_dato` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `contrato_x_documento` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `estado_contrato_id` int(11) NOT NULL,
  `documento_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_contrato_x_documento_on_id` (`id`),
  KEY `index_contrato_x_documento_on_estado_contrato_id` (`estado_contrato_id`),
  KEY `index_contrato_x_documento_on_documento_id` (`documento_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `contrato_x_financiador` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contrato_id` int(11) NOT NULL,
  `agente_id` int(11) NOT NULL,
  `importe` decimal(24,2) NOT NULL DEFAULT '0.00',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_contrato_x_financiador_ids` (`contrato_id`,`agente_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `convocatoria` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `observaciones` text COLLATE utf8_unicode_ci,
  `agente_id` int(11) NOT NULL,
  `fecha_publicacion` date DEFAULT NULL,
  `fecha_presentacion` date DEFAULT NULL,
  `fecha_resolucion` date DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `tipo_convocatoria_id` int(11) DEFAULT NULL,
  `cerrado` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_convocatoria_on_agente_id` (`agente_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `convocatoria_x_pais` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `convocatoria_id` int(11) NOT NULL,
  `pais_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_convocatoria_x_pais_on_convocatoria_id_and_pais_id` (`convocatoria_id`,`pais_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `cuenta_contable` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `elemento_contable_id` int(11) DEFAULT NULL,
  `elemento_contable_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `observaciones` text COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `centro_coste` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_cuenta_contable_on_agente_id_and_codigo` (`agente_id`,`codigo`),
  KEY `idx_cuenta_contable_elemento` (`elemento_contable_id`,`elemento_contable_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `dato_texto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dato` text COLLATE utf8_unicode_ci,
  `proyecto_id` int(11) DEFAULT NULL,
  `definicion_dato_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `datos_proyecto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proyecto_id` int(11) DEFAULT NULL,
  `beneficiarios_directos_hombres` int(11) DEFAULT '0',
  `beneficiarios_directos_mujeres` int(11) DEFAULT '0',
  `beneficiarios_indirectos_hombres` int(11) DEFAULT '0',
  `beneficiarios_indirectos_mujeres` int(11) DEFAULT '0',
  `beneficiarios_directos_sin_especificar` int(11) DEFAULT '0',
  `beneficiarios_indirectos_sin_especificar` int(11) DEFAULT '0',
  `poblacion_total_de_la_zona` int(11) DEFAULT '0',
  `pais_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_datos_proyecto_pais` (`proyecto_id`,`pais_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `datos_tarjeta_socio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `informacion_socio_id` int(11) DEFAULT NULL,
  `tipo_tarjeta` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `numero_tarjeta` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fecha_caducidad` date DEFAULT NULL,
  `numero_verificacion` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `definicion_dato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rotulo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tipo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rango` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `grupo_dato_dinamico_id` int(11) DEFAULT NULL,
  `asignar_proyecto` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `definicion_estado` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `estado_padre_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `primer_estado` tinyint(1) NOT NULL DEFAULT '0',
  `formulacion` tinyint(1) NOT NULL DEFAULT '0',
  `aprobado` tinyint(1) NOT NULL DEFAULT '0',
  `cerrado` tinyint(1) NOT NULL DEFAULT '0',
  `orden` int(11) NOT NULL DEFAULT '0',
  `reporte` tinyint(1) NOT NULL DEFAULT '0',
  `ejecucion` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `definicion_estado_tarea` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `titulo` text COLLATE utf8_unicode_ci,
  `descripcion` text COLLATE utf8_unicode_ci,
  `tipo_tarea_id` int(11) DEFAULT NULL,
  `estado_tarea_id` int(11) DEFAULT NULL,
  `definicion_estado_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `definicion_estado_x_definicion_estado` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `definicion_estado_padre_id` int(11) DEFAULT NULL,
  `definicion_estado_hijo_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `definicion_estado_x_etiqueta` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `definicion_estado_id` int(11) DEFAULT NULL,
  `etiqueta_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `documento` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `adjunto_file_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `adjunto_content_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `adjunto_file_size` int(11) DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `tipo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `usuario_id` int(11) DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `adjunto_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `documento_x_espacio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `espacio_id` int(11) DEFAULT NULL,
  `documento_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `empleado` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `activo` tinyint(1) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `empleado_salario_hora` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `empleado_id` int(11) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `salario_hora` decimal(24,4) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `espacio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` text COLLATE utf8_unicode_ci,
  `descripcion` text COLLATE utf8_unicode_ci,
  `espacio_padre_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `definicion_espacio_proyecto` tinyint(1) DEFAULT NULL,
  `definicion_espacio_proyecto_id` int(11) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `definicion_espacio_agente` tinyint(1) DEFAULT NULL,
  `definicion_espacio_agente_id` int(11) DEFAULT NULL,
  `ocultar` tinyint(1) DEFAULT NULL,
  `modificable` tinyint(1) DEFAULT '1',
  `definicion_espacio_financiador` tinyint(1) DEFAULT '0',
  `definicion_espacio_financiador_id` int(11) DEFAULT NULL,
  `pais_id` int(11) DEFAULT NULL,
  `definicion_espacio_pais` tinyint(1) DEFAULT '0',
  `definicion_espacio_pais_id` int(11) DEFAULT NULL,
  `definicion_espacio_socia` tinyint(1) DEFAULT '0',
  `definicion_espacio_socia_id` int(11) DEFAULT NULL,
  `espacio_contratos` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `estado` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `definicion_estado_id` int(11) DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `observacion` text COLLATE utf8_unicode_ci,
  `usuario_id` int(11) DEFAULT NULL,
  `estado_actual` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_estado_on_definicion_estado_id` (`definicion_estado_id`),
  KEY `index_estado_definicion_estado_proyecto` (`proyecto_id`,`estado_actual`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `estado_contrato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `workflow_contrato_id` int(11) NOT NULL,
  `contrato_id` int(11) NOT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `observaciones` text COLLATE utf8_unicode_ci,
  `usuario_id` int(11) NOT NULL,
  `estado_actual` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_estado_contrato_on_contrato_id` (`contrato_id`),
  KEY `index_estado_contrato_on_workflow_contrato_id` (`workflow_contrato_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `estado_tarea` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `activo` tinyint(1) DEFAULT NULL,
  `seleccionable` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `etapa` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `cerrada` tinyint(1) DEFAULT '0',
  `saldos_transferidos` tinyint(1) DEFAULT '0',
  `importe_previsto_subvencion` decimal(24,2) DEFAULT '0.00',
  `presupuestable` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_etapa_on_id` (`id`),
  KEY `index_etapa_on_nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `etiqueta` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `tipo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `etiqueta_tecnica` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `etiqueta_x_documento` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `etiqueta_id` int(11) NOT NULL,
  `documento_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `forma_pago_socio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `forma_pago` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `fuente_verificacion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `indicador_id` int(11) DEFAULT NULL,
  `objetivo_especifico_id` int(11) DEFAULT NULL,
  `resultado_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `completada` tinyint(1) DEFAULT '0',
  `fuente_verificacion_convenio_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `fuente_verificacion_x_documento` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fuente_verificacion_id` int(11) DEFAULT NULL,
  `documento_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `gasto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `importe` decimal(24,2) DEFAULT NULL,
  `impuestos` decimal(24,2) DEFAULT '0.00',
  `partida_id` int(11) DEFAULT NULL,
  `moneda_id` int(11) DEFAULT NULL,
  `observaciones` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `numero_factura` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fecha` date DEFAULT NULL,
  `concepto` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fecha_informe` date DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `proyecto_origen_id` int(11) DEFAULT NULL,
  `marcado_id` int(11) DEFAULT NULL,
  `subpartida_agente_id` int(11) DEFAULT NULL,
  `agente_tasa_cambio_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `orden_factura_agente` int(11) DEFAULT NULL,
  `marcado_agente_id` int(11) DEFAULT NULL,
  `pais_id` int(11) DEFAULT NULL,
  `es_valorizado` tinyint(1) NOT NULL DEFAULT '0',
  `ref_contable` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `proveedor_id` int(11) DEFAULT NULL,
  `orden_factura_proyecto` int(11) DEFAULT NULL,
  `empleado_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_orden_factura_proyecto` (`proyecto_origen_id`,`agente_id`),
  KEY `idx_gasto_ref_contable` (`agente_id`,`ref_contable`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `gasto_x_actividad` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gasto_id` int(11) DEFAULT NULL,
  `actividad_id` int(11) DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `importe` decimal(24,2) DEFAULT '0.00',
  PRIMARY KEY (`id`),
  KEY `index_gxact_proyecto_gasto_actividad` (`proyecto_id`,`gasto_id`,`actividad_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `gasto_x_agente` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `agente_id` int(11) DEFAULT NULL,
  `gasto_id` int(11) DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `importe` decimal(24,2) DEFAULT '0.00',
  PRIMARY KEY (`id`),
  KEY `index_gxagt_gasto_proyecto_agente` (`gasto_id`,`proyecto_id`,`agente_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `gasto_x_contrato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contrato_id` int(11) NOT NULL,
  `gasto_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_gasto_x_contrato_on_contrato_id_and_gasto_id` (`contrato_id`,`gasto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `gasto_x_documento` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gasto_id` int(11) DEFAULT NULL,
  `documento_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `gasto_x_proyecto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proyecto_id` int(11) DEFAULT NULL,
  `gasto_id` int(11) DEFAULT NULL,
  `orden_factura` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `subpartida_id` int(11) DEFAULT NULL,
  `importe` decimal(24,2) DEFAULT '0.00',
  `tasa_cambio_id` int(11) DEFAULT NULL,
  `marcado_proyecto_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_gasto_x_proyecto_on_gasto_id_and_proyecto_id` (`gasto_id`,`proyecto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `gasto_x_transferencia` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gasto_id` int(11) DEFAULT NULL,
  `transferencia_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `gor_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `index_gor_config_on_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `grupo_dato_dinamico` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rango` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `seguimiento` tinyint(1) DEFAULT '0',
  `cierre` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `grupo_usuario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `ocultar_proyecto` tinyint(1) NOT NULL DEFAULT '0',
  `asignar_proyecto_rol_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `grupo_usuario_x_agente` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `grupo_usuario_id` int(11) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `rol_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_grupo_x_agente` (`grupo_usuario_id`,`agente_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `grupo_usuario_x_espacio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `grupo_usuario_id` int(11) DEFAULT NULL,
  `espacio_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_grupo_x_espacio` (`grupo_usuario_id`,`espacio_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `grupo_usuario_x_libro` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `grupo_usuario_id` int(11) DEFAULT NULL,
  `libro_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_grupo_x_libro` (`grupo_usuario_id`,`libro_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `grupo_usuario_x_proyecto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `grupo_usuario_id` int(11) DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `rol_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_grupo_x_proyecto` (`grupo_usuario_id`,`proyecto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `hipotesis` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `descripcion` text COLLATE utf8_unicode_ci,
  `objetivo_especifico_id` int(11) DEFAULT NULL,
  `resultado_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `indicador` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `objetivo_especifico_id` int(11) DEFAULT NULL,
  `resultado_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `indicador_convenio_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `indicador_general` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `codigo` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `unidad` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_indicador_general_on_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `indicador_general_x_programa_marco` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `programa_marco_id` int(11) NOT NULL,
  `indicador_general_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `igxpm_idx` (`programa_marco_id`,`indicador_general_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `indicador_general_x_proyecto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proyecto_id` int(11) NOT NULL,
  `indicador_general_id` int(11) NOT NULL,
  `herramienta_medicion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fuente_informacion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contexto` text COLLATE utf8_unicode_ci,
  `valor_base_id` int(11) DEFAULT NULL,
  `valor_objetivo_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `igxp_idx` (`proyecto_id`,`indicador_general_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `informacion_socio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `socio_id` int(11) DEFAULT NULL,
  `fecha_alta` date DEFAULT NULL,
  `fecha_baja` date DEFAULT NULL,
  `fecha_alta_sistema` date DEFAULT NULL,
  `importe_cuota` decimal(24,2) DEFAULT '0.00',
  `calendario_pagos` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `motivo_baja` text COLLATE utf8_unicode_ci,
  `enviar_periodica` tinyint(1) DEFAULT NULL,
  `enviar_puntual` tinyint(1) DEFAULT NULL,
  `enviar_182` tinyint(1) DEFAULT NULL,
  `fecha_carta_bienvenida` date DEFAULT NULL,
  `fecha_envio_documentacion` date DEFAULT NULL,
  `fecha_envio_carne` date DEFAULT NULL,
  `origen_socio_id` int(11) DEFAULT '1',
  `comentario_origen_socio` text COLLATE utf8_unicode_ci,
  `forma_pago_socio_id` int(11) DEFAULT '1',
  `activo` tinyint(1) DEFAULT NULL,
  `tipo_cuota_socio_id` int(11) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `ingreso` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `importe` decimal(24,2) NOT NULL,
  `moneda_id` int(11) NOT NULL,
  `concepto` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `observaciones` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `partida_ingreso_id` int(11) NOT NULL,
  `fecha` date NOT NULL,
  `marcado_id` int(11) DEFAULT NULL,
  `tasa_cambio_id` int(11) DEFAULT NULL,
  `agente_id` int(11) NOT NULL,
  `numero_documento` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `proveedor_id` int(11) DEFAULT NULL,
  `financiador_id` int(11) DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `ref_contable` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `es_valorizado` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_ingreso_on_id` (`id`),
  KEY `index_ingreso_on_agente_id` (`agente_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `item_contrato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contrato_id` int(11) NOT NULL,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `cantidad` int(11) NOT NULL,
  `coste_unitario` decimal(24,2) NOT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_item_contrato_on_contrato_id` (`contrato_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `libro` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `moneda_id` int(11) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `cuenta` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tipo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pais_id` int(11) DEFAULT NULL,
  `iban` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `swift` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bloqueado` tinyint(1) DEFAULT '0',
  `oculto` tinyint(1) DEFAULT '0',
  `entidad` varchar(255) COLLATE utf8_unicode_ci DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `libro_x_proyecto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `libro_id` int(11) DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `log_contabilidad` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `agente_id` int(11) NOT NULL,
  `usuario_id` int(11) DEFAULT NULL,
  `elemento` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `finalizado_ok` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `running` tinyint(1) NOT NULL DEFAULT '0',
  `partial_execution` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_log_contabilidad_on_agente_id` (`agente_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `marcado` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` text COLLATE utf8_unicode_ci,
  `descripcion` text COLLATE utf8_unicode_ci,
  `color` text COLLATE utf8_unicode_ci,
  `primer_estado` tinyint(1) DEFAULT NULL,
  `marcado_padre_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `automatico` tinyint(1) DEFAULT '0',
  `error` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `moneda` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `abreviatura` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `moneda_x_pais` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `moneda_id` int(11) DEFAULT NULL,
  `pais_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `municipio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `comunidad_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `naturaleza_socio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `naturaleza` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `oauth_access_grants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `resource_owner_id` int(11) NOT NULL,
  `application_id` int(11) NOT NULL,
  `token` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `expires_in` int(11) NOT NULL,
  `redirect_uri` text COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `scopes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_oauth_access_grants_on_token` (`token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `oauth_access_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `resource_owner_id` int(11) DEFAULT NULL,
  `application_id` int(11) DEFAULT NULL,
  `token` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `refresh_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `expires_in` int(11) DEFAULT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `scopes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_oauth_access_tokens_on_token` (`token`),
  UNIQUE KEY `index_oauth_access_tokens_on_refresh_token` (`refresh_token`),
  KEY `index_oauth_access_tokens_on_resource_owner_id` (`resource_owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `oauth_applications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `uid` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `secret` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `redirect_uri` text COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_oauth_applications_on_uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `objetivo_especifico` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `proyecto_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `objetivo_general` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `descripcion` text COLLATE utf8_unicode_ci,
  `proyecto_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `origen_socio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `origen` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `pago` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `importe` decimal(24,2) DEFAULT '0.00',
  `fecha` date DEFAULT NULL,
  `gasto_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `libro_id` int(11) DEFAULT NULL,
  `observaciones` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `forma_pago` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `referencia_pago` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ref_contable` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_pago_on_gasto_id` (`gasto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `pago_socio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `concepto` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fecha_emision` date DEFAULT NULL,
  `fecha_pago` date DEFAULT NULL,
  `importe` decimal(24,2) DEFAULT '0.00',
  `comentario` text COLLATE utf8_unicode_ci,
  `fecha_alta_sistema` date DEFAULT NULL,
  `socio_id` int(11) DEFAULT NULL,
  `forma_pago_socio_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `pais` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `area_geografica_id` int(11) DEFAULT NULL,
  `codigo` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `partida` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `codigo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tipo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ocultar_agente` tinyint(1) DEFAULT NULL,
  `ocultar_proyecto` tinyint(1) NOT NULL DEFAULT '0',
  `tipo_empleado` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_partida_on_id` (`id`),
  UNIQUE KEY `index_partida_on_codigo` (`codigo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `partida_financiacion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `codigo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `tipo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `puede_ser_padre` tinyint(1) DEFAULT NULL,
  `partida_financiacion_id` int(11) DEFAULT NULL,
  `padre` tinyint(1) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `porcentaje_maximo` decimal(5,4) DEFAULT '0.0000',
  `importe` decimal(24,2) DEFAULT '0.00',
  PRIMARY KEY (`id`),
  KEY `index_partida_financiacion_on_proyecto_id` (`proyecto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `partida_financiacion_x_partida_financiacion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `partida_padre_id` int(11) DEFAULT NULL,
  `partida_hijo_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `partida_ingreso` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `presupuestable` tinyint(1) NOT NULL DEFAULT '1',
  `proyecto` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_partida_ingreso_on_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `partida_x_partida_financiacion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `partida_financiacion_id` int(11) DEFAULT NULL,
  `partida_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_partidas_x_financiacion` (`partida_id`,`partida_financiacion_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `periodo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tipo_periodo_id` int(11) NOT NULL,
  `proyecto_id` int(11) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `gastos_cerrados` tinyint(1) NOT NULL DEFAULT '0',
  `fecha_informe` date DEFAULT NULL,
  `periodo_cerrado` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_periodo_on_id_and_tipo_periodo_id_and_proyecto_id` (`id`,`tipo_periodo_id`,`proyecto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `periodo_contrato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contrato_id` int(11) NOT NULL,
  `importe` decimal(24,2) NOT NULL DEFAULT '0.00',
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_periodo_contrato_on_id` (`id`),
  KEY `index_periodo_contrato_on_contrato_id` (`contrato_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `permiso_x_rol` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rol_id` int(11) NOT NULL,
  `menu` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `controlador` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `ver` tinyint(1) NOT NULL DEFAULT '1',
  `cambiar` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `personal` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proyecto_id` int(11) NOT NULL,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `tipo_personal_id` int(11) NOT NULL,
  `categoria` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `residencia` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tipo_contrato` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `horas_imputadas` int(11) NOT NULL DEFAULT '0',
  `salario_mensual` float NOT NULL DEFAULT '0',
  `meses` float NOT NULL DEFAULT '0',
  `salario_total` float NOT NULL DEFAULT '0',
  `moneda_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_personal_on_id_and_proyecto_id_and_tipo_personal_id` (`id`,`proyecto_id`,`tipo_personal_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `plugin` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `codigo` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `clase` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '0.0.0',
  `peso` int(11) NOT NULL DEFAULT '10',
  `disponible` tinyint(1) NOT NULL DEFAULT '1',
  `activo` tinyint(1) NOT NULL DEFAULT '0',
  `engine` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_plugin_on_id` (`id`),
  KEY `index_plugin_on_clase` (`clase`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `presupuesto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `importe` decimal(24,2) DEFAULT NULL,
  `concepto` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `observaciones` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `partida_id` int(11) DEFAULT NULL,
  `moneda_id` int(11) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `libro_id` int(11) DEFAULT NULL,
  `coste_unitario` decimal(24,2) DEFAULT NULL,
  `numero_unidades` decimal(24,2) DEFAULT NULL,
  `subpartida_id` int(11) DEFAULT NULL,
  `unidad` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `etapa_id` int(11) DEFAULT NULL,
  `marcado_id` int(11) DEFAULT NULL,
  `tasa_cambio_id` int(11) DEFAULT NULL,
  `pais_id` int(11) DEFAULT NULL,
  `empleado_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_presupuesto_on_id` (`id`),
  KEY `index_presupuesto_on_agente_id` (`agente_id`),
  KEY `index_presupuesto_on_libro_id` (`libro_id`),
  KEY `index_presupuesto_on_moneda_id` (`moneda_id`),
  KEY `index_presupuesto_on_partida_id` (`partida_id`),
  KEY `index_presupuesto_on_proyecto_id` (`proyecto_id`),
  KEY `index_presupuesto_on_tasa_cambio_id` (`tasa_cambio_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `presupuesto_detallado` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `presupuesto_id` int(11) DEFAULT NULL,
  `importe` decimal(24,2) DEFAULT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `mes` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_presupuesto_detallado_on_id` (`id`),
  KEY `index_presupuesto_detallado_on_presupuesto_id` (`presupuesto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `presupuesto_ingreso` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `importe` decimal(24,2) NOT NULL,
  `porcentaje` decimal(12,11) NOT NULL DEFAULT '0.00000000000',
  `concepto` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `observaciones` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `partida_ingreso_id` int(11) NOT NULL,
  `moneda_id` int(11) NOT NULL,
  `etapa_id` int(11) NOT NULL,
  `marcado_id` int(11) DEFAULT NULL,
  `tasa_cambio_id` int(11) DEFAULT NULL,
  `agente_id` int(11) NOT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `financiador_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_presupuesto_ingreso_on_id` (`id`),
  KEY `index_presupuesto_ingreso_on_agente_id` (`agente_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `presupuesto_ingreso_detallado` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `presupuesto_ingreso_id` int(11) NOT NULL,
  `importe` decimal(24,2) NOT NULL DEFAULT '0.00',
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `mes` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_presupuesto_ingreso_detallado_on_id` (`id`),
  KEY `index_presupuesto_ingreso_detallado_on_presupuesto_ingreso_id` (`presupuesto_ingreso_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `presupuesto_x_actividad` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `presupuesto_id` int(11) DEFAULT NULL,
  `actividad_id` int(11) DEFAULT NULL,
  `importe` decimal(24,2) DEFAULT NULL,
  `numero_unidades` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_presupuesto_x_actividad_on_id` (`id`),
  KEY `index_presupuesto_x_actividad_on_actividad_id` (`actividad_id`),
  KEY `index_presupuesto_x_actividad_on_presupuesto_id` (`presupuesto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `presupuesto_x_agente` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `agente_id` int(11) DEFAULT NULL,
  `presupuesto_id` int(11) DEFAULT NULL,
  `importe` decimal(24,2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_presupuesto_x_agente_on_agente_id` (`agente_id`),
  KEY `index_presupuesto_x_agente_on_presupuesto_id` (`presupuesto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `presupuesto_x_proyecto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `presupuesto_id` int(11) DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `importe` decimal(24,2) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `programa_marco` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `objetivo_general` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `moneda_id` int(11) NOT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `proveedor` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `nif` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `observaciones` text COLLATE utf8_unicode_ci,
  `agente_id` int(11) NOT NULL,
  `pais_id` int(11) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `entidad_bancaria` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cuenta_bancaria` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_proveedor_on_id` (`id`),
  KEY `index_proveedor_on_agente_id` (`agente_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `provincia` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pais_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `proyecto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `titulo` text COLLATE utf8_unicode_ci,
  `moneda_id` int(11) DEFAULT NULL,
  `moneda_intermedia_id` int(11) DEFAULT NULL,
  `convenio_id` int(11) DEFAULT NULL,
  `convenio_accion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `libro_id` int(11) DEFAULT NULL,
  `pais_principal_id` int(11) DEFAULT NULL,
  `importe_previsto_total` decimal(24,2) DEFAULT '0.00',
  `importe_previsto_subvencion` decimal(24,2) DEFAULT '0.00',
  `convocatoria_id` int(11) NOT NULL,
  `gestor_id` int(11) DEFAULT NULL,
  `identificador_financiador` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `fecha_limite_peticion_prorroga` date DEFAULT NULL,
  `fecha_inicio_aviso_peticion_prorroga` date DEFAULT NULL,
  `ocultar_gastos_otras_delegaciones` tinyint(1) NOT NULL DEFAULT '0',
  `fecha_limite_peticion_prorroga_justificacion` date DEFAULT NULL,
  `fecha_inicio_aviso_peticion_prorroga_justificacion` date DEFAULT NULL,
  `fecha_inicio_aprobada_original` date DEFAULT NULL,
  `fecha_fin_aprobada_original` date DEFAULT NULL,
  `programa_marco_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_proyecto_on_id` (`id`),
  UNIQUE KEY `index_proyecto_on_nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `proyecto_x_area_actuacion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proyecto_id` int(11) DEFAULT NULL,
  `area_actuacion_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `porcentaje` decimal(5,4) DEFAULT '0.0000',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `proyecto_x_definicion_dato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proyecto_id` int(11) DEFAULT NULL,
  `definicion_dato_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `proyecto_x_financiador` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `agente_id` int(11) DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_proyecto_x_financiador_on_agente_id` (`agente_id`),
  KEY `index_proyecto_x_financiador_on_proyecto_id` (`proyecto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `proyecto_x_implementador` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `agente_id` int(11) DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_proyecto_x_implementador_on_agente_id` (`agente_id`),
  KEY `index_proyecto_x_implementador_on_proyecto_id` (`proyecto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `proyecto_x_moneda` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proyecto_id` int(11) DEFAULT NULL,
  `moneda_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_proyecto_x_moneda_on_moneda_id` (`moneda_id`),
  KEY `index_proyecto_x_moneda_on_proyecto_id` (`proyecto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `proyecto_x_pais` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proyecto_id` int(11) DEFAULT NULL,
  `pais_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `proyecto_x_proyecto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proyecto_id` int(11) DEFAULT NULL,
  `proyecto_cofinanciador_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `importe` decimal(24,2) DEFAULT '0.00',
  `financiacion_privada` tinyint(1) DEFAULT '0',
  `financiacion_publica` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_pxp_proyecto_cofinanciador` (`proyecto_id`,`proyecto_cofinanciador_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `proyecto_x_sector_intervencion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proyecto_id` int(11) DEFAULT NULL,
  `sector_intervencion_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `porcentaje` decimal(5,4) DEFAULT '0.0000',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `proyecto_x_sector_poblacion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proyecto_id` int(11) DEFAULT NULL,
  `sector_poblacion_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `porcentaje` decimal(5,4) DEFAULT '0.0000',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `resultado` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `proyecto_id` int(11) DEFAULT NULL,
  `objetivo_especifico_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `rol` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `seccion` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `admin` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `sector_intervencion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `categoria_sector_intervencion_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `sector_poblacion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `data` text COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `simple_captcha_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  `value` varchar(6) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `socio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `apellido1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `apellido2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tratamiento` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `NIF` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `NIF_representante` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sexo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fecha_nacimiento` date DEFAULT NULL,
  `direccion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `localidad` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `codigo_postal` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `provincia` varchar(255) COLLATE utf8_unicode_ci DEFAULT '',
  `comunidad` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `municipio` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `codigo_provincia_fiscal` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pais` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `telefono_fijo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `telefono_movil` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `comentarios` text COLLATE utf8_unicode_ci,
  `naturaleza_socio_id` int(11) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `subactividad` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `actividad_id` int(11) DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `responsables_ejecucion` text COLLATE utf8_unicode_ci,
  `descripcion_detallada` text COLLATE utf8_unicode_ci,
  `comentarios_ejecucion` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `subactividad_detallada` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `mes` int(11) DEFAULT NULL,
  `etapa_id` int(11) DEFAULT NULL,
  `subactividad_id` int(11) DEFAULT NULL,
  `seguimiento` tinyint(1) DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `subpartida` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `numero` int(11) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `partida_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `subtipo_movimiento` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `tipo_asociado` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `tarea` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `titulo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `tipo_tarea_id` int(11) DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `usuario_id` int(11) DEFAULT NULL,
  `usuario_asignado_id` int(11) DEFAULT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `porcentage_implementacion` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `estado_tarea_id` int(11) DEFAULT NULL,
  `fecha_prevista` date DEFAULT NULL,
  `horas_empleadas` int(11) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `periodo_id` int(11) DEFAULT NULL,
  `definicion_estado_tarea_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `tasa_cambio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `etapa_id` int(11) DEFAULT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `tasa_fija` tinyint(1) DEFAULT '1',
  `objeto` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'presupuesto',
  `moneda_id` int(11) DEFAULT NULL,
  `tasa_cambio` decimal(15,8) DEFAULT NULL,
  `tasa_cambio_divisa` decimal(15,8) DEFAULT '0.00000000',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `pais_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_tasa_cambio_pais_moneda` (`etapa_id`,`moneda_id`,`pais_id`,`objeto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `tipo_agente` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_tipo_agente_on_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `tipo_contrato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `observaciones` text COLLATE utf8_unicode_ci,
  `duracion` int(11) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_tipo_contrato_on_id` (`id`),
  KEY `index_tipo_contrato_on_agente_id` (`agente_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `tipo_contrato_x_documento` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tipo_contrato_id` int(11) NOT NULL,
  `documento_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_tipo_contrato_x_documento_ids` (`tipo_contrato_id`,`documento_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `tipo_convocatoria` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_tipo_convocatoria_on_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `tipo_cuota_socio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tipo_cuota` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `meses` int(11) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `tipo_periodo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `oficial` tinyint(1) DEFAULT '0',
  `no_borrable` tinyint(1) DEFAULT '0',
  `grupo_tipo_periodo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_tipo_periodo_on_id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `tipo_personal` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_tipo_personal_on_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `tipo_tarea` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descripcion` text COLLATE utf8_unicode_ci,
  `tipo_proyecto` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `tipo_agente` tinyint(1) DEFAULT '0',
  `administracion` tinyint(1) DEFAULT '0',
  `configuracion` tinyint(1) DEFAULT '0',
  `formulacion_economica` tinyint(1) DEFAULT '0',
  `formulacion_tecnica` tinyint(1) DEFAULT '0',
  `seguimiento_economico` tinyint(1) DEFAULT '0',
  `seguimiento_tecnico` tinyint(1) DEFAULT '0',
  `justificacion` tinyint(1) DEFAULT '0',
  `dias_aviso_finalizacion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `transferencia` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proyecto_id` int(11) DEFAULT NULL,
  `observaciones` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `iban` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tasa_cambio` decimal(15,8) DEFAULT '0.00000000',
  `tipo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `numero_cheque` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `remanente` tinyint(1) DEFAULT '0',
  `subtipo_movimiento_id` int(11) DEFAULT NULL,
  `fecha_enviado` date DEFAULT NULL,
  `importe_enviado` decimal(24,2) DEFAULT NULL,
  `libro_origen_id` int(11) DEFAULT NULL,
  `fecha_recibido` date DEFAULT NULL,
  `importe_recibido` decimal(24,2) DEFAULT NULL,
  `importe_cambiado` decimal(24,2) DEFAULT NULL,
  `libro_destino_id` int(11) DEFAULT NULL,
  `ref_contable_enviado` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ref_contable_recibido` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `marcado_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `transferencia_x_agente` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `transferencia_id` int(11) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `importe` decimal(24,2) DEFAULT '0.00',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `transferencia_x_documento` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `transferencia_id` int(11) DEFAULT NULL,
  `documento_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `usuario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contrasena` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `nombre_completo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `correoe` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `administracion` tinyint(1) DEFAULT NULL,
  `proyectos` tinyint(1) DEFAULT NULL,
  `agentes` tinyint(1) DEFAULT NULL,
  `cuadromando` tinyint(1) DEFAULT NULL,
  `socios` tinyint(1) DEFAULT NULL,
  `documentos` tinyint(1) DEFAULT NULL,
  `informes_aecid` tinyint(1) NOT NULL DEFAULT '0',
  `external_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bloqueado` tinyint(1) NOT NULL DEFAULT '0',
  `agente_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `skype_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `programas_marco` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `usuario_x_agente` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) DEFAULT NULL,
  `agente_id` int(11) DEFAULT NULL,
  `grupo_usuario_id` int(11) DEFAULT NULL,
  `rol_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `usuario_x_espacio` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `espacio_id` int(11) DEFAULT NULL,
  `usuario_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `grupo_usuario_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `usuario_x_grupo_usuario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) DEFAULT NULL,
  `grupo_usuario_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_usuario_x_grupo` (`usuario_id`,`grupo_usuario_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `usuario_x_libro` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `libro_id` int(11) DEFAULT NULL,
  `usuario_id` int(11) DEFAULT NULL,
  `grupo_usuario_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `usuario_x_proyecto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) DEFAULT NULL,
  `proyecto_id` int(11) DEFAULT NULL,
  `notificar_comentario` tinyint(1) DEFAULT NULL,
  `grupo_usuario_id` int(11) DEFAULT NULL,
  `rol_id` int(11) NOT NULL,
  `notificar_estado` tinyint(1) DEFAULT NULL,
  `notificar_usuario` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_usuario_x_proyecto_on_usuario_id_and_proyecto_id` (`usuario_id`,`proyecto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `valor_intermedio_x_actividad` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `actividad_x_etapa_id` int(11) DEFAULT NULL,
  `fecha` date DEFAULT NULL,
  `porcentaje` decimal(5,4) DEFAULT NULL,
  `realizada` tinyint(1) DEFAULT '0',
  `comentario` text COLLATE utf8_unicode_ci,
  `usuario_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `valor_intermedio_x_indicador` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `indicador_id` int(11) DEFAULT NULL,
  `fecha` date DEFAULT NULL,
  `porcentaje` decimal(5,4) DEFAULT NULL,
  `comentario` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usuario_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `valor_intermedio_x_subactividad` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `subactividad_id` int(11) DEFAULT NULL,
  `fecha` date DEFAULT NULL,
  `porcentaje` decimal(5,4) DEFAULT NULL,
  `estado` text COLLATE utf8_unicode_ci,
  `comentario` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usuario_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `valor_variable_indicador` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `valor` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `fecha` date NOT NULL,
  `comentario` text COLLATE utf8_unicode_ci,
  `variable_indicador_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `valor_x_indicador_general` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `indicador_general_x_proyecto_id` int(11) DEFAULT NULL,
  `fecha` date NOT NULL,
  `valor` int(11) NOT NULL DEFAULT '0',
  `comentario` text COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `vxig_idx` (`indicador_general_x_proyecto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `variable_indicador` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `herramienta_medicion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fuente_informacion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contexto` text COLLATE utf8_unicode_ci,
  `indicador_id` int(11) NOT NULL,
  `valor_base_id` int(11) DEFAULT NULL,
  `valor_objetivo_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `version_contrato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contrato_id` int(11) NOT NULL,
  `estado_contrato_id` int(11) NOT NULL,
  `importe` decimal(24,2) NOT NULL,
  `moneda_id` int(11) NOT NULL,
  `observaciones` text COLLATE utf8_unicode_ci,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_version_contrato_on_id` (`id`),
  KEY `index_version_contrato_on_contrato_id` (`contrato_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `workflow_contrato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255) COLLATE utf8_unicode_ci DEFAULT '0',
  `descripcion` text COLLATE utf8_unicode_ci,
  `primer_estado` tinyint(1) NOT NULL DEFAULT '0',
  `formulacion` tinyint(1) NOT NULL DEFAULT '0',
  `aprobado` tinyint(1) NOT NULL DEFAULT '0',
  `cerrado` tinyint(1) NOT NULL DEFAULT '0',
  `orden` int(11) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `ejecucion` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_workflow_contrato_on_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `workflow_contrato_x_etiqueta` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `workflow_contrato_id` int(11) NOT NULL,
  `etiqueta_id` int(11) NOT NULL,
  `agente_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `workflow_contrato_x_workflow_contrato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `workflow_contrato_padre_id` int(11) NOT NULL,
  `workflow_contrato_hijo_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `wf_contrato_x_wf_contrato_padre_id` (`workflow_contrato_padre_id`),
  KEY `wf_contrato_x_wf_contrato_hijo_id` (`workflow_contrato_hijo_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO schema_migrations (version) VALUES ('20131106155231');

INSERT INTO schema_migrations (version) VALUES ('20131111092904');

INSERT INTO schema_migrations (version) VALUES ('20131112171546');

INSERT INTO schema_migrations (version) VALUES ('20131115085807');

INSERT INTO schema_migrations (version) VALUES ('20131204082846');

INSERT INTO schema_migrations (version) VALUES ('20140131100046');

INSERT INTO schema_migrations (version) VALUES ('20140207143006');

INSERT INTO schema_migrations (version) VALUES ('20140210105049');

INSERT INTO schema_migrations (version) VALUES ('20140210120156');

INSERT INTO schema_migrations (version) VALUES ('20140210173455');

INSERT INTO schema_migrations (version) VALUES ('20140211115944');

INSERT INTO schema_migrations (version) VALUES ('20140220182014');

INSERT INTO schema_migrations (version) VALUES ('20140220193937');

INSERT INTO schema_migrations (version) VALUES ('20140227134158');

INSERT INTO schema_migrations (version) VALUES ('20140303164043');

INSERT INTO schema_migrations (version) VALUES ('20140303190730');

INSERT INTO schema_migrations (version) VALUES ('20140321093105');

INSERT INTO schema_migrations (version) VALUES ('20140411083712');

INSERT INTO schema_migrations (version) VALUES ('20140423141145');

INSERT INTO schema_migrations (version) VALUES ('20140604091511');

INSERT INTO schema_migrations (version) VALUES ('20140612114114');

INSERT INTO schema_migrations (version) VALUES ('20140620152232');

INSERT INTO schema_migrations (version) VALUES ('20140626164857');

INSERT INTO schema_migrations (version) VALUES ('20140701172814');

INSERT INTO schema_migrations (version) VALUES ('20140701200218');

INSERT INTO schema_migrations (version) VALUES ('20140703135044');

INSERT INTO schema_migrations (version) VALUES ('20140703144133');

INSERT INTO schema_migrations (version) VALUES ('20140709113319');

INSERT INTO schema_migrations (version) VALUES ('20140710163936');

INSERT INTO schema_migrations (version) VALUES ('20140717145912');

INSERT INTO schema_migrations (version) VALUES ('20140722180315');

INSERT INTO schema_migrations (version) VALUES ('20140728113009');

INSERT INTO schema_migrations (version) VALUES ('20140804213520');

INSERT INTO schema_migrations (version) VALUES ('20140807133921');

INSERT INTO schema_migrations (version) VALUES ('20140828084233');

INSERT INTO schema_migrations (version) VALUES ('20140901145135');

INSERT INTO schema_migrations (version) VALUES ('20140905154049');

INSERT INTO schema_migrations (version) VALUES ('20140919144004');

INSERT INTO schema_migrations (version) VALUES ('20140923112643');

INSERT INTO schema_migrations (version) VALUES ('20140923125648');

INSERT INTO schema_migrations (version) VALUES ('20141013155836');

INSERT INTO schema_migrations (version) VALUES ('20141020131716');

INSERT INTO schema_migrations (version) VALUES ('20141112151632');

INSERT INTO schema_migrations (version) VALUES ('20141126125608');

INSERT INTO schema_migrations (version) VALUES ('20141210101940');

INSERT INTO schema_migrations (version) VALUES ('20150209101547');

INSERT INTO schema_migrations (version) VALUES ('20150218105529');

INSERT INTO schema_migrations (version) VALUES ('20150219095438');

INSERT INTO schema_migrations (version) VALUES ('20150223100000');

INSERT INTO schema_migrations (version) VALUES ('20150223100051');

INSERT INTO schema_migrations (version) VALUES ('20150223105251');

INSERT INTO schema_migrations (version) VALUES ('20150226115725');

INSERT INTO schema_migrations (version) VALUES ('20150302164929');

INSERT INTO schema_migrations (version) VALUES ('20150306094802');

INSERT INTO schema_migrations (version) VALUES ('20150507115019');

INSERT INTO schema_migrations (version) VALUES ('20150518155950');

INSERT INTO schema_migrations (version) VALUES ('20150519104626');

INSERT INTO schema_migrations (version) VALUES ('20150616091046');

INSERT INTO schema_migrations (version) VALUES ('20150617080920');

INSERT INTO schema_migrations (version) VALUES ('20150618084124');

INSERT INTO schema_migrations (version) VALUES ('20150625101836');

INSERT INTO schema_migrations (version) VALUES ('20150626130258');

INSERT INTO schema_migrations (version) VALUES ('20150915135519');

INSERT INTO schema_migrations (version) VALUES ('20150916092045');

INSERT INTO schema_migrations (version) VALUES ('20150916141944');

INSERT INTO schema_migrations (version) VALUES ('20150928110406');

INSERT INTO schema_migrations (version) VALUES ('20151006083648');

INSERT INTO schema_migrations (version) VALUES ('20151006142116');

INSERT INTO schema_migrations (version) VALUES ('20151007084334');

INSERT INTO schema_migrations (version) VALUES ('20151007153221');

INSERT INTO schema_migrations (version) VALUES ('20151028171441');

INSERT INTO schema_migrations (version) VALUES ('20151104154328');

INSERT INTO schema_migrations (version) VALUES ('20151119140221');

INSERT INTO schema_migrations (version) VALUES ('20151127132600');

INSERT INTO schema_migrations (version) VALUES ('20151130120236');

INSERT INTO schema_migrations (version) VALUES ('20151210121943');

INSERT INTO schema_migrations (version) VALUES ('20151221092445');

INSERT INTO schema_migrations (version) VALUES ('20160120190257');

INSERT INTO schema_migrations (version) VALUES ('20160129094044');

INSERT INTO schema_migrations (version) VALUES ('20160209104013');

INSERT INTO schema_migrations (version) VALUES ('20160209121802');

INSERT INTO schema_migrations (version) VALUES ('20160307091757');

INSERT INTO schema_migrations (version) VALUES ('20160331104922');

INSERT INTO schema_migrations (version) VALUES ('20160412085245');

INSERT INTO schema_migrations (version) VALUES ('20160412153257');

INSERT INTO schema_migrations (version) VALUES ('20160413152515');

INSERT INTO schema_migrations (version) VALUES ('20160414104933');

INSERT INTO schema_migrations (version) VALUES ('20160527114046');

INSERT INTO schema_migrations (version) VALUES ('20160614163224');

INSERT INTO schema_migrations (version) VALUES ('20160615103650');

INSERT INTO schema_migrations (version) VALUES ('20160616101613');

INSERT INTO schema_migrations (version) VALUES ('20161004150215');

INSERT INTO schema_migrations (version) VALUES ('20161006134015');

INSERT INTO schema_migrations (version) VALUES ('20161006145105');

INSERT INTO schema_migrations (version) VALUES ('20161013101104');

INSERT INTO schema_migrations (version) VALUES ('20161025104350');

INSERT INTO schema_migrations (version) VALUES ('20161026125439');

INSERT INTO schema_migrations (version) VALUES ('20161117124254');

INSERT INTO schema_migrations (version) VALUES ('20161125115941');

INSERT INTO schema_migrations (version) VALUES ('20161128095735');

INSERT INTO schema_migrations (version) VALUES ('20161128163956');

INSERT INTO schema_migrations (version) VALUES ('20161216101513');

INSERT INTO schema_migrations (version) VALUES ('20161216142216');

INSERT INTO schema_migrations (version) VALUES ('20161219111000');

INSERT INTO schema_migrations (version) VALUES ('20161220122458');

INSERT INTO schema_migrations (version) VALUES ('20170109102717');

INSERT INTO schema_migrations (version) VALUES ('20170119145311');

INSERT INTO schema_migrations (version) VALUES ('20170131104938');

INSERT INTO schema_migrations (version) VALUES ('20170213092202');

INSERT INTO schema_migrations (version) VALUES ('20170213132509');

INSERT INTO schema_migrations (version) VALUES ('20170228130908');

INSERT INTO schema_migrations (version) VALUES ('20170322074106');

INSERT INTO schema_migrations (version) VALUES ('20170322080802');

INSERT INTO schema_migrations (version) VALUES ('20170323123547');

INSERT INTO schema_migrations (version) VALUES ('20170327092741');

INSERT INTO schema_migrations (version) VALUES ('20170327095906');

INSERT INTO schema_migrations (version) VALUES ('20170419092251');

INSERT INTO schema_migrations (version) VALUES ('20170427144126');

INSERT INTO schema_migrations (version) VALUES ('20170517104844');