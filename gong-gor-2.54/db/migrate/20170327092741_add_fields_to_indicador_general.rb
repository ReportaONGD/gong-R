class AddFieldsToIndicadorGeneral < ActiveRecord::Migration
  def change
    add_column :indicador_general, :codigo, :string, null: false
    add_column :indicador_general, :activo, :boolean, null: false, default: true 
    add_column :indicador_general, :unidad, :string
  end
end
