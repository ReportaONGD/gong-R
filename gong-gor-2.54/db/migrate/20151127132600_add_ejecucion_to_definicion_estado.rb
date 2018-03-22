class AddEjecucionToDefinicionEstado < ActiveRecord::Migration
  def up 
    add_column :definicion_estado, :ejecucion, :boolean, null: false, default: false
    DefinicionEstado.reset_column_information
    # Recorre todas las definciones de estado existentes para incluir como "ejecucion" lo que estuviera como "aprobado" evitando los "cerrado"
    DefinicionEstado.where(aprobado: true, cerrado: false).each do |estado|
      estado.update_attribute(:ejecucion, true)
    end
  end
  def down
    remove_column :definicion_estado, :ejecucion
  end
end
