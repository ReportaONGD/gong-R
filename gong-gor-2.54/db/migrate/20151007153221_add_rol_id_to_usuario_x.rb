class AddRolIdToUsuarioX < ActiveRecord::Migration
  def up
    # Crea los nuevos campos de referencia a roles
    add_column(:usuario_x_proyecto, :rol_id, :integer, null: false) unless column_exists?(:usuario_x_proyecto, :rol_id)
    add_column(:grupo_usuario_x_proyecto, :rol_id, :integer, null: false) unless column_exists?(:grupo_usuario_x_proyecto, :rol_id)
    add_column(:usuario_x_agente, :rol_id, :integer, null: false) unless column_exists?(:usuario_x_agente, :rol_id)
    add_column(:grupo_usuario_x_agente, :rol_id, :integer, null: false) unless column_exists?(:grupo_usuario_x_agente, :rol_id)
    # Recarga los modelos...
    UsuarioXProyecto.reset_column_information
    UsuarioXAgente.reset_column_information
    GrupoUsuarioXProyecto.reset_column_information
    GrupoUsuarioXAgente.reset_column_information
    puts "--------> Actualizando roles de los permisos asignados... puede tardar un rato..."
    # Recorre el modelo de relacion con Proyectos para actualizar la info con la del modelo de roles
    roles = { "usuario" => Rol.find_by_nombre_and_seccion("Usuario", "proyectos"),
              "coordinador" => Rol.find_by_nombre_and_seccion("Coordinador", "proyectos"),
              "configurador" => Rol.find_by_nombre_and_seccion("Configurador", "proyectos"),
              "auditor" => Rol.find_by_nombre_and_seccion("Auditor", "proyectos") }
    UsuarioXProyecto.all.each do |uxp|
      # Usamos siempre read_attribute para salvar el metodo "rol" de ayuda de los modelos
      rol = uxp.read_attribute(:rol)
      uxp.update_column(:rol_id, roles[rol].id) if rol
      puts "-------> ERROR!!!!: No conseguimos encontrar el rol para " + uxp.inspect unless roles[uxp.rol]
    end
    GrupoUsuarioXProyecto.all.each do |guxp|
      rol = guxp.read_attribute(:rol)
      guxp.update_column(:rol_id, roles[rol].id) if rol
      puts "-------> ERROR!!!!: No conseguimos encontrar el rol para " + guxp.inspect unless roles[guxp.rol]
    end
    # Recorre el modelo de relacion con Agentes para actualizar la info con la del modelo de roles
    roles = { "usuario" => Rol.find_by_nombre_and_seccion("Usuario", "agentes"),
              "coordinador" => Rol.find_by_nombre_and_seccion("Coordinador", "agentes"),
              "economico" => Rol.find_by_nombre_and_seccion("Economico", "agentes"),
              "auditor" => Rol.find_by_nombre_and_seccion("Auditor", "agentes") }
    UsuarioXAgente.all.each do |uxa|
      rol = uxa.read_attribute(:rol)
      uxa.update_column(:rol_id, roles[rol].id) if rol
      puts "-------> ERROR!!!!: No conseguimos encontrar el rol para " + uxa.inspect unless roles[uxa.rol]
    end
    GrupoUsuarioXAgente.all.each do |guxa|
      rol = guxa.read_attribute(:rol)
      guxa.update_column(:rol_id, roles[rol].id) if rol
      puts "-------> ERROR!!!!: No conseguimos encontrar el rol para " + guxa.inspect unless roles[guxa.rol]
    end
    # Elimina los viejos campos
    remove_column :usuario_x_proyecto, :rol
    remove_column :grupo_usuario_x_proyecto, :rol
    remove_column :usuario_x_agente, :rol
    remove_column :grupo_usuario_x_agente, :rol
  end
  # Hace rollback de la migracion
  def down
    # Crea los campos antiguos
    add_column(:usuario_x_proyecto, :rol, :string) unless column_exists?(:usuario_x_proyecto, :rol)
    add_column(:grupo_usuario_x_proyecto, :rol, :string) unless column_exists?(:grupo_usuario_x_proyecto, :rol)
    add_column(:usuario_x_agente, :rol, :string, default: "usuario") unless column_exists?(:usuario_x_agente, :rol)
    add_column(:grupo_usuario_x_agente, :rol, :string) unless column_exists?(:grupo_usuario_x_agente, :rol)
    # Recarga los modelos...
    UsuarioXProyecto.reset_column_information
    UsuarioXAgente.reset_column_information
    GrupoUsuarioXProyecto.reset_column_information
    GrupoUsuarioXAgente.reset_column_information
    # Recorre los modelos para mantener la informacion
    UsuarioXProyecto.all.each { |obj| obj.update_column(:rol, obj.rol_asignado.nombre.downcase) }
    GrupoUsuarioXProyecto.all.each {|obj| obj.update_column(:rol, obj.rol_asignado.nombre.downcase) }
    UsuarioXAgente.all.each { |obj| obj.update_column(:rol, obj.rol_asignado.nombre.downcase) }
    GrupoUsuarioXAgente.all.each {|obj| obj.update_column(:rol, obj.rol_asignado.nombre.downcase) }
    # Elimina los nuevos campos
    remove_column(:usuario_x_proyecto, :rol_id) if column_exists?(:usuario_x_proyecto, :rol_id)
    remove_column(:grupo_usuario_x_proyecto, :rol_id) if column_exists?(:grupo_usuario_x_proyecto, :rol_id)
    remove_column(:usuario_x_agente, :rol_id) if column_exists?(:usuario_x_agente, :rol_id)
    remove_column(:grupo_usuario_x_agente, :rol_id) if column_exists?(:grupo_usuario_x_agente, :rol_id)
  end
end
