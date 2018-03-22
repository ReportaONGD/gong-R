class AddSistemaToComentario < ActiveRecord::Migration
  def change
    add_column :comentario, :sistema, :boolean, nil: false, default: false
  end
end
