class CreateTipoContrato < ActiveRecord::Migration
  def up
    create_table :tipo_contrato, :force => true do |t|
      t.string :nombre, :null => false
      t.string :descripcion
      t.text :observaciones
      t.integer :duracion
      t.integer :agente_id
      t.timestamps
    end
    add_index :tipo_contrato, [:id]
    add_index :tipo_contrato, [:agente_id]
  end

  def down
    drop_table :tipo_contrato
  end
end
