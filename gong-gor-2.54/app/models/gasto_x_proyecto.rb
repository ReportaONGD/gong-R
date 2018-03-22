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
# GastoXProyecto: relaciona gasto con proyecto y el porcentaje de esta relación

class GastoXProyecto < ActiveRecord::Base

  #untranslate_all

  # Metemos la validacion antes para que no se eliminen gxp de proyectos cerrados
  before_destroy :verifica_borrado

  # acts_as_reportable
  belongs_to :gasto
  belongs_to :proyecto
  belongs_to :subpartida
  belongs_to :marcado, :class_name => "Marcado", :foreign_key => "marcado_proyecto_id"
  belongs_to :tasa_cambio_proyecto, :class_name => "TasaCambio", :foreign_key => "tasa_cambio_id"
  # has_many :gasto_x_actividad, :through => :gasto
  # has_many :gasto_x_agente, :through => :gasto

  # Permitimos gasto_x_proyecto vacio para porcentaje de gastos asumidos por delegacion
  #validates_presence_of :proyecto_id, :message => _("Proyecto") + " " + _("no puede estar vacío.")
  #validates_associated :proyecto, :message => _("El proyecto asociado no es correcto.")
  validates_presence_of :gasto_id, :message => _("Gasto") + " " + _("no puede estar vacío.")
  #validates_associated :gasto, :message =>  _("El gasto asociado no es correcto.")
  validates_uniqueness_of :proyecto_id, :scope => :gasto_id, :message => _("Asignación del gasto repetida.")

  validate :comprueba_importe, :comprueba_implementador_proyecto, :verifica_plugins
  validate :comprobar_estado_proyecto, :comprobar_fecha_etapas_proyecto, :comprobar_periodos_proyecto
  after_save :comprueba_transferencia_proyecto_empleado, if: "comprueba_transferencia_proyecto_empleado_configurado?"

  before_save :obtiene_tasa_cambio
  # Este callback es en create para evitar cambiar cosas modificadas o no seguir validaciones de gastos
  after_create :asigna_subpartida_por_defecto

  # Para que los plugins puedan modificar saltandose la validacion "verifica_plugins"
  # OJO!: Siempre que se hagan movimientos en los gastos desde migraciones hay que tener en cuenta esto y
  #       actualizar el gasto incluyendo "evitar_validacion_plugins: true"!
  attr_accessor :evitar_validacion_plugins


  # Comprueba que el proyecto tenga como implementador al implementador del gasto
  def comprueba_implementador_proyecto
    errors.add("proyecto", _("El proyecto '%{proy}' no tiene asignado el implementador del gasto '%{gsto}'")%{proy: proyecto.nombre, gsto: gasto.agente.nombre}) unless gasto.nil? || proyecto.nil? || proyecto.implementador.find_by_id(gasto.agente_id)
    return errors.empty?
  end

  # Comprueba que la fecha del gasto está dentro de alguna etapa del proyecto
  def comprobar_fecha_etapas_proyecto
    # Solo comprobamos si hay proyecto (proyecto_id == nil => imputado al agente)
    # y la configuracion indica que lo comprobemos
    if proyecto && gasto && GorConfig.getValue(:VALIDATE_STAGES_DATES_IN_PROJECT_EXPENSES) == "TRUE"
      # Comprueba que el gasto entre dentro de las fechas de proyecto
      p_fecha_inicio = proyecto.fecha_de_inicio
      p_fecha_fin = proyecto.fecha_de_fin
      unless p_fecha_inicio and p_fecha_fin and gasto.fecha >= p_fecha_inicio and gasto.fecha <= p_fecha_fin
       errors.add("fecha", _("Proyecto '%s' no tiene definidas fechas de comienzo o de fin") % [proyecto.nombre]) unless p_fecha_inicio and p_fecha_fin
       errors.add("fecha", _("La fecha '%s' no esta dentro de las etapas del proyecto '%s'") % [gasto.fecha,proyecto.nombre]) if p_fecha_inicio and p_fecha_fin
      end
    end
    return errors.empty?
  end

  # Comprueba que el proyecto no este cerrado
  def comprobar_estado_proyecto
    # Solo comprobamos si hay proyecto (proyecto_id == nil => imputado al agente) y si este tiene estado
    if proyecto && proyecto.estado_actual
      errors.add(_("Proyecto"),  _("El proyecto '%{proy}' se encuentra en estado '%{est}'.")%{proy: proyecto.nombre, est: proyecto.estado_actual.definicion_estado.nombre} + " " +
                                 _("En este estado no se puede modificar el gasto.")) if proyecto.estado_actual.definicion_estado.cerrado || !proyecto.estado_actual.definicion_estado.ejecucion
    end
    return errors.empty?
  end

  def comprobar_periodos_proyecto
    if proyecto && gasto
      for periodo in proyecto.periodo
        if periodo.gastos_cerrados and (gasto.fecha >= periodo.fecha_inicio and gasto.fecha <= periodo.fecha_fin) 
          texto = _("El periodo '%{per}' (%{inicio} / %{fin}) del proyecto '%{proy}' tiene los gastos cerrados.")%{proy: proyecto.nombre, per: periodo.tipo_periodo.nombre, inicio: periodo.fecha_inicio.to_s , fin: periodo.fecha_fin.to_s }
          errors.add(_("Proyecto"), texto) 
        end
      end
    end
    return false unless self.errors.empty?
  end


  def comprueba_importe
    errors.add("GastoXProyecto", _("El gasto no existe")) if gasto.nil?
    errors.add("GastoXProyecto", _("El gasto por proyecto no puede ser mayor que el total.")) if gasto && importe && importe.round(2) > gasto.importe 
    errors.add("GastoXProyecto", _("El importe vinculado al proyecto no puede estar vacío.")) unless importe
  end

  # Agrupamos la comprobacion de que estan creadas las variables de configuracion que permiten la gestion de transferencias de empleados
  def comprueba_transferencia_proyecto_empleado_configurado?
    nombre_cuenta = GorConfig::getValue('ACCOUNT_FOR_EMPLOYED_PAYMENTS')
     if gasto.empleado_id and nombre_cuenta != "" and  gasto.moneda_id == gasto.agente.moneda_principal.id
      cuenta_empleados, cuenta_sin_proyecto, marcado_automatico, marcado_errores = comprueba_transferencia_proyecto_empleado_configuracion
      return (cuenta_empleados and cuenta_sin_proyecto and  marcado_automatico and marcado_errores)
    else
      return false
    end
  end

  # Agrupamos la busqueda de las variables de configuracion que permite la gestion de transferencias de empleados
  def comprueba_transferencia_proyecto_empleado_configuracion
    cuenta_empleados = Libro.find_by_nombre(GorConfig::getValue('ACCOUNT_FOR_EMPLOYED_PAYMENTS'))
    cuenta_sin_proyecto = Libro.find_by_nombre(GorConfig::getValue('ACCOUNT_FOR_EMPLOYED_PAYMENTS_WITHOUT_PROJECT'))
    marcado_automatico = Marcado.find_by_nombre(GorConfig::getValue('MARKED_FOR_AUTOMATIC_EMPLOYED_PAYMENTS'))
    marcado_errores = Marcado.find_by_nombre(GorConfig::getValue('MARKED_FOR_EMPLOYED_PAYMENTS_ERRORS'))
    return cuenta_empleados, cuenta_sin_proyecto, marcado_automatico, marcado_errores
  end

  # Comprueba si hay transferencias asociadas al pago de nominas, y las crea, o las marca si fuese necesario.
  def comprueba_transferencia_proyecto_empleado
    logger.info "************* Variables: de configuracion ACCOUNT_FOR_EMPLOYED_PAYMENTS,ACCOUNT_FOR_EMPLOYED_PAYMENTS_WITHOUT_PROJECT, MARKED_FOR_AUTOMATIC_EMPLOYED_PAYMENTS, MARKED_FOR_EMPLOYED_PAYMENTS_ERRORS activas.  Se chequea transferencias de proyecto de empleado"
    cuenta_empleados, cuenta_sin_proyecto, marcado_automatico, marcado_error = comprueba_transferencia_proyecto_empleado_configuracion
    inicio = gasto.fecha.at_beginning_of_month
    fin = gasto.fecha.at_end_of_month
    if proyecto
      cuenta_proyecto_id = proyecto.libro_id
      # Si no hay cuenta de proyecto se añade un marcado a gasto y se añade un comentario.
      unless cuenta_proyecto_id
        gasto.update_column :marcado_id, marcado_error.id
        texto = "Error creacion transferencia asociada: No existe cuenta de proyecto #{proyecto.nombre}"
        Comentario.create(texto: texto, elemento_type: "gasto", elemento_id: gasto_id, sistema: true)
        return 
      end
    else
      cuenta_proyecto_id = cuenta_sin_proyecto.id
    end
    transferencias = Transferencia.where libro_origen_id: cuenta_proyecto_id, libro_destino_id: cuenta_empleados.id, 
                                         fecha_enviado: [inicio..fin], tipo: "transferencia"
    # Acciones en funcion de que haya mas de una transferencia asociada al proyecto y al mes.
    if transferencias.count > 1
      texto = "Error: Más de una transferencia de empleados para el proyecto #{proyecto.nombre} en el mes #{inicio.month}" 
      for transferencia in transferencias
        transferencia.update_attribute :marcado_id, marcado_error.id
        Comentario.create(texto: texto, elemento_type: "Transferencia", elemento_id: transferencia.id, sistema: true) 
      end
    else
      # Calculamos todos los gastos que tienen empleado, que estan en el mes y que pertenecen al mismo proyecto que el gasto, y que estan en la misma moneda que la cuenta de empleados (no entramos a ver que los pagos estan hechos desde dicha cuenta)
      condiciones1 = "gasto.empleado_id IS NOT NULL" 
      condiciones2 = {"gasto.moneda_id" => cuenta_empleados.moneda_id, "gasto_x_proyecto.proyecto_id" => proyecto_id, "gasto.fecha" => [inicio..fin]}
      gasto_total = Gasto.includes(:gasto_x_proyecto).where(condiciones1).where(condiciones2).sum("gasto_x_proyecto.importe")
      if transferencias.count == 1
        transferencia = transferencias.first
        # Acciones en funcion de que haya una transferencia pero no este marcada como automatica y el gasto no coincida con el importe de transferencia.
        if gasto_total != transferencia.importe_enviado and transferencia.marcado_id != marcado_automatico.id
          texto = "Error: Gastos empleados imputados a #{proyecto.nombre} del mes #{inicio.month}  no coinciden con transferencia."
          transferencia.update_attribute :marcado_id, marcado_trans_error
        # Accioes en funcion de que haya una trasferencia y este marcada como transferencia automatica y el gasto no coincida importe ransferencia.
        elsif gasto_total != transferencia.importe_enviado and transferencia.marcado_id == marcado_automatico.id
          transferencia.update_attribute :importe_enviado, gasto_total
          texto = "Actualización importe. Gasto: " + gasto.fecha.to_s + " / " + importe.to_s + " / " + gasto.concepto
        end
      # Acciones en funcion de que no haya transferencia
      elsif transferencias.count == 0 
        transferencia = Transferencia.create fecha_enviado: fin ,  importe_enviado: gasto_total,
                                             marcado_id: marcado_automatico.id, agente_id: gasto.agente_id,
                                             tipo: "transferencia", proyecto_id: proyecto_id,
                                             libro_origen_id: cuenta_proyecto_id, libro_destino_id: cuenta_empleados.id

        texto = "Transferencia automatica creada. Gasto: " + gasto.fecha.to_s + " -- " + importe.to_s + " -- " + gasto.concepto
        # Si la transferencia no se ha grabado por alguna validacion interna se recoge en un error en el gasto.
        unless transferencia.errors.empty?
          gasto.update_column :marcado_id, marcado_error.id
          texto = "Error creacion transferencia asociada:  #{transferencia.errors.full_messages.to_s}"
          Comentario.create(texto: texto, elemento_type: "gasto", elemento_id: gasto_id, sistema: true)
        end
      end
      Comentario.create(texto: texto, elemento_type: "Transferencia", elemento_id: transferencia.id, sistema: true) if texto
    end
  end

  # Obtiene la TC para asignaciones nuevas, cambios de proyecto o de gasto
  # Los en TC producidos por modificacion desde moneda o fecha los invoca el propio gasto
  def obtiene_tasa_cambio
    actualiza_tasa_cambio if self.id.nil? || self.gasto_id_changed? || self.proyecto_id_changed?
  end

  # Recalcula la TC a utilizar
  def actualiza_tasa_cambio
    tc = TasaCambio.tasa_cambio_para_gasto(self.gasto, self.proyecto)
    self.tasa_cambio_id = tc ? tc.id : nil
  end

  # Asigna la subpartida por defecto al gasto_x_proyecto o al gasto segun quien lo haya introducido
  def asigna_subpartida_por_defecto
    # Si es un gasto originado en un proyecto
    if self.gasto.proyecto_origen_id
      # Si el gasto esta creado por este proyecto 
      if self.gasto.proyecto_origen_id == self.proyecto_id
        # Si tenemos una subpartida, probamos a vincularla
        if self.subpartida
          # Si existe la subpartida en el agente, la asignamos 
          subp_agente = Subpartida.find_by_agente_id_and_partida_id_and_nombre(self.gasto.agente_id, self.gasto.partida_id, subpartida.nombre)
          # Actualizamos sin invocar validaciones ni callbacks. No hay peligro con las validaciones de fechas en agente porque en este caso acaba de crearse el gasto
          self.gasto.update_column(:subpartida_agente_id, subp_agente.id) if subp_agente
        end  
      # Si esta creado por otro proyecto
      else
        gxp = GastoXProyecto.find_by_gasto_id_and_proyecto_id(self.gasto_id, self.gasto.proyecto_origen_id)
        # Si existe la subpartida en el proyecto origen, asignamos esa
        if gxp && gxp.subpartida
          # Si existe la subpartida en nuestro proyecto, la asignamos
          subp_nuestra = Subpartida.find_by_proyecto_id_and_partida_id_and_nombre(self.proyecto_id, self.gasto.partida_id, gxp.subpartida.nombre)
          # Actualizamos sin invocar validaciones ni callbacks
          self.update_column(:subpartida_id, subp_nuestra.id) if subp_nuestra
        end
      end
    # Si es un gasto originado en un agente
    else
      # Si existe la subpartida en nuestro proyecto, la asignamos
      if self.gasto.subpartida_agente
        subp_nuestra = Subpartida.find_by_proyecto_id_and_partida_id_and_nombre(self.proyecto_id, self.gasto.partida_id, self.gasto.subpartida_agente.nombre)
        # Actualizamos sin invocar validaciones ni callbacks
        self.update_column(:subpartida_id, subp_nuestra.id) if subp_nuestra
      end
    end
  end

  # Proyecto de la relación.
  def proyecto
    return Proyecto.find_by_id self.proyecto_id
  end

  # Tasa de Cambio asociada
  def tasa_cambio
    tc = TasaCambio.find_by_id(self.tasa_cambio_id)
    return (tc ? tc.tasa_cambio : 0.0)
  end
  # Tasa de Cambio a la divisa 
  def tasa_cambio_divisa
    tc = TasaCambio.find_by_id(self.tasa_cambio_id)
    return (tc ? tc.tasa_cambio_divisa : 0.0)
  end

  # Porcentaje en formato para la visualización
  def porcentaje_to_s
    return (100 * gasto.importe / importe ).to_i.to_s + "%"
  end
  
  #Calcula el importe por la tasa de cambio
  def importe_por_tasa_cambio
    importe_x_tc = importe * tasa_cambio_proyecto.tasa_cambio if tasa_cambio_proyecto && tasa_cambio_proyecto.tasa_cambio
    return ('%.2f' % importe_x_tc) if importe_x_tc
  end

 private

  # Agrupa todas las validaciones para el borrado anteponiendo una variable de clase que permita saber que estamos antes de un borrado
  def verifica_borrado
    @eliminando_gasto = true
    # Agrupamos todos con AND para que el solo se devuelva true si todos devuelven true
    return ( comprobar_estado_proyecto && comprobar_periodos_proyecto && verifica_plugins )
  end

  # Verifica que los plugins permitan la edicion
  # OJO!: Siempre que se hagan movimientos en los gastos desde migraciones hay que tener en cuenta esto!
  def verifica_plugins
    Plugin.activos.each do |plugin|
      begin
        eval(plugin.clase + "::GastoXProyecto").verifica self, @eliminando_gasto
      rescue => ex
      end
    end unless self.evitar_validacion_plugins || (self.changed.empty? && @eliminando_gasto.nil?)
    return self.errors.empty?
  end

end
