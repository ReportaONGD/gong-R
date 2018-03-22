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
# definición de workflow de contratos 

class WorkflowContrato < ActiveRecord::Base

  before_destroy :verificar_borrado

  has_many :workflow_contrato_padre, class_name: 'WorkflowContratoXWorkflowContrato', foreign_key: 'workflow_contrato_hijo_id', dependent: :destroy
  has_many :estado_padre, through: :workflow_contrato_padre, source: :workflow_contrato_padre
  has_many :workflow_contrato_hijo, class_name: 'WorkflowContratoXWorkflowContrato', foreign_key: 'workflow_contrato_padre_id', dependent: :destroy
  has_many :estado_hijo, through: :workflow_contrato_hijo, source: :workflow_contrato_hijo
  # No dejamos el dependent: :destroy para evitar que se borre si tiene contratos asignados a este estado
  has_many :estado_contrato

  has_many :workflow_contrato_x_etiqueta, dependent: :destroy
  # En rails4 usaremos la siguiente formula para "etiqueta" en lugar de utilizar "etiquetas_estado" y el metodo "etiqueta"
  #has_many :etiqueta, -> (agente){ where("workflow_contrato_x_etiqueta.agente_id" => agente.id)}, through: :workflow_contrato_x_etiqueta
  has_many :etiquetas_estado, through: :workflow_contrato_x_etiqueta, source: :etiqueta, foreign_key: :etiqueta_id

  validates_presence_of :nombre
  validates_uniqueness_of :nombre, message: _("Nombre repetido.")
  validates_uniqueness_of :primer_estado, unless: "self.primer_estado == false", message: _("Primer estado debe ser único")

  # Obtenemos todas las etiquetas del workflow para un agente concreto
  # (esto hay que resolverlo en el has_many dejando un unico etiqueta_agente cuando se migre a rails4)
  def etiqueta agente=nil
    filtro_agente = agente && agente.class.name == "Agente" ? {"workflow_contrato_x_etiqueta.agente_id" => agente.id} : nil
    etiquetas_estado.where(filtro_agente)
  end
  # Y por compatibilidad, tambien creamos el metodo que active record no genera al ser etiqueta un metodo
  def etiqueta_ids agente=nil 
    etiqueta(agente).collect{|e| e.id}
  end
  # y el metodo que asigna (al tener parametros no puede ser "etiqueta_ids=" )
  def set_etiqueta_ids(agente=nil,ids=[])
    agente_id = agente && agente.class.name == "Agente" ? agente.id : nil
    # Etiquetas activas
    ids_activas = ids.select{|i| i[1] == "1"}.collect{|i| i[0]}
    # Borramos todas las que no esten activas 
    (self.etiqueta_ids(agente) - ids_activas).each do |etiqueta_id|
      wcxe = WorkflowContratoXEtiqueta.find_by_agente_id_and_workflow_contrato_id_and_etiqueta_id(agente_id, self.id, etiqueta_id)
      wcxe.destroy if wcxe
      errors.add( :base, _("Error borrando vinculación con etiqueta") + ": " + wcxe.errors.inject('') {|total, e| total + e[1]} ) unless wcxe.nil? || wcxe.errors.empty?
    end
    # Recorremos todas para incluir las que faltan (solo en el caso de que no haya habido errores antes)
    ids_activas.each do |etiqueta_id|
      # Primero miramos si ya existe
      wcxe = WorkflowContratoXEtiqueta.find_or_create_by_agente_id_and_workflow_contrato_id_and_etiqueta_id(agente_id, self.id, etiqueta_id)
      errors.add( :base, _("Error vinculando con etiqueta") + ": " + wcxe.errors.inject('') {|total, e| total + e[1]} ) unless wcxe.errors.empty?
    end if self.errors.empty?
  end

  # Obtenemos los nombres de todas las etiquetas documentales
  def etiqueta_nombre agente=nil
    etiqueta(agente).order(:nombre).collect{|e| e.nombre}
  end

  def estado_padre_visualizacion
    estado_padre.collect{|e| e.nombre}.join(", ")
  end

  def nombre_completo
    self.orden ? self.orden.to_s + " - " + self.nombre : self.nombre
  end

 private

  def verificar_borrado
   errors.add( :base, _("Existen contratos relacionados con este estado. Imposible borrar.") ) unless estado_contrato.empty?
   return errors.empty?
  end
end
