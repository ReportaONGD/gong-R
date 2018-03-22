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

class PartidaXPartidaFinanciacion < ActiveRecord::Base
  
  #untranslate_all

  belongs_to :partida
  belongs_to :partida_financiacion
  validates_presence_of :partida_id, :message => _("No ha seleccionado partida.")
  validates_presence_of :partida_financiacion_id, :message => _("No ha seleccionado partida de financiacion.")
  validates_uniqueness_of :partida_id, :scope => :partida_financiacion_id, :message => _("La partida ya esta asociada a la partida de la financiación.")
  validate :partida_unica_x_financiacion

  after_create :crear_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs

  # En este metodo validamos que una partida general del sistema solo este relacionada una vez con alguna partida de la financiación.
  def partida_unica_x_financiacion
#    partida_financiacion.financiacion_id
    condiciones = {"partida_financiacion.proyecto_id" =>  partida_financiacion.proyecto_id, 
                   "partida_x_partida_financiacion.partida_id" => self.partida_id} if partida_financiacion.proyecto_id
    condiciones = {"partida_financiacion.agente_id" =>  partida_financiacion.agente_id,
                   "partida_x_partida_financiacion.partida_id" => self.partida_id} unless partida_financiacion.proyecto_id
    unless PartidaXPartidaFinanciacion.find(:all, :include => :partida_financiacion, :conditions => condiciones).empty?
      return errors.add "partida_id", _("Atención: La partida del sistema ya esta asociada a alguna otra partida de la financiacion.")
    end
  end

 private
  def crear_asociacion_pacs
    self.partida_financiacion.proyecto.pacs.each do |p|
      mipf = p.partida_financiacion.find_by_codigo(self.partida_financiacion.codigo)
      PartidaXPartidaFinanciacion.find_or_create_by_partida_id_and_partida_financiacion_id(self.partida_id, mipf.id)
    end if self.partida_financiacion.proyecto && self.partida_financiacion.proyecto.convenio?
  end

  def eliminar_asociacion_pacs
    self.partida_financiacion.proyecto.pacs.each do |p|
      mipf = p.partida_financiacion.find_by_codigo(self.partida_financiacion.codigo)
      PartidaXPartidaFinanciacion.destroy_all(:partida_id => self.partida_id, :partida_financiacion_id => mipf.id) 
    end if self.partida_financiacion.proyecto && self.partida_financiacion.proyecto.convenio?
  end

end
