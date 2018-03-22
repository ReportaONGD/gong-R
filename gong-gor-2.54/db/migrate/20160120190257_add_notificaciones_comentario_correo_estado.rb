class AddNotificacionesComentarioCorreoEstado < ActiveRecord::Migration
  def up
    rename_column :usuario_x_proyecto, :notificar, :notificar_comentario
    change_column :usuario_x_proyecto, :notificar_comentario, :boolean, :default => nil
    add_column :usuario_x_proyecto, :notificar_estado, :boolean
    add_column :usuario_x_proyecto, :notificar_usuario, :boolean
  end

  def down
    rename_column :usuario_x_proyecto, :notificar_comentario, :notificar
    change_column :usuario_x_proyecto, :notificar, :boolean, :default => true
    remove_column :usuario_x_proyecto, :notificar_estado
    remove_column :usuario_x_proyecto, :notificar_usuario
  end
end
