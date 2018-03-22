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
# definición de estado

class DefinicionEstado < ActiveRecord::Base

  before_destroy :verificar_borrado

  validates_uniqueness_of :nombre, :message => _("Nombre repetido.")
  validates_uniqueness_of :primer_estado, :unless => "self.primer_estado == false", :message => _("Primer estado debe ser único")
  validates_presence_of :nombre

  has_many :definicion_estado_padre, :class_name => 'DefinicionEstadoXDefinicionEstado' , :foreign_key => 'definicion_estado_hijo_id'
  has_many :estado_padre, :through => :definicion_estado_padre, :source => :definicion_estado_padre
  has_many :definicion_estado_hijo, :class_name => 'DefinicionEstadoXDefinicionEstado', :foreign_key => 'definicion_estado_padre_id'
  has_many :estado_hijo, :through => :definicion_estado_hijo, :order => "orden", :source => :definicion_estado_hijo
  has_many :estado
  has_many :definicion_estado_tarea
  has_many :definicion_estado_x_etiqueta
  has_many :etiqueta, :through => :definicion_estado_x_etiqueta 

  def verificar_borrado
   errors.add( :base, _("Existen proyectos relacionados con este estado. Imposible borrar.") ) unless estado.empty?
   return false unless errors.empty?
  end

  def estado_padre_visualizacion
    estado_padre.inject("") {|sum, e| sum + "  " + e.nombre}
  end

  def nombre_completo
    self.orden ? self.orden.to_s + " - " + self.nombre : self.nombre
  end

end
