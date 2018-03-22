class AddOcultarProyectoToGrupoUsuario < ActiveRecord::Migration
  def up
    add_column :grupo_usuario, :ocultar_proyecto, :boolean, null: false, default: false 
  end
  def down
    remove_column :grupo_usuario, :ocultar_proyecto
  end
end
