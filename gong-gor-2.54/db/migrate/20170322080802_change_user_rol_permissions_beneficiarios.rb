class ChangeUserRolPermissionsBeneficiarios < ActiveRecord::Migration
  def up
    # Como hemos movido la gestion de beneficiarios del controlador de datos_proyecto
    # al controlador de beneficiarios, modificamos los permisos que tengamos definidos
    PermisoXRol.where(menu: "identificacion", controlador: "datos_proyecto").each do |pxr|
      pxr.update_attribute :controlador, "beneficiarios"
    end
  end

  def down
    # Como hemos movido la gestion de beneficiarios del controlador de datos_proyecto
    # al controlador de beneficiarios, modificamos los permisos que tengamos definidos
    PermisoXRol.where(menu: "identificacion", controlador: "beneficiarios").each do |pxr|
      pxr.update_attribute :controlador, "datos_proyecto"
    end
  end
end
