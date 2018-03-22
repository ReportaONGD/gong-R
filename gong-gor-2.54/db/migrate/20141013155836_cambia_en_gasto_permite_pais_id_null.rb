class CambiaEnGastoPermitePaisIdNull < ActiveRecord::Migration
  def up
    change_column :gasto, :pais_id, :integer, :null => true
  end

  def down
    change_column :gasto, :pais_id, :integer, :null => false 
  end
end
