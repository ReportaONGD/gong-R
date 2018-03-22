class CreateTipoConvocatoria < ActiveRecord::Migration
  def up
    # Crea la tabla donde se recogen los tipos de convocatorias
    create_table :tipo_convocatoria, :force => true do |t|
      t.string :nombre, :null => false
      t.timestamps
    end
    add_index :tipo_convocatoria, [:id]

    # Vinculacion a tipo de convocatoria desde la tabla de convocatorias
    add_column :convocatoria, :tipo_convocatoria_id, :integer
  end

  def down
    remove_column :convocatoria, :tipo_convocatoria_id
    drop table :tipo_convocatoria
  end
end
