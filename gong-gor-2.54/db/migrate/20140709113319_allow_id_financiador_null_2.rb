class AllowIdFinanciadorNull2 < ActiveRecord::Migration
  def up
    change_column :proyecto, :identificador_financiador, :string, :null => false, :default => ""
  end

  def down
    change_column :proyecto, :identificador_financiador, :string, :null => true
  end
end
