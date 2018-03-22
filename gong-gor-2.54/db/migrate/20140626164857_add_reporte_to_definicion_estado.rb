class AddReporteToDefinicionEstado < ActiveRecord::Migration
  def up
    add_column :definicion_estado, :reporte, :boolean, :null => false
  end

  def down
   remove_column :definicion_estado, :reporte
  end
end
