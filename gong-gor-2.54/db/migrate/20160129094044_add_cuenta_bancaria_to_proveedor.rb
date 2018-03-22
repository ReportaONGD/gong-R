class AddCuentaBancariaToProveedor < ActiveRecord::Migration
  def change
    add_column :proveedor, :entidad_bancaria, :string
    add_column :proveedor, :cuenta_bancaria, :string
  end
end
