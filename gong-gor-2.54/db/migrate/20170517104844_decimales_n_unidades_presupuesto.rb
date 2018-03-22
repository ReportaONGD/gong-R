class DecimalesNUnidadesPresupuesto < ActiveRecord::Migration
  def up
    change_column :presupuesto, :numero_unidades, :decimal, :precision => 24, :scale => 2
  end

  def down
    change_column :presupuesto, :numero_unidades, :integer
  end
end
