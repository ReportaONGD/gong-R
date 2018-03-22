class CambiaTipoDatoValoresIndicador < ActiveRecord::Migration
  def up
    change_column :valor_variable_indicador, :valor, :string, :null => false
  end

  def down
    change_column :valor_variable_indicador, :valor, :decimal, :precision => 24, :scale => 4, :null => false
  end
end
