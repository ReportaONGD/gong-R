class AddRunningToLogContabilidad < ActiveRecord::Migration
  def change
    add_column :log_contabilidad, :running, :boolean, null: false, default: false
  end
end
