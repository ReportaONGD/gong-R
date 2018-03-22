class AddGrupoUsuario < ActiveRecord::Migration
  def up
    # Tabla para los grupos de usuarios
    create_table :grupo_usuario do |t|
      t.string :nombre
      t.timestamps
    end

    # Tabla para los usuarios miembros de un grupo
    create_table :usuario_x_grupo_usuario do |t|
      t.integer :usuario_id
      t.integer :grupo_usuario_id
    end
    add_index :usuario_x_grupo_usuario, [:usuario_id, :grupo_usuario_id], :name => "index_usuario_x_grupo", :unique => true

    # Tabla para los proyectos gestionables por un grupo
    create_table :grupo_usuario_x_proyecto do |t|
      t.integer :grupo_usuario_id
      t.integer :proyecto_id
      t.string  :rol
    end
    add_index :grupo_usuario_x_proyecto, [:grupo_usuario_id, :proyecto_id], :name => "index_grupo_x_proyecto", :unique => true

    # Tabla para los agentes gestionables por un grupo
    create_table :grupo_usuario_x_agente do |t|
      t.integer :grupo_usuario_id
      t.integer :agente_id
    end
    add_index :grupo_usuario_x_agente, [:grupo_usuario_id, :agente_id], :name => "index_grupo_x_agente", :unique => true

    # Tabla para los libros gestionables por un grupo
    create_table :grupo_usuario_x_libro do |t|
      t.integer :grupo_usuario_id
      t.integer :libro_id
    end
    add_index :grupo_usuario_x_libro, [:grupo_usuario_id, :libro_id], :name => "index_grupo_x_libro", :unique => true

    # Tabla para los espacios gestionables por un grupo
    create_table :grupo_usuario_x_espacio do |t|
      t.integer :grupo_usuario_id
      t.integer :espacio_id
    end
    add_index :grupo_usuario_x_espacio, [:grupo_usuario_id, :espacio_id], :name => "index_grupo_x_espacio", :unique => true

    # Campos para indicar que el usuario esta relacionado a traves de un grupo
    add_column :usuario_x_proyecto, :grupo_usuario_id, :integer
    add_column :usuario_x_agente, :grupo_usuario_id, :integer
    add_column :usuario_x_libro, :grupo_usuario_id, :integer
    add_column :usuario_x_espacio, :grupo_usuario_id, :integer
  end

  def down
    remove_column :usuario_x_espacio, :grupo_usuario_id
    remove_column :usuario_x_libro, :grupo_usuario_id
    remove_column :usuario_x_agente, :grupo_usuario_id
    remove_column :usuario_x_proyecto, :grupo_usuario_id
    drop_table :grupo_usuario_x_espacio
    drop_table :grupo_usuario_x_libro
    drop_table :grupo_usuario_x_agente
    drop_table :grupo_usuario_x_proyecto
    drop_table :usuario_x_grupo_usuario
    drop_table :grupo_usuario
  end
end
