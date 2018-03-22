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
class LibroXProyecto < ActiveRecord::Base
  #untranslate_all

  belongs_to :libro
  belongs_to :proyecto
  validates_presence_of :libro_id, :message => _("Cuenta") + " " + _("no puede estar vacía.")
  validates_uniqueness_of :libro_id, :scope => :proyecto_id, :message => _("Cuenta repetida.")
  validate :moneda_libro

  after_create :crear_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs

  # comprobacion de que la moneda del libro esta dentro de las monedas asociadas al proyecto
  def moneda_libro
    unless Proyecto.find(self.proyecto_id).moneda.include?(Libro.find(self.libro.id).moneda)
      errors.add("libro_id", _("La moneda de la cuenta no pertenece al proyecto."))
    end if libro_id
  end

 private

    # Si el proyecto asociado es un convenio, copia la relacion a los pacs existentes
  def crear_asociacion_pacs
    self.proyecto.pacs.each {|p| p.libro_x_proyecto.find_or_create_by_libro_id(self.libro_id) } if self.proyecto.convenio?
  end

    # Si el proyecto asociado es un convenio, elimina la relacion de los pacs existentes
  def eliminar_asociacion_pacs
    self.proyecto.pacs.each {|p| LibroXProyecto.destroy_all(:proyecto_id => p.id, :libro_id => self.libro_id) } if self.proyecto.convenio?
  end
end


