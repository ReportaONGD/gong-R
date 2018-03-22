class AddMetaTipoToTipoTarea < ActiveRecord::Migration
  def up
	add_column :tipo_tarea, :administracion, :boolean, default: false
    	add_column :tipo_tarea, :configuracion, :boolean, default: false 
	add_column :tipo_tarea, :formulacion_economica, :boolean, default: false
	add_column :tipo_tarea, :formulacion_tecnica, :boolean, default: false
	add_column :tipo_tarea, :seguimiento_economico, :boolean, default: false
	add_column :tipo_tarea, :seguimiento_tecnico, :boolean, default: false
  end

  def down
	remove_column :tipo_tarea, :administracion
        remove_column :tipo_tarea, :configuracion
        remove_column :tipo_tarea, :formulacion_economica
        remove_column :tipo_tarea, :formulacion_tecnica
        remove_column :tipo_tarea, :seguimiento_economico
        remove_column :tipo_tarea, :seguimiento_tecnico
  end

end
