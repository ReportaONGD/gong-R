class AddPaisIdToGasto < ActiveRecord::Migration
  def up 
    # Incluimos el pais del gasto como no nulo
    add_column :gasto, :pais_id, :integer, :null => false
    Gasto.reset_column_information
    puts ">>>>>>>>>>>>> Asignando pais a todos los gastos (puede tardar un poco)..."
    Gasto.all.each do |gasto|
      pais_id = nil
      # Si el gasto esta pagado, pilla el pais del primer pago
      if gasto.pago.first && gasto.pago.first.libro
        pais_id = gasto.pago.first.libro.pais_id
      # Si no esta pagado, lo pilla del pais del implementador
      else
        pais_id = gasto.agente.pais_id if gasto.agente
        # Y si no, del primer proyecto que tenga
        pais_id ||= gasto.gasto_x_proyecto.first.proyecto.pais.first.id unless gasto.gasto_x_proyecto.empty? || gasto.gasto_x_proyecto.first.proyecto.nil? || gasto.gasto_x_proyecto.first.proyecto.pais.empty? 
      end
      # Evitamos validaciones y callbacks
      gasto.update_column(:pais_id, pais_id)
    end
  end
  def down
    remove_column :gasto, :pais_id
  end
end
