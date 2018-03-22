class ChangePrecisionPresupupuestoIngresoPorcentaje < ActiveRecord::Migration
  def up
    # Cambiamos a 5 digitos en total con 4 decimales (para poder tener una precision de 0.01%)
    change_column :presupuesto_ingreso, :porcentaje, :decimal, precision: 5, scale: 4
  end

  def down
    # volvemos a la que teniamos de 4 digitos con 2 decimales
    change_column :presupuesto_ingreso, :porcentaje, :decimal, precision: 4, scale: 2
  end
end
