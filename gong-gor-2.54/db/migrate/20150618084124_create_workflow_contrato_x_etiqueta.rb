class CreateWorkflowContratoXEtiqueta < ActiveRecord::Migration
  def up
    create_table :workflow_contrato_x_etiqueta, force: true do |t|
      t.integer :workflow_contrato_id, null: false
      t.integer :etiqueta_id, null: false
      t.integer :agente_id, null: false

      t.timestamps
    end
  end

  def down
    drop_table :workflow_contrato_x_etiqueta
  end
end
