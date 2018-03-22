# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2015 Free Software's Seed, CENATIC y IEPALA
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
# relaciones entre los workflows de contratos 

class WorkflowContratoXWorkflowContrato < ActiveRecord::Base
  belongs_to :workflow_contrato_padre,  :class_name => 'WorkflowContrato' , :foreign_key => :workflow_contrato_padre_id
  belongs_to :workflow_contrato_hijo, :class_name => 'WorkflowContrato' , :foreign_key => :workflow_contrato_hijo_id

  # Evita que se vincule con el mismo 
  validate :evita_bucle

 private

  # Evita una referencia a si mismo
  def evita_bucle
    errors.add(:base, _("No se puede asociar un estado del workflow a si mismo") ) if workflow_contrato_padre_id == workflow_contrato_hijo_id
    return errors.empty? 
  end 
end
