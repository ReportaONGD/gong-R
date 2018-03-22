class AddValorizadoToGasto < ActiveRecord::Migration
  def up
    add_column :gasto, :es_valorizado, :boolean, :null => false, :default => false
  end

  def down
    remove_column :gasto, :es_valorizado
  end
end
