class AddPartialExecutionToLogContabilidad < ActiveRecord::Migration
  def change
    add_column :log_contabilidad, :partial_execution, :boolean, null: false, default: false
  end
end
