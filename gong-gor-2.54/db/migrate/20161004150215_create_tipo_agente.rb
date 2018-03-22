class CreateTipoAgente < ActiveRecord::Migration
  def up
    # Crea la tabla donde se recogen los tipos de agentes 
    create_table :tipo_agente, :force => true do |t|
      t.string :nombre, :null => false
      t.timestamps
    end
    add_index :tipo_agente, [:id]

    # Vinculacion a tipo de agente desde la tabla de agentes
    add_column :agente, :tipo_agente_id, :integer
  end

  def down
  end
end
