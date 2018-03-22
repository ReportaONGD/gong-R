class EmpleadoSalarioHora < ActiveRecord::Migration
  def up
    create_table :empleado_salario_hora, force: true do |t|
      t.integer :empleado_id, null: false
      t.date :fecha_inicio, null: false
      t.date :fecha_fin, null: false
      t.decimal :salario_hora, :precision => 24, :scale => 4
    end
  end
end
