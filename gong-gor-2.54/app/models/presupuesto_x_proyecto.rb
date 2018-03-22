class PresupuestoXProyecto < ActiveRecord::Base
  attr_accessible :importe, :presupuesto_id, :proyecto_id
  belongs_to :presupuesto
  belongs_to :proyecto
end
