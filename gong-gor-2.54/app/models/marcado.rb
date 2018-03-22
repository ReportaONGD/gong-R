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
# estado

class Marcado < ActiveRecord::Base
  #untranslate_all
  validates_uniqueness_of :nombre, :message => _("Nombre repetido.")
  validates_presence_of :nombre
  belongs_to :marcado_padre, :class_name => 'Marcado' , :foreign_key => 'marcado_padre_id'
  has_many :marcado_hijo, :class_name => 'Marcado' , :foreign_key => 'marcado_padre_id'
  has_many :presupuesto, :dependent => :nullify
  has_many :gasto, :dependent => :nullify
end
