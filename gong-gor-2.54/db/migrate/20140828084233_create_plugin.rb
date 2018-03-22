class CreatePlugin < ActiveRecord::Migration
  def up
    # Crea la tabla donde se recogen los plugins
    create_table :plugin, :force => true do |t|
      t.string :nombre, :null => false
      t.string :codigo, :null => false
      t.string :clase, :null => false
      t.string :descripcion, :null => false, :default => ""
      t.string :version, :null => false, :default => "0.0.0"
      t.integer :peso, :null => false, :default => 10 
      t.boolean :disponible, :null => false, :default => true 
      t.boolean :activo, :null => false, :default => false
      t.boolean :engine, :null => false, :default => true
      t.timestamps
    end
    add_index :plugin, [:id]
    add_index :plugin, [:clase] 
  end

  def down
    drop_table :plugin
  end
end
