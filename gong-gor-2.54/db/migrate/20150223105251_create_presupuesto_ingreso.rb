class CreatePresupuestoIngreso < ActiveRecord::Migration
  def up
    create_table :presupuesto_ingreso, force: true do |t|
      t.decimal :importe,                precision: 24, scale: 2, null: false
      t.decimal :porcentaje, precision: 4, scale: 2, null: false, default: 0.0
      t.string  :concepto
      t.string  :observaciones
      t.integer :partida_ingreso_id, null: false
      t.integer :moneda_id, null: false
      t.integer :etapa_id, null: false
      t.integer :marcado_id
      t.integer :tasa_cambio_id
      t.integer :agente_id, null: false
      t.integer :proyecto_id
      t.integer :financiador_id
      t.timestamps
    end
    add_index :presupuesto_ingreso, [:id]
    add_index :presupuesto_ingreso, [:agente_id] 
  end

  def down
    drop_table :presupuesto_ingreso
  end
end
