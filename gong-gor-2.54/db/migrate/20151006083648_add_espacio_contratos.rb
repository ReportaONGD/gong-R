class AddEspacioContratos < ActiveRecord::Migration
  def up
    add_column :espacio, :espacio_contratos, :boolean, null: false, default: false
  end

  def down
    remove_column :espacio, :espacio_contratos
  end
end
