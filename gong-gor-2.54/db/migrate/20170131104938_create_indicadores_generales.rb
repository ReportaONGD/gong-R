class CreateIndicadoresGenerales < ActiveRecord::Migration
  def change
    create_table :indicador_general, force: true do |t|
      t.string :nombre, null: false
      t.string :descripcion
      t.timestamps
    end
    add_index :indicador_general, [:id]
  end
end
