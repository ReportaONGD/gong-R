class AddJustificacionToTipoTarea < ActiveRecord::Migration
  def up 
    add_column :tipo_tarea, :justificacion, :boolean, default: false
    add_column :tipo_tarea, :dias_aviso_finalizacion, :string
  end
  def down
    remove_column :tipo_tarea, :justificacion
    remove_column :tipo_tarea, :dias_aviso_finalizacion
  end
end
