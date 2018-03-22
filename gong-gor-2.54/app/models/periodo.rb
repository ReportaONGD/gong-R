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
class Periodo < ActiveRecord::Base
  belongs_to :tipo_periodo
  belongs_to :proyecto
  has_many :tarea, :dependent => :destroy

  before_destroy :comprobar_estado_proyecto

  validates_presence_of :fecha_inicio, message: _("Fecha inicio") + " " + _("no puede estar vacío.")
  validates_presence_of :fecha_fin, message: _("Fecha fin") + " " + _("no puede estar vacío.")
  # Validamos la fecha de informe solo cuando no sea de prorroga (de ejecucion)
  validates_presence_of :fecha_informe,
                         if: Proc.new{|periodo| periodo.tipo_periodo && periodo.tipo_periodo.grupo_tipo_periodo != "prorroga"},
                         message: _("Fecha informes") + " " + _("no puede estar vacío.")
  
  validates_uniqueness_of :tipo_periodo_id,
                          scope: :proyecto_id,
                          if: Proc.new{|periodo| periodo.tipo_periodo && periodo.tipo_periodo.grupo_tipo_periodo == "final"},
                          message: _("Informe Final repetido.")

  validate :comprobar_estado_proyecto 
  validate :comprobar_fechas
  validate :comprobar_fechas_etapa
  # Modificamos la etapa del proyecto si el periodo es de tipo "prorroga" y se cierra
  after_save :modificar_etapa_proyecto, if: Proc.new { |periodo| periodo.periodo_cerrado && periodo.tipo_periodo && periodo.tipo_periodo.grupo_tipo_periodo == "prorroga" }
  # Actualizamos las tareas del proyecto relacionadas con el periodo
  after_save :actualiza_tareas_proyecto

  def estado_color
    color = ""
    hoy = Date.today
    if fecha_fin && fecha_inicio && fecha_informe
      if hoy > fecha_fin && hoy < fecha_informe
        color = "verde"
      elsif hoy > fecha_informe
        color = "rojo"
      end
    end unless periodo_cerrado
    return color
  end
  
  def estado
     periodo_cerrado ? _("Cerrado/Aceptado") : _("Abierto") 
  end
  
  def estado_cerrado
    estado = "cerrado"
    for tarea in self.tarea
      estado = "abierto" unless tarea.estado_tarea.nil? || tarea.estado_tarea.activo
    end
    return estado == "abierto" ? false : true
  end

  def estado_abierto
    abierto = tarea.empty? 
    tarea.each { |t| abierto = true unless t.estado_tarea && !t.estado_tarea.activo }
    return abierto
  end
  
  def porcentaje_tiempo
    hoy = Date.today
    if hoy < fecha_inicio 
      0
    elsif hoy > fecha_fin
      1
    else
      (hoy - fecha_inicio).to_f / (fecha_fin - fecha_inicio).to_f
    end
  end

  def porcentaje_tiempo_rotulo
    hoy = Date.today
    if hoy < fecha_inicio 
      _("Faltan %{num} días para comenzar") % {:num => (fecha_inicio - hoy).to_i}
    elsif  hoy > fecha_fin 
      _("%{num} días desde su finalización") % {:num => (hoy - fecha_fin).to_i}
    else 
      _("%{num} días restantes") % {:num => (fecha_fin - hoy).to_i}
    end
  end

  def tiempo_al_informe
    ((fecha_informe - Date.today).to_i.to_s + " dias") if fecha_informe
  end

 private

  # Actualiza las tareas de proyecto definidas desde workflow
  def actualiza_tareas_proyecto
    # Si se trata de un periodo de proyecto, y ha la fecha de fin o la aceptacion...
    if proyecto && (fecha_fin_changed? || periodo_cerrado_changed?)
      fecha_de_fin = self.fecha_fin
      # Ajusta los filtros para los periodos relacionados con ejecucion y justificacion final
      case tipo_periodo.grupo_tipo_periodo 
      # Para los periodos de prorroga a la ejecucion...
        when "prorroga"
          # ... buscamos tareas de tipo de tarea "seguimiento_economico" o "seguimiento_tecnico"
          filtro_tipo_tarea = "tipo_tarea.seguimiento_economico IS TRUE OR tipo_tarea.seguimiento_tecnico IS TRUE"
          # Miramos que no sea posterior la fecha de fin del proyecto
          if (ultima_etapa = proyecto.etapa.reorder(:fecha_fin).last)
            fecha_de_fin = ultima_etapa.fecha_fin if ultima_etapa.fecha_fin > fecha_de_fin 
          end
        # Para los periodos de justificacion final y de prorroga de justificacion...
        when "final", "prorroga_justificacion"
          filtro_tipo_tarea = "tipo_tarea.justificacion IS TRUE"
          # Miramos que no existiera un periodo contrario al obtenido, aceptado y con fecha mayor
          grupo_tipo_otro = (tipo_periodo.grupo_tipo_periodo == "final" ? "prorroga_justificacion" : "final")
          if (otro = proyecto.periodo.where(periodo_cerrado: true).
                                      where("fecha_fin > ?", fecha_de_fin).
                                      joins(:tipo_periodo).
                                      where("tipo_periodo.grupo_tipo_periodo" => grupo_tipo_otro).
                                      reorder(:fecha_fin).last)
            fecha_de_fin = otro.fecha_fin
          end
      end 
      # Si tenemos alguno de los tipos de periodo aceptados (ejecucion, justificacion),
      # buscamos las tareas y las modificamos
      if filtro_tipo_tarea
        # Buscamos las tareas con fecha de fin distinta
        proyecto.tarea.where("tarea.fecha_fin != ?", fecha_de_fin).
                       joins(:estado_tarea).
                       where("estado_tarea.activo" => true).
                       joins(:tipo_tarea).
                       where(filtro_tipo_tarea).
                       joins(definicion_estado_tarea: :definicion_estado).
                       where("definicion_estado.id IS NOT NULL").readonly(false).each do |tarea|
          tarea.update_attribute(:fecha_fin, fecha_de_fin)
          Comentario.create(texto: _("Tarea actualizada por cambio en periodo '%s'")%[tipo_periodo.nombre],
                            elemento_type: "Tarea",
                            elemento_id: tarea.id, sistema: true) if tarea.errors.empty?
        end
      end
    end
  end

  # Modifica la fecha de fin de la ultima etapa del proyectos si el periodo es de tipo "prorroga"
  def modificar_etapa_proyecto
    if GorConfig::getValue("UPDATE_STAGE_ENDING_DATE_WHEN_EXTENSION_IS_APPROVED") == "TRUE"
      texto_modificacion = _("Fecha de finalización modificada por Prórroga Aprobada")
      # Averigua la ultima etapa del proyecto y la modifica
      etapa = proyecto.etapa.order(:fecha_fin).last
      # Guardamos recortando la descripcion por si se pasa de longitud
      etapa.update_attributes(fecha_fin: fecha_fin, descripcion: ((etapa.descripcion||"") + " (" + texto_modificacion + ")").slice(0,254) ) if etapa && fecha_fin
    end
  end

  # Comprueba que las fechas del periodo sean coherentes entre si
  def comprobar_fechas
    # Primero comprobamos que existen fechas que comprobar. Si no hubiese fechas ya hay comrpobaciones que impiden guardar.
    if fecha_inicio && fecha_fin
      if fecha_fin < fecha_inicio
        # Comprueba que la fecha de inicio sea anterior a la de fin
        errors.add("fecha_fin", _("Fecha fin tiene que ser mayor que fecha inicio"))
      elsif fecha_informe && fecha_informe < fecha_fin
        # Comprueba que la fecha de inicio sea anterior a la de fin
        errors.add("fecha_informe", _("La fecha del informe tiene que ser mayor que fecha fin"))
      else 
        errores = false
        # Comprueba que no se solapen fechas (una fecha de inicio de un periodo anterior a la de fin de otro)
        (proyecto.periodo.where(:tipo_periodo_id => self.tipo_periodo_id) - [self]).each do |p|
          # Simplificamos ese lio de fechas
          #errores = true unless (self.fecha_inicio < p.fecha_inicio && self.fecha_fin < p.fecha_inicio) ||
          #                      (self.fecha_inicio > p.fecha_fin && self.fecha_fin > p.fecha_fin)
          errores = (self.fecha_inicio < p.fecha_fin && self.fecha_fin > p.fecha_inicio) 
        end
        errors[:base] << _("El periodo no puede solaparse con otro periodo del mismo tipo") if errores
      end
    end
    return errors.nil?
  end
  
  # Compruba la coherencia de las fechas respecto a las etapas del proyecto. SEgun el tipo de periodo
  def comprobar_fechas_etapa
    # Primero comprobamos que existen fechas que comprobar. Si no hubiese fechas ya hay comrpobaciones que impiden guardar.
    if fecha_inicio && fecha_fin
      if tipo_periodo.grupo_tipo_periodo == "seguimiento" && (proyecto.fecha_de_inicio > fecha_inicio || proyecto.fecha_de_fin < fecha_inicio)
        errors[:base] <<  _("Los periodos de seguimiento deben estar dentro de las etapas del proyecto") 
      end
    end
  end
  

  def comprobar_estado_proyecto
    # Impide la creacion si no hay estado actual
    if id.nil? && !proyecto.estado_actual
      errors.add("Estado", _("El proyecto no tiene asignado ningún estado todavía.")+ _("No se pueden modificar los periodos.") )
    # O el borrado y modificacion si el proyecto esta cerrado
    elsif proyecto.estado_actual && proyecto.estado_actual.definicion_estado && proyecto.estado_actual.definicion_estado.cerrado
      errors.add("Estado", _("El proyecto se encuentra en estado '%{estado}'.")%{:estado => proyecto.estado_actual.definicion_estado.nombre} + _("No se pueden modificar los periodos.") )
    end
    return errors.empty? 
  end

end
