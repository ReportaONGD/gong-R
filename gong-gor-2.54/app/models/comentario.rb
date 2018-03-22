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
# comentario

class Comentario < ActiveRecord::Base
  #untranslate_all
  belongs_to :usuario
  belongs_to :tarea
  belongs_to :elemento, polymorphic: true
  validates_presence_of :texto, message: _("Texto") + " " + _("no puede estar vacio.")
  validates_presence_of :elemento_type, message: _("Tipo de comentario") + " " + _("no puede estar vacío.")
  validates_presence_of :elemento_id, message: _("Objeto referido") + " " + _("no puede estar vacío.")
end
