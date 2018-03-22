class CreateContratoXFinanciador < ActiveRecord::Migration
  def up
    # Crea la asociacion entre contratos y financiadores
    create_table :contrato_x_financiador, force: true do |t|
      t.integer  :contrato_id, null: false
      t.integer  :agente_id,   null: false
      t.decimal  :importe,     null: false, precision: 24, scale: 2, default: 0.0
      
      t.timestamps
    end
    add_index :contrato_x_financiador, [:contrato_id, :agente_id], name: :index_contrato_x_financiador_ids
  end

  def down
  end
end
