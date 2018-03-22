class AddImportesToProyecto < ActiveRecord::Migration
  def up 
    add_column :proyecto, :importe_previsto_total, :decimal, :precision => 24, :scale => 2, :default => 0.0
    add_column :proyecto, :importe_previsto_subvencion, :decimal, :precision => 24, :scale => 2, :default => 0.0
  end
  def down
    remove_column :proyecto, :importe_previsto_total
    remove_column :proyecto, :importe_previsto_subvencion
  end
end
