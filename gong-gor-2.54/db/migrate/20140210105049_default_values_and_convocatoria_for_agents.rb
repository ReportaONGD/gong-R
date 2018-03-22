class DefaultValuesAndConvocatoriaForAgents < ActiveRecord::Migration
  def up
    change_column_default :agente, :sistema, false
    change_column_default :agente, :publico, false
    change_column_default :agente, :financiador, false
    change_column_default :agente, :implementador, false
    # Aplica el valor a los no definidos
    Agente.update_all( {:sistema => false}, { :sistema => nil } )
    Agente.update_all( {:publico => false}, { :publico => nil } )
    Agente.update_all( {:financiador => false}, { :financiador => nil } )
    Agente.update_all( {:implementador => false}, { :implementador => nil } )

    # Crea las convocatorias para financiadores ya existentes
    Agente.where(:financiador => true, :implementador => false, :sistema => false).each do |agente|
      nombre_conv = agente.nombre + "-" + _("General")
      Convocatoria.find_or_create_by_codigo_and_nombre_and_agente_id(nombre_conv, nombre_conv, agente.id)
    end
  end

  def down
  end
end
