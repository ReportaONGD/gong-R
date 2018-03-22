class ChangeUserRolPermissions3 < ActiveRecord::Migration
  def up
     Rol.all.each do |r|
       PermisoXRol.create(rol_id: r.id, menu: "resumen", controlador: "comentario", ver: true, cambiar: true) if r.seccion == "proyectos"
       PermisoXRol.create(rol_id: r.id, menu: "resumen_agente", controlador: "comentario", ver: true, cambiar: true) if r.seccion == "agentes"
     end
  end

  def down
    PermisoXRol.where(menu: "resumen", controlador: "comentario").destroy_all
    PermisoXRol.where(menu: "resumen_agente", controlador: "comentario").destroy_all
  end
end
