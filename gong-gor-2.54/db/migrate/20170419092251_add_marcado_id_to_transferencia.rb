class AddMarcadoIdToTransferencia < ActiveRecord::Migration
  def up
    add_column :transferencia, :marcado_id, :integer
  end

  def down
    remove_column :transferencia, :marcado_id
  end
end
