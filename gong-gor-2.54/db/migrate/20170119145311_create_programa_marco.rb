class CreateProgramaMarco < ActiveRecord::Migration
  def up 
    # Crea los permisos particulares sobre esta seccion para los usuarios
    add_column :usuario, :programas_marco, :boolean, :null => false, :default => false
    # Genera la tabla que recoge los proyectos marco
    create_table :programa_marco, force: true do |t|
      t.string  :nombre, null: false
      t.string  :objetivo_general, null: false
      t.integer :moneda_id, null: false
      t.text    :descripcion
      t.boolean :activo, null: false, default: true
      t.timestamps
    end
    # Incluye la vinculacion de un proyecto con su proyecto marco
    add_column :proyecto, :programa_marco_id, :integer
  end
  def down
    remove_column :proyecto, :programa_marco_id
    drop_table :programa_marco
    remove_column :usuario, :proyectos_marco
  end
end
