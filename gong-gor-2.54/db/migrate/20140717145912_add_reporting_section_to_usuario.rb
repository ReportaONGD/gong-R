class AddReportingSectionToUsuario < ActiveRecord::Migration
  def up
    add_column :usuario, :informes_aecid, :boolean, :null => false, :default => false
  end

  def down
    remove_column :usuario, :informes_aecid
  end
end
