class AddPaisToTasaCambio < ActiveRecord::Migration
  def up 
    # Incluimos el pais de la tc
    add_column :tasa_cambio, :pais_id, :integer  
  end
  def down
    remove_column :tasa_cambio, :pais_id 
  end
end
