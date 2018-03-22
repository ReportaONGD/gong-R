class AddColumnTipoEmpleadoToPartida < ActiveRecord::Migration
  def change
    add_column :partida, :tipo_empleado, :boolean, default: false
  end
end
