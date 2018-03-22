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

class TipoContrato < ActiveRecord::Base

  before_destroy :verificar_borrado

  validate :mayusculas

  validates_uniqueness_of :nombre, :scope => [:agente_id], :message => _("Nombre + NIF repetidos."), :case_sensitive => false
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")

  belongs_to :agente
  has_many :contrato
  has_many :campo_tipo_contrato, order: :nombre
  has_many :tipo_contrato_x_documento, dependent: :destroy
  has_many :documento, through: :tipo_contrato_x_documento 

  # Devuelve el nombre (esto es necesario para hacer comunes los helpers en el listado de subcuentas)
  def codigo_nombre
    return self.nombre
  end

 private
 
  def mayusculas
    self.nombre = self.nombre.upcase if self.nombre
  end

  def verificar_borrado
    errors.add :base, _("Hay %{num} contratos asociados.")%{num: contrato.count} unless contrato.empty?
    errors[:base] << ( _("Un tipo de contrato tiene que estar vacío para poder ser borrado.") ) unless errors.empty?
    return errors.empty?
 end

end
