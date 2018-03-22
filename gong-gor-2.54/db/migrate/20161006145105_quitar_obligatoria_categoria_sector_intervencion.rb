class QuitarObligatoriaCategoriaSectorIntervencion < ActiveRecord::Migration
  def up
    change_column :sector_intervencion, :categoria_sector_intervencion_id, :integer, null: true
  end

  def down
    change_column :sector_intervencion, :categoria_sector_intervencion_id, :integer, null: false
  end
end
