class CreateConvocatorias < ActiveRecord::Migration
  def up
    create_table :convocatoria, :force => true do |t|
      t.string    :codigo, :null => false
      t.string    :nombre, :null => false
      t.text      :descripcion
      t.text      :observaciones
      t.integer   :agente_id, :null => false
      t.date      :fecha_publicacion
      t.date      :fecha_presentacion
      t.date      :fecha_resolucion

      t.timestamps
    end
    add_index :convocatoria, :agente_id

    #add_column :usuario, :convocatorias, :boolean, :null => false, :default => true
  end

  def down
    #remove_column :usuario, :convocatorias
    drop_table :convocatoria
  end
end
