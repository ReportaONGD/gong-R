class CreateIngreso < ActiveRecord::Migration
  def up
    create_table :ingreso, force: true do |t|
      t.decimal :importe, null: false, precision: 24, scale: 2
      t.integer :moneda_id, null: false
      t.string  :concepto
      t.string  :observaciones
      t.integer :partida_ingreso_id, null: false
      t.date    :fecha, null: false
      t.integer :marcado_id
      t.integer :tasa_cambio_id
      t.integer :agente_id, null: false
      t.string  :numero_documento
      t.integer :proveedor_id
      t.integer :financiador_id
      t.integer :proyecto_id
      t.string  :ref_contable
      t.boolean :es_valorizado, null: false, default: false
      t.timestamps
    end
    add_index :ingreso, [:id]
    add_index :ingreso, [:agente_id] 
  end

  def down
    drop_table :ingreso
  end
end
