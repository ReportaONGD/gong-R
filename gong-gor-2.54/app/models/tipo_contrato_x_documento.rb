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

class TipoContratoXDocumento < ActiveRecord::Base

  belongs_to :tipo_contrato
  belongs_to :documento

  validates_uniqueness_of :documento_id, :scope => [:tipo_contrato_id], :message => _("El documento ya está asociado al tipo de contrato.")
  validates_presence_of :tipo_contrato_id, :message => _("Tipo de Contrato") + " " + _("no puede estar vacío.")
  validates_associated :tipo_contrato, message: _("El tipo de contrato asociado no es válido.")
  validates_presence_of :documento_id, :message => _("Documento") + " " + _("no puede estar vacío.")
  validates_associated :documento, message: _("El documento asociado no es válido.")

end
