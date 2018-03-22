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

class ContratoXCampoTipoContrato < ActiveRecord::Base


  before_destroy :verificar_modificacion

  belongs_to :campo_tipo_contrato
  belongs_to :contrato

  validates_associated :campo_tipo_contrato, message: _("El campo asociado no es correcto.")
  validates_associated :contrato, message: _("El contrato asociado no es correcto.")
  validates_uniqueness_of :campo_tipo_contrato_id, scope: [:contrato_id], message: _("El campo ya está definido en el contrato.")

  before_save :verificar_modificacion
  before_save :adapta_valor_campo

  # Devuelve un valor adaptado segun el tipo de campo que sea
  def valor_adaptado
    case campo_tipo_contrato.tipo_campo
      when "boolean" then ( self.valor_dato == "1" ? _("Sí") : _("No") )
      when "number" then self.valor_dato.to_f.to_s
      else self.valor_dato
    end
  end

 private

  # Adapta el valor guardado segun el tipo de campo
  def adapta_valor_campo
    self.valor_dato = case campo_tipo_contrato.tipo_campo
      when "boolean" then ( self.valor_dato == "1" ? "1" : "0" )
      when "number" then self.valor_dato.blank? ? nil : self.valor_dato.to_f.to_s
      else self.valor_dato
    end 
  end

  # Verifica el borrado del contrato
  def verificar_modificacion
   errors.add :base, _("El contrato está aprobado: No se pueden modificar sus datos de identificación") if contrato.aprobado? 
   return errors.empty?
  end

end
