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
# Clases del modelo que gestiona la entidad TasaCambio.
class TasaCambio < ActiveRecord::Base
  belongs_to :moneda
  belongs_to :etapa
  belongs_to :agente
  belongs_to :pais

  has_many :presupuesto
  #has_many :gasto

  #untranslate_all

  validates_presence_of :etapa_id, :message => _("La tasa de cambio debe estar asociada a una etapa.")
  validates_presence_of :fecha_inicio, :message => _("El intervalo debe tener una fecha de inicio.")
  validates_presence_of :fecha_fin, :message => _("El intervalo debe tener una fecha de fin.")
  validates_numericality_of :tasa_cambio, :greater_than_or_equal_to => 0, :message => _("Tasa de Cambio debe ser mayor de 0.")
  validates_numericality_of :tasa_cambio_divisa, :greater_than_or_equal_to => 0, :if => :must_tasa_cambio_divisa, :message => _("Tasa de Cambio para Divisa debe ser mayor de 0.")
  validates_presence_of :moneda_id,  :message => _("La tasa de cambio debe estar asociada a una moneda.")

  #validates_uniqueness_of :moneda_id, :scope => [:etapa_id, :objeto], :message => _("Ya existe una tasa de cambio para esa moneda.")
  validates_uniqueness_of :moneda_id, :scope => [:etapa_id, :objeto], :if => Proc.new { |tc| tc.objeto == "presupuesto" }, :message => _("Ya existe una tasa de cambio de presupuesto para esa moneda en la etapa.")

  validate :comprueba_fechas, :comprueba_moneda

  # Callbacks para modificar presupuestos y gastos al cambiar una tc
  after_save 'TasaCambio.cambiada(self)'
  after_destroy 'TasaCambio.borrada(self)'


  # Devuelve el valor de la TC en un string incluyendo la moneda (para los helpers de listado)
  def cadena_tasa_cambio
    format("%.5f ", tasa_cambio) + moneda_principal.abreviatura    
  end
  # Devuelve el valor de la TC de la divisa en un string incluyendo la moneda (para los helpers de listado)
  def cadena_tasa_cambio_divisa
    format("%.5f ", tasa_cambio_divisa||0.0) + divisa.abreviatura if divisa
  end

  def tasa_cambio_base_a_divisa
    return ((tasa_cambio_divisa||0) == 0 ? 0.0 : (tasa_cambio/tasa_cambio_divisa).round(8))
  end

  # Devolvemos cual seria la TC a la divisa
  # No usamos tasa_cambio_divisa porque esta contendria valores erroneos cuando:
  # 1) moneda_id == moneda_base (al generarse automaticamente no existe tasa_cambio_divisa)
  # 2) moneda_id == moneda_intermedia (no estamos seguros de que siempre sea tasa_cambio_divisa = 1)
  def tasa_cambio_moneda_intermedia
    tasa = 0.0
    elemento = self.etapa.proyecto || self.etapa.agente
    moneda_base_id = elemento.moneda_id
    moneda_intermedia_id = elemento.moneda_intermedia_id

    # Si la moneda es la propia moneda base, no habra conversion a divisa en la TC (su tc tiene solo 1.0 a la moneda base) 
    # tenemos que usar entonces la inversa de la TC de la divisa
    if moneda_intermedia_id && moneda_base_id == self.moneda_id
      if self.objeto == "presupuesto"
        tc = TasaCambio.tasa_cambio_para_presupuesto(self.etapa, moneda_intermedia_id)
      else
        gasto_falso = Gasto.new(:moneda_id => moneda_intermedia_id, :pais_id => self.pais_id, :fecha => self.fecha_inicio)
        tc = TasaCambio.tasa_cambio_para_gasto(gasto_falso, elemento)
      end
      tasa = 1.0/tc.tasa_cambio if tc && tc.tasa_cambio != 0
    # Cuando la moneda no es la base, usamos la tasa de cambio a divisa
    elsif moneda_intermedia_id == self.moneda_id
      tasa = 1.0
    # Por fin, cuando no es ni la moneda base ni la divisa, usamos la TC a divisa propia
    elsif moneda_intermedia_id
      tasa = self.tasa_cambio_divisa
    end
    return tasa
  end

  def tipo
    return _(self.objeto.capitalize)
  end
  def modo
    return self.tasa_fija ? _("Manual") : _("Ponderada")
  end
  def moneda_principal
    elemento = self.etapa.proyecto || self.etapa.agente
    return elemento.moneda_principal
  end
  def divisa 
    elemento = self.etapa.proyecto || self.etapa.agente
    return self.moneda_id == elemento.moneda_id ? nil : elemento.moneda_intermedia
  end

  def comprueba_fechas 
    # Comprueba que exista fecha_inicio y fecha_fin y que tengan logica
    if self.fecha_fin < self.fecha_inicio
      errors.add("fecha", _("La fecha de fin tiene que ser mayor que la fecha de inicio"))
      return false
    end

    # Comprueba que las fechas no se salgan de la etapa
    if self.fecha_inicio < self.etapa.fecha_inicio || self.fecha_fin > self.etapa.fecha_fin
      errors.add("fecha", _("Las fechas deben estar comprendidas entre las de la etapa"))
      return false
    end

    # Comprueba que las fechas no se solapen con otra TC
    self.etapa.tasa_cambio.all(:conditions => {:objeto => self.objeto, :moneda_id => self.moneda_id, :pais_id => self.pais_id}).each do |tc|
      if tc.id != self.id && (
          (self.fecha_inicio >= tc.fecha_inicio && self.fecha_inicio <= tc.fecha_fin) ||
          (self.fecha_fin >= tc.fecha_inicio && self.fecha_fin <= tc.fecha_fin) ||
          (self.fecha_inicio <= tc.fecha_inicio && self.fecha_fin >= tc.fecha_fin) )
        errors.add("fecha", _("Las fechas se solapan con las de otra tasa de cambio"))
        return false
      end
    end
    
  end

  # Si la moneda es la divisa del agente o del proyecto, ajusta su tc a 1
  def comprueba_moneda
    obj = etapa.proyecto || etapa.agente
    self.tasa_cambio_divisa = 1.0 if obj && obj.moneda_intermedia_id && obj.moneda_intermedia_id == self.moneda_id
  end

  # Comprueba si debe ser obligatoria la tasa de cambio para la divisa
  def must_tasa_cambio_divisa
    obj = etapa.proyecto || etapa.agente
    return (!divisa.nil? && obj.moneda_id != moneda_id )
  end

    # +++
    # Sobrecargamos la clase para incluir calculos de tasa de cambio
    # ---
  class << self

    # Devuelve si la TC a aplicar debe ser de formulacion o de ejecucion (presupuesto o gasto)


    # Actualiza los valores asociados cuando se modifica 
    def cambiada(tc)
      if tc.class.name == "TasaCambio"
        # Si el objeto aplicable es un presupuesto y ha cambiado la moneda o el objeto o las fechas...
        if (tc.objeto == "presupuesto" || (tc.objeto_changed? && !tc.id_was.nil?) && (tc.moneda_id_changed? || tc.fecha_inicio_changed? || tc.fecha_fin_changed?))
          # Si ha cambiado la moneda, actualizamos todos los presupuestos, si no solo los de la moneda
          actualiza_presupuestos(tc.etapa, (tc.moneda_id_changed? ? nil : tc.moneda_id))
        end
        # Si el objeto aplicable es un gasto o ha cambiado este o la moneda o las fechas...
        if (tc.objeto == "gasto" || (tc.objeto_changed? && !tc.id_was.nil?) && (tc.moneda_id_changed? || tc.fecha_inicio_changed? || tc.fecha_fin_changed?))
          objeto = (tc.etapa.proyecto || tc.etapa.agente)
          # Si ha cambiado la fecha de inicio o de fin, actualizamos todos los gastos de las fechas anteriores, si no solo ese rango
          fecha_inicio = (tc.fecha_inicio_was.nil? || tc.fecha_inicio < tc.fecha_inicio_was) ? tc.fecha_inicio : tc.fecha_inicio_was
          fecha_fin = (tc.fecha_fin_was.nil? || tc.fecha_fin > tc.fecha_fin_was) ? tc.fecha_fin : tc.fecha_fin_was
          # Si ha cambiado la moneda, actualizamos solo los gastos de ella
          actualiza_gastos(objeto, fecha_inicio, fecha_fin, (tc.moneda_id_changed? ? nil : tc.moneda_id))
        end
      end
    end

    # Actualiza los valores asociados cuando se borra
    # (tambien podriamos actualizar solo aquellos que tienen asociada la tasa borrada, pero asi unificamos codigo)
    def borrada(tc)
      if tc.class.name == "TasaCambio"
        # Si el objeto aplicable es un presupuesto...
        if tc.objeto == "presupuesto"
          actualiza_presupuestos(tc.etapa, tc.moneda_id)
        end
        # Si el objeto aplicable es un gasto...
        if tc.objeto == "gasto"
          # Actualizamos todos los gastos en ese rango de fechas y para esa moneda 
          actualiza_gastos( (tc.etapa.proyecto || tc.etapa.agente), tc.fecha_inicio, tc.fecha_fin, tc.moneda_id)
        end
      end
    end

    # Actualiza las tasas de cambio cuando se les cambia las fechas de la etapa
    def etapa_cambia_fechas(etapa)
      #puts "-----------> Modificando tasas de cambio por cambios en etapa"
      etapa.tasa_cambio.each do |tc|
        #puts "-----------> Modificando TC " + tc.id.to_s
        modifica_auto = tc.objeto == "presupuesto" || (etapa.proyecto || etapa.agente).moneda_id == tc.moneda_id
        tc.fecha_inicio = etapa.fecha_inicio if modifica_auto || tc.fecha_inicio < etapa.fecha_inicio
        tc.fecha_fin = etapa.fecha_fin if modifica_auto || tc.fecha_fin > etapa.fecha_fin
        tc.save 
      end
      # Si no existe alguna de las tasas de cambio de la moneda base, las crea
      condiciones = {:etapa_id => etapa.id, :moneda_id => (etapa.proyecto || etapa.agente).moneda_id, :tasa_cambio => 1.0, :fecha_inicio => etapa.fecha_inicio, :fecha_fin => etapa.fecha_fin}
      condiciones[:objeto] = "presupuesto"
      #puts "-------------> Creando TC de moneda_base para presupuesto"
      TasaCambio.create(condiciones) unless TasaCambio.first(:conditions => condiciones)
      condiciones[:objeto] = "gasto"
      #puts "-------------> Creando TC de moneda_base para gasto"
      TasaCambio.create(condiciones) unless TasaCambio.first(:conditions => condiciones)
    end

    # Actualiza tasas de cambio si se modifica la monedas base
    def cambia_moneda(etapa)
      # Primero se carga todas las tasas de cambio de la etapa
      etapa.tasa_cambio.all.each { |tc| tc.destroy }
      # Y luego manda generarlas de nuevo
      TasaCambio.etapa_cambia_fechas(etapa) 
    end

    # Actualiza todos los presupuestos de la etapa si se ha cambiado una tasa de cambio
    def actualiza_presupuestos(etapa, moneda_id=nil)
      if etapa && etapa.class.name == "Etapa"
        objeto = etapa.proyecto || etapa.agente
        #puts "    --> Actualizando presupuestos de la etapa " + etapa.nombre + " para el " + objeto.class.name + " " + objeto.nombre
        condiciones = moneda_id ? {:moneda_id => moneda_id} : {}
        # Los presupuestos de ingresos
        etapa.presupuesto.all(:conditions => condiciones).each do |presupuesto|
          tc = TasaCambio.tasa_cambio_para_presupuesto(etapa, presupuesto.moneda_id)
          tc_id = tc ? tc.id : nil
          presupuesto.tasa_cambio_id = tc_id
          presupuesto.save
        end
        # y los presupuestos de gastos
        etapa.presupuesto_ingreso.all(:conditions => condiciones).each do |presupuesto|
          tc = TasaCambio.tasa_cambio_para_presupuesto(etapa, presupuesto.moneda_id)
          tc_id = tc ? tc.id : nil
          presupuesto.tasa_cambio_id = tc_id
          presupuesto.save
        end
      end
    end

    # Actualiza todos los gastos
    def actualiza_gastos(objeto, fecha_inicio=nil, fecha_fin=nil, moneda_id=nil)
      if objeto
        #puts "    --> Actualizando gastos del " + objeto.class.name + " " + objeto.nombre
        condiciones = {}
        condiciones = { "gasto.fecha" => fecha_inicio..fecha_fin } if fecha_inicio && fecha_fin
        condiciones["gasto.moneda_id"] = moneda_id if moneda_id
        # Actualiza gasto (tasa de cambio para agentes)
        if objeto.class.name == "Agente"
          condiciones[:agente_id] = objeto.id
          Gasto.all(:conditions => condiciones).each do |gasto|
            tc = TasaCambio.tasa_cambio_para_gasto(gasto, objeto)
            gasto.agente_tasa_cambio_id = tc ? tc.id : nil
            gasto.save
          end
          # Actualiza tambien la TC de todos los ingresos de la etapa del agente
          condiciones_i = {}
          condiciones_i[:agente_id] = objeto.id
          condiciones_i[:moneda_id] = moneda_id if moneda_id 
          condiciones_i[:fecha] = fecha_inicio..fecha_fin if fecha_inicio && fecha_fin
          Ingreso.where(condiciones_i).each do |ingreso|
            tc = TasaCambio.tasa_cambio_para_gasto(ingreso, objeto)
            ingreso.tasa_cambio_id = tc ? tc.id : nil
            ingreso.save
          end
        end
        # Actualiza gasto_x_proyecto (tasa de cambio para proyectos)
        if objeto.class.name == "Proyecto"
          condiciones[:proyecto_id] = objeto.id
          GastoXProyecto.all(:conditions => condiciones, :include => "gasto").each do |gxp|
            tc = TasaCambio.tasa_cambio_para_gasto(gxp.gasto, gxp.proyecto)
            gxp.tasa_cambio_id = tc ? tc.id : nil
            gxp.save
          end
        end
      end 
    end

    # Devuelve la tasa de cambio para un presupuesto
    def tasa_cambio_para_presupuesto(etapa, moneda_id)
      return etapa.tasa_cambio.first(:conditions => ["moneda_id = ? AND objeto = 'presupuesto'", moneda_id]) if etapa && etapa.class.name == "Etapa" && moneda_id
    end

    # Devuelve la tasa de cambio para una TasaCambioGasto
    def tasa_cambio_para_gasto(gasto, objeto, financiador=nil)
      tc = nil
      #puts "-------------> Averiguamos la tasa de cambio del gasto para el " + objeto.class.name + " " + objeto.id.to_s + " con fecha " + gasto.fecha.to_s + " y moneda " + gasto.moneda.abreviatura + (financiador ? " sobre el financiador " + financiador.nombre : "")
      if objeto && gasto && (gasto.class.name == "Gasto" || gasto.class.name == "Ingreso")
        fecha_gasto = gasto.fecha

        # Averiguamos si estamos antes de etapa o despues de etapa
        if objeto.etapa.where(["fecha_inicio <= ?", fecha_gasto]).empty? 
          condiciones_fecha = ["fecha_fin >= ?", fecha_gasto]
          orden_fecha = "fecha_inicio ASC"
        else
          condiciones_fecha = ["fecha_inicio <= ?", fecha_gasto]
          orden_fecha = "fecha_inicio DESC"
        end

        # En el futuro tendremos que prescindir de etapas y buscar solo por periodos de tasas de cambio
        etapa_tasa = objeto.etapa.where(condiciones_fecha).reorder(orden_fecha).first
        # Si tenemos una etapa donde buscar, averiguamos la TC que le corresponderia
        if etapa_tasa
          condiciones = {etapa_id: etapa_tasa.id, moneda_id: gasto.moneda_id, objeto: 'gasto'}
          pais_gasto = gasto.respond_to?(:pais_id) ? gasto.pais_id : nil 

          # Eliminamos en todas las busquedas los where(condiciones_fecha) por ser redundantes
          # Primero buscamos la TC para financiador/pais
          tc = TasaCambio.where(condiciones).where(agente_id: financiador).where(pais_id: pais_gasto).reorder(orden_fecha).first
          # Si no encontramos, buscamos una TC para financiador y cualquier pais
          tc ||= TasaCambio.where(condiciones).where(agente_id: financiador).where(pais_id: nil).reorder(orden_fecha).first
          # Si tampoco, una TC para pais y cualquier financiador
          tc ||= TasaCambio.where(condiciones).where(agente_id: nil).where(pais_id: pais_gasto).order(orden_fecha).first
          # Y si tampoco, una TC para cualquier pais y cualquier financiador
          tc ||= TasaCambio.where(condiciones).where(condiciones_fecha).where(agente_id: nil).where(pais_id: nil).order(orden_fecha).first
        end
      end
      return tc
    end

    # Actualiza todas las tasas de cambio aplicables al objeto modificado (callback desde Transferencia)
    def actualiza_ponderadas(transferencia)
      # Solo actuamos si la transferencia tiene ciertas "propiedades"
      if 	transferencia && transferencia.proyecto &&
		transferencia.libro_origen_id && transferencia.libro_destino_id &&
		transferencia.tasa_cambio && transferencia.tasa_cambio > 0
        if transferencia.libro_destino.moneda_id != transferencia.proyecto.moneda_id
          # Para cada etapa, comprueba si hay tasas de cambio aplicables a esa fecha
          transferencia.proyecto.etapa.all( :conditions => ["fecha_inicio <= ? AND fecha_fin >= ?", transferencia.fecha_recibido, transferencia.fecha_recibido] ).each do |etapa|
            # Obtiene todas las tasas de cambio sin tasa fija y en el periodo de la transferencia
            etapa.tasa_cambio.all( :conditions => ["NOT tasa_fija AND moneda_id = ? AND fecha_inicio <= ? AND fecha_fin >= ?", transferencia.libro_destino.moneda_id, transferencia.fecha_recibido, transferencia.fecha_recibido] ).each do |tc|
              (tc.tasa_cambio,tc.tasa_cambio_divisa) = TasaCambio.media_ponderada(transferencia.proyecto, transferencia.libro_destino.moneda_id, tc.fecha_inicio, tc.fecha_fin)
              tc.save
            end
            # Si la moneda es una divisa de proyecto, realiza el calculo tambien para el resto de monedas
            if transferencia.proyecto && transferencia.libro_destino.moneda_id == transferencia.proyecto.moneda_intermedia_id
              (transferencia.proyecto.moneda.collect{|m| m.id} - [transferencia.proyecto.moneda_id, transferencia.proyecto.moneda_intermedia_id]).each do |mon_id|
                etapa.tasa_cambio.all( :conditions => ["NOT tasa_fija AND moneda_id = ? AND fecha_inicio <= ? AND fecha_fin >= ?", mon_id, transferencia.fecha_recibido, transferencia.fecha_recibido] ).each do |tc|
                  (tc.tasa_cambio,tc.tasa_cambio_divisa) = TasaCambio.media_ponderada(transferencia.proyecto, mon_id, tc.fecha_inicio, tc.fecha_fin)
                  tc.save
                end
              end
            end
          end
        end
      end
    end

    # Devuelve la tasa de cambio por media ponderada segun las transferencias del objeto (de momento solo proyectos)
    def media_ponderada(objeto, moneda_id, fecha_inicio, fecha_fin)
      moneda_base_id = objeto.moneda_id
      moneda_divisa_id = objeto.moneda_intermedia_id
      importe_temporal_recibido = importe_temporal_recibido_divisa = importe_temporal_recibido_intermedia = 0.0
      importe_temporal_cambiado = importe_temporal_cambiado_divisa = importe_temporal_cambiado_intermedia = 0.0
      tasa_temporal = tasa_temporal_divisa = tasa_temporal_intermedia = 0.0

      # Busca las transferencias a la moneda local
      #transferencias = objeto.transferencia.all :conditions => { "moneda_id" => moneda_id, "entrante_saliente" => "entrante", "fecha" => fecha_inicio..fecha_fin }
      transferencias = objeto.transferencia.all :include => 'libro_destino', :conditions => { "libro.moneda_id" => moneda_id, "fecha_recibido" => fecha_inicio..fecha_fin }
      transferencias.each do |transferencia|
        # Calcula la media ponderada directa (de la moneda principal a la seleccionada)
        #if ( transferencia.libro_receptor_emisor && transferencia.libro_receptor_emisor.moneda_id == moneda_base_id )
        if ( transferencia.libro_origen && transferencia.libro_origen.moneda_id == moneda_base_id )
          importe_temporal_recibido += transferencia.importe_recibido
          importe_temporal_cambiado += transferencia.importe_cambiado
          tasa_temporal += transferencia.importe_recibido * transferencia.tasa_cambio
        end
        # Calcula la media ponderada desde divisa a la seleccionada (si hay intermedia)
        #if ( moneda_divisa_id && transferencia.libro_receptor_emisor && moneda_id != moneda_divisa_id && transferencia.libro_receptor_emisor.moneda_id == moneda_divisa_id )
        if ( moneda_divisa_id && moneda_id != moneda_divisa_id && transferencia.libro_origen && transferencia.libro_origen.moneda_id == moneda_divisa_id )
          importe_temporal_recibido_intermedia += transferencia.importe_recibido
          importe_temporal_cambiado_intermedia += transferencia.importe_cambiado
          tasa_temporal_intermedia += transferencia.importe_recibido * transferencia.tasa_cambio
        end
      end

      # Busca las transferencias desde la moneda base hacia la divisa
      if moneda_divisa_id
        #transferencias = objeto.transferencia.all :conditions => { "moneda_id" => moneda_divisa_id,"entrante_saliente" => "entrante","fecha" => fecha_inicio..fecha_fin }
        transferencias = objeto.transferencia.all :include => 'libro_destino', :conditions => { "libro.moneda_id" => moneda_divisa_id, "fecha_recibido" => fecha_inicio..fecha_fin }
        transferencias.each do |transferencia|
          # Calcula la media ponderada desde la moneda base a la divisa
          #if ( transferencia.libro_receptor_emisor && transferencia.libro_receptor_emisor.moneda_id == moneda_base_id )
          if ( transferencia.libro_origen && transferencia.libro_origen.moneda_id == moneda_base_id )
            importe_temporal_recibido_divisa += transferencia.importe_recibido
            importe_temporal_cambiado_divisa += transferencia.importe_cambiado
            tasa_temporal_divisa += transferencia.importe_recibido * transferencia.tasa_cambio
          end
        end
      end

      tasa_directa = importe_temporal_cambiado != 0 ? importe_temporal_recibido/importe_temporal_cambiado : 0.0
      tasa_divisa = importe_temporal_cambiado_divisa != 0 ? importe_temporal_recibido_divisa/importe_temporal_cambiado_divisa : 0.0
      tasa_intermedia = importe_temporal_cambiado_intermedia != 0 ? importe_temporal_recibido_intermedia/importe_temporal_cambiado_intermedia : 0.0
      total_cambiado = importe_temporal_cambiado + importe_temporal_cambiado_intermedia

      tasa_combinada = total_cambiado !=0 ? (tasa_directa * importe_temporal_cambiado/total_cambiado) + (tasa_divisa * tasa_intermedia * importe_temporal_cambiado_intermedia/total_cambiado) : 0.0
      
      #puts "-----------> Cambiado directo: " + importe_temporal_cambiado.to_s
      #puts "-----------> Divisa cambiada: " + importe_temporal_cambiado_divisa.to_s
      #puts "-----------> Cambiado via divisa: " + importe_temporal_cambiado_intermedia.to_s
      #puts "-----------> Tasa directa: " + tasa_directa.inspect
      #puts "-----------> Tasa divisa: " + tasa_divisa.inspect
      #puts "-----------> Tasa intermedia: " + tasa_intermedia.inspect
      #puts "-----------> Tasa combinada: " + tasa_combinada.inspect

      # Si hay moneda intermedia y no ha habido transferencias desde esta a la moneda, metemos una media para que no quede como 0
      tasa_intermedia = tasa_combinada/tasa_divisa if tasa_intermedia == 0.0 && tasa_divisa != 0.0 && moneda_divisa_id

      return tasa_combinada.round(8), tasa_intermedia.round(8)
    end

    # Devuelve la tasa de cambio por metodo fifo (a implementar)
    def fifo objeto, moneda_id, fecha_inicio, fecha_fin
      return 3
    end
  end

end
