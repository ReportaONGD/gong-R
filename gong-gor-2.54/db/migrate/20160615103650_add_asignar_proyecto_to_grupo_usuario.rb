class AddAsignarProyectoToGrupoUsuario < ActiveRecord::Migration
  def up
    add_column :grupo_usuario, :asignar_proyecto_rol_id, :integer
  end
  def down
    remove_column :grupo_usuario, :asignar_proyecto_rol_id
  end
end
