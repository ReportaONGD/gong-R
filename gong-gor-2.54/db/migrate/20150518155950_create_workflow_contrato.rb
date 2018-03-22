class CreateWorkflowContrato < ActiveRecord::Migration
  def up
    # Tabla para recoger los estados del workflow de contratos
    create_table :workflow_contrato, force: true do |t|
      t.string   :nombre,          default: false
      t.text     :descripcion
      t.boolean  :primer_estado,   default: false, null: false
      t.boolean  :formulacion,     default: false, null: false
      t.boolean  :aprobado,        default: false, null: false
      t.boolean  :cerrado,         default: false, null: false
      t.integer  :orden,           default: 0,     null: false
      t.timestamps
    end
    add_index :workflow_contrato, [:id]

    # Tabla para recoger las relaciones padre/hijo del workflow de contratos
    create_table :workflow_contrato_x_workflow_contrato, force: true do |t|
      t.integer :workflow_contrato_padre_id, null: false
      t.integer :workflow_contrato_hijo_id,  null: false
      t.timestamps
    end
    add_index :workflow_contrato_x_workflow_contrato, [:workflow_contrato_padre_id], name: :wf_contrato_x_wf_contrato_padre_id
    add_index :workflow_contrato_x_workflow_contrato, [:workflow_contrato_hijo_id],  name: :wf_contrato_x_wf_contrato_hijo_id
  end

  def down
    drop_table :workflow_contrato_x_workflow_contrato
    drop_table :workflow_contrato
  end
end
