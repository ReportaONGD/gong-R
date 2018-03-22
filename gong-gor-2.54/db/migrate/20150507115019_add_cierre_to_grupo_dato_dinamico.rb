class AddCierreToGrupoDatoDinamico < ActiveRecord::Migration
  def up 
    add_column :grupo_dato_dinamico, :cierre, :boolean, null: false, default: false 
  end
  def down
    remove_column :grupo_dato_dinamico, :cierre
  end
end
