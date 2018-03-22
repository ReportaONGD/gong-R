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
class PresupuestoIngreso < ActiveRecord::Base

  before_destroy :verifica_etapa

  belongs_to :moneda
  belongs_to :partida_ingreso
  belongs_to :agente
  belongs_to :financiador, class_name: "Agente", foreign_key: "financiador_id"
  belongs_to :proyecto
  belongs_to :etapa
  belongs_to :tasa_cambio

  has_many :presupuesto_detallado, :foreign_key => 'presupuesto_ingreso_id', :class_name => "PresupuestoIngresoDetallado", dependent: :destroy

  # Auditado de modificaciones, comentarios y marcado
  include ::Auditable
  has_many :comentario, as: :elemento, dependent: :destroy
  belongs_to :marcado

  validates_presence_of :moneda, :message => _("Moneda") + " " + _("no puede estar vacía.")
  validates_presence_of :agente, :message => _("Agente") + " " + _("no puede estar vacío.")
  validates_presence_of :partida_ingreso, :message => _("Partida") + " " + _("no puede estar vacío.")
  validates_presence_of :concepto, :message => _("Concepto") + " " + _("no puede estar vacío.")
  validates_presence_of :etapa, :message => _("Etapa") + " " + _("no puede estar vacía.")
  validates_numericality_of :importe, :message => _("Importe") + " " + _("no puede estar vacío.")
  validates_numericality_of :porcentaje, :greater_or_equal_than => 0, :message => _("El porcentaje de funcionamiento debe ser positivo.")

  validates_uniqueness_of :concepto, :scope => [:agente_id, :etapa_id], :message => _("Concepto repetido") + " (%{value})"

  validate :verifica_etapa
  before_save :adaptacion_datos
  after_create :dividir_por_mes


    # Para presupuestos de agentes, comprueba que la etapa no este cerrada o sea no presupuestable
  def verifica_etapa
    e_old = Etapa.find_by_id(etapa_id_was) if self.etapa_id_was
    if self.etapa.cerrada || !self.etapa.presupuestable || (self.etapa_id_was && (e_old.cerrada|| !e_old.presupuestable))
      errors.add(_("Etapa"), _("La etapa esta cerrada. No se pueden modificar presupuestos."))
      return false
    else
      return true
    end
  end

  # Solo para permitir el uso de algunos elementos de gestion comun
  def proyecto
    nil
  end

  # Devuelve el porcentaje de funcionamiento formateado
  def porcentaje_funcionamiento 
    # Redondeamos a 2 decimales
    return ('%.2f' % (self.porcentaje_convertido||0.0)) + "%"
  end

  # 1) convierte el concepto a mayusculas
  # 2) actualiza el valor de la tasa de cambio usada
  # 3) si la partida no es de proyecto ajusta el % de overhead (todo es ingreso de funcionamiento)
  def adaptacion_datos
    # Concepto en mayusculas
    self.concepto = self.concepto.upcase
    # Cambia la tasa de cambio si es nuevo o se ha actualizado etapa o moneda
    if (self.id.nil? || self.etapa_id_changed? || self.moneda_id_changed?)
      tc = TasaCambio.tasa_cambio_para_presupuesto(self.etapa,self.moneda_id)
      self.tasa_cambio_id = tc ? tc.id : nil
    end
    # Ajusta el % de ingresos de funcionamiento cuando no es una partida de proyecto
    self.porcentaje = 1.0 unless (self.partida_ingreso && self.partida_ingreso.proyecto)
    # y en general, evita que el % sea mayor de 1
    self.porcentaje = 1.0 if self.porcentaje > 1.0
  end
  
  # Metodo especifico creado para el report y la exportacion
  def moneda_abreviatura
    return Moneda.find(self.moneda_id).abreviatura if self.moneda_id
  end


  # Metodo especifico creado para el report y la exportacion
  def agente_nombre
    return Agente.find(self.agente_id).nombre if self.agente_id
  end

  # Devuelve el importe en la moneda base (principal) del proyecto/agente
  def importe_ml
    return self.importe * self.tasa_cambio
  end
  def importe_en_base
    ixtc = self.importe_ml
    return ('%.2f' % ixtc).to_s + " " + self.agente.moneda_principal.abreviatura if ixtc
  end

  # Devuelve el importe en la divisa del proyecto/agente
  def importe_divisa
    return self.importe * self.tasa_cambio_divisa
  end
  def importe_en_divisa
    divisa = (self.agente||self.proyecto).moneda_intermedia
    ixtc = self.importe_divisa if divisa
    return ('%.2f' % ixtc).to_s + " " + divisa.abreviatura if divisa && ixtc
  end

  # Devuelve el importe de funcionamiento
  def importe_funcionamiento
    return (self.importe||0.0) * (self.porcentaje||0.0) 
  end

  # Devuelve el importe de funcionamiento en la moneda base (principal) del proyecto/agente
  def importe_funcionamiento_en_base
    ixtc = self.importe_funcionamiento * self.tasa_cambio
    return ('%.2f' % ixtc).to_s + " " + self.agente.moneda_principal.abreviatura if ixtc
  end

  # Devuelve el importe de funcionamiento en la divisa del proyecto/agente
  def importe_funcionamiento_en_divisa
    divisa = self.agente.moneda_intermedia
    ixtc = self.importe_funcionamiento * self.tasa_cambio_divisa if divisa
    return ('%.2f' % ixtc).to_s + " " + divisa.abreviatura if divisa && ixtc
  end

  # Actualiza el detalle del presupuesto.
  def actualizar_presupuesto_detallado listado
    # Actualiza el detalle solo si se puede
    if verifica_etapa
      presupuesto_detallado.clear
      listado.each do |mes, value|
        presupuesto_detallado.create(value) unless value[:importe] == ""
      end
      errors.add(_('Porcentajes'),_("La suma del detalle no coincide con la importe de la linea del presupuesto. Vuelva a editar el detalle para corregirlo.")) unless self.importe == presupuesto_detallado.inject(0) {|sum,p| sum+(p.importe||0.0)}
    end
  end

  def dividir_por_mes fecha_inicio=nil, fecha_fin=nil, evitar=nil
    fecha_inicio ||= self.etapa.fecha_inicio if self.etapa
    fecha_fin ||= self.etapa.fecha_fin if self.etapa
    # Toma los valores segun evitemos meses o no
    meses_repartir = evitar ? 0 : etapa.meses
    ultimo_mes = evitar ? 0 : etapa.periodos
    # Si evitamos meses, hacemos los calculos de el total y el ultimo
    evitar.each do |m|
      if m[1] == "false"
        ultimo_mes = m[0].to_i
        meses_repartir += 1
      end
    end if evitar
    detalle, fecha = Hash.new,  Date.new(fecha_inicio.year, fecha_inicio.month, 1)
    # Hacemos el ajuste en base a los centimos/centavos y no a las unidades de moneda
    # Si no tenemos meses a repartir, el divmod daria un error...
    unless meses_repartir == 0
      importe_x_mes, resto = (importe * 100).divmod(meses_repartir)
    else
      # No hay meses completos, asi que dejamos el resto para los dias sueltos
      importe_x_mes, resto = 0.0, (importe*100) if etapa.meses == 0
      # Si hay mas de un mes, pero se deja sin meses a repartir... sera por algo...
      importe_x_mes, resto = 0.0, 0.0 unless etapa.meses == 0
    end
    # Volvemos a multiplicar por 100 para obtener unidades de moneda
    importe_x_mes, resto = importe_x_mes/100, resto/100
    for mes in 1..(etapa.periodos)
      # Si estamos evitando algunos meses, comprobamos si este es uno
      if evitar && evitar["#{mes}"] == "true"
        detalle[mes] = { :importe => 0, :fecha_inicio => fecha >> (mes -1), :fecha_fin => fecha_fin, :mes => mes }
      else
        # Para el último, hacemos un ajuste fino
        if mes != ultimo_mes 
          detalle[mes] = { :importe => importe_x_mes, :fecha_inicio => (mes == 1 ? fecha_inicio : fecha >> (mes - 1)), :fecha_fin => (fecha >> mes) - 1, :mes => mes }
        # Para los intermedios...
        else 
          importe = resto + ( (evitar ||etapa.periodos == etapa.meses) ? importe_x_mes : 0)
          detalle[mes] = { :importe => importe, :fecha_inicio => fecha >> (mes -1), :fecha_fin => fecha_fin, :mes => mes }  
        end
      end
    end
    #debugger
    actualizar_presupuesto_detallado detalle unless etapa.cerrada
  end

  # Comprueba si el detalle del presupuesto se ha configurado adecuadamente.
  def comprobar_presupuesto_detallado
    return ( presupuesto_detallado.inject(0) {|suma, p| suma + (p.importe||0.0)} == self.importe ) ? true : false
  end

  # Devuelve la tasa de cambio para la línea de presupuesto (si existe)
  def tasa_cambio
    tc = TasaCambio.find_by_id(self.tasa_cambio_id)
    return (tc ? tc.tasa_cambio : 0.0)
  end

  # Devuelve la tasa de cambio a divisa para la línea de presupuesto (si existe)
  def tasa_cambio_divisa
    tc = TasaCambio.find_by_id(self.tasa_cambio_id)
    return (tc ? tc.tasa_cambio_moneda_intermedia : 0.0)
  end

  # Devuelve un texto amigable para la tasa de cambio del presupuesto
  def cadena_tasa_cambio
    moneda_principal = (self.etapa.agente || self.etapa.proyecto).moneda_principal
    return self.tasa_cambio.to_s + " " + self.moneda.abreviatura + "/" + moneda_principal.abreviatura
  end

  # Devuelve un texto amigable para la tasa de cambio a divisa del presupuesto
  def cadena_tasa_cambio_divisa
    divisa = (self.etapa.agente || self.etapa.proyecto).moneda_intermedia
    return self.tasa_cambio_divisa.to_s + " " + self.moneda.abreviatura + "/" + divisa.abreviatura if divisa 
  end

end
