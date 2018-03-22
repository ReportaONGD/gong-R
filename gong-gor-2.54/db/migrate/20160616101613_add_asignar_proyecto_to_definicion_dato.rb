class AddAsignarProyectoToDefinicionDato < ActiveRecord::Migration
  def up
    add_column :definicion_dato, :asignar_proyecto, :boolean, null: false, default: false
  end
  def down
    remove_column :definicion_dato, :asignar_proyecto
  end
end
