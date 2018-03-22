class AddCentroCosteToContabilidad < ActiveRecord::Migration
  def up 
    add_column :cuenta_contable, :centro_coste, :boolean, :default => false 
  end
  def down
    remove_column :cuenta_contable, :centro_coste
  end
end
