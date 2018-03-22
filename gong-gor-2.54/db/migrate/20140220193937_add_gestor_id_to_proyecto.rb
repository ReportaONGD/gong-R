class AddGestorIdToProyecto < ActiveRecord::Migration
  def up
    add_column :proyecto, :gestor_id, :integer
    Proyecto.reset_column_information
    Proyecto.all.each do |proyecto|
      gestor = proyecto.libro_principal.agente if proyecto.libro_principal
      proyecto.update_column( :gestor_id, gestor.id ) if gestor
    end
  end

  def down
    remove_column :proyecto, :gestor_id
  end
end
