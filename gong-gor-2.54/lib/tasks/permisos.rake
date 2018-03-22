# encoding: UTF-8


namespace :permisos do
  desc "Reasigna permisos"
  task :reasigna => :environment do
    puts "\n\n"
    puts "*********************************************"
    puts "********** ASIGNACION DE PERMISOS ***********"
    puts "*********************************************"
    puts ""
    PermisoXRol.destroy_all
    Rake::Task["permisos:asigna"].invoke
  end

  desc "Asigna permisos"
  task :asigna => :environment do
    # Define los roles de usuario por defecto
    # (los roles ya deberian venir generados en la migracion, pero por si en el futuro se consolidan migraciones...)
    if PermisoXRol.count == 0
      # Roles de Proyectos
      r1 = Rol.find_or_create_by_nombre_and_seccion "Usuario", "proyectos"
      r1.update_attributes descripcion: "Usuario técnico y económico del proyecto"
      rol_id = r1.id
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "info", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "tarea", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "resumen_proyecto", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "resumen", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "estado", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "tasa_cambio", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "tarea", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "datos_proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "partida_financiacion", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "subpartida", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "remanente", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "personal", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "exportacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "importacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "identificacion", controlador: "datos_proyecto_dinamicos", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "identificacion", controlador: "datos_proyecto", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "matriz", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "marcado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "cronograma", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "indicador", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "presupuesto_proyectos", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "presupuesto_actividad", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "presupuesto_detallado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "resumen_proyecto", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "exportacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "importacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "cronograma", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "matriz", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "actividad", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "indicador", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "fuente_verificacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "datos_proyecto_dinamicos", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "resumen_proyecto", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "documento", ver: true, cambiar: true 
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "marcado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "gasto_proyectos", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "pago", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "transferencia", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "contrato", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "estado_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "documento", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "exportacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "importacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_proyecto", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_proyecto", controlador: "documento", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_proyecto", controlador: "documento_busqueda", ver: true, cambiar: true
      r2 = Rol.find_or_create_by_nombre_and_seccion "Coordinador", "proyectos"
      r2.update_attributes descripcion: "Coordinador del proyecto", admin: true
      rol_id = r2.id
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "info", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "tarea", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "resumen_proyecto", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "resumen", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "estado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "tasa_cambio", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "tarea", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "datos_proyecto", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "partida_financiacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "subpartida", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "remanente", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "personal", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "exportacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "importacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "identificacion", controlador: "datos_proyecto_dinamicos", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "identificacion", controlador: "datos_proyecto", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "matriz", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "marcado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "cronograma", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "indicador", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "presupuesto_proyectos", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "presupuesto_actividad", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "presupuesto_detallado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "resumen_proyecto", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "exportacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "importacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "cronograma", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "matriz", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "actividad", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "indicador", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "fuente_verificacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "datos_proyecto_dinamicos", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "resumen_proyecto", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "documento", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "marcado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "gasto_proyectos", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "pago", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "transferencia", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "contrato", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "estado_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "documento", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "exportacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "importacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_proyecto", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_proyecto", controlador: "documento", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_proyecto", controlador: "documento_busqueda", ver: true, cambiar: true
      r3 = Rol.find_or_create_by_nombre_and_seccion "Configurador", "proyectos"
      r3.update_attributes descripcion: "Configurador del proyecto"
      rol_id = r3.id
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "info", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "tarea", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "resumen_proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "resumen", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "estado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "tasa_cambio", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "tarea", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "datos_proyecto", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "partida_financiacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "subpartida", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "remanente", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "personal", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "exportacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "importacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "identificacion", controlador: "datos_proyecto_dinamicos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "identificacion", controlador: "datos_proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "matriz", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "comentario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "marcado", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "cronograma", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "indicador", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "presupuesto_proyectos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "presupuesto_actividad", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "presupuesto_detallado", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "resumen_proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "exportacion", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "importacion", ver: false, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "comentario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "cronograma", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "matriz", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "actividad", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "indicador", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "fuente_verificacion", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "datos_proyecto_dinamicos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "resumen_proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "documento", ver: false, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "comentario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "marcado", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "gasto_proyectos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "pago", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "transferencia", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "estado_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "documento", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "exportacion", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "importacion", ver: false, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_proyecto", controlador: "comentario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_proyecto", controlador: "documento", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_proyecto", controlador: "documento_busqueda", ver: true, cambiar: false
      r4 = Rol.find_or_create_by_nombre_and_seccion "Auditor", "proyectos"
      r4.update_attributes  descripcion: "Auditor del proyecto"
      rol_id = r4.id
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "info", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "tarea", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "resumen_proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen", controlador: "resumen", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "estado", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "tasa_cambio", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "tarea", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "datos_proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "partida_financiacion", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "subpartida", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "remanente", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "personal", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "exportacion", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion", controlador: "importacion", ver: false, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "identificacion", controlador: "datos_proyecto_dinamicos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "identificacion", controlador: "datos_proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "matriz", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "comentario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "marcado", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "cronograma", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "indicador", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "presupuesto_proyectos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "presupuesto_actividad", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "presupuesto_detallado", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "resumen_proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "exportacion", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "formulacion", controlador: "importacion", ver: false, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "comentario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "cronograma", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "matriz", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "actividad", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "indicador", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "fuente_verificacion", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "datos_proyecto_dinamicos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "resumen_proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_tecnica", controlador: "documento", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "comentario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "marcado", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "gasto_proyectos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "pago", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "transferencia", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "estado_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "documento", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "exportacion", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "ejecucion_economica", controlador: "importacion", ver: false, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_proyecto", controlador: "comentario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_proyecto", controlador: "documento", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_proyecto", controlador: "documento_busqueda", ver: true, cambiar: false
      # Roles de Agentes
      r5 = Rol.find_or_create_by_nombre_and_seccion "Usuario", "agentes"
      r5.update_attributes  descripcion: "Personal de la delegación"
      rol_id = r5.id
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "info", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "tarea", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen_agente", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen_proyectos_agente", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "convocatoria", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "datos_agente", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "subpartida", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "convocatoria", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "libro", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "proveedor", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "tipo_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "workflow_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "contabilidad", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "usuario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "grupo_usuario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "tasa_cambio", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_ingresos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "ingreso", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "gasto_agentes", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "pago", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "transferencia", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "exportacion", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "importacion", ver: false, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_agentes", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_detallado", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "documento", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "estado_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "documento", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "documento_busqueda", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "contrato", ver: true, cambiar: false
      r6 = Rol.find_or_create_by_nombre_and_seccion "Economico", "agentes"
      r6.update_attributes  descripcion: "Administrador económico de la delegación"
      rol_id = r6.id
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "info", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "tarea", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen_agente", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen_proyectos_agente", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "convocatoria", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "datos_agente", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "subpartida", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "convocatoria", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "proyecto", ver: false, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "libro", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "proveedor", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "tipo_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "workflow_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "contabilidad", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "usuario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "grupo_usuario", ver: true, cambiar: true 
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "tasa_cambio", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "marcado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_ingresos", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "ingreso", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "gasto_agentes", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "pago", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "transferencia", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "contrato", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "exportacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "importacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_agentes", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_detallado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_proyectos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "documento", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "estado_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "documento", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "document_busqueda", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "contrato", ver: true, cambiar: true 
      r7 = Rol.find_or_create_by_nombre_and_seccion "Coordinador", "agentes"
      r7.update_attributes  descripcion: "Coordinador de la delegación", admin: true
      rol_id = r7.id
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "info", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "tarea", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen_agente", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen_proyectos_agente", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "convocatoria", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen_empleados_agente", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "relaciones_usuario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "empleado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "datos_agente", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "subpartida", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "convocatoria", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "proyecto", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "libro", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "proveedor", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "tipo_contrato", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "workflow_contrato", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "contabilidad", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "usuario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "grupo_usuario", ver: true, cambiar: true 
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "tasa_cambio", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_empleado_agentes", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "marcado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_ingresos", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "ingreso", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "gasto_agentes", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "pago", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "transferencia", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "contrato", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "exportacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "importacion", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_agentes", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_detallado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_proyectos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "documento", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "estado_contrato", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "documento", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "documento_busqueda", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "contrato", ver: true, cambiar: true
      r8 = Rol.find_or_create_by_nombre_and_seccion "Auditor", "agentes"
      r8.update_attributes  descripcion: "Auditor de la delegación"
      rol_id = r8.id
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "info", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "tarea", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen_agente", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen_proyectos_agente", ver: true, cambiar: false 
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "convocatoria", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "datos_agente", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "subpartida", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "convocatoria", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "libro", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "proveedor", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "tipo_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "workflow_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "contabilidad", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "usuario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "grupo_usuario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "tasa_cambio", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "comentario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_ingresos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "ingreso", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "gasto_agentes", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "pago", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "transferencia", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "exportacion", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "importacion", ver: false, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_agentes", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_detallado", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "documento", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "estado_contrato", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "comentario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "documento", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "documento_busqueda", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "contrato", ver: true, cambiar: false
      r9 = Rol.find_or_create_by_nombre_and_seccion "Contratos", "agentes"
      r9.update_attributes  descripcion: "Gestor de contratos de la delegación"
      rol_id = r9.id
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "info", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "tarea", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen_agente", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "resumen", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "resumen_agente", controlador: "convocatoria", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "datos_agente", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "subpartida", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "convocatoria", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "proyecto", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "libro", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "proveedor", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "tipo_contrato", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "workflow_contrato", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "contabilidad", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "usuario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "grupo_usuario", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "configuracion_agente", controlador: "tasa_cambio", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "marcado", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_ingresos", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "ingreso", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "gasto_agentes", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "pago", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "transferencia", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "contrato", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "exportacion", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "importacion", ver: false, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "presupuesto_agentes", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "documento", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "economico_agente", controlador: "estado_contrato", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "comentario", ver: true, cambiar: true
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "documento", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "documento_busqueda", ver: true, cambiar: false
      PermisoXRol.create rol_id: rol_id, menu: "documentos_agente", controlador: "contrato", ver: true, cambiar: true
    end

  end
end

