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
class Subpartida < ActiveRecord::Base
  #untranslate_all
  has_many :presupuesto, :dependent => :nullify
  has_many :gasto_x_proyecto, :dependent => :nullify
  has_many :gasto_x_agente, :class_name => "Gasto", :foreign_key => :subpartida_agente_id, :dependent => :nullify
  belongs_to :proyecto
  belongs_to :agente
  belongs_to :partida

  # Codigo de contabilidad (hay uno por cada delegacion)
  has_many :cuenta_contable, :as => :elemento_contable

  validates_uniqueness_of :nombre, :scope => [:proyecto_id, :agente_id], :message => _("La subpartida ya esta asignada a otra partida"), :case_sensitive => false

  validate :subpartida_nombre
  before_save :verificar_presupuesto_gasto, :genera_numero_de_orden

  after_create :crear_asociacion_pacs
  after_update :modificar_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs

  
  def subpartida_nombre
    self.nombre = self.nombre.upcase
  end

  # Por compatibilidad con algunos helpers...
  def codigo_nombre
    self.nombre
  end

  #+++
  # Metodos de ayuda para la elaboracion de resumenes.
  # Los siguientes metodos aceptan un parametro que puede ser:
  #  * Etapa.
  #    Se calcularán las sumas de presupuestos para dicha etapa
  #  * Hash con keys: etapa, fecha_inicio, fecha_fin .
  #    Se calcularán las sumas de presupuestos detallados para ese intervalo de fechas en la etapa indicada
  #---

  # Devuelve el numero de presupuestos
  def numero_presupuestos condicion=nil
    etapa, filtro = obtiene_filtros(condicion)
    self.presupuesto.count unless etapa
    self.presupuesto.where(etapa_id: etapa).count if etapa
  end
  # Devuelve la suma total de los presupuestos de la subpartida en la moneda principal
  def suma_presupuestos condicion=nil
    suma = 0.0
    etapa, filtro = obtiene_filtros(condicion)
    suma = presupuesto.where(etapa_id: etapa).joins(:tasa_cambio).sum("importe * tasa_cambio").to_f unless filtro
    suma = presupuesto.where(etapa_id: etapa).joins(:presupuesto_detallado).where(filtro).joins(:tasa_cambio).
                       sum("presupuesto_detallado.importe * tasa_cambio").to_f if etapa && filtro
    return suma 
  end
  # Devuelve la suma en divisa de los presupuestos de la partida
  def suma_presupuestos_divisa condicion=nil
    suma = 0.0
    etapa, filtro = obtiene_filtros(condicion)
    elemento = agente || proyecto
    divisa = elemento.moneda_intermedia
    if divisa && etapa
      # Primero toma los presupuestos en todas las monedas salvo la principal (no habra TC de esta a la divisa)
      suma = presupuesto.where(etapa_id: etapa).where('presupuesto.moneda_id != ?', elemento.moneda_id).
                         joins(:tasa_cambio).sum("importe * tasa_cambio_divisa").to_f unless filtro
      suma = presupuesto.where(etapa_id: etapa).where('presupuesto.moneda_id != ?', elemento.moneda_id).
                         joins(:presupuesto_detallado).where(filtro).
                         joins(:tasa_cambio).sum("presupuesto_detallado.importe * tasa_cambio_divisa").to_f if filtro
      # Averigua los pptos formulados en la moneda principal
      subsuma = presupuesto.where(etapa_id: etapa).where(moneda_id: elemento.moneda_id).sum("importe").to_f unless filtro
      subsuma = presupuesto.where(etapa_id: etapa).where(moneda_id: elemento.moneda_id).
                            joins(:presupuesto_detallado).where(filtro).
                            joins(:tasa_cambio).sum("presupuesto_detallado.importe").to_f if filtro
      # ... averigua la TC de divisa a moneda principal
      tc = TasaCambio.tasa_cambio_para_presupuesto(etapa, divisa.id)
      # ... y por ultimo divide (la inversa de multiplicar)
      suma += (subsuma / tc.tasa_cambio) if tc && tc.tasa_cambio != 0
    end
    return suma 
  end

  private

    # Descompone un filtro de ayudas a resumenes
    def obtiene_filtros condicion=nil
      case condicion.class.name
        when "Etapa"
          etapa = condicion
          filtro = nil
        when "Hash"
          # Generamos un array para las condiciones y otro array para sus valores
          con = []
          val = []
          # El filtro de fecha lo asignamos directamente
          filtro2 = ["presupuesto_detallado.fecha_inicio >= ? AND presupuesto_detallado.fecha_fin <= ?", condicion[:fecha_inicio], condicion[:fecha_fin]]
          # El resto de claves, las vamos asignando
          condicion.each do |clave,valor|
            if clave == :etapa
              etapa = condicion[:etapa]
            elsif clave == :fecha_inicio
              con.push "presupuesto_detallado.fecha_inicio >= ?"
              val.push condicion[:fecha_inicio] 
            elsif clave == :fecha_fin
              con.push "presupuesto_detallado.fecha_fin <= ?"
              val.push condicion[:fecha_fin]
            else
              con.push "#{clave.to_s} IN (?)"
              val.push valor
            end
          end
          filtro = [con.join(" AND ")] + val
        else
          etapa = nil
          filtro = nil
      end
      return etapa, filtro
    end

    def crear_asociacion_pacs
      self.proyecto.pacs.each do |p|
        # Solo actua si la pac no esta cerrada
        if p.estado_actual.nil? || !p.estado_actual.definicion_estado.cerrado
          misp = self.dup
          misp.proyecto_id = p.id
          misp.save
        end
      end if self.proyecto && self.proyecto.convenio?
    end
  
    def modificar_asociacion_pacs
      self.proyecto.pacs.each do |p|
        # Solo actua si la pac no esta cerrada
        if p.estado_actual.nil? || !p.estado_actual.definicion_estado.cerrado
          misp = p.subpartida.find_by_nombre(self.nombre_was)
          if misp
            misp.nombre = self.nombre
            misp.partida_id = self.partida_id
            misp.save
          end
        end
      end if self.proyecto && self.proyecto.convenio?
    end

    def eliminar_asociacion_pacs
      self.proyecto.pacs.each do |p|
        # Solo actua si la pac no esta cerrada
        Subpartida.destroy_all(:proyecto_id => p.id, :nombre => self.nombre) if p.estado_actual.nil? || !p.estado_actual.definicion_estado.cerrado
      end if self.proyecto && self.proyecto.convenio?
    end

    # Verifica que no haya presupuestos ni gastos vinculados a la subpartida cuando modificamos la partida
    def verificar_presupuesto_gasto
      if self.partida_id_changed? && !self.partida_id_was.nil?
        errors.add("Subpartida", _("La subpartida está siendo usada en %{num} presupuestos.") % {:num => presupuesto.count.to_s} + " " + _("No se puede cambiar la partida vinculada.")) unless presupuesto.empty?
        errors.add("Subpartida", _("La subpartida está siendo usada en %{num} gastos.") % {:num => gasto_x_proyecto.count.to_s} + " " + _("No se puede cambiar la partida vinculada.")) unless gasto_x_proyecto.empty?
        errors.add("Subpartida", _("La subpartida está siendo usada en %{num} gastos.") % {:num => gasto_x_agente.count.to_s} + " " + _("No se puede cambiar la partida vinculada.")) unless gasto_x_agente.empty?
        return false unless presupuesto.empty? && gasto_x_proyecto.empty? && gasto_x_agente.empty?
      end
    end

    # Genera un numero de orden de la subpartida
    def genera_numero_de_orden
      # Generamos el numero de orden solo si no lo tiene y esta asignado a un proyecto
      self.numero = (Subpartida.maximum(:numero, :group => :proyecto_id)[proyecto_id]||0) + 1 if self.numero.nil? && !self.proyecto_id.nil?
    end
end
