class CreateConvocatoriaXPais < ActiveRecord::Migration
  def up
    create_table :convocatoria_x_pais, :force => true do |t|
      t.integer   :convocatoria_id, :null => false
      t.integer   :pais_id, :null => false

      t.timestamps
    end
    add_index :convocatoria_x_pais, [:convocatoria_id, :pais_id]
  end

  def down
    drop_table :convocatoria_x_pais
  end
end
