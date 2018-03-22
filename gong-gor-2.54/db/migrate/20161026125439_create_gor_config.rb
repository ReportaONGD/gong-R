class CreateGorConfig < ActiveRecord::Migration
  def up
    # Crea la tabla de configuracion
    create_table :gor_config, :force => true do |t|
      t.string :name, null: false
      t.string :value
      t.text :description
    end
    add_index :gor_config, [:name]
  end

  def down
    drop_table :gor_config 
  end
end
