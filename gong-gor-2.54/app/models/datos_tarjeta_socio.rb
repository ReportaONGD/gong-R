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
class DatosTarjetaSocio < ActiveRecord::Base
  #untranslate_all
  belongs_to :informacion_socio

  validates_presence_of :informacion_socio_id, :message => _("Debe existir un socio.")
  validates_associated :informacion_socio, :message =>  _("El socio no es correcto.")
  validates_presence_of :numero_tarjeta, :message => _("Número de Tarjeta") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :numero_tarjeta, :message => _("Número de Tarjeta repetido.")
  validates_presence_of :fecha_caducidad, :message => _("Fecha de Caducidad") + " " + _("no puede estar vacía.")
  validates_presence_of :numero_verificacion, :message => _("Número de Verificación") + " " + _("no puede estar vacío.")

  validate :luhnCheck, :expirationDate
  before_save :ccTypeCheck

  def codigo_verificacion
    self.numero_verificacion.to_s
  end

private

  # Comprueba el numero de la tarjeta segun el algoritmo de Luhn
  # http://en.wikipedia.org/wiki/Luhn_algorithm
  def luhnCheck
    tarjeta_valida = false
    if self.numero_tarjeta
      ccNumber = self.numero_tarjeta.gsub(/\D/, '')
      cardLength = ccNumber.length
      parity = cardLength % 2

      sum = 0
      for i in 0..(cardLength - 1)
        digit = ccNumber[i] - 48
        if i % 2 == parity
          digit = digit * 2
        end
        if digit > 9
          digit = digit - 9
        end
        sum = sum + digit
      end

      tarjeta_valida = (sum % 10) == 0
    end
    errors.add(_("numero_tarjeta"), _("El número de la tarjeta no es válido.")) unless tarjeta_valida
    return tarjeta_valida 
  end
 
  # Si no lo tiene, obtiene el tipo de tarjeta 
  # http://en.wikipedia.org/wiki/Bank_Identification_Number
  def ccTypeCheck
    ccNumber = self.numero_tarjeta.gsub(/\D/, '')
    case ccNumber
      when /^3[47]\d{13}$/ then self.tipo_tarjeta = "AMEX"
      when /^4\d{12}(\d{3})?$/ then self.tipo_tarjeta = "VISA"
      when /^5[1-5]\d{14}$/ then self.tipo_tarjeta = "MASTERCARD"
      when /^5[1-5]\d{17}$/ then self.tipo_tarjeta = "MASTERCARDCORP"			# No estoy seguro de esta
      when /^5[0678]\d{14}$/ then self.tipo_tarjeta = "MAESTRO"				# No estoy seguro de esta (debito mastercard)
      when /^5859\d{13}$/ then self.tipo_tarjeta = "4B"					# No estoy seguro de esta
      when /^6011\d{12}|650\d{13}$/ then self.tipo_tarjeta = "DISC"
      when /^676(292|323)\d{10}$/ then self.tipo_tarjeta = "4BMAESTRO"			# No estoy seguro de esta
      when /^3(0[0-5]|6[0-9]|8[0-1])d{11}$/ then self.tipo_tarjeta = "DINERS"
      when /^(39\d{12})|(389\d{11})$/ then self.tipo_tarjeta = "CB"
      when /^3[15]|1800\d{11}|2131\d{11}$/ then self.tipo_tarjeta = "JCB"
      else self.tipo_tarjeta = "OTRA"
    end unless self.tipo_tarjeta && self.tipo_tarjeta != ""
  end

  # Valida que no haya expirado la tarjeta
  def expirationDate
    if self.fecha_caducidad
      self.fecha_caducidad = self.fecha_caducidad.at_beginning_of_month
      errors.add(_("fecha_caducidad"), _("La tarjeta está caducada.")) if self.fecha_caducidad <= Date.today
    end
  end

end
