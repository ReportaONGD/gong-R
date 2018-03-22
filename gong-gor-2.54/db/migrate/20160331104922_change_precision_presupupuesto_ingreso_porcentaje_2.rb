class ChangePrecisionPresupupuestoIngresoPorcentaje2 < ActiveRecord::Migration
  def up
    # Cambiamos a 12 digitos en total con 11 decimales (para poder tener una precision de 0.01%)
    change_column :presupuesto_ingreso, :porcentaje, :decimal, precision: 12, scale: 11 
  end

  def down
    # volvemos a la que teniamos de 5 digitos con 4 decimales
    change_column :presupuesto_ingreso, :porcentaje, :decimal, precision: 4, scale: 4
  end
end
