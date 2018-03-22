class CreateContratoXDocumento < ActiveRecord::Migration
  def up
    create_table :contrato_x_documento, force: true do |t|
      t.integer :estado_contrato_id, null: false
      t.integer :documento_id, null: false

      t.timestamps
    end
    add_index :contrato_x_documento, ["id"]
    add_index :contrato_x_documento, ["estado_contrato_id"]
    add_index :contrato_x_documento, ["documento_id"]
  end

  def down
    drop_table :contrato_x_documento
  end
end
