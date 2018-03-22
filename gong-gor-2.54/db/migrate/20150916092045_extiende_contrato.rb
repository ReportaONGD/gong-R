class ExtiendeContrato < ActiveRecord::Migration
  def up
    add_column :contrato, :objetivo, :text
    add_column :contrato, :justificacion, :text
    add_column :contrato, :tipo_contrato_id, :integer
  end

  def down
    remove_column :contrato, :objetivo
    remove_column :contrato, :justificacion
    remove_column :contrato, :tipo_contrato_id
  end
end
