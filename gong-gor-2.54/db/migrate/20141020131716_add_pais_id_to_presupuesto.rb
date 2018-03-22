class AddPaisIdToPresupuesto < ActiveRecord::Migration
  def up
    # Incluimos el pais del gasto como no nulo
    add_column :presupuesto, :pais_id, :integer
    Presupuesto.reset_column_information
    puts ">>>>>>>>>>>>> Asignando pais a todas las lineas de presupuesto (puede tardar un poco)..."
    Presupuesto.all.each do |presupuesto|
      # Si es un presupuesto de proyecto
      if presupuesto.proyecto_id
        # Averiguamos los posibles paises desde actividad_x_pais -> actividad -> pais
        paises = Pais.joins(:actividad_x_pais).where("actividad_x_pais.actividad_id" => presupuesto.actividad).uniq
        # Si solo tenemos un pais, ese es el de la linea de presupuesto, si no es una linea de presupuesto regional
        pais_id = paises.first.id if paises.count == 1
      # Si es un presupuesto de agente, el pais es el del agente
      elsif presupuesto.agente && presupuesto.agente.pais
        pais_id = presupuesto.agente.pais_id
      end
      # Evitamos validaciones y callbacks
      presupuesto.update_column(:pais_id, pais_id) if pais_id
    end
  end
  def down
    remove_column :presupuesto, :pais_id
  end
end
