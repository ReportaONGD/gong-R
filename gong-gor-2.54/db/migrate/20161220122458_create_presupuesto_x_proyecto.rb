class CreatePresupuestoXProyecto < ActiveRecord::Migration
  def change
    create_table :presupuesto_x_proyecto do |t|
      t.integer :presupuesto_id
      t.integer :proyecto_id
      t.decimal :importe, precision: 24, scale: 2, null: false

      t.timestamps
    end
  end
end
