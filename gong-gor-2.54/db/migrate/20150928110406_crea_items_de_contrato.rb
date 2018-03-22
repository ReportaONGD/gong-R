class CreaItemsDeContrato < ActiveRecord::Migration
  def up
    # Crea la definicion de campos particulares de cada tipo de contrato
    create_table :item_contrato, force: true do |t|
      t.integer  :contrato_id,      null: false
      t.string   :nombre,           null: false
      t.integer  :cantidad,         null: false
      t.decimal  :coste_unitario,   null: false, precision: 24, scale: 2
      t.string   :descripcion
      t.timestamps
    end
    add_index :item_contrato, [:contrato_id]
  end

  def down
    drop_table :item_contrato
  end

end
