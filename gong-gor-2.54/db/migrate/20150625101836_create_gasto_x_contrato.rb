class CreateGastoXContrato < ActiveRecord::Migration
  def up
    create_table :gasto_x_contrato, force: true do |t|
      t.integer :contrato_id, null: false
      t.integer :gasto_id, null: false

      t.timestamps
    end
    add_index :gasto_x_contrato, ["contrato_id", "gasto_id"]
  end

  def down
    drop_table :gasto_x_contrato
  end
end
