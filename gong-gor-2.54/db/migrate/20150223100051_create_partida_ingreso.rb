class CreatePartidaIngreso < ActiveRecord::Migration
  def up
    create_table :partida_ingreso, :force => true do |t|
      t.string  :nombre, :null => false
      t.string  :descripcion
      t.boolean :presupuestable, :null => false, :default => true
      t.boolean :proyecto, :null => false, :default => false
      t.timestamps
    end
    add_index :partida_ingreso, [:id]
  end

  def down
    drop_table :partida_ingreso
  end
end
