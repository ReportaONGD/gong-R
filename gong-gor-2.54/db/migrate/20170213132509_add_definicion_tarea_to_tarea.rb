class AddDefinicionTareaToTarea < ActiveRecord::Migration
  def up 
    # Hacemos que una tarea recuerde que se le ha invocado desde el workflow
    add_column :tarea, :definicion_estado_tarea_id, :integer
  end
  def down
    remove_column :tarea, :definicion_estado_tarea_id
  end
end
