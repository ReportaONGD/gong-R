class CreateCategoriaAreaActuacion < ActiveRecord::Migration
  def up
    # Crea la tabla de categorias
    create_table :categoria_area_actuacion, force: true do |t|
      t.string   :nombre, null: false
      t.string   :descripcion
      t.timestamps
    end
    add_column :area_actuacion, :categoria_area_actuacion_id, :integer
  end

  def down
    drop_table :categoria_area_actuacion
    remove_column :area_actuacion, :categoria_area_actuacion_id
  end
end
