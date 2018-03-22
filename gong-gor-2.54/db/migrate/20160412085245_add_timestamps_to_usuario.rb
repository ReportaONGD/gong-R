class AddTimestampsToUsuario < ActiveRecord::Migration
  def change
    add_column :usuario, :created_at, :datetime
    add_column :usuario, :updated_at, :datetime
  end
end
