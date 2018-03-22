# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2015 Free Software's Seed
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
# etiquetas para los estados del workflow de contratos

class WorkflowContratoXEtiqueta < ActiveRecord::Base
  #untranslate_all
  belongs_to :workflow_contrato
  belongs_to :etiqueta
  # Lo vinculamos con agente pues desde ahí es desde donde se pueden hacer las condiciones
  belongs_to :agente

  validates_presence_of :workflow_contrato_id, message: _("Estado del workflow de contratos") + " " + ("no puede estar vacío.")
  validates_presence_of :etiqueta_id, message: _("Etiqueta") + " " + ("no puede estar vacía.")
  validates_presence_of :agente_id, message: _("Delegación") + " " + ("no puede estar vacía.")

  validates_uniqueness_of :etiqueta_id, scope: [:workflow_contrato_id, :agente_id], message: _("Etiqueta repetida.")
end
