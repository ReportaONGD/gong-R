class AddCerradoToConvocatoria < ActiveRecord::Migration
  def change
    add_column :convocatoria, :cerrado, :boolean, null: false, default: false
  end
end
