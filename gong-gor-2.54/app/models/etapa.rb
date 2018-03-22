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
# etapa

class Etapa < ActiveRecord::Base

  before_destroy :verificar_borrado

  belongs_to :proyecto
  belongs_to :agente
  has_many :actividad_x_etapa
  has_many :actividad, :through => :actividad_x_etapa, :order => :codigo
  has_many :presupuesto
  has_many :presupuesto_ingreso, :dependent => :destroy
  has_many :tasa_cambio, :dependent => :destroy

  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  #validates_presence_of [:fecha_inicio, :fecha_fin], :message => _("Nombre") + " " + _("no pueden estar vacío.")
  validates_uniqueness_of :nombre, :scope => [:proyecto_id, :agente_id], :message => _("Nombre repetido.")
  validates_format_of :fecha_inicio, :with => /\d{4}-\d{1,2}-\d{1,2}/, :on => :create
  validates_format_of :fecha_fin, :with => /\d{4}-\d{1,2}-\d{1,2}/, :on => :create
  validate :comprobar_fechas

  # Antes de guardar convertimos la fecha de fin para que sea el ultimo dia
  #before_save  "self.fecha_fin = (self.fecha_fin >> 1) - 1"

  after_save :actualiza_tasa_cambio_moneda_principal, :actualizar_cronograma_presupuesto, :actualizar_cronograma_actividad, :comprueba_estado_cerrada, :actualiza_tareas_proyecto

  # Actualiza las tareas de proyecto definidas desde workflow
  # que sean de tipo "seguimiento_tecnico" o "seguimiento_economico
  def actualiza_tareas_proyecto
    # Validamos si es un proyecto y ha cambiado la fecha de fin
    if proyecto && fecha_fin_changed?
      fecha_de_fin = proyecto.fecha_fin_actividades
      # Revisa la fecha de todas las tareas "no cerradas" del proyecto
      # con fecha de fin distinta a la calculada, que vengan de una definicion del workflow y
      # que sean de seguimiento tecnico o economico.
      # usamos readonly(false) para poder actualizar los registros
      proyecto.tarea.where("tarea.fecha_fin != ?", fecha_de_fin).
                     joins(:estado_tarea).
                     where("estado_tarea.activo" => true).
                     joins(:tipo_tarea).
                     where("tipo_tarea.seguimiento_economico IS TRUE OR tipo_tarea.seguimiento_tecnico IS TRUE").
                     joins(definicion_estado_tarea: :definicion_estado).
                     where("definicion_estado.id IS NOT NULL").readonly(false).each do |tarea|
        tarea.update_attribute(:fecha_fin, fecha_de_fin)
        Comentario.create(texto: _("Tarea actualizada por cambio en fechas de etapa de ejecución."),
                          elemento_type: "Tarea",
                          elemento_id: tarea.id, sistema: true) if tarea.errors.empty?       
      end
    end
  end

  # Si se abre o se cierra una etapa de agente, actua sobre los remanentes
  def comprueba_estado_cerrada
    if self.agente && self.cerrada_changed?
      # Si ha cerrado, comprueba si los remanentes son correctos
      if self.cerrada
        # Rails3: actualiza presupuestable sin invocar callbacks
        self.update_column(:presupuestable, false)
        todo_transferido = true
        # Realiza el calculo de remanentes
        remanente = self.agente.remanente(self)
        lineas = Array.new
        # Comprueba libro a libro si los remanentes estan correctamente aplicados
        for libro_id in remanente.keys
          l=Libro.find_by_id(libro_id)
          transf = Transferencia.first(:conditions=>{:proyecto_id => nil, :libro_destino_id => libro_id, :remanente => true, :fecha_recibido => self.etapa_siguiente.fecha_inicio})
          saldo = remanente[libro_id][:entrante] - remanente[libro_id][:saliente]
          todo_transferido = false unless (transf.nil? && saldo == 0) || (transf && transf.importe_recibido == saldo)
        end
        # Si todo ha sido transferido, guarda la etapa indicandolo
        # Rails3: actualiza saldos sin invocar callbacks
        self.update_column(:saldos_transferidos, todo_transferido)
      # Si ha abierto, indica que los remanentes no son correctos
      else
        # Rails3: actualiza saldos sin invocar callbacks
        self.update_column(:saldos_transferidos, false)
      end
    end
  end

  # Genera las tasas de cambio para la moneda principal en la etapa
  def actualiza_tasa_cambio_moneda_principal
    objeto = (self.proyecto || self.agente)
    # Si es una etapa nueva o se modifican las fechas, manda actualizar/crear tasas de cambio
    if self.id_was.nil? || self.fecha_inicio_changed? || self.fecha_fin_changed?
      TasaCambio.etapa_cambia_fechas(self)
    end
  end
  # Al cambiar las fechas de una etapa actualizamos todos los presupuestos_detallados de los presupuestos asociados a dicha etapa
  def actualizar_cronograma_presupuesto 
    if self.fecha_inicio_changed? || self.fecha_fin_changed?
      fecha =  Date.new(self.fecha_inicio.year, self.fecha_inicio.month, 1)
      # Actualiza los presupuestos detallados de gastos
      self.presupuesto.each {|ppto| self.corrige_detalle_presupuesto(fecha, ppto.presupuesto_detallado) }
      # Actualiza los presupuestos detallados de ingresos (solo delegaciones)
      self.presupuesto_ingreso.each {|ppto| self.corrige_detalle_presupuesto(fecha, ppto.presupuesto_ingreso_detallado) } if self.agente
    end
  end

  # Al cambiar las fechas de una etapa actualizamos todas las actividad_detalladas de las actividades asociadas a dicha etapa
  def actualizar_cronograma_actividad
    self.actividad.each do |a| 
      a.actividad_detallada.each do |ad|
        (ad.destroy; next) if ad.mes > self.meses #Borramos el detalle cuyo mes sea mayor que el nuevo numero de meses
      end
    end
  end

	# Devuelve el numero de meses enteros que tiene el proyecto
  def meses
    # Calculamos el numero de meses sin contar los dias
    meses = ((self.fecha_fin.month) - self.fecha_inicio.month) + (12 * (self.fecha_fin.year - self.fecha_inicio.year))
    # Si la fecha de inicio es dia 1 y la de fin el final de mes, entonces hay un mes mas (el mes está completo)
    meses += 1 if self.fecha_inicio.day == 1 and (self.fecha_fin + 1.day).day == 1
    return meses
  end
	# Devuelve el numero de periodos mensuales (incluyendo mes no entero) que tiene el proyecto
  def periodos
    return ((self.fecha_fin.month) - self.fecha_inicio.month) + (12 * (self.fecha_fin.year - self.fecha_inicio.year)) + 1
  end

  # Comprueba que las fechas son correctas.
  def comprobar_fechas

    if self.fecha_fin and self.fecha_inicio
      # Comprueba que la fecha de inicio sea anterior a la de fin
      errors.add("fecha_fin", _("Fecha fin tiene que ser mayor que fecha inicio")) if self.fecha_fin <= self.fecha_inicio
      # Comprueba que las fechas no se solapen con otra Etapa
      (self.proyecto || self.agente).etapa.each do |et|
        if et.id != self.id && (
            (self.fecha_inicio >= et.fecha_inicio && self.fecha_inicio <= et.fecha_fin) ||
            (self.fecha_fin >= et.fecha_inicio && self.fecha_fin <= et.fecha_fin) ||
            (self.fecha_inicio <= et.fecha_inicio && self.fecha_fin >= et.fecha_fin) )
          errors.add("fecha", _("Las fechas se solapan con las de otra etapa"))
        end
      end
    else
     errors.add("fecha", _("fecha no puede esta vacio") ) 
    end
    # Para Convenios comprueba que todos los pacs tengan sus etapas dentro del pac. Esto habria que revisarlo
    #self.proyecto.pacs.each do |pac|
    #  unless pac.etapa.empty?
    #    errors.add("fecha", _("Las fechas excluyen las definidas para la PAC") + " '" + pac.nombre + "'") if fecha_inicio > pac.fecha_de_inicio || fecha_fin < pac.fecha_de_fin
    #  end
    #end if self.proyecto
    # Para PACs
    if self.proyecto && self.proyecto.convenio
      # Comprueba que las fechas esten entre las del convenio
      errors.add("fecha", _("Las fechas están fuera del Convenio")) if proyecto.convenio.fecha_de_inicio.nil? || proyecto.convenio.fecha_de_fin.nil? || proyecto.convenio.fecha_de_inicio > fecha_inicio || proyecto.convenio.fecha_de_fin < fecha_fin
      # Comprueba que no haya otra PAC con esas fechas
      proyecto.convenio.pacs.each do |pac|
        unless pac.etapa.empty? || pac == self.proyecto
          errors.add("fecha", _("Las fechas se solapan con las de la PAC") + " '" + pac.nombre + "'") unless fecha_fin < pac.fecha_de_inicio || fecha_inicio > pac.fecha_de_fin 
        end
      end
    end
  end

  def etapa_siguiente
    return (self.proyecto || self.agente).etapa.first(:conditions => ["fecha_inicio > ?",self.fecha_fin], :order => "fecha_inicio")
  end

  def etapa_anterior
    return (self.proyecto || self.agente).etapa.last(:conditions => ["fecha_fin < ?",self.fecha_inicio], :order => "fecha_fin")
  end

 private

  # Se asegura de poder borrar la etapa
  def verificar_borrado
    unless self.presupuesto.empty?
      errors.add("Presupuesto", "<br>" + _("La etapa no se puede borrar. Tiene asociada %{num} presupuestos:")%{:num => self.presupuesto.count})
      pres = self.presupuesto.all(:limit => 5)
      pres.each do |p|
        errors.add("Presupuesto", p.concepto + " / " + p.importe.to_s + " " + p.moneda.abreviatura)
      end
      errors.add("Presupuesto", _("... y %{num} presupuestos más.")%{:num => (self.presupuesto.count - pres.count) }) if (self.presupuesto.count - pres.count) > 0
    end
    unless self.actividad.empty?
      errors.add("Actividad", "<br>" + _("La etapa no se puede borrar. Tiene asociada %{num} actividades:")%{:num => self.actividad.count})
      acts = self.actividad.all(:limit => 5)
      acts.each do |a|
        errors.add("Actividad", a.codigo + " - " + a.descripcion)
      end
      errors.add("Actividad", _("... y %{num} actividades más.")%{:num => (self.actividad.count - acts.count) }) if (self.actividad.count - acts.count) > 0
    end
    return false unless errors.empty?
  end


 protected

  # Actualiza los presupuestos detallados
  def corrige_detalle_presupuesto fecha, presupuestos_detallados=[]
    logger.info "------------------------- CORRIGIENDO PRESUPUESTO DETALLADO (???) para periodos posteriores a la fecha de la etapa."
    presupuestos_detallados.each do |pd|
      (pd.destroy; next) if pd.mes > self.periodos #Borramos el detalle cuyo mes sea mayor que el nuevo numero de meses
      if pd.mes != self.periodos
        fecha_inicial = pd.mes == 1 ? self.fecha_inicio : fecha >> (pd.mes - 1)
        fecha_final =  (fecha >> pd.mes) - 1
        pd.update_attributes(:fecha_inicio => fecha_inicial, :fecha_fin => fecha_final) unless pd.fecha_inicio == fecha_inicial and pd.fecha_fin == fecha_final
      else
        pd.update_attributes :fecha_inicio => (fecha >> (pd.mes - 1)), :fecha_fin => self.fecha_fin
      end
    end
  end

end
