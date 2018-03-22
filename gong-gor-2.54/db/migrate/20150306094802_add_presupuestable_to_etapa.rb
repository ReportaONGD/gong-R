class AddPresupuestableToEtapa < ActiveRecord::Migration
  def up 
    add_column :etapa, :presupuestable, :boolean, null: false, default: true
  end
  def down
    remove_column :etapa, :presupuestable
  end
end
