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
# ActiveResource que devuelve sector_intervencion.
class SectorIntervencion < ActiveRecord::Base

  before_destroy :verificar_borrado

  belongs_to :categoria_sector_intervencion
  has_many :proyecto_x_sector_intervencion, :dependent => :destroy
  has_many :proyecto, :through => :proyecto_x_sector_intervencion, :uniq => true

  has_many :libro

  validates_uniqueness_of :nombre, :message => _("Nombre repetido.")
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")

  # Devuelve el porcentaje que la meta supone en el total del proyecto
  def porcentaje_x_proyecto proyecto_id=nil
    proyecto_x_sector_intervencion.where(proyecto_id: proyecto_id).sum(:porcentaje)
  end

 private

  # Comprueba si es posible borrar el sector de intervencion
  def verificar_borrado
    unless self.proyecto.empty?
      texto_proyectos = self.proyecto.limit(3).collect{|p| "'#{p.nombre}'"}.join(", ")
      texto_proyectos += ", ..." if self.proyecto.count > 3
      errors.add( "proyecto", _("Hay %{num} proyectos asociados: %{nom}")%{num: self.proyecto.count, nom: texto_proyectos})
      errors[:base] << ( _("Un sector de intervención tiene que estar vacío para poder ser borrado.") )
    end
    return false unless errors.empty?
  end

end