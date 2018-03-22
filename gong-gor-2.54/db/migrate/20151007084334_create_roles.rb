class CreateRoles < ActiveRecord::Migration
  def up
    # Crea la tabla de definicion de roles 
    create_table :rol, force: true do |t|
      t.string :nombre, null: false
      t.string :seccion, null: false
      t.string :descripcion
      t.boolean :admin, null: false, default: false
      t.timestamps
    end
    # Crea la tabla de permisos por rol
    create_table :permiso_x_rol, force: true do |t|
      t.integer :rol_id, null: false
      t.string :menu, null: false
      t.string :controlador, null: false
      t.boolean :ver, null: false, default: true
      t.boolean :cambiar, null: false, default: false
      t.timestamps
    end

    # Crea los roles iniciales
    # (esto tambien esta en el seeds, pero lo incluimos aqui para contemplar los datos de instalaciones ya en marcha)
    [ ["Usuario", "proyectos", false],
      ["Coordinador", "proyectos", true],
      ["Configurador", "proyectos", false],
      ["Auditor", "proyectos", false],
      ["Usuario", "agentes", false],
      ["Coordinador", "agentes", true],
      ["Economico", "agentes", false],
      ["Auditor", "agentes", false],
      ["Contratos", "agentes", false] ].each do |nuevo|
        rol = Rol.create nombre: nuevo[0], seccion: nuevo[1], admin: nuevo[2] 
        puts "--------> ERROR!!!: " + rol.errors.inspect unless rol.errors.empty?
      end
  end

  def down
    drop_table :permiso_x_rol
    drop_table :rol 
  end
end
