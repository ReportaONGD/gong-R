# encoding: UTF-8

# Esta tarea se crea para hacer lo mismo que hace el migrate:
#https://gong.org.es/projects/gor/repository/revisions/7459/entry/trunk/gor/db/migrate/20160209121802_change_user_rol_permissions.rb
# Esta información se perdio, posiblemente por una reasignacion general en algunas instancias

namespace :permisos do
  desc "Reaplica permisos para la gestión de usuario en delegaciones para roles de administracion"
  task :reasigna_permisos_gestion_usuario_agente => :environment do
    puts "\n\n"
    puts "*************************************************************************"
    puts "********** RE-ASIGNACION DE PERMISOS USUARIOS DE DELEGACIONES ***********"
    puts "*************************************************************************"
    puts ""
    Rol.where(seccion: "agentes", admin: true).each do |r|
      PermisoXRol.create(rol_id: r.id, menu: "configuracion_agente", controlador: "relaciones_usuario", ver: true, cambiar: true)
    end
  end
end  
