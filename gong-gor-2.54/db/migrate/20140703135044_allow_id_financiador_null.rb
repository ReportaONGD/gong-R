class AllowIdFinanciadorNull < ActiveRecord::Migration
  def up
    change_column :proyecto, :identificador_financiador, :string, :null => true 
  end

  def down
    change_column :proyecto, :identificador_financiador, :string, :null => false 
  end
end
