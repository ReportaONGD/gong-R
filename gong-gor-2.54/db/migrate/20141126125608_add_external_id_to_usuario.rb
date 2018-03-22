class AddExternalIdToUsuario < ActiveRecord::Migration
  def change
    add_column :usuario, :external_id, :string
  end
end
