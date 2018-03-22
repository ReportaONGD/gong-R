class AddRefContableToTransferenciaGastoPago < ActiveRecord::Migration
  def change
    add_column :transferencia, :ref_contable_enviado, :string
    add_column :transferencia, :ref_contable_recibido, :string
    add_column :gasto, :ref_contable, :string
    add_column :pago, :ref_contable, :string
  end
end
