class AnadirIdFinanciadorToProyecto < ActiveRecord::Migration
  def up
    add_column :proyecto, :identificador_financiador, :string, :null => false
  end

  def down
   remove_column :proyecto, :identificador_financiador
  end
end
