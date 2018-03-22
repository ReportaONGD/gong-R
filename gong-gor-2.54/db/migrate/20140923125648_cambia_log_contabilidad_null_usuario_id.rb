class CambiaLogContabilidadNullUsuarioId < ActiveRecord::Migration
  def up
    change_column :log_contabilidad, :usuario_id, :integer, :null => true 
  end

  def down
    change_column :log_contabilidad, :usuario_id, :integer, :null => false, :default => 0
  end
end
