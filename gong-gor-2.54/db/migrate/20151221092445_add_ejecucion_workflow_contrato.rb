class AddEjecucionWorkflowContrato < ActiveRecord::Migration
  def up
    add_column :workflow_contrato, :ejecucion,:boolean, null: false, default: false
    WorkflowContrato.reset_column_information
    # Recorre todas las definciones de estado existentes para incluir como "ejecucion" lo que estuviera como "aprobado" evitando los "cerrado"
    WorkflowContrato.where(aprobado: true, cerrado: false).each do |estado|
      estado.update_attribute(:ejecucion, true)
    end
  end

  def down
    remove_column :workflow_contrato, :ejecucion
  end
end