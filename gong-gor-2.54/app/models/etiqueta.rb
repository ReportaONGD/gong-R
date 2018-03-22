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
class Etiqueta < ActiveRecord::Base
  #untranslate_all
  has_many :etiqueta_x_documento, :dependent => :destroy
  has_many :documento, :through => :etiqueta_x_documento, :uniq => true
  #has_and_belongs_to_many :documento, :join_table => :etiqueta_x_documento

  validates_uniqueness_of :nombre, :message => _("Nombre repetido")

  # Devuelve los tipos de etiquetas 
  def self.tipos_etiqueta
    [[_("Etiquetas comunes"),"comunes"],[_("Etiquetas de proyecto"),"proyecto"],[_("Etiquetas de contratos"),"contrato"]]
  end

end