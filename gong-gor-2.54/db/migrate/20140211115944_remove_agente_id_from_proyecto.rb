class RemoveAgenteIdFromProyecto < ActiveRecord::Migration
  def up
    remove_column :proyecto, :agente_id
  end

  def down
    add_column :proyecto, :agente_id, :integer
    Proyecto.reset_column_information
    Proyecto.all.each do |proyecto|
      proyecto.update_column(:agente_id, proyecto.convocatoria.agente_id)
    end
  end
end
