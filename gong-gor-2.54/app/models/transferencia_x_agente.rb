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
class TransferenciaXAgente < ActiveRecord::Base
  #untranslate_all

  belongs_to :agente
  belongs_to :transferencia
  validates_presence_of :transferencia_id, :message => _("No ha seleccionado transferencia.")
  validates_presence_of :agente_id, :message => _("No ha seleccionado financiador.")
  validates_uniqueness_of :transferencia_id, :scope => :agente_id, :message => _("El financiador ya esta asociada a la transferencia.")
  validates_presence_of :importe, :message => _("No se ha definido importe para el financiador.")
  #validate agente_es_financiador

  validate :comprueba_importes
 
 private
  def comprueba_importes
    errors.add(_("Importe"), _("Financiador con importe 0 no se guarda.")) if importe.nil? || importe == 0
    return errors.empty?
  end

  def agente_es_financiador
    errors.add(_("Agente"), _("no es un financiador")) unless agente.financiador
  end

end
