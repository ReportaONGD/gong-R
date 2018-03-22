class CreatePeriodoContrato < ActiveRecord::Migration
  def up
    create_table "periodo_contrato", :force => true do |t|
      t.integer "contrato_id", null: false
      t.decimal "importe", precision: 24, scale: 2, null: false, default: 0.0
      t.date    "fecha_inicio", null: false
      t.date    "fecha_fin", null: false
      t.string  "descripcion"

      t.timestamps
    end
    add_index :periodo_contrato, ["id"]
    add_index :periodo_contrato, ["contrato_id"]
  end

  def down
    drop_table :periodo_contrato
  end
end
