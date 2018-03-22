# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2015 OEI 
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>. 
#
#################################################################################
#
#++
# ActiveResource que devuelve la categoria de sector_intervencion.
class CategoriaSectorIntervencion < ActiveRecord::Base

  before_destroy :verificar_borrado

  has_many :sector_intervencion
  has_many :proyecto_x_sector_intervencion, :through => :sector_intervencion
  has_many :proyecto, :through => :proyecto_x_sector_intervencion, :uniq => true

  validates_uniqueness_of :nombre, :message => _("Nombre repetido.")
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")

  # Devuelve el porcentaje que la meta supone en el total del proyecto
  def porcentaje_por_proyecto proyecto_id=nil
    proyecto_x_sector_intervencion.where(proyecto_id: proyecto_id).sum(:porcentaje)
  end

 private

  # Comprueba si es posible borrar la categoria del sector de intervencion
  def verificar_borrado
    errors.add( "sector_intervencion", _("Hay sectores de intervención asignados a esta categoría.")) unless self.sector_intervencion.empty?
    errors.add( "proyectos", _("Hay proyectos usando algún sector de intervención de esta categoría.")) unless self.proyecto.empty?
    errors[:base] << ( _("Una categoría de sector de intervención tiene que estar vacía para poder ser borrada.") ) unless errors.empty?
    return false unless errors.empty?
  end

end
