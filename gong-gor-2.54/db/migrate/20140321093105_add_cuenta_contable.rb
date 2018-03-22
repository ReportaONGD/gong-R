class AddCuentaContable < ActiveRecord::Migration
  def up 
    # Crea la tabla donde se recogen los codigos contables
    create_table :cuenta_contable, :force => true do |t|
      t.string    :codigo, :null => false
      t.integer   :agente_id
      t.references :elemento_contable, :polymorphic => true
      t.text      :descripcion
      t.text      :observaciones
      t.timestamps
    end
    add_index :cuenta_contable, [:agente_id, :codigo]
  end
  def down
    drop_table :cuenta_contable
  end
end
