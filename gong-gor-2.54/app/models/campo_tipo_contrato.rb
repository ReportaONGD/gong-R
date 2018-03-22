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

class CampoTipoContrato < ActiveRecord::Base

  # Recoge los posibles tipos de campo
  TIPOS_DE_CAMPO = { "boolean" => ["igual a"],
                     "text" => [],
                     "number" => ["menor o igual a", "mayor o igual a", "igual a"]
   }

  before_destroy :verificar_borrado

  belongs_to :tipo_contrato
  has_many :contrato_x_campo_tipo_contrato

  validates_associated :tipo_contrato, message: _("El tipo de contrato asociado no es correcto.")
  validates_presence_of :nombre, message: _("Nombre") + " " + _("no puede estar vacío.")
  validates_presence_of :etiqueta, message: _("Etiqueta") + " " + _("no puede estar vacía.")
  validates_presence_of :tipo_campo, message: _("Tipo de campo") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :nombre, scope: :tipo_contrato_id, message: _("Nombre repetido.")
  validate :valida_nombre, :valida_tipo_campo, :valida_condicion_campo

  # Valida un valor introducido contra el propio tipo de campo
  def valida_valor valor=nil
    validado = true 
    unless tipo_condicion.blank?
      valor_dato = valor ? valor.valor_dato : nil
      validado = false if valor_dato.blank?
      validado = case tipo_condicion
        when "igual a" then valor_dato == valor_condicion
        when "menor o igual a" then valor_dato.to_f <= valor_condicion.to_f
        when "mayor o igual a" then valor_dato.to_f >= valor_condicion.to_f
      end unless valor_dato.blank?
    end
    return validado
  end

 private

  # Valida el formato del nombre del campo
  def valida_nombre
    self.nombre = self.nombre.downcase.gsub(/\s+/,"_")
    return true
  end
 
  # Verifica que el tipo de campo sea uno de los permitidos
  def valida_tipo_campo
    errors.add :base, _("El tipo de campo no es válido.") unless CampoTipoContrato::TIPOS_DE_CAMPO.keys.include? self.tipo_campo
    return errors.empty?
  end

  # Valida que la condicion del campo sea correcta
  def valida_condicion_campo
    if self.tipo_condicion.blank?
      self.tipo_condicion = nil
      self.valor_condicion = nil
    else
      errors.add :base, _("La condición no es válida para el tipo de campo.") unless CampoTipoContrato::TIPOS_DE_CAMPO[self.tipo_campo].include?(self.tipo_condicion)
      errors.add :base, _("El valor de la condición no puede estar vacío.") if self.valor_condicion.blank?
    end
    return errors.empty?
  end
  
  # Verifica que pueda borrar el campo
  def verificar_borrado
    errors.add :base, _("Hay contratos utilizando este tipo de dato.") unless contrato_x_campo_tipo_contrato.empty?
    errors.add :base, _("No se puede borrar un tipo de campo si ya está asociado a contratos. Desactívelo si no desea que aparezca en contratos futuros.") unless errors.empty?
    return errors.empty?
 end

end
