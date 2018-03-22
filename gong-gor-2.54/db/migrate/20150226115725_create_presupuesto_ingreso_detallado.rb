class CreatePresupuestoIngresoDetallado < ActiveRecord::Migration
  def up
    create_table "presupuesto_ingreso_detallado", :force => true do |t|
      t.integer "presupuesto_ingreso_id", null: false
      t.decimal "importe", precision: 24, scale: 2, null: false, default: 0.0
      t.date    "fecha_inicio"
      t.date    "fecha_fin"
      t.string  "nombre"
      t.integer "mes"
    end
    add_index :presupuesto_ingreso_detallado, ["id"]
    add_index :presupuesto_ingreso_detallado, ["presupuesto_ingreso_id"]
  end

  def down
    drop_table :presupuesto_ingreso_detallado
  end
end
