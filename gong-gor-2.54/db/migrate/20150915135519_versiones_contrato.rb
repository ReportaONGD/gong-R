class VersionesContrato < ActiveRecord::Migration
  def up
    create_table :version_contrato, force: true do |t|
      t.integer  :contrato_id,        null: false
      t.integer  :estado_contrato_id, null: false
      t.decimal  :importe,            null: false, precision: 24, scale: 2
      t.integer  :moneda_id,          null: false
      t.text     :observaciones
      t.date     :fecha_inicio,       null: false
      t.date     :fecha_fin,          null: false
      t.timestamps
    end
    add_index :version_contrato, [:id]
    add_index :version_contrato, [:contrato_id]
  end
  def down
    drop_table :version_contrato
  end
end
