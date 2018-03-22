class AddCodeToPais < ActiveRecord::Migration
  def change
    add_column :pais, :codigo, :string, null: false, default: "" 
  end
end
