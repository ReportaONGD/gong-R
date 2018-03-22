class CreateEmpleado < ActiveRecord::Migration
  def change
    create_table :empleado do |t|
      t.string :nombre
      t.boolean :activo
      t.integer :agente_id

      t.timestamps
    end
  end
end
