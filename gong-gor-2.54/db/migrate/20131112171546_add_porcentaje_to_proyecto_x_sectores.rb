class AddPorcentajeToProyectoXSectores < ActiveRecord::Migration
  def change
    add_column :proyecto_x_sector_poblacion, :porcentaje, :decimal, :precision => 5, :scale => 4, :default => 0.0
    add_column :proyecto_x_sector_intervencion, :porcentaje, :decimal, :precision => 5, :scale => 4, :default => 0.0
  end
end
