class AddOcultarGastosOtrasDelegacionesToProyecto < ActiveRecord::Migration
  def change
    add_column :proyecto, :ocultar_gastos_otras_delegaciones, :boolean, null: false, default: false
  end
end
