class CreateTipoContratoXDocumento < ActiveRecord::Migration
  def up
    # Crea la asociacion entre tipos de contratos y plantillas de documentos
    create_table :tipo_contrato_x_documento, force: true do |t|
      t.integer  :tipo_contrato_id, null: false
      t.integer  :documento_id,     null: false
      t.timestamps
    end
    add_index :tipo_contrato_x_documento, [:tipo_contrato_id, :documento_id], name: :index_tipo_contrato_x_documento_ids
  end

  def down
    drop_table :tipo_contrato_x_documento
  end
end
