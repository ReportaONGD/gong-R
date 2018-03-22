class CreatePeriodo < ActiveRecord::Migration
  def up
   # Crea la tabla donde se recogen los tipos de periodos
    create_table :tipo_periodo, :force => true do |t|
      t.string    :nombre, :null => false
      t.timestamps
    end
    add_index :tipo_periodo, [:id]

   # Crea la tabla donde se recogen los periodos
    create_table :periodo, :force => true do |t|
      t.integer :tipo_periodo_id, :null => false
      t.integer :proyecto_id, :null => false
      t.date :fecha_inicio, :null => false
      t.date :fecha_fin, :null => false
      t.text :descripcion
      t.timestamps
    end
    add_index :periodo, [:id, :tipo_periodo_id, :proyecto_id]

    # Crea la columna para vincular tareas a periodos
    add_column :tarea, :periodo_id, :integer
  end

  def down
    drop_table :tipo_periodo
    drop_table :periodo
    remove_column :tarea, :periodo_id
  end
end
