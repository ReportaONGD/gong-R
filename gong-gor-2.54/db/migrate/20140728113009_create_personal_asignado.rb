class CreatePersonalAsignado < ActiveRecord::Migration
  def up
    # Crea la tabla donde se recogen los tipos de personal
    create_table :tipo_personal, :force => true do |t|
      t.string :codigo, :null => false
      t.string :nombre, :null => false
      t.timestamps
    end
    add_index :tipo_personal, [:id]

    # Crea la tabla donde se recoge la relacion de personal
    create_table :personal, :force => true do |t|
      t.integer :proyecto_id, :null => false
      t.string  :nombre, :null => false
      t.integer :tipo_personal_id, :null => false
      t.string  :categoria
      t.string  :residencia
      t.string  :tipo_contrato, :null => false
      t.integer :horas_imputadas, :null => false, :default => 0
      t.float   :salario_mensual, :null => false, :default => 0.0
      t.float   :meses, :null => false, :default => 0.0
      t.float   :salario_total, :null => false, :default => 0.0
      t.integer :moneda_id, :null => false
      t.timestamps
    end
    add_index :personal, [:id, :proyecto_id, :tipo_personal_id]
  end

  def down
    drop_table :personal
    drop_table :tipo_personal
  end
end
