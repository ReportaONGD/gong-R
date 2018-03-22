# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2016 OEI 
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
# ActiveResource que devuelve la categoria de area_actuacion.
class CategoriaAreaActuacion < ActiveRecord::Base

  before_destroy :verificar_borrado

  has_many :area_actuacion
  has_many :proyecto_x_area_actuacion, :through => :area_actuacion
  has_many :proyecto, :through => :proyecto_x_area_actuacion, :uniq => true

  validates_uniqueness_of :nombre, :message => _("Nombre repetido.")
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")

  # Devuelve el porcentaje que la meta supone en el total del proyecto
  def porcentaje_por_proyecto proyecto_id=nil
    proyecto_x_area_actuacion.where(proyecto_id: proyecto_id).sum(:porcentaje)
  end

 private

  # Comprueba si es posible borrar la categoria del area de actuacion
  def verificar_borrado
    errors.add( "area_actuacion", _("Hay áreas de actuación asignadas a esta categoría.")) unless self.area_actuacion.empty?
    errors.add( "proyectos", _("Hay proyectos usando alguna área de actuación de esta categoría.")) unless self.proyecto.empty?
    errors[:base] << ( _("Una categoría de área de actuación tiene que estar vacía para poder ser borrada.") ) unless errors.empty?
    return false unless errors.empty?
  end

end
