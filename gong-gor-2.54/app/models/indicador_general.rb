# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2017 Free Software's Seed, CENATIC y IEPALA
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
# indicador general 
class IndicadorGeneral < ActiveRecord::Base

  validate :valida_formato_codigo
  validates_uniqueness_of :codigo, message: _("Indicador General repetido.")
  validates_uniqueness_of :nombre, message: _("Nombre repetido.")
  validates_presence_of :codigo, message: _("Código") + " " + _("no puede estar vacío.")
  validates_presence_of :nombre, message: _("Nombre") + " " + _("no puede estar vacío.")

  before_destroy :verificar_borrado

  # Devuelve el codigo-nombre (es necesario para unificar helpers)
  def codigo_nombre
    self.codigo + " " + self.nombre
  end
  def codigo_descripcion
    self.codigo + " - " + self.descripcion
  end

 private

  def valida_formato_codigo
    # Comprueba que no tenga caracteres no permitidos
    if self.codigo && self.codigo.match(/[@#]/)
      errors.add _("Código"), _("El código no puede contener los caracteres '@' ó '#'.")
    else
      # Elimina los espacios anteriores y posteriores,
      # cambia el resto de espacios por "_" y lo pone todo en mayusculas
      self.codigo = self.codigo.upcase.gsub(' ','_') if self.codigo
    end
    return errors.empty?
  end

  def verificar_borrado
    return true
  end
end
