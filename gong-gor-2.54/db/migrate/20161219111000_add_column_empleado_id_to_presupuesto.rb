class AddColumnEmpleadoIdToPresupuesto < ActiveRecord::Migration
  def change
    add_column :presupuesto, :empleado_id, :integer
  end
end
