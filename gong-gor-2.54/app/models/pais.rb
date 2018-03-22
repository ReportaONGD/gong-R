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
class Pais < ActiveRecord::Base

  before_destroy :verificar_borrado

  validates_presence_of :nombre, :message => _("Nombre del País") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :nombre, :message => _("Nombre del País está repetido.")
  validate :valida_codigo
  validates_uniqueness_of :codigo, :message => _("El código del País está repetido."), :case_sensitive => false, :unless => Proc.new{|p| p.codigo==""}

  has_many :proyecto_x_pais, :dependent => :destroy
  has_many :proyecto, :through => :proyecto_x_pais
  has_many :agente
  has_many :libro
  has_many :provincia
  has_many :actividad_x_pais, :dependent => :destroy
  has_many :actividad, :through => :actividad_x_pais
  has_many :moneda_x_pais, :dependent => :destroy
  has_many :moneda, :through => :moneda_x_pais
  has_one :espacio, :dependent => :nullify
  
  belongs_to :area_geografica

  after_save :actualiza_espacio
  after_destroy :borrar_espacio

  def valida_codigo
    self.codigo = codigo.upcase if codigo
  end

  def verificar_borrado
    errors.add( "agente", _("hay agentes vinculados")) unless self.agente.empty?
    errors.add( "proyecto",_("hay proyectos")) unless self.proyecto.empty?
    errors.add( "libro", _("hay libros")) unless self.libro.empty?
    errors[:base] << ( _("Un país tiene que estar vacío para poder ser borrado.") ) unless errors.empty?
    return false unless errors.empty?
  end

  def actualiza_espacio
    espacio_padre = Espacio.find_by_nombre("Paises")
    if espacio_padre
      if espacio
        espacio.update_attributes :nombre => nombre, :espacio_padre_id => espacio_padre.id
        espacio.errors.each {|e,m|  errors.add "", m}
      else
        espacio = Espacio.create :nombre => nombre, :pais_id => id, :espacio_padre_id => espacio_padre.id, :descripcion => _("Espacio del país") + " " + nombre
        espacio.errors.each {|e,m|  errors.add "", m}
        if espacio.errors.empty?
          sl = Espacio.create :nombre => "Socias Locales", :espacio_padre_id => espacio.id, :descripcion => _("Espacio de Socias Locales del país") + " " + nombre
          dl = Espacio.create :nombre => "Delegaciones", :espacio_padre_id => espacio.id, :descripcion => _("Espacio de Delegaciones del país") + " " + nombre
          sl.errors.each {|e,m|  errors.add "", m}
          dl.errors.each {|e,m|  errors.add "", m}
          for esp in Espacio.find_all_by_definicion_espacio_pais_and_espacio_padre_id(true,nil)
            ne = Espacio.create :nombre => esp.nombre, :espacio_padre_id => espacio.id, :definicion_espacio_pais_id => esp.id, :ocultar => esp.ocultar
            ne.errors.each {|e,m|  errors.add "", m}
          end
        end
      end
    else
      logger.info "ERROR: No existe el espacio padre para el agente " + nombre
    end
  end

  def borrar_espacio
    if espacio
      for un_espacio in Espacio.find_all_by_definicion_espacio_pais(true)
        esp = Espacio.find_by_espacio_padre_id_and_definicion_espacio_pais_id(espacio.id, un_espacio.id)
        esp.destroy if esp
        esp.errors.each {|e,m|  errors.add "", m} if esp
      end
      espacio.destroy
    end
  end

end
