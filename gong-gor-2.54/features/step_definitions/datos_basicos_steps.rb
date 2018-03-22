Dado /^unos datos básicos$/ do
  # Nota: Ojo usar el español aquí parece que no funciona
  steps %Q{
  Given "Africa oriental" es una area geografica con el nombre "Africa oriental"
  And "Controamérica" es una area geografica con el nombre "Centroamérica"
  And "Europa" es una area geografica con el nombre "Europa"
  And "España" es un pais con el nombre "España" y con el area geografica anterior
  And hay una Provincia con el nombre "otro" y el pais anterior
  And hay una Comunidad con el nombre "otro" y la provincia anterior
  And hay un Municipio con el nombre "otro" y la comunidad anterior
  And "Mozambique" es un pais con el nombre "Mozambique" y la area geografica "Africa oriental"
  And "Nicaragua" es un pais con el nombre "Nicaragua" y la area geografica "Centroamérica"
  And "Euro" es una moneda con el nombre "Euro" y la abreviatura "EUR"
  And "Peso" es una moneda con el nombre "Peso" y la abreviatura "PES"
  And hay una moneda con el nombre "Nuevo Metical" y la abreviatura "MZN"
  And hay una partida con el nombre "Consultorio" y el codigo "I" y el tipo "directo"
  And hay una partida con el nombre "Viajes" y el codigo "II" y el tipo "directo"
  And hay una partida con el nombre "Salarios" y el codigo "III" y el tipo "directo"
  And hay una partida con el nombre "Materiales" y el codigo "IV" y el tipo "directo"
  And hay una partida con el nombre "Estructura" y el codigo "V" y el tipo "indirecto"
  And hay un sector poblacion con el nombre "Infancia"
  And hay un sector poblacion con el nombre "Juventud"
  And hay un sector poblacion con el nombre "Mujer"
  And hay una area actuacion con el nombre "Desarrollo rural"
  And hay una area actuacion con el nombre "Genero"
  And hay una area actuacion con el nombre "Salud"
  And hay un sector intervencion con el nombre "Diversificacion produccion rural"
  And hay un sector intervencion con el nombre "Salud infantil"
  And hay un sector intervencion con el nombre "Salud reproductiva"
  And hay un agente con el nombre "AECI" y el nombre completo "Agencia Estatal" y que es financiador y que es implementador
  And hay un agente con el nombre "ONG-INT" y el nombre completo "ONG internacional para el desarrollo" y que es financiador y que no es implementador
  And "SOL" es un agente con el nombre "SOL" y el nombre completo "Solidaridad Internacional" y que es financiador y que es implementador
  And "Actividades" es una etiqueta con el nombre "Actividades"
  And "Contacto" es una etiqueta con el nombre "Contacto"
  And "Financiero" es una etiqueta con el nombre "Financiero"
  And "Identificación" es una etiqueta con el nombre "Identificación"
  And "Presupuesto" es una etiqueta con el nombre "Presupuesto"
  And "Técnico" es una etiqueta con el nombre "Técnico"
  And hay un TipoCuotaSocio con el tipo_cuota "otro"
  And hay un OrigenSocio con el origen "otro"
  And hay un FormaPagoSocio con el forma_pago "otro'
  And hay un NaturalezaSocio con el naturaleza "otro"
  And hay un TipoTarea con el nombre "Proyecto - Revisar documento"
  And hay un TipoTarea con el nombre "Proyecto - Revisar presupuesto"
  And hay un TipoTarea con el nombre "Proyecto - Revisar gasto"
  And hay un TipoTarea con el nombre "Proyecto - Revisar matriz"
  And hay un EstadoTarea con el nombre "cerrada" y la descripcion "Tarea cerrada" y no es activo
  And hay un EstadoTarea con el nombre "en curso" y la descripcion "Tarea en la cual se trabaja actualmente" y es activo
  And hay un EstadoTarea con el nombre "en espera" y la descripcion "Tarea en espera" y es activo
  And hay una DefinicionEstado con el nombre "contacto" y es documento y es tarea y es primer_estado y es datos_proyecto
  }
end

  # And hay un DefinicionEstado con el nombre "contacto" y el tipo "proyecto" y es datos_proyecto y es primer_estado y es documento y es tarea
  # And hay un DefinicionEstado con el nombre "identificacion" y el tipo "proyecto" y es datos_proyecto y es tarea y es documento y es matriz y el estado_padre_id DefinicionEstado.find_by_nombre("contacto").id y no es primer_estado
  # And hay un DefinicionEstado con el nombre "formulación" y el tipo "proyecto" y es datos_proyecto y es tarea y es documento y es matriz y es presupuesto_proyectos y es resumen_proyecto y el estado_padre_id DefinicionEstado.find_by_nombre("identificacion").id y no es primer_estado
  # And hay un DefinicionEstado con el nombre "aprobado" y el tipo "proyecto" y es datos_proyecto y es tarea y es documento y es matriz y es presupuesto_proyectos y es resumen_proyecto y es gasto_proyectos y es transferencia y es resumen_proyecto y es importacion y es exportacion y el estado_padre_id DefinicionEstado.find_by_nombre("formulación").id y no es primer_estado

  # And hay un DefinicionEstado con el nombre "Formulación" y el tipo "financiacion" y es datos_financiacion y es primer_estado y es documento y es tarea y es primer_estado y es datos_financiacion
  # And hay un DefinicionEstado con el nombre "Presentación" y el tipo "financiacion" y es datos_financiacion y es tarea y es documento y es partida_financiacion y es resumen_financiacion y el estado_padre_id DefinicionEstado.find_by_nombre("Formulación").id y no es primer_estado
  # And hay un DefinicionEstado con el nombre "Aprobado" y el tipo "financiacion" y es datos_financiacion y es tarea y es documento y es partida_financiacion y es resumen_financiacion y es tasa_cambio y el estado_padre_id DefinicionEstado.find_by_nombre("Presentación").id y no es primer_estado
