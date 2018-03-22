class DefaultValuesForDefinicionEstado < ActiveRecord::Migration
  def up
    change_column_default :definicion_estado, :primer_estado, false
    change_column_default :definicion_estado, :formulacion, false
    change_column_default :definicion_estado, :aprobado, false
    change_column_default :definicion_estado, :cerrado, false
    DefinicionEstado.update_all( {:primer_estado => false}, {:primer_estado => nil } )
    DefinicionEstado.update_all( {:formulacion => false}, {:formulacion => nil } )
    DefinicionEstado.update_all( {:aprobado => false}, {:aprobado => nil } )
    DefinicionEstado.update_all( {:cerrado => false}, {:cerrado => nil } )
  end

  def down
  end
end
