class AddPaisIdToDatosProyecto < ActiveRecord::Migration
  def up 
    # Crea el nuevo campo para recoger el pais asociado
    add_column :datos_proyecto, :pais_id, :integer
    add_index :datos_proyecto, [:proyecto_id, :pais_id], name: "index_datos_proyecto_pais"
    # Asigna los valores por defecto al resto de datos
    change_column_default :datos_proyecto, :beneficiarios_directos_hombres, 0 
    change_column_default :datos_proyecto, :beneficiarios_directos_mujeres, 0 
    change_column_default :datos_proyecto, :beneficiarios_indirectos_hombres, 0 
    change_column_default :datos_proyecto, :beneficiarios_indirectos_mujeres, 0 
    change_column_default :datos_proyecto, :beneficiarios_directos_sin_especificar, 0 
    change_column_default :datos_proyecto, :beneficiarios_indirectos_sin_especificar, 0 
    change_column_default :datos_proyecto, :poblacion_total_de_la_zona, 0 
    # Recarga el modelo de datos
    DatosProyecto.reset_column_information
    # Recorre todos los datos existentes para vincular al pais mas adecuado (si existe)
    DatosProyecto.all.each do |dato|
      # Si solo tenemos un pais, lo asignamos al dato
      if dato.proyecto
        dato.update_column(:pais_id, dato.proyecto.pais.first.id) if  dato.proyecto.pais and  dato.proyecto.pais.count == 1
      else
        dato.delete
      end
    end
  end
  def down
    # Crea el nuevo campo para recoger el pais asociado
    remove_index :datos_proyecto, name: "index_datos_proyecto_pais"
    remove_column :datos_proyecto, :pais_id
    # Asigna los valores por defecto al resto de datos
    change_column_default :datos_proyecto, :beneficiarios_directos_hombres, nil 
    change_column_default :datos_proyecto, :beneficiarios_directos_mujeres, nil
    change_column_default :datos_proyecto, :beneficiarios_indirectos_hombres, nil
    change_column_default :datos_proyecto, :beneficiarios_indirectos_mujeres, nil
    change_column_default :datos_proyecto, :beneficiarios_directos_sin_especificar, nil
    change_column_default :datos_proyecto, :beneficiarios_indirectos_sin_especificar, nil
    change_column_default :datos_proyecto, :poblacion_total_de_la_zona, nil
  end
end
