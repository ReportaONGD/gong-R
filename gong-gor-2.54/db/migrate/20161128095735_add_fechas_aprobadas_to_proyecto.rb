class AddFechasAprobadasToProyecto < ActiveRecord::Migration
  def up 
    add_column :proyecto, :fecha_inicio_aprobada_original, :date
    add_column :proyecto, :fecha_fin_aprobada_original, :date
    # Recorreo todos los proyectos aprobados para asignar
    # las fechas aprobadas originales
    Proyecto.reset_column_information
    Proyecto.joins(:definicion_estado).where("definicion_estado.aprobado" => true).each do |proyecto|
      # Aplicamos las modificaciones para no invocar validaciones ni callbacks
      proyecto.update_column(:fecha_inicio_aprobada_original, proyecto.fecha_de_inicio)
      proyecto.update_column(:fecha_fin_aprobada_original, proyecto.fecha_de_fin)
    end
  end
  def down
    remove_column :proyecto, :fecha_inicio_aprobada_original
    remove_column :proyecto, :fecha_fin_aprobada_original
  end
end
