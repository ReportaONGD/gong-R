class AddOcultarProyectoToPartida < ActiveRecord::Migration
  def up
    add_column :partida, :ocultar_proyecto, :boolean, null: false, default: false 
  end
  def down
    remove_column :partida, :ocultar_proyecto
  end
end
