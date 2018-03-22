class CreateLogContabilidad < ActiveRecord::Migration
  def up
    # Crea la tabla de logs de acciones de contabilidad
    create_table :log_contabilidad, :force => true do |t|
      t.integer :agente_id, :null => false
      t.integer :usuario_id, :null => false
      t.string :elemento, :null => false
      t.boolean :finalizado_ok, :null => false, :default => false

      t.timestamps
    end
    add_index :log_contabilidad, [:agente_id]
  end

  def down
    drop_table :log_contabilidad
  end
end
