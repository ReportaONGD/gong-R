class AddImportePrevistoToEtapa < ActiveRecord::Migration
  def up
    add_column :etapa, :importe_previsto_subvencion, :decimal, :precision => 24, :scale => 2, :default => 0.0
  end
  def down
    remove_column :etapa, :importe_previsto_subvencion
  end
end
