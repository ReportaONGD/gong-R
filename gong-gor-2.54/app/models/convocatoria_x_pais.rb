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
# MonedaXPais: relaciona moneda con pais

class ConvocatoriaXPais < ActiveRecord::Base

  before_destroy :verificar_borrado

  belongs_to :convocatoria
  belongs_to :pais

  validates_presence_of :convocatoria_id, :message => _("Convocatoria") + " " + _("no puede estar vacía.")
  validates_associated :convocatoria, :message => _("La convocatoria asociada no es correcta.")
  validates_presence_of :pais_id, :message => _("País") + " " + _("no puede estar vacío.")
  validates_associated :pais, :message =>  _("El país asociado no es correcto.")

  validates_uniqueness_of :pais_id, :scope => :convocatoria_id, :message => _("País ya asignado.")

 
 private

  def verificar_borrado
    self.convocatoria.proyecto.each do |proyecto|
      errors.add( "pais", _("El país está asignado en el proyecto %{proj}.")%{:proj => proyecto.nombre}) if proyecto.pais.include? self.pais
    end
    errors[:base] << ( _("No se puede eliminar un país si está asignado a algún proyecto de la convocatoria.") ) unless errors.empty?
    return errors.empty?
  end 
end
