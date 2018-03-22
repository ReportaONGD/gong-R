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
# definición de datos

class DefinicionDato < ActiveRecord::Base
  before_destroy :verificar_borrado

  validates_uniqueness_of :nombre, :message => _("Nombre repetido.")
  validates_uniqueness_of :rotulo, :scope => :grupo_dato_dinamico_id, :message => _("Rótulo repetido.")
  validates_presence_of :nombre, :rotulo

  has_many :dato_texto
  has_many :proyecto, :through => :proyecto_x_definicion_dato
  has_many :proyecto_x_definicion_dato, :dependent => :destroy

  belongs_to :grupo_dato_dinamico

 private

  # Evita que se borre una definicion de dato de un proyecto existente
  def verificar_borrado
    proyectos_asociados = Proyecto.joins(:dato_texto).where("dato_texto.definicion_dato_id" => id)
    if proyectos_asociados.count > 0
      # Pillamos los 3 primeros
      proys = proyectos_asociados[0..2]
      nom_proys = proys.collect{|p| "'" + p.nombre + "'"}.join(", ")
      nom_proys = _("%{nom_proys} y %{num} más")%{nom_proys: nom_proys, num: (proyectos_asociados.count - 3)} if proyectos_asociados.count > 3
      errors.add( "documento", _("El dato está asociado a algún proyecto (%{nombres}).")%{nombres: nom_proys} )
    end

    return errors.empty?
  end
end
