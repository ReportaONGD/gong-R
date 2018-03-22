class AddSkypeIdToUsuario < ActiveRecord::Migration
  def change
    add_column :usuario, :skype_id, :string
  end
end
