class AddBloqueadoToUsuario < ActiveRecord::Migration
  def change
    add_column :usuario, :bloqueado, :boolean, null: false, default: false
  end
end
