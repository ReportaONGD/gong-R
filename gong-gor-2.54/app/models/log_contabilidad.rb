# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2014 Free Software's Seed
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
class LogContabilidad < ActiveRecord::Base
  belongs_to :agente
  belongs_to :usuario

  validates_presence_of :agente_id, :message => _("Agente") + " " + _("no puede estar vacío.")
  validates_presence_of :elemento, :message => _("Elemento") + " " + _("no puede estar vacío.")

  # Nos interesa el orden por fecha de creacion y ese es precisamente el que hay por defecto
  scope :valido, ->(tipo) { where(finalizado_ok: true, elemento: tipo) }
end
