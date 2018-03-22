class AddCerradoToPeriodo < ActiveRecord::Migration
  def change
    add_column :periodo, :cerrado, :boolean, null: false, default: false
  end
end
