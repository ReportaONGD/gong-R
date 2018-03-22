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
# estado

class Estado < ActiveRecord::Base
  #untranslate_all
  belongs_to :definicion_estado
  belongs_to :proyecto
  belongs_to :financiacion
  belongs_to :usuario

  # Comprobamos cambio de estado en proyectos
  validates_presence_of :proyecto_id, message: _("Proyecto") + " " + _("no puede estar vacío.")
  validate :verificar_proyecto_aprobado
  validate :verificar_condiciones_estado_plugins
  validate :verificar_cierre_proyecto_tareas
  validate :verificar_documentacion
  after_save :aplicar_remanentes_cierre_pac
  after_save :guardar_fechas_aprobadas_originales
  after_create :asignar_tareas_estado

 private

  # Asigna las tareas asociadas al estado de workflow correspondiente
  # si fuera posible, le asigna tambien las fechas de inicio y fin
  # correspondientes a la ejecucion o la justificacion
  def asignar_tareas_estado
    definicion_estado.definicion_estado_tarea.each do |tarea|
      fecha_inicio = fecha_fin = nil
      # Si tenemos tipo de tarea definido, miramos como asignar las fechas indicadas
      if (tipo_tarea = tarea.tipo_tarea)
        # Para los tipos de tarea de seguimiento (economico o tecnico)
        if tipo_tarea.seguimiento_economico || tipo_tarea.seguimiento_tecnico
          fecha_inicio = proyecto.fecha_inicio_actividades
          fecha_fin = proyecto.fecha_fin_actividades
        # Para los tipos de tarea de justificacion, buscamos la fecha del periodo
        elsif tipo_tarea.justificacion
          fecha_inicio = proyecto.fecha_inicio_justificacion
          fecha_fin = proyecto.fecha_fin_justificacion
        end
      end
      tarea_proyecto = Tarea.find_by_definicion_estado_tarea_id_and_proyecto_id( tarea.id, proyecto.id ) ||
                       Tarea.new( definicion_estado_tarea_id: tarea.id, proyecto_id: proyecto.id,
                                  descripcion: tarea.descripcion, tipo_tarea_id: tarea.tipo_tarea_id )
      texto_comentario = tarea_proyecto.id ? _("Tarea actualizada por cambio a estado '%s'")%[definicion_estado.nombre] :
                                             _("Tarea creada por cambio a estado '%s'")%[definicion_estado.nombre]
      tarea_proyecto.update_attributes titulo: tarea.titulo, estado_tarea_id: tarea.estado_tarea_id,
                                       fecha_inicio: fecha_inicio, fecha_fin: fecha_fin
      Comentario.create(texto: texto_comentario, elemento_type: "Tarea", elemento_id: tarea_proyecto.id, sistema: true) if tarea_proyecto.errors.empty?
    end
  end

  # Comprueba que se cumplen las condiciones para la aprobacion del proyecto
  def verificar_proyecto_aprobado
    # Cuando el estado actual es aprobado...
    if self.proyecto && self.estado_actual && self.definicion_estado.aprobado
      # valida que exista la cuenta de recepción de la subvencion
      if GorConfig.getValue(:VALIDATE_GRANT_ACCOUNT_ON_APPROVED_PROJECT) == "TRUE" && self.proyecto.libro_principal.nil?
        errors.add("proyecto", _("El proyecto no tiene definida cuenta de recepción de la Subvención."))
      end

      # valida que el proyecto tenga un periodo de justificacion final aprobado
      if GorConfig.getValue(:VALIDATE_REPORTING_PERIOD_ON_APPROVED_PROJECT) == "TRUE"
        if proyecto.periodo.where(periodo_cerrado: true).
                            joins(:tipo_periodo).
                            where("tipo_periodo.grupo_tipo_periodo" => "final").empty?
          errors.add("proyecto", _("El proyecto no tiene un Periodo de Justificación aprobado para el Informe Final."))
          errors.add("proyecto", "<a href='/proyectos/#{proyecto_id}/configuracion/datos_proyecto/etapas'>" +
                                     _("Definir Periodo de Justificación.") + "</a>")
        end
      end

      # Valida los porcentajes de sector, area y poblacion del proyecto
      proyecto.valida_porcentajes_relaciones
      unless proyecto.errors.empty?
        # Muestra los mensajes de error
        proyecto.errors.full_messages.each{|error| errors.add("proyecto", error) }
        errors.add("proyecto", "<a href='/proyectos/#{proyecto_id}/configuracion/datos_proyecto/relaciones'>" +
                                   _("Corregir porcentajes.") + "</a>")
        # Y limpia la cola de mensajes
        proyecto.errors.clear
      end

      # valida que la matriz tenga objetivo general, objetivos específicos y actividades definidas
      if GorConfig.getValue(:VALIDATE_MATRIX_ON_APPROVED_PROJECT) == "TRUE"
        errores_matriz = self.proyecto.objetivo_general.nil? || self.proyecto.objetivo_especifico.blank? || self.proyecto.actividad.blank?
        if errores_matriz
          errors.add("proyecto", "<br>" + _("Hay errores en la matriz del proyecto:"))
          errors.add("proyecto", _("El proyecto no tiene definido Objetivo General.")) if self.proyecto.objetivo_general.nil?
          errors.add("proyecto", _("El proyecto no tiene definido ningún Objetivo Específico.")) if self.proyecto.objetivo_especifico.blank?
          errors.add("proyecto", _("El proyecto no tiene ninguna Actividad definida.")) if self.proyecto.actividad.blank?
          errors.add("proyecto", _("Para corregirlo vaya a:") +
                     " <a href='/proyectos/#{proyecto_id}/formulacion/matriz'>" + _("Matriz") + "</a>")
        end
      end

      # valida cada una de las lineas de presupuesto para determinar si hay errores
      # en el desglose por financiadores, actividades o detalle mensual
      if GorConfig.getValue(:VALIDATE_BUDGET_ON_APPROVED_PROJECT) == "TRUE"
        proyecto.valida_presupuesto
        unless proyecto.errors.empty?
          errors.add("presupuesto", "<br>" + _("Hay %{num} errores en el Presupuesto del proyecto:")%{num: proyecto.errors.count})
          proyecto.errors.full_messages.each{|error| errors.add("presupuesto", error) }
          errors.add("presupuesto", _("Para corregirlo vaya a:") +
                     " <a href='/proyectos/#{proyecto_id}/formulacion/presupuesto_proyectos'>" + _("Presupuesto") + "</a>")
        end
      end
    end

    return self.errors.empty?
  end

  # Comprueba las condiciones de paso del estado para plugins
  def verificar_condiciones_estado_plugins
    # Revisa las condiciones de cambio de los plugins (si las hubiera)
    Plugin.activos.each do |plugin|
      begin
        eval(plugin.clase + "::Estado").verificar_condiciones_estado self
      rescue => ex 
      end
    end
    return self.errors.empty?
  end

  # Comprueba si es un cierre del proyecto y si tiene tareas activas
  def verificar_cierre_proyecto_tareas
    # OJO: Errores en los logs del tipo:
    # NoMethodError (undefined method `activo' for nil:NilClass):
    #   app/models/estado.rb:54:in `block in verificar_cierre_proyecto_tareas'
    #   app/models/estado.rb:54:in `verificar_cierre_proyecto_tareas'
    #   app/controllers/estado_controller.rb:69:in `modificar_estado'
    #
    if self.estado_actual and self.definicion_estado.cerrado and proyecto.tarea.find{|t| t.estado_tarea.nil? || t.estado_tarea.activo}
      texto = [ _("No se puede cambiar el proyecto a un estado de tipo “cerrado” hasta haber finalizado todas las tareas del proyecto."),
                _("Para cerrar las tareas vaya a:") + " <a href='/proyectos/#{proyecto_id}/resumen/tarea'>" + _("tareas del proyecto") + "</a>" ]
      errors.add("proyecto", texto.join("<br><br>"))
    end
  end
  # Comprobamos que todas la documentacion-etiquetada definida para pasar de estado esta en el proyecto
  def verificar_documentacion
    if self.estado_actual
      todas_etiquetas = Array.new
      for documento in proyecto.documento
        todas_etiquetas << documento.etiqueta
      end
      todas_etiquetas = todas_etiquetas.flatten
      unless (definicion_estado.etiqueta - todas_etiquetas).empty?
        mensaje = _("No se puede cambiar de estado. Compruebe que tiene los documentos necesarios y que están adecuadamente etiquetados.") + " "
        mensaje << _("Los documentos etiquetados necesarios para cambiar el estado actual son:") + "    "
        mensaje << definicion_estado.etiqueta.inject("") {|todo, a| todo + '  "' + a.nombre + '"   ' }
        errors.add("proyecto", mensaje)
      end
    end
  end

  # Almacena las fechas aprobadas originales la primera vez que pasa a estado "aprobado"
  def guardar_fechas_aprobadas_originales
    if proyecto && self.estado_actual && self.definicion_estado.aprobado
      proyecto.update_column(:fecha_inicio_aprobada_original, proyecto.fecha_de_inicio) if proyecto.fecha_inicio_aprobada_original.blank?
      proyecto.update_column(:fecha_fin_aprobada_original, proyecto.fecha_de_fin) if proyecto.fecha_fin_aprobada_original.blank?
    end
  end

  # Comprueba si es un cierre de un pac y aplica remanentes al siguiente
  def aplicar_remanentes_cierre_pac
    # Si es el estado actual y es cerrado...
    if self.estado_actual && self.definicion_estado.cerrado
      # Para pacs, aplica remanentes sobre el pac siguiente
      self.proyecto.pac_siguiente.aplica_remanentes if self.proyecto.pac_siguiente
    end
  end

end
