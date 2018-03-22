class CamposTipoContrato < ActiveRecord::Migration
  def up
    # Crea la definicion de campos particulares de cada tipo de contrato
    create_table :campo_tipo_contrato, force: true do |t|
      t.integer  :tipo_contrato_id, null: false
      t.string   :nombre,           null: false
      t.string   :etiqueta,         null: false
      t.string   :descripcion
      # Trabajaremos con posibles valores: "boolean", "text", "number"
      t.string   :tipo_campo,       null: false, default: "boolean"
      t.string   :tipo_condicion
      t.string   :valor_condicion
      t.boolean  :activo,           null: false, default: true
      t.timestamps
    end
    add_index :campo_tipo_contrato, [:id]
    add_index :campo_tipo_contrato, [:tipo_contrato_id]

    # Crea el mapeado entre definiciones de campos y contratos
    create_table :contrato_x_campo_tipo_contrato, force: true do |t|
      t.integer  :campo_tipo_contrato_id, null: false
      t.integer  :contrato_id,            null: false
      t.text     :valor_dato
    end
  end

  def down
    drop_table :campo_tipo_contrato
    drop_table :contrato_x_campo_tipo_contrato
  end
end
