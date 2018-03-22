class UpdateResumenProyectosAgentePermissions < ActiveRecord::Migration
  def up 
    # Actualiza los permisos de los roles de agentes
    # para el nuevo controlador de resumenes de proyectos del agente
    PermisoXRol.where(menu: "resumen_agente", controlador: "resumen_agente", ver: true).each do |pxr|
      # Crea el permiso para el nuevo controlador
      PermisoXRol.create rol_id: pxr.rol_id,
                         menu: "resumen_agente", controlador: "resumen_proyectos_agente",
                         ver: true, cambiar: pxr.cambiar 
    end
  end

  def down
  end
end
