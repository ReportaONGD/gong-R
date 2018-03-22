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

class ProgramaMarco < ActiveRecord::Base

  # Relaciones con otros elementos
  has_many :proyecto, order: :nombre, dependent: :nullify
  has_many :financiador, order: :nombre, through: :proyecto
  has_many :implementador, order: :nombre, through: :proyecto
  has_many :pais, order: :nombre, through: :proyecto
  has_many :etapa, order: :fecha_inicio, through: :proyecto
  has_many :indicador_general_x_programa_marco, dependent: :destroy
  has_many :indicador_general, through: :indicador_general_x_programa_marco
  belongs_to :moneda

  validate :nombre_mayusculas
  validates_uniqueness_of :nombre, message: _("Nombre repetido."), case_sensitive: false

  # Devuelve el nombre (esto es necesario para hacer comunes helpers)
  def codigo_nombre
    return self.nombre
  end

  def nombre_mayusculas
    self.nombre = self.nombre.upcase
  end 

  # Devuelve los nombres de los proyectos involucrados
  def nombres_proyectos
    proyecto.collect{|p| p.nombre}.join(", ")
  end

  # Devuelve los nombres de los paises involucrados
  def nombres_paises
    pais.uniq.collect{|p| p.nombre}.join(", ")
  end

  # Devuelve los nombres de los financiadores involucrados
  def nombres_financiadores
    financiador.uniq.collect{|f| f.nombre}.join(", ")
  end

  # Devuelve los nombres de los implemantadores involucrados
  def nombres_implementadores
    implementador.uniq.collect{|a| a.nombre}.join(", ")
  end

  # Devuelve la fecha de inicio del programa
  def fecha_de_inicio
    etp = etapa.reorder(:fecha_inicio).first
    # Revisar esto para considerar las prorrogas de ejecucion
    # (p.ej. meter un has_many :periodo filtrado a "prorroga" y buscar luego el aprobado mas tardio)
    etp.fecha_inicio if etp
  end

  # Devuelve la fecha de fin del programa
  def fecha_de_fin
    etp = etapa.reorder(:fecha_fin).last
    etp.fecha_fin if etp
  end
end
