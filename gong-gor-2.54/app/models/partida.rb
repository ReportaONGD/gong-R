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
class Partida < ActiveRecord::Base

  before_destroy :verificar_borrado

  has_many :gasto
  has_many :presupuesto
  # has_and_belongs_to_many :partida_financiacion, :join_table =>  "partida_x_partida_financiacion"
  has_many :partida_financiacion, :through => :partida_x_partida_financiacion, :uniq => true
  has_many :partida_x_partida_financiacion
  has_many :subpartida

  # Codigo de contabilidad (hay uno por cada delegacion)
  has_many :cuenta_contable, :as => :elemento_contable

  validate :codigo_mayusculas
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  validates_presence_of :codigo, :message => _("Código") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :nombre, :message => _("Nombre repetido.")
  validates_uniqueness_of :codigo, :message => _("Código repetido."), :case_sensitive => false

  #def subpartida_proyecto proyecto_id
  #  subpartidas = Array.new
  #  presupuesto.find_all_by_proyecto_id(proyecto_id).each do |pre|
  #    subpartidas.push( pre.subpartida )
  #  end
  #  return subpartidas.uniq
  #end

#  def subpartida_agente agente_id
#    subpartidas = Array.new
#    Subpartida.find_all_by_agente_id_and_partida_id(agente_id, id).each do |pre|
#      subpartidas.push( pre.subpartida ) unless pre.subpartida.nil? or pre.subpartida.proyecto_id
#    end
#    return subpartidas.uniq
#  end


  def codigo_mayusculas
    self.codigo = self.codigo.upcase
    # Reemplaza ' - ' quitandole los espacios (se usa esa forma en codigo nombre)
    self.codigo = self.codigo.gsub(' - ','-')
  end

  # devuelve codigo y nombre en una misma cadena.
  def codigo_nombre proyecto_id=nil
    texto = ""
    if proyecto_id
      partida = partida_financiacion.find(:first, :conditions => {"proyecto_id" => proyecto_id})
      texto += "(" + partida.codigo + ") " if partida 
    end
    texto += self.codigo + " - " + self.nombre
    return texto 
  end

  def tipo_mayusculas
    self.tipo.capitalize
  end

  # devuelve las partidas del sistema que no fueron asociadas a ninguna partida de financiación
  def self.partidas_pendientes_de_financiacion proyecto_id
    partidas = Partida.find( :all, :include => "partida_financiacion", :conditions => ["partida_financiacion.proyecto_id = ?", proyecto_id] ).collect{ |p| p.id }
    conditions = [ "id NOT IN (?)", partidas]  if ! partidas.empty?
    Partida.where(ocultar_proyecto: false).where(conditions).order("partida.codigo")
  end

  # devuelve las partidas del sistema que no fueron asociadas a ninguna partida de financiación en el mapeo de agentes
  def self.partidas_pendientes_de_financiacion_para_financiador agente_id
    partidas = Partida.find( :all, :include => "partida_financiacion", :conditions => ["partida_financiacion.agente_id = ?", agente_id] ).collect{ |p| p.id }
    conditions = [ "id NOT IN (?)", partidas]  if ! partidas.empty?
    Partida.where(ocultar_proyecto: false).where(conditions).order("partida.codigo")
  end

  # comprueba si la partida esta asociada a alguna partida de financiacion
  def partida_asociada proyecto
    partida_financiacion.find :first, :conditions => {"proyecto_id" => proyecto}
  end

  def verificar_borrado
    unless self.presupuesto.empty?
      nulos = false 
      self.presupuesto.collect{|p| (p.proyecto||p.agente)}.uniq.each do |objeto| 
        errors.add( "presupuesto",_("Hay presupuestos en el proyecto %{nombre}") % {:nombre => "<b>" + objeto.nombre + "</b>"}) if objeto.class.name == "Proyecto"
        errors.add( "presupuesto",_("Hay presupuestos en el agente %{nombre}") % {:nombre => "<b>" + objeto.nombre + "</b>"}) if objeto.class.name == "Agente" 
        nulos = true if objeto.class.name == "NilClass"
      end
      errors.add( "presupuesto",_("Hay presupuestos") ) if nulos
    end
    unless self.gasto.empty?
      nulos = false 
      self.gasto.collect{|p| (p.proyecto||p.agente)}.uniq.each do |objeto|
        errors.add( "gasto", _("Hay gastos en el proyecto %{nombre}") % {:nombre => "<b>" + objeto.nombre + "</b>"}) if objeto.class.name == "Proyecto"
        errors.add( "gasto", _("Hay gastos en el agente %{nombre}") % {:nombre => "<b>" + objeto.nombre + "</b>"}) if objeto.class.name == "Agente"
        nulos = true if objeto.class.name == "NilClass"
      end
      errors.add( "gasto", _("Hay gastos") ) if nulos
    end
    unless partida_financiacion.empty?
      nulos = false 
      self.partida_financiacion.collect{|p| p.proyecto}.uniq.each do |objeto|
        errors.add( "partida_financiacion", _("Hay partidas de financiación en el proyecto %{nombre}") % {:nombre => "<b>"+objeto.nombre+"</b>"}) if objeto 
        nulos = true if objeto.class.name == "NilClass" 
      end
      errors.add( "partida_financiacion", _("Hay partidas de financiación") ) if nulos
    end
    unless subpartida.empty?
      nulos = false 
      self.subpartida.collect{|sp| sp.proyecto}.uniq.each do |objeto|
        errors.add( "subpartida", _("Hay subpartidas en el proyecto %{nombre}") % {:nombre => "<b>"+objeto.nombre+"</b>"}) if objeto 
        nulos = true if objeto.class.name == "NilClass" 
      end
      errors.add( "subpartida", _("Hay subpartidas") ) if nulos
    end
    errors[:base] << ( "<br>" + _("Una partida tiene que estar vacía para poder ser borrada.") ) unless errors.empty?
    return errors.empty?
 end
end
