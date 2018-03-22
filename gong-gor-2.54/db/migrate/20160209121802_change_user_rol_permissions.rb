class ChangeUserRolPermissions < ActiveRecord::Migration
  def up
    PermisoXRol.where(menu: "configuracion_agente", controlador: "usuario").each do |pxr|
      pxr.update_attribute :controlador, "relaciones_usuario"
    end
  end

  def down
    PermisoXRol.where(menu: "configuracion_agente", controlador: "relaciones_usuario").each do |pxr|
      pxr.update_attribute :controlador, "usuario"
    end
  end
end
