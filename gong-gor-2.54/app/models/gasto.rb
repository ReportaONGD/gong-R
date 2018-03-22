# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2015 Free Software's Seed, CENATIC y IEPALA
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
# gasto

class Gasto < ActiveRecord::Base

  # Marcador para evitar o dejar pasar gastos fuera de fecha en proyectos
  # (revisar si esta constante esta obsoleta o se sigue usando) 
  PERMITIR_GASTOS_FUERA_DE_ETAPA_DE_PROYECTO = false

  #before_destroy :verifica_fechas_y_estado_proyectos, :verifica_plugins, :verifica_fechas_estado_periodos_al_eliminar
  before_destroy :verifica_borrado

  belongs_to :moneda
  belongs_to :agente
  belongs_to :empleado
  belongs_to :pais
  belongs_to :partida
  belongs_to :marcado_agente, :class_name => "Marcado", :foreign_key => "marcado_agente_id"
  belongs_to :subpartida_agente, :class_name => "Subpartida", :foreign_key => "subpartida_agente_id"
  belongs_to :tasa_cambio_agente, :class_name => "TasaCambio", :foreign_key => "agente_tasa_cambio_id"
  belongs_to :proveedor

  has_many :gasto_x_proyecto, :dependent => :destroy
  has_many :gasto_x_agente, :dependent => :destroy
  has_many :gasto_x_actividad, :dependent => :destroy
  #has_many :tasa_cambio_gasto, :dependent => :destroy
  has_many :pago, :dependent => :destroy, :order => "fecha"

  # Auditado de modificaciones, comentarios y marcado 
  include ::Auditable
  has_many :comentario, as: :elemento, dependent: :destroy
  belongs_to :marcado

  # Para vinculacion con transferencias
  has_many :gasto_x_transferencia, :dependent => :destroy
  has_many :transferencia, :through => :gasto_x_transferencia

  # Para vinculacion con documentos
  has_many :gasto_x_documento
  has_many :documento, :through => :gasto_x_documento

  # Vinculacion con contratos
  has_one :gasto_x_contrato, dependent: :destroy
  has_one :contrato, through: :gasto_x_contrato
  
  has_and_belongs_to_many :transferencia, :join_table =>  "gasto_x_transferencia"

  #named_scope :vinculable_al_proyecto, lambda { |p| { :conditions => ["`proyecto_origen_id` IN (?)",p.proyecto_cofinanciador]} }

  validates_presence_of :importe, :message => _("Importe") + " " + _("no puede estar vacío.")
  # Permitimos gastos negativos para aceptar devoluciones
  #validates_numericality_of :importe, :greater_than => 0, :message => _("Importe debe ser mayor que cero.")
  validates_presence_of :moneda_id, :message => _("Moneda") + " " + _("no puede estar vacío.")
  validates_presence_of :partida_id, :message => _("Partida") + " " + _("no puede estar vacío.")
  validates_presence_of :agente_id, :message => _("Agente Implementador") + " " + _("no puede estar vacío.")
  validates_presence_of :fecha,  :message => _("Fecha") + " " + _("no puede estar vacío.")  
  validates_associated :agente, :message =>  _("El agente implementador asociado no es correcto.")
  validates_presence_of :concepto, :message => _("Concepto") + " " + _("no puede estar vacío.")

  validate :comprueba_libro_moneda, :verifica_fechas_y_estado_proyectos, :verifica_pais, :verifica_plugins, :verifica_periodo_gastos_cerrados

  before_validation :fecha_y_fecha_informe
  before_save :actualiza_tasa_cambio, :actualiza_proveedor
  after_save :comprueba_orden_factura_agente, if: "!proyecto_origen_id"
  after_save :comprueba_orden_factura_proyecto, if: "proyecto_origen_id"
  after_save :comprueba_presupuesto_empleado, if: "comprueba_presupuesto_empleado_configurado?"

  # Para que los plugins puedan modificar saltandose la validacion "verifica_plugins"
  # OJO!: Siempre que se hagan movimientos en los gastos desde migraciones hay que tener en cuenta esto y 
  #       actualizar el gasto incluyendo "evitar_validacion_plugins: true"!
  attr_accessor :evitar_validacion_plugins

  # Para permitir que se actualice el proveedor en base a su nombre y nif y no como relacion
  attr_writer :proveedor_nombre
  attr_writer :proveedor_nif
  
  # Valor para poder mostrar un listado de gastos con un valor especifico que ya tenemos del importe por financiador
  attr_accessor :importe_x_financiador

  # Comprueba que el gasto tenga pais asignado. En caso contrario, asigna el más probable (en gastos de agentes, el propio suyo)
  def verifica_pais
    # Asignamos el pais del agente si está vacío y es un gasto de agente
    if self.proyecto_origen_id.nil?
      self.pais_id = self.agente.pais_id if self.pais_id.nil? && self.agente
      errors.add :base, _("País") + " " + _("no puede estar vacío.") if self.pais_id.nil?
    end
  end

  # Agrupa todas las validaciones para el borrado anteponiendo una variable de clase que permita saber que estamos antes de un borrado
  def verifica_borrado
    @eliminando_gasto = true
    # Agrupamos todos con AND para que el solo se devuelva true si todos devuelven true 
    return ( verifica_fechas_y_estado_proyectos && verifica_periodo_gastos_cerrados && verifica_plugins )
  end

    # Comprueba que la etapa del agente implantador no este cerrada o que haya proyectos cofinanciados cerrados
  def verifica_fechas_y_estado_proyectos
    # Comprueba posibles etapas del agente
    if self.agente
      et_nueva_1 = self.agente.etapa.first(:conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", fecha, fecha] )
      et_vieja_1 = fecha_was ? self.agente.etapa.first(:conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", fecha_was, fecha_was] ) : nil
      if self.agente_id_was && (self.agente_id_was != self.agente_id)
        aw = Agente.find_by_id(agente_id_was)
        et_nueva_2 = aw.etapa.first(:conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", fecha, fecha] )
        et_vieja_2 = fecha_was ? aw.etapa.first(:conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", fecha_was, fecha_was] ) : nil
      else
        et_nueva_2 = nil
        et_vieja_2 = nil
      end
      if (et_nueva_1 && et_nueva_1.cerrada) || (et_vieja_1 && et_vieja_1.cerrada)
        errors.add(_("Etapa"), _("El agente '%{agt}' ha cerrado la etapa donde se ejecuta el gasto. No se pueden modificar gastos de esas fechas.")%{agt: self.agente.nombre})
      end
      if (et_nueva_2 && et_nueva_2.cerrada) || (et_vieja_2 && et_vieja_2.cerrada)
        errors.add(_("Etapa"), _("El agente '%{agt}' ha cerrado la etapa donde se ejecuta el gasto. No se pueden modificar gastos de esas fechas.")%{agt: aw.nombre})
      end
    end

    # Comprueba gastos cofinanciados (solo si la modificacion es distinta a tc de agente)
    cambios = self.changed
    cambios.delete("agente_tasa_cambio_id")
    cambios.delete("orden_factura_agente")
    cambios.delete("subpartida_agente_id")

    # Aqui evitamos que un gasto vinculado a un proyecto se modifique o se borre, pero no que se haga una vinculacion nueva. Eso hay que hacerlo en gasto_x_proyecto
    self.gasto_x_proyecto.each do |gxp|
      if gxp.proyecto && gxp.proyecto.estado_actual
        # Si los proyectos estan cerrados o no están en ejecucion
        if gxp.proyecto.estado_actual.definicion_estado.cerrado || !gxp.proyecto.estado_actual.definicion_estado.ejecucion
          texto_gxp = _("El proyecto '%{proy}' se encuentra en estado '%{est}'.")%{proy: gxp.proyecto.nombre, est: gxp.proyecto.estado_actual.definicion_estado.nombre} + " " +
                      _("En este estado no se puede modificar el gasto.") if gxp.proyecto_id == self.proyecto_origen_id
          texto_gxp = _("El proyecto cofinanciador '%{proy}' está en estado '%{est}'.")%{proy: gxp.proyecto.nombre, est: gxp.proyecto.estado_actual.definicion_estado.nombre} + " " +
                      _("En este estado no se puede modificar el gasto.") unless gxp.proyecto_id == self.proyecto_origen_id
          errors.add(_("Proyecto"), texto_gxp) 
        end
      # Devuelve error para proyectos que no tengan estado definido
      elsif gxp.proyecto && gxp.proyecto.estado_actual.nil?
        errors.add(_("Proyecto"), _("El proyecto '%{proy}' no tiene un estado definido.")%{proy: gxp.proyecto.nombre} )
      end
    end if cambios.size > 0 or @eliminando_gasto

    # En el caso de tratarse de un nuevo gasto cuyo proyecto esta cerrado o no esta en ejecucion
    if self.new_record? && self.proyecto && self.proyecto.estado_actual
      if self.proyecto.estado_actual.definicion_estado.cerrado || !self.proyecto.estado_actual.definicion_estado.ejecucion
        texto = _("El proyecto '%{proy}' se encuentra en estado '%{est}'.")%{proy: self.proyecto.nombre, est: self.proyecto.estado_actual.definicion_estado.nombre} + " " +
                _("En este estado no se puede modificar el gasto.")
        errors.add(_("Proyecto"), texto)
      end
    # Si tiene un proyecto que no tiene estado, tambien da error
    elsif self.new_record? && self.proyecto && self.proyecto.estado_actual.nil?
      errors.add(_("Proyecto"), _("El proyecto '%{proy}' no tiene un estado definido.")%{proy: self.proyecto.nombre} )
    end

    # Ojo!... hacer esto esta mal porque cuando esta ok no devuelve "true"
    #return false unless self.errors.empty?    
    return self.errors.empty?
  end

  # Verifica que no se modifiquen gastos de periodos con los gastos cerrados
  # OJO! REVISAR!:
  #  * Las fechas de periodos de justificacion se refieren a cuando se puede justificar, no a que intervalo de tiempo contemplar
  #  * Los textos de los mensajes no estan bien formateados para la traduccion (genera textos raros sin contexto). Mejor un solo texto que encadenar con "+"
  def verifica_periodo_gastos_cerrados

    # Comprueba gastos cofinanciados (solo si la modificacion es distinta a tc de agente)
    cambios = self.changed
    cambios.delete("agente_tasa_cambio_id")
    cambios.delete("orden_factura_agente")
    cambios.delete("subpartida_agente_id")

    # revisamos los periodos de los proyectos asociados a un gasto en caso de modificación o borrado    
    self.gasto_x_proyecto.each do |gxp|
      if gxp.proyecto
        proyecto = gxp.proyecto
        for periodo in proyecto.periodo
          # Si el periodo esta cerrado y el gasto coincide en fechas con el periodo
          if periodo.gastos_cerrados and (self.fecha >= periodo.fecha_inicio and self.fecha <= periodo.fecha_fin)
            texto = _("El periodo '%{per}' (%{inicio} / %{fin}) del proyecto '%{proy}' tiene los gastos cerrados.")%{proy: proyecto.nombre, per: periodo.tipo_periodo.nombre, inicio: periodo.fecha_inicio.to_s , fin: periodo.fecha_fin.to_s }
            errors.add(_("Proyecto"), texto) 
          end
        end
      end
    end if cambios.size > 0 or @eliminando_gasto
    # En el caso de ser un nuevo registro comprobamos sobre el proyecto de origen del gasto.
    if self.new_record? and self.proyecto
      for periodo in self.proyecto.periodo
        # Si el periodo esta cerrado y el gasto coincide en fechas con el periodo
        if periodo.gastos_cerrados and (self.fecha >= periodo.fecha_inicio and self.fecha <= periodo.fecha_fin)
          texto = _("El periodo '%{per}' ( %{inicio} / %{fin}) del proyecto '%{proy}' tiene los gastos cerrados.")%{proy: self.proyecto.nombre, per: periodo.tipo_periodo.nombre, inicio: periodo.fecha_inicio.to_s , fin: periodo.fecha_fin.to_s }
          errors.add(_("Proyecto"), texto) 
        end
      end
    end
  
    return self.errors.empty?
  end

  # Obtiene la etapa del agente relacionado
  def etapa_agente gasto_fecha=nil
    gasto_fecha ||= self.fecha
    self.agente.etapa.first(:order => "fecha_inicio", :conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", gasto_fecha, gasto_fecha]) if self.agente
  end

  
  # Metodo que comprueba que se tienen la configuracion adecuada para ejecutar "comprueba_presupuesto_emeplado"
  # Ejecutamos comprueba_presupuesto_empleado si:
  # * Es un gasto de empleado
  # * Esta en la moneda principal del agente (que es la moneda en la que se hace el presupuesto)
  # * No ha sido simplemente un cambio de marcado de gasto
  # * Existen las dos variables de configuración necesarias (y estan correctamente definidas)
  def comprueba_presupuesto_empleado_configurado?
    marcado_tipo = Marcado.find_by_nombre(GorConfig::getValue('MARKED_EMPLOYED_BUDGET_ON_EXPENSES_ERRORS'))
    habilitado = GorConfig::getValue('CHECK_EMPLOYED_BUDGET_ON_EXPENSES')
    return ( empleado_id and !marcado_id_changed? and moneda_id == agente.moneda_principal.id and marcado_tipo and habilitado == "TRUE" )
  end

  # Metodo que comprueba la correspondencia de un gasto asociado a un empleado con su presupuesto 
  def comprueba_presupuesto_empleado
    logger.info "************* Variable: CHECK_EMPLOYED_BUDGET_ON_EXPENSES y MARKED_EMPLOYED_BUDGET_ON_EXPENSES_ERRORS activas. Se chequea el presupuesto de empleado"
    tipo_marcado = Marcado.find_by_nombre(GorConfig::getValue('MARKED_EMPLOYED_BUDGET_ON_EXPENSES_ERRORS'))
    condiciones = {agente_id: agente_id, empleado_id: empleado_id, partida_id: partida_id, subpartida_id: subpartida_agente_id }
    condiciones_fecha = ["presupuesto_detallado.fecha_inicio <= ? AND presupuesto_detallado.fecha_fin >= ?", fecha, fecha]     
    presupuestos = Presupuesto.includes(:presupuesto_detallado).where(condiciones).where(condiciones_fecha)
    numero_presupuestos = presupuestos.count
    # Si no hay ningun presupuesto 
    if numero_presupuestos == 0 
      texto = "GASTO SIN PRESUPUESTO"
      Comentario.create  texto: texto, elemento_type: "Gasto", elemento_id: id, sistema: true      
      # Añadimos marcado al gasto.
      update_column(:marcado_id, tipo_marcado.id) if texto and tipo_marcado
    # Si hay mas de un presupuesto
    elsif numero_presupuestos > 1
      texto = "MÁS DE UN PRESUPUESTO PARA EL GASTO"
      Comentario.create  texto: texto ,elemento_type: "Gasto", elemento_id: id, sistema: true      
      texto += " (Gasto:" + fecha.to_s + " -- " + importe.to_s + " -- " + concepto + ")"
      for presupuesto in presupuestos
        presupuesto.update_attribute :marcado_id, tipo_marcado.id if tipo_marcado
        Comentario.create  texto: texto ,elemento_type: "Presupuesto", elemento_id: presupuesto.id, sistema: true      
      end
    # Si hay un solo presupuesto comparamos importes y 
    elsif numero_presupuestos == 1
      presupuesto = presupuestos.first
      if importe != presupuesto.importe
        texto = "Error IMPORTE DISTINTO"
      end
      unless igual_distribucion_por_proyecto(presupuesto)
        texto = "Error DISTRIBUCIÓN POR PROYECTO"
      end
      if texto 
        texto_g = ". Gasto: " + fecha.to_s + " -- " + importe.to_s + " -- " + concepto
        texto_p = ". Presupuesto: " + presupuesto.importe.to_s + " -- " + presupuesto.concepto
        presupuesto.update_attribute :marcado_id, tipo_marcado.id if tipo_marcado
        Comentario.create  texto: texto + texto_g, elemento_type: "Presupuesto", elemento_id: presupuesto.id, sistema: true      
        Comentario.create  texto: texto + texto_p, elemento_type: "Gasto", elemento_id: id, sistema: true      
      end
    end
  end

  # Metodo utilizado para comprueba_presupuesto_empleado
  # Devuelve si el gasto tiene la misma districuion por proyecto que el presupuesto pasado
  def igual_distribucion_por_proyecto presupuesto
    gxp = gasto_x_proyecto.collect {|gxp| [gxp.proyecto_id, gxp.importe]}
    pxp = presupuesto.presupuesto_x_proyecto.collect {|pxp| [pxp.proyecto_id, pxp.importe]}
    return ((gxp - pxp).blank? and (pxp - gxp).blank?)
  end
 
  # Obtiene la etapa para el proyecto origen del gasto si lo hubiese
  def etapa_proyecto gasto_fecha=nil
    gasto_fecha ||= self.fecha
    self.proyecto.etapa.first(:order => "fecha_inicio", :conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", gasto_fecha, gasto_fecha]) if self.proyecto
  end
  
  # Incluye el orden de factura para el proyecto y el implantador
  def comprueba_orden_factura_proyecto
    if self.proyecto 
      # Ponemos un orden de factura si no hay numeracion previa o si ha cambiado el agente y no es un nuevo registro (procedente de importancion).
      # NOTA: Utilizamos para ver si es un nuevo registro lo de id_was != nil por que new_record? no sirve en un after_filter
      if orden_factura_proyecto.nil? || (agente_id_was != agente_id && id_was != nil)
        # Calculamos el ultimo gasto para el agente implementador correpondiente
        if id_was == nil || orden_factura_proyecto.nil?
          condiciones = ["proyecto_origen_id = ? AND agente_id = ? ", proyecto_origen_id, agente_id]
        else
          condiciones = ["proyecto_origen_id = ? AND agente_id = ? AND orden_factura_proyecto <> ?", proyecto_origen_id, agente_id, orden_factura_proyecto]
        end
        numeracion_ultimo_gasto = Gasto.where(condiciones).maximum(:orden_factura_proyecto)
        # Y el siguiente codigo a utilizar
        numero = numeracion_ultimo_gasto.nil? ? 1 : (numeracion_ultimo_gasto + 1)
        # Guardamos evitando las validaciones y los callbacks
        self.update_column(:orden_factura_proyecto, numero)
      end
    end  
  end
  
  # Incluye el orden de factura para el agente implantador
  def comprueba_orden_factura_agente
    if self.agente
      etapa_actual = etapa_agente
      etapa_vieja = fecha_was ? etapa_agente(fecha_was) : etapa_actual
      if orden_factura_agente.nil? || (etapa_actual != etapa_vieja)
        # Obtiene la etapa del agente
        # Si existe una etapa definida, encuentra el ultimo codigo valido
        if etapa_actual
          # Calculamos el ultimo gasto de esa etapa
          ultimo_gasto = Gasto.last(:conditions => ["agente_id = ? AND orden_factura_agente > ? AND fecha >= ? AND fecha <= ?",agente_id, 0, etapa_actual.fecha_inicio,etapa_actual.fecha_fin])
          # Y el siguiente codigo a utilizar
          # Guardamos evitando las validaciones y los callbacks
          self.update_column(:orden_factura_agente, ultimo_gasto && ultimo_gasto.orden_factura_agente ? (ultimo_gasto.orden_factura_agente + 1) : 1 )
        end
      end
    end
  end

  # Devuelve la numeración de la factura tanto si se ha dado de alta desde agente, como si es una numeración de proyecto.
  def numeracion_factura
    if self.proyecto_origen_id
      orden_factura_proyecto
    else 
      orden_factura_agente
    end
  end 

  # Muestra la numeracion de la factura. La numeración de la factura tiene un formato que incluye los siguientes elementos:
  # P ó D : Origen en Proyecto o en Delegacion 
  # Con Origen en Proyecto: NombreProyecto -  NombreEtapaProyecto (si hubiese mas de 1) - NombreAgente -
  # Con Origen en Delegacion: NombreAgente - NombreEtapaAgente
  # Numero Secuencial si se da de alta desde el sistema, o el numero (o código) que se le haya dado si se importa el gasto desde fuera del sistema
  # NOTA: El numero secuencial se encuentra en el campo orden_factura_proyecto si es un gasto con origen en proyecto o en orden_factura_agente si el gasto viene de agente
  def numeracion_factura_completo
    if self.proyecto_origen_id
      "P / " + proyecto.nombre + " - " + agente.nombre +  " / " + (orden_factura_proyecto.to_s || "")  
    else 
      "D / " + agente.nombre + " - " + etapa_agente.nombre + " / "  + (orden_factura_agente.to_s || "")  
    end
  end

  # Obtiene la tasa de cambio para el agente o el proyecto
  def actualiza_tasa_cambio
    # Cambia la tasa de cambio de agente si es nuevo o se ha actualizado agente, fecha o moneda
    if (self.id.nil? || self.agente_id_changed? || self.fecha_changed? || self.moneda_id_changed?)
      # Tasa de cambio para el agente
      tc = TasaCambio.tasa_cambio_para_gasto(self, self.agente)
      self.agente_tasa_cambio_id = tc ? tc.id : nil
    end
    # Cambia las tasas de cambio de gasto_x_proyecto si se ha actualizado fecha o moneda (no nuevo)
    if !self.id.nil? && (self.fecha_changed? || self.moneda_id_changed? || self.pais_id_changed?)
      self.gasto_x_proyecto.each do |gxp|
        gxp.actualiza_tasa_cambio
        gxp.save
      end
    end
  end

  # Comprueba que el libro de cada pago pertenezca al agente implementador
  # y que el libro tiene la misma moneda que el gasto
  def comprueba_libro_moneda
    # Con mirar el primero vale
    p=pago.first
    if p && p.libro
      errors.add("Pago", _("La cuenta de algún pago no pertenece al agente. Elimine los pagos existentes antes de cambiar el agente.")) if p.libro.agente != agente
      errors.add("Pago", _("Existe algún pago con moneda distinta al gasto. Elimine los pagos existentes antes de cambiar la moneda.")) if p.libro.moneda != moneda
    end
  end

  # Por compatibilidad con metodos anteriores (principalmente para plugin de webservices)...
  def emisor_factura
    ( (proveedor.nombre||"") + ( proveedor.nif.empty? ? "" : " (" + proveedor.nif + ")" )) if proveedor
  end
  # Devuelve el nombre del proveedor del gasto
  def proveedor_nombre
    proveedor.nombre if proveedor
  end
  # Devuelve el nif del proveedor del gasto
  def proveedor_nif 
    proveedor.nif if proveedor
  end
  # Actualiza la info del proveedor relativa al gasto
  # Se invoca despues de las validaciones con el callback "after_validation"
  def actualiza_proveedor
    # Tenemos proveedor_nombre y proveedor_nif como attr_writers, asi que podemos usarlos
    # Buscamos el proveedor del agente implementador del gasto que corresponda...
    if @proveedor_nombre || @proveedor_nif
      prov = self.agente.proveedor.find_or_create_by_nombre_and_nif(@proveedor_nombre, @proveedor_nif)
      self.proveedor_id = prov ? prov.id : nil
    end
  end
  
  def orden_factura_agente_completo
    etp = self.agente.etapa.first(:order => "fecha_inicio", :conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", fecha, fecha]) if self.agente
    if orden_factura_agente && etp 
      orden_factura_agente.to_s + " (" + etp.nombre + ")"
    end
  end

  def subpartida_proyecto proyecto
    gxp = gasto_x_proyecto.find_by_proyecto_id(proyecto)
    return gxp ? gxp.subpartida : nil
  end
  def subpartida_proyecto_nombre proyecto
    subpartida = subpartida_proyecto proyecto
    subpartida ? subpartida.nombre : nil
  end

  def pagado?
    return self.es_valorizado || (self.importe - self.importe_pagado) == 0
  end

  def importe_pagado
    total = 0
    self.pago.each do |p|
      total += p.importe 
    end
    return total
  end

  def marcado_proyecto proy=nil
    if proy && proy.class.name == "Proyecto"
      gxp = gasto_x_proyecto.find_by_proyecto_id(proy)
      gxp.marcado if gxp
    end
  end

  # Revisa si el gasto tiene errores y en ese caso, se automarca
  def marcado_errores
    # recoge el marcado de error
    marcado_error = Marcado.where(:error => true).first
    # Si existe un marcado de errores, mira si aplicarlo
    if marcado_error
      # Para marcado del gasto
      marcado_nuevo = nil
      # Si el gasto no esta pagado, marca error
      marcado_nuevo = marcado_error unless pagado?
      # Si no ha habido errores y estaba como error, el marcado es el inicial
      marcado_nuevo = Marcado.where(:automatico => true).first if marcado_nuevo.nil? && marcado_id == marcado_error.id
      # Si tenemos que cambiar el marcado, lo hacemos
      update_column(:marcado_id, marcado_nuevo.id) if marcado_nuevo
      # Para marcado de gasto_x_proyecto
      self.gasto_x_proyecto.each do |gxp|
        marcado_nuevo_id = nil
        # Si el gasto por financiadores no coincide (proyectos), marca error
        marcado_nuevo_id = marcado_error.id unless comprobar_financiadores(gxp.proyecto)
        # Si el gasto por actividades no coincide (proyectos), marca error
        marcado_nuevo_id = marcado_error.id unless comprobar_actividades(gxp.proyecto)
        gxp.update_column(:marcado_proyecto_id, marcado_nuevo_id) if gxp.marcado_proyecto_id != marcado_nuevo_id
      end
      # Para marcado del gasto en el agente
      marcado_nuevo_id = nil
      # Si el gasto por proyectos no coincide (agentes), marca error
      marcado_nuevo_id = marcado_error.id unless comprobar_proyectos
      update_column(:marcado_agente_id, marcado_nuevo_id) if marcado_agente_id != marcado_nuevo_id
    end
  end

  # Si alguna de las fechas (del documento: fecha_informe, o del gasto: fecha) esta vacia, le asignamos por defecto
  # la otra fecha.
  # Mas adelante definiremos concretamente como se trabaja con cada una, pero por defecto mejor no tener
  # el campo fecha_informe vacio
  def fecha_y_fecha_informe
    self.fecha_informe = self.fecha if self.fecha_informe.blank?
    self.fecha = self.fecha_informe if self.fecha.blank?
  end

  def subpartidas_nombres
    subpartida.nombre if subpartida
  end 

   # En gastos no creamos subpartidas!!!
   #def subpartida_nombre=(nombre)
   #  self.subpartida=Subpartida.find_or_create_by_nombre(nombre) unless nombre.blank?
   #end 

  # Comprueba que la fecha esta dentro de la etapa selecionada. 
  def comprobar_fecha_etapa fecha_inicio, fecha_fin
    if self.fecha and self.fecha >= fecha_inicio and self.fecha <= fecha_fin
      return true
    else
      errors.add(_("Fecha"), _("La fecha '%s' debe estar dentro de la etapa") % [self.fecha]) ; return false
    end
  end

  # Devuelve el nombre del proyecto origen del gasto
  def proyecto_origen
    Proyecto.find_by_id(proyecto_origen_id).nombre if proyecto_origen_id
  end
  def proyecto
    Proyecto.find_by_id(proyecto_origen_id) if proyecto_origen_id
  end

  # Devuelve los financiadores del gasto para un determinado proyecto   
  def financiador proyecto
     gasto_x_agente.find :all, :conditions => {"proyecto_id" => ( proyecto.class.name != "Proyecto" ? proyecto.to_i : proyecto.id )}
  end

  # Devuelve los actividades del gasto para un determinado proyecto
  def actividad proyecto
     gasto_x_actividad.find :all, :conditions => {"proyecto_id" => ( proyecto.class.name != "Proyecto" ? proyecto.to_i : proyecto.id )}
  end

  # Devuelve un array con los importes por actividad
  def importes_por_actividades proyecto=nil
    salida = Array.new
    condiciones = Hash.new
    condiciones["proyecto_id"] = (proyecto.class.name != "Proyecto" ? proyecto.to_i : proyecto.id) if proyecto
    gxas = gasto_x_actividad.find(:all, :conditions => condiciones)
    gxas.each {|gxa| salida.push( gxa.actividad.codigo + ": " + gxa.importe.to_s ) }
    return salida
  end

  # Devuelve un array con los importes por financiador
  def importes_por_financiadores proyecto=nil
    salida = Array.new
    condiciones = Hash.new
    condiciones["proyecto_id"] = (proyecto.class.name != "Proyecto" ? proyecto.to_i : proyecto.id) if proyecto
    gxp = gasto_x_proyecto.first(:conditions => condiciones)
    gxfs = gasto_x_agente.find(:all, :conditions => condiciones)
    gxfs.each {|gxf| salida.push( gxf.agente.nombre + ": " + gxf.importe.to_s + " " + moneda.abreviatura + " (" + (100*gxf.importe/gxp.importe).round(2).to_s + "%)" ) }
    return salida
  end

  # Devuelve un array con los importes por proyectos (chapucilla... hay que revisar esto)
  def importes_por_proyectos
    # No podemos usar gasto_x_proyecto sino GastoXProyecto pues los filtros del controlador hacen que desaparezcan cosas
    #gasto_x_proyecto.collect { |gxp| (gxp.proyecto ? gxp.proyecto.nombre : _("Imputado a Delegación")) + ": " + (gxp.importe).to_s + " " + moneda.abreviatura + " (" + (100*gxp.importe/importe).round(2).to_s + "%)" }
    GastoXProyecto.all(:conditions => {:gasto_id => self.id}).collect { |gxp| (gxp.proyecto ? '<a href="' + Rails.application.routes.url_helpers.gastos_proyecto_path(gxp.proyecto) + '">' + ActionController::Base.helpers.sanitize(gxp.proyecto.nombre) + '</a>' : _("Imputado a Delegación")) + ": " + (gxp.importe).to_s + " " + moneda.abreviatura + " (" + (100*gxp.importe/importe).round(2).to_s + "%)" }
  end

  def enlace_nota_gasto_proyecto proyecto=nil
    #['<a href="' + Rails.application.routes.url_helpers.nota_gasto_proyecto_path(proyecto.to_i,self.id) + '">' + _("Descargar") + '</a>']
    notas = Documento.includes("etiqueta").where("etiqueta.nombre" => "Nota de Gasto", "etiqueta.tipo" => "plantilla")          
    notas.collect do |docu|
      '<a href="' + Rails.application.routes.url_helpers.nota_gasto_proyecto_path(proyecto.to_i,self.id,docu.id) + '">' + docu.adjunto_file_name + '</a>'
    end
  end
  def enlace_nota_gasto_agente
    #['<a href="' + Rails.application.routes.url_helpers.nota_gasto_agente_path(self.agente_id,self.id) + '">' + _("Descargar") + '</a>']
    notas = Documento.includes("etiqueta").where("etiqueta.nombre" => "Nota de Gasto", "etiqueta.tipo" => "plantilla") 
    notas.collect do |docu|
      '<a href="' + Rails.application.routes.url_helpers.nota_gasto_agente_path(self.agente_id,self.id,docu.id) + '">' + docu.adjunto_file_name + '</a>'
    end
  end

  def todas_actividades? proyecto
    return gasto_x_actividad.find_all_by_proyecto_id(proyecto.id).size == proyecto.actividad.size if proyecto
  end

   # Moneda del gasto
   def moneda
     return self.moneda_id ? Moneda.find(self.moneda_id) : nil
   end

   #Metodo especifico creado para el ruport y la exportacion
   def moneda_abreviatura
     return Moneda.find(self.moneda_id).abreviatura if self.moneda_id
   end

   #Metodo especifico creado para el ruport y la exportacion
   def partida_codigo_nombre_aborrar
     return partida.codigo_nombre if self.partida_id
   end

   # Devuelve el codigo/nombre de la partida del financiador para el proyecto seleccionado
   def partida_proyecto_codigo_nombre proyecto
     unless proyecto.nil? || gasto_x_proyecto.where(:proyecto_id => proyecto).empty?
       par = partida.partida_asociada(proyecto) if partida
       return par.codigo + " - " + par.nombre if par
     end
   end

   # importe para el proyecto asociado al gasto
   # Esto modifica el importe del gasto asociando el que tendría en el proyecto, pero no lo guarda
   # se usa desde el listado de gastos de proyecto
   def importe_x_proyecto proyecto
     gxp = gasto_x_proyecto.detect {|gxp| gxp.proyecto_id == proyecto.id}
     if gxp
       self.importe = gxp.importe
     end
   end

	# devuelve el gasto por proyecto y agente
   def importe_x_proyecto_financiador proyecto, financiador=nil
     g = gasto_x_proyecto.detect {|gxp| gxp.proyecto_id == proyecto.id} unless financiador
     g = gasto_x_agente.detect {|gxa| gxa.proyecto_id == proyecto.id && gxa.agente_id == financiador.id} if financiador
     return g ? g.importe : nil
   end

   # Actualiza el listado de agentes con los que se ha asociado el gasto para un determinado proyecto.
   # Antiguamente se borraban todos y luego se volvian a generar. Sin embargo esto no solo es ineficiente
   # sino que no funciona con los bloqueos de modificaciones impuestos desde plugins
   def actualizar_gasto_x_agente listado, proyecto
     gxp = self.gasto_x_proyecto.find_by_proyecto_id(proyecto.id)

     # Si el gasto esta asignado al proyecto, le actualiza el gasto por actividad indicado
     if gxp
       # Obtiene todos los financiadores a utilizar
       gxa_existentes = gasto_x_agente.where(proyecto_id: proyecto).collect{|gxa| gxa.agente_id}

       # Creamos o actualizamos todos los proporcionados por el usuario
       listado.each do |key, value|
         if value["agente_id"] != ""
           gxa = gasto_x_agente.find_by_agente_id_and_proyecto_id( value["agente_id"], proyecto ) || gasto_x_agente.new(proyecto_id: proyecto.id)
           gxa.update_attributes(value)
           errors.add("", gxa.errors.inject('') {|total, e| total + e[1]  }) unless gxa.errors.empty?
           # Como estaba contemplado, lo eliminamos del listado
           gxa_existentes.delete(gxa.agente_id)
         else
           # Esto lo hacemos para calcular luego si el importe total coincide
           listado.delete(key)
         end
       end

       # Nos quedaria eliminar aquellos que no estaban en el listado original
       gxa_existentes.each do |agt_id|
         gxa = gasto_x_agente.find_by_agente_id_and_proyecto_id( agt_id, proyecto )
         gxa.destroy if gxa
         errors.add("", gxa.errors.inject('') {|total, e| total + e[1]  }) unless gxa.nil? || gxa.errors.empty?
       end

       total = gxp.importe
       if  listado.inject(0) {|suma, value| suma + importe_desconvertido(value.pop[:importe_convertido])} != total.to_f
         errors.add( _('Importes'), _("Los importes de los financiadores no suman el importe total del gasto."))        
       end
     # Si el gasto no esta asignado al proyecto, volcamos error
     else
       errors.add( :base, _("Imposible guardar reparto por financiadores.") + " " + _("El gasto no está asignado al proyecto '%{proy}'")%{proy: proyecto.nombre} )
     end 
   end

   # Actualiza el listado de actividades con los que se ha asociado el gasto para un determinado proyecto.
   def actualizar_gasto_x_actividad listado, proyecto
     gxp = self.gasto_x_proyecto.find_by_proyecto_id(proyecto.id)
     # Si el gasto esta asignado al proyecto, le actualiza el gasto por actividad indicado
     if gxp
       actividad(proyecto).each {|f| f.destroy}
       # Primero elimina las actividades que no tienen actividad_id
       listado = limpia_listado_actividades(listado)
       # Y va recorriendo el listado
       listado.each do |key, value|
         value[:proyecto_id] = proyecto.id
         gxa = gasto_x_actividad.create(value)
         errors.add( "", gxa.errors.inject('') {|total, e| total + e[1]  } ) unless gxa.errors.empty?
       end        
       total = gxp.importe
       total_acts = listado.inject(0){|suma, value| suma + (importe_desconvertido(value.pop[:importe_convertido]) || 0)}
       # Convertimos a string para validar la literalidad y no comparar entre diferentes tipos de datos
       if (total_acts.round(2).to_s != total.round(2).to_s)
         errors.add( _('Importes'), _("La suma de importes de las actividades ('%{imp_act}') no suman el importe total del gasto ('%{imp_gsto}').")%{imp_act: total_acts, imp_gsto: total} )
       end
     # Si el gasto no esta asignado al proyecto, volcamos error
     else
       errors.add( :base, _("Imposible guardar reparto por actividades.") + " " + _("El gasto no está asignado al proyecto '%{proy}'")%{proy: proyecto.nombre} )
     end
   end

   # Actualiza los proyectos a los que se ha asociado el gasto.
   # Antiguamente se borraban todos y luego se volvian a generar. Sin embargo esto no solo es ineficiente
   # sino que no funciona con los bloqueos de modificaciones impuestos desde plugins
   def actualizar_gasto_x_proyecto listado
     # Obtiene todos los proyectos a utilizar
     gxp_existentes = gasto_x_proyecto.collect{|gxp| gxp.proyecto_id}

     # Creamos o actualizamos todos los proporcionados por el usuario
     listado.each do |key, value|
       gxp = gasto_x_proyecto.find_by_proyecto_id( (value["proyecto_id"] == "" ? nil : value["proyecto_id"]) ) || gasto_x_proyecto.new
       # Introducimos la posibilidad de borrar lineas de proyectos si dejamos su importe vacio o a cero
       if value[:importe_convertido] != "" and value[:importe_convertido] != "0"
         gxp.update_attributes(value) 
       else
         gxp.destroy
       end
       errors.add("", gxp.errors.inject('') {|total, e| total + e[1]  }) unless gxp.errors.empty?
       # Como estaba contemplado, lo eliminamos del listado
       gxp_existentes.delete(gxp.proyecto_id)
     end

     # Nos quedaria eliminar aquellos que no estaban en el listado original
     gxp_existentes.each do |prj_id|
       gxp = gasto_x_proyecto.find_by_proyecto_id( prj_id )
       gxp.destroy if gxp
       errors.add("", gxp.errors.inject('') {|total, e| total + e[1]  }) unless gxp.nil? || gxp.errors.empty?
     end
   end
 
  # Divide las actividades por el importe total
  # Hacemos 2 trucos para que funcione mejor:
  #  a) Trabajamos con los importes en centimos para que la division sea mas ajustada
  #  b) Trabajamos con los importes en positivo para que el redondeo del modulo sea el adecuado
  def dividir_por_actividades actividades, proyecto
     detalle = Hash.new
     # Primero elimina las actividades que no tienen actividad_id
     actividades = limpia_listado_actividades(actividades)
     # Si hay al menos una actividad, divide el importe entre estas
     if actividades.size > 0
       # Obtenemos el valor absoluto y el multiplicador
       gxp = self.gasto_x_proyecto.find_by_proyecto_id(proyecto.id)
       importe_en_proyecto = gxp ? gxp.importe : 0.0
       importe_multiplicador = importe_en_proyecto > 0 ? 1.0 : -1.0
       # Calcula el importe por actividad a aplicar 
       ixa, ixa_resto = (100.0 * importe_en_proyecto.abs).divmod(actividades.size)
       importe_x_actividad = ixa * importe_multiplicador / 100
       resto_importe = ixa_resto * importe_multiplicador / 100
       #numero_unidades_x_actividad, resto_numero_unidades = numero_unidades.divmod(actividades.size)
       # Divide por las actividades existentes
       for actividad in actividades
          detalle[actividad.id] = { :importe_convertido => importe_x_actividad, :actividad_id => actividad.id, :proyecto_id => proyecto.id} if actividad.class.name == "Actividad"
          detalle[actividad[0]] = { :importe_convertido => importe_x_actividad, :actividad_id => actividad[1]["actividad_id"], :proyecto_id => proyecto.id} unless actividad.class.name == "Actividad"
       end
       if detalle.size > 0
         detalle[detalle.keys.last][:importe_convertido] = importe_x_actividad + resto_importe
         actualizar_gasto_x_actividad detalle, proyecto
       end
    end
  end

  # Limpia un listado de actividades de aquellas que no tienen actividad_id
  def limpia_listado_actividades actividades
    actividades.each do |key, value|
      actividades.delete(key) if key.class.name != "Actividad" && (value.nil? || !value.has_key?(:actividad_id) || value[:actividad_id] == "")
    end
    return actividades
  end

  # Devuelve la tasa de cambio para un determinado proyeto.
  def tasa_cambio_proyecto proyecto
    gxp = self.gasto_x_proyecto.find_by_proyecto_id(proyecto.to_i) if proyecto
    return TasaCambio.find_by_id(gxp.tasa_cambio_id) if gxp 
  end

  #def tasa_cambio_agente
  #  return TasaCambio.find_by_id(self.agente_tasa_cambio_id)
  #end

  # Devuelve importes en euros y en divisas para proyectos y agentes
  def importe_x_proyecto_en_base proyecto_id
    tasa_cambio = self.tasa_cambio_proyecto proyecto_id
    proyecto = Proyecto.find_by_id proyecto_id
    ixtc = (gasto_x_proyecto.first(:conditions => {:proyecto_id => proyecto_id.to_i}).importe * tasa_cambio.tasa_cambio) if tasa_cambio && proyecto
    #return ('%.2f' % ixtc).to_s + " " + proyecto.moneda_principal.abreviatura if ixtc && proyecto
    return ('%.2f' % ixtc) if ixtc && proyecto
  end

  def importe_x_proyecto_en_divisa proyecto_id
    tasa_cambio = self.tasa_cambio_proyecto proyecto_id
    proyecto = Proyecto.find_by_id proyecto_id
    divisa = proyecto.moneda_intermedia if proyecto
    ixtc = (gasto_x_proyecto.first(:conditions => {:proyecto_id => proyecto_id.to_i}).importe * tasa_cambio.tasa_cambio_divisa) if tasa_cambio && tasa_cambio.tasa_cambio_divisa && divisa
    return ('%.2f' % ixtc).to_s + " " + divisa.abreviatura if ixtc
  end

  def importe_implantador_en_base
    tasa_cambio = self.tasa_cambio_agente
    ixtc = (importe * tasa_cambio.tasa_cambio) if tasa_cambio
    return ('%.2f' % ixtc).to_s + " " + agente.moneda_principal.abreviatura if ixtc 
  end

  def importe_implantador_en_divisa
    divisa = self.agente.moneda_intermedia
    # Averigua cual es la TC a aplicar...
    # ... para la propia divisa la TC es 1
    if divisa == self.moneda
      valor_tasa_cambio = 1
      ixtc = importe
    # ... para la moneda principal se calcula segun la TC inversa
    elsif divisa && agente.moneda_principal == self.moneda
      gasto_ficticio = self.dup
      gasto_ficticio.moneda_id = divisa.id
      tasa_cambio = TasaCambio.tasa_cambio_para_gasto(gasto_ficticio, self.agente)
      ixtc = (importe / tasa_cambio.tasa_cambio) if tasa_cambio && tasa_cambio.tasa_cambio && tasa_cambio.tasa_cambio != 0 
    # ... en cualquier otra circunstancia, depende de la TC intermedia
    else
      tasa_cambio = self.tasa_cambio_agente
      ixtc = (importe * tasa_cambio.tasa_cambio_divisa) if tasa_cambio && tasa_cambio.tasa_cambio_divisa && divisa 
    end
    return ('%.2f' % ixtc).to_s + " " + divisa.abreviatura if ixtc
  end

  # Devuelve la identificacion del gasto para un determinado proyeto y una determinada financiación.
  def identificacion_gasto_aborrar proyecto, financiacion
    return gasto_identificacion.detect {|ig| ig.proyecto_id == proyecto and ig.financiacion_id == financiacion}
  end

  # Comprueba si el gasto esta asociado correctamente a proyectos.
  def comprobar_proyectos
    # No podemos usar gasto_x_proyecto sino GastoXProyecto pues los filtros del controlador hacen que desaparezcan cosas
    #return gasto_x_proyecto.inject(0) {|suma, gxp| suma + gxp.importe} == self.importe 
    return GastoXProyecto.all(:conditions => {:gasto_id => self.id}).inject(0) {|suma, gxp| suma + gxp.importe} == self.importe
  end

  # Comprueba si el gasto esta asociado correctamente a financiadores.
  def comprobar_financiadores proyecto
    gxp = self.gasto_x_proyecto.find_by_proyecto_id(proyecto.id) if proyecto
    return (proyecto && gxp) ? financiador(proyecto).inject(0) {|suma, f| suma + f.importe} == gxp.importe : false
  end

  # Comprueba si el gasto esta asociado correctamente a actividades.
  def comprobar_actividades proyecto
    gxp = self.gasto_x_proyecto.find_by_proyecto_id(proyecto.id) if proyecto
    return (proyecto && gxp) ? actividad(proyecto).inject(0) {|suma, f| suma + f.importe} == gxp.importe : false
  end

  #--
  # FINDERS complicados... Mas alla de ActiveRecordBase
  # ++

  # Busqueda creada manualmente para los detalles de busquedas especificas que no cubre el find habitual de ActiveRecord.
  def self.busqueda campos, condiciones, asociacion, agrupado, ordenado
    consulta = " SELECT " + campos + " FROM gasto  "
    consulta += asociaciones asociacion
    consulta += " WHERE " + merge_conditions(condiciones) if condiciones
    consulta += " GROUP BY " + agrupado if agrupado
    consulta += " ORDER BY " + ordenado if ordenado
    return find_by_sql consulta 
  end
  
  # Cutrada para sustituir el include para el metodo busqueda.
  def self.asociaciones asociacion
    asociacion.inject(' ') do |suma, elemento|
      case elemento
        #when :libro
        #suma + ' LEFT OUTER JOIN libro on gasto.libro_id = libro.id'
        when :gasto_x_proyecto
        suma + ' LEFT OUTER JOIN gasto_x_proyecto on gasto_x_proyecto.gasto_id = gasto.id'
        when :tasa_cambio_gasto
        suma + ' LEFT OUTER JOIN tasa_cambio_gasto on tasa_cambio_gasto.gasto_id = gasto.id'
        when :gasto_x_agente
        suma + ' LEFT OUTER JOIN gasto_x_agente on gasto_x_agente.gasto_id = gasto.id'
        when :gasto_x_actividad
        suma + ' LEFT OUTER JOIN gasto_x_actividad on gasto_x_actividad.gasto_id = gasto.id'
        when :partida_x_partida_financiacion
        suma + ' LEFT OUTER JOIN partida_x_partida_financiacion on partida_x_partida_financiacion.partida_id = gasto.partida_id'
        when :partida_financiacion
        suma + ' LEFT OUTER JOIN partida_financiacion on partida_financiacion.id = partida_x_partida_financiacion.partida_financiacion_id'
        #when :gasto_identificacion
        #suma + ' LEFT OUTER JOIN gasto_identificacion on gasto_identificacion.gasto_id = gasto.id'
      end
    end
  end

  # Metodo que iguala algunos valores basicos para procesos de insercion de datos.
  # Lo comento por que no se bien para que puede servir. Con el tiempo se eliminara (sram-22092014)
  #def self.datos_basicos_igualar gasto, gasto_anterior
  #  gasto.partida = gasto_anterior.partida
  #  gasto.fecha = gasto_anterior.fecha
  #  #gasto.libro_id = gasto_anterior.libro_id
  #  gasto.agente_id = gasto_anterior.agente_id
  #  gasto.moneda_id = gasto_anterior.moneda_id
  #
  #end


  # Total de campos posibles para edicion
  # todos los existentes en el modelo + subpartida de proyecto y documentos asociados (usados indirectamente)
  # Lo metemos dependiente de que exista la tabla para no romper el primer migrate de creacion (aun no existe esa tabla)
  CAMPOS_EDICION = (ActiveRecord::Base.connection.table_exists?('gasto') ? Gasto.column_names : []) +
                   ["documentos_asociados", "subpartida_proyecto_id", "actividades", "financiadores", "proyectos", "pagos"]

  # Devuelve los campos editables segun los plugins en general y para un gasto concreto
  def self.campos_edicion_permitidos gasto=nil
    # En principio permite todos y segun los plugins va recortando
    campos = Gasto::CAMPOS_EDICION
    # Si cualquiera de los proyectos relacionados esta cerrado evitamos tocar cosas que puedan ser comunes a todos los proyectos
    if Proyecto.joins(:gasto_x_proyecto).where("gasto_x_proyecto.gasto_id" => gasto).
                joins(estado_actual: :definicion_estado).where("definicion_estado.cerrado" => true).size > 0
      # A priori permitimos actividades, financiadores, y que sea el controlador el que limite si es proyecto concreto esta cerrado
      campos = ["actividades", "financiadores", "agente_tasa_cambio_id", "orden_factura_agente", "subpartida_agente_id", "subpartida_proyecto_id", "proyectos"]
    end
    # Si la etapa del agente del gasto esta cerrada
    if gasto && (etapa_agente = gasto.etapa_agente)
      if etapa_agente.cerrada
        campos_posibles = ["fecha_informe", "subpartida_proyecto_id", "actividades", "financiadores"]
        campos = campos_posibles.select{|c| campos.include?(c)}
      end 
    end
    # Permite solo los campos contemplados por los plugins
    Plugin.activos.each do |plugin|
      begin
        campos_plugin = eval(plugin.clase + "::Gasto").campos_edicion_permitidos(gasto)
        # Si existe el metodo anterior, sigue el flujo por aqui... y si no existe se sale en el rescue
        # Consideramos solo los que ya existan previamente y el plugin diga que tambien se consideren
        campos = campos_plugin.select{|c| campos.include?(c)}
      rescue => ex
      end
    end
    return campos
  end
  
  # Concentramos en este metodo todos los avisos de las lineas de gasto en la seccion proyectos.
  # Ademas desde este metodo consultamos a los plugins por avisos adicionales.
  # NOTA: Pasamos la variable fecha_fuera_etapas para no cargar con calculos/consultas que ya estan incluidos en la vista
  def chequea_avisos_proyecto proyecto, fecha_fuera_etapas
    avisos = []
    avisos.push _("La fecha de gestión y la fecha de documento no coinciden.") if fecha_informe and fecha_informe != fecha
    avisos.push _("La fecha está fuera de las etapas del proyecto.") if fecha_fuera_etapas
    avisos.push _("La suma por actividades no es correcta.") unless comprobar_actividades(proyecto)
    avisos.push _("La suma por financiadores no es correcta.") unless comprobar_financiadores(proyecto)
    avisos.push _("El gasto no está pagado correctamente.") unless proyecto_origen_id != proyecto.id || pagado?
    Plugin.activos.each do |plugin|
      begin
        avisos_plugin = eval(plugin.clase + "::Gasto").chequea_avisos_proyecto(self)
        avisos += avisos_plugin if avisos_plugin.class.name == "Array" 
      rescue => ex
      end
    end
    return avisos
  end

  # Concentramos en este metodo todos los avisos de las lineas de gasto en la seccion agentes.
  # Ademas desde este metodo consultamos a los plugins por avisos adicionales.
  def chequea_avisos_agente
    avisos = []
    avisos.push _("La suma por proyectos no es correcta.") if proyecto_origen_id.nil? && !comprobar_proyectos
    avisos.push _("El gasto no está pagado correctamente.") unless proyecto_origen_id || pagado?
    avisos.push _("No se ha especificado una subpartida.") unless subpartida_agente
    Plugin.activos.each do |plugin|
      begin
        avisos_plugin = eval(plugin.clase + "::Gasto").chequea_avisos_agente(self)
        avisos += avisos_plugin if avisos_plugin.class.name == "Array" 
      rescue => ex
      end
    end
    return avisos
  end


 private

  # Verifica que los plugins permitan la edicion
  # OJO!: Siempre que se hagan movimientos en los gastos desde migraciones hay que tener en cuenta esto!
  def verifica_plugins
    Plugin.activos.each do |plugin|
      begin
        eval(plugin.clase + "::Gasto").verifica self, @eliminando_gasto
      rescue => ex
      end
    end unless self.evitar_validacion_plugins
    return self.errors.empty?
  end

  # Permite la ejecucion de metodos de plugins no existentes en el modelo
  def method_missing(method_sym, *arguments, &block)
    clase = nil
    # Primero averigua que plugins tienen la clase "Gasto" y cuales de ellos el metodo pedido
    Plugin.activos.each do |plugin|
      begin
        clase = plugin.clase if eval(plugin.clase)::Gasto.respond_to?(method_sym)
      rescue => ex
      end
    end
    # Invoca al ultimo plugin que haya encontrado (o al super si no hay ninguno)
    clase ? eval(clase)::Gasto.send(method_sym,self) : super
  end

end
