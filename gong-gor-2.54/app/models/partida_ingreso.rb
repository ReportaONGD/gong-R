# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2015 Free Software's Seed
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
class PartidaIngreso < ActiveRecord::Base

  before_destroy :verificar_borrado

  has_many :ingreso
  has_many :presupuesto_ingreso

  validates_uniqueness_of :nombre, :message => _("Nombre repetido."), :case_sensitive => false
  validates_presence_of :nombre
  validate :nombre_mayusculas

  # Codigo de contabilidad (hay uno por cada delegacion)
  has_many :cuenta_contable, :as => :elemento_contable, :dependent => :destroy


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
    self.presupuesto_ingreso.count unless etapa
    self.presupuesto_ingreso.where(etapa_id: etapa).count if etapa
  end

  # La suma de los prespuestos en la moneda principal
  def suma_presupuestos condicion=nil
    suma = 0.0
    etapa, filtro = obtiene_filtros(condicion)
    suma = self.presupuesto_ingreso.where(etapa_id: etapa).joins(:tasa_cambio).sum("importe * tasa_cambio").to_f if etapa && filtro.nil?
    suma = self.presupuesto_ingreso.where(etapa_id: etapa).joins(:presupuesto_detallado).where(filtro).joins(:tasa_cambio).
                                    sum("presupuesto_ingreso_detallado.importe * tasa_cambio").to_f if etapa && filtro
    return suma
  end
  # La suma de los presupuestos en la divisa
  def suma_presupuestos_divisa condicion=nil
    etapa, filtro = obtiene_filtros(condicion)
    suma = 0.0
    moneda_principal_id = (etapa.agente||etapa.proyecto).moneda_id if etapa
    moneda_intermedia_id = (etapa.agente||etapa.proyecto).moneda_intermedia_id if etapa
    if etapa && moneda_intermedia_id
      # Esta operacion la hace en 2 partes...
      # en la primera obtiene la suma de todas las monedas salvo de la principal
      suma = self.presupuesto_ingreso.where(etapa_id: etapa).where('presupuesto_ingreso.moneda_id != ?', moneda_principal_id).
                                      joins(:tasa_cambio).sum("importe * tasa_cambio_divisa").to_f unless filtro
      suma = self.presupuesto_ingreso.where(etapa_id: etapa).where('presupuesto_ingreso.moneda_id != ?', moneda_principal_id).
                                      joins(:presupuesto_detallado).where(filtro).
                                      joins(:tasa_cambio).sum("presupuesto_ingreso_detallado.importe * tasa_cambio_divisa").to_f if filtro
      # en la segunda obtiene la suma de todos los presupuestos en moneda_principal...
      subsuma = self.presupuesto_ingreso.where(etapa_id: etapa, moneda_id: moneda_principal_id).sum("importe").to_f unless filtro
      subsuma = self.presupuesto_ingreso.where(etapa_id: etapa, moneda_id: moneda_principal_id).
                                         joins(:presupuesto_detallado).where(filtro).
                                         sum("presupuesto_ingreso_detallado.importe").to_f if filtro
      # ... averigua la TC de divisa a moneda principal
      tc = TasaCambio.tasa_cambio_para_presupuesto(etapa, moneda_intermedia_id)
      # ... y por ultimo divide (la inversa de multiplicar)
      suma += (subsuma / tc.tasa_cambio) if tc && tc.tasa_cambio != 0
    end
    return suma
  end
  # El porcentaje respecto al total de presupuestos de la etapa
  def porcentaje_presupuestos condicion=nil
    etapa, filtro = obtiene_filtros(condicion)
    pct = 0.0
    if etapa
      actual = suma_presupuestos(etapa)
      total = PresupuestoIngreso.where(etapa_id: etapa).joins(:tasa_cambio).sum("importe * tasa_cambio").to_f
      pct = actual / total if actual && total && total != 0.0
    end
    return pct * 100
  end
  # El total de funcionamiento
  def suma_presupuesto_funcionamiento condicion=nil
    suma = 0.0
    etapa, filtro = obtiene_filtros(condicion)
    suma = self.presupuesto_ingreso.where(etapa_id: etapa).joins(:tasa_cambio).sum("importe * porcentaje * tasa_cambio").to_f if etapa && filtro.nil?
    suma = self.presupuesto_ingreso.where(etapa_id: etapa).joins(:presupuesto_detallado).where(filtro).joins(:tasa_cambio).
                                    sum("presupuesto_ingreso_detallado.importe * porcentaje * tasa_cambio").to_f if etapa && filtro
    return suma
  end
  # El total de funcionamiento para la divisa
  def suma_presupuesto_funcionamiento_divisa condicion=nil
    etapa, filtro = obtiene_filtros(condicion)
    suma = 0.0
    moneda_principal_id = (etapa.agente||etapa.proyecto).moneda_id if etapa
    moneda_intermedia_id = (etapa.agente||etapa.proyecto).moneda_intermedia_id if etapa
    if etapa && moneda_intermedia_id
      # Esta operacion la hace en 2 partes...
      # en la primera obtiene la suma de todas las monedas salvo de la principal
      suma = self.presupuesto_ingreso.where(etapa_id: etapa).where('presupuesto_ingreso.moneda_id != ?', moneda_principal_id).
                                      joins(:tasa_cambio).sum("importe * porcentaje * tasa_cambio_divisa").to_f unless filtro
      suma = self.presupuesto_ingreso.where(etapa_id: etapa).where('presupuesto_ingreso.moneda_id != ?', moneda_principal_id).
                                      joins(:presupuesto_detallado).where(filtro).
                                      joins(:tasa_cambio).sum("presupuesto_ingreso_detallado.importe * porcentaje * tasa_cambio_divisa").to_f if filtro
      # en la segunda obtiene la suma de todos los presupuestos en moneda_principal...
      subsuma = self.presupuesto_ingreso.where(etapa_id: etapa, moneda_id: moneda_principal_id).
                                         sum("importe * porcentaje").to_f unless filtro
      subsuma = self.presupuesto_ingreso.where(etapa_id: etapa, moneda_id: moneda_principal_id).
                                         joins(:presupuesto_detallado).where(filtro).
                                         sum("presupuesto_ingreso_detallado.importe * porcentaje").to_f if filtro
      # ... averigua la TC de divisa a moneda principal
      tc = TasaCambio.tasa_cambio_para_presupuesto(etapa, moneda_intermedia_id)
      # ... y por ultimo divide (la inversa de multiplicar)
      suma += (subsuma / tc.tasa_cambio) if tc && tc.tasa_cambio != 0
    end
    return suma
  end

  # Devuelve el nombre (esto es asi por compatibilidad con metodos generales)
  def codigo_nombre
    self.nombre
  end

private

  def nombre_mayusculas
    self.nombre = self.nombre.upcase
  end

  def verificar_borrado
   errors.add( "presupuesto_ingreso", _("Existen presupuestos de ingresos asociados a la partida") ) unless presupuesto_ingreso.empty?
   return errors.empty?
  end


  # Descompone un filtro de ayudas a resumenes
  def obtiene_filtros condicion=nil
    case condicion.class.name
      when "Etapa"
        etapa = condicion
        filtro = nil
      when "Hash"
        etapa = condicion[:etapa]
        filtro = ["presupuesto_ingreso_detallado.fecha_inicio >= ? AND presupuesto_ingreso_detallado.fecha_fin <= ?", condicion[:fecha_inicio], condicion[:fecha_fin]]
      else
        etapa = nil
        filtro = nil
    end
    return etapa, filtro
  end
end
