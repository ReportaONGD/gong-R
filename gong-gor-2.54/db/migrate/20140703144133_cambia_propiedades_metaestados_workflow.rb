class CambiaPropiedadesMetaestadosWorkflow < ActiveRecord::Migration
  def up
    change_column :definicion_estado, :primer_estado, :boolean, :null => false, :default => false
    change_column :definicion_estado, :formulacion, :boolean, :null => false, :default => false
    change_column :definicion_estado, :aprobado, :boolean, :null => false, :default => false
    change_column :definicion_estado, :cerrado, :boolean, :null => false, :default => false
    change_column :definicion_estado, :reporte, :boolean, :null => false, :default => false
    change_column :definicion_estado, :orden, :integer, :null => false, :default => 0 
  end

  def down
    change_column :definicion_estado, :primer_estado, :boolean, :null => true, :default => false
    change_column :definicion_estado, :formulacion, :boolean, :null => true, :default => false
    change_column :definicion_estado, :aprobado, :boolean, :null => true, :default => false
    change_column :definicion_estado, :cerrado, :boolean, :null => true, :default => false
    change_column :definicion_estado, :orden, :integer, :null => true, :default => nil 
  end
end
