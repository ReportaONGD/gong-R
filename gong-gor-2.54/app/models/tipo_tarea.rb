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
class TipoTarea < ActiveRecord::Base
  before_destroy :verificar_borrado

  #untranslate_all
  validates_uniqueness_of :nombre, :scope => :tipo_proyecto, :message => _("Nombre repetido.")

  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  has_many :tarea

  # Verifica que el tipo de tarea no esté siendo utilizado antes de borrar
  def verificar_borrado
    errors.add( "tarea", _("Hay tareas vinculadas")) unless self.tarea.empty?
    errors[:base] << ( _("Un tipo de tarea tiene que no estar utilizado para poder ser borrado.") ) unless errors.empty?
    return false unless errors.empty?
  end

end
