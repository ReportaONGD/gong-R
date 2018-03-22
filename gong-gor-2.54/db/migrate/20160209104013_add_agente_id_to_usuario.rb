class AddAgenteIdToUsuario < ActiveRecord::Migration
  def change
    add_column :usuario, :agente_id, :integer
  end
end
