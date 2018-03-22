class AddColumnEmpleadoIdToGasto < ActiveRecord::Migration
  def change
    add_column :gasto, :empleado_id, :integer
  end
end
