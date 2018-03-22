class CreateCategoriaSectorIntervencion < ActiveRecord::Migration
  def up
    # Crea la tabla de categorias
    create_table :categoria_sector_intervencion, force: true do |t|
      t.string   :nombre, null: false
      t.string   :descripcion
      t.timestamps
    end
    add_column :sector_intervencion, :categoria_sector_intervencion_id, :integer, null: false
  end

  def down
    drop_table :categoria_sector_intervencion
    remove_column :sector_intervencion, :categoria_sector_intervencion_id
  end
end
