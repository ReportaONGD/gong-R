class CreateContrato < ActiveRecord::Migration
  def up
    # Tabla para recoger los contratos
    create_table :contrato, force: true do |t|
      t.string   :codigo
      t.string   :nombre,          null: false
      t.decimal  :importe,         null: false, precision: 24, scale: 2
      t.integer  :moneda_id,       null: false
      t.text     :descripcion
      t.text     :observaciones
      t.date     :fecha_inicio,    null: false
      t.date     :fecha_fin,       null: false
      t.integer  :agente_id,       null: false
      t.integer  :proyecto_id
      t.integer  :proveedor_id
      t.integer  :marcado_id
      t.timestamps
    end
    add_index :contrato, [:id]
    add_index :contrato, [:agente_id]

    # Tabla que recoge los cambios en estados de contratos
    create_table :estado_contrato, force: true do |t|
      t.integer  :workflow_contrato_id, null: false
      t.integer  :contrato_id,          null: false 
      t.date     :fecha_inicio
      t.date     :fecha_fin
      t.text     :observaciones
      t.integer  :usuario_id,           null: false
      t.boolean  :estado_actual,        null: false, default: false
      t.timestamps
    end
    add_index :estado_contrato, [:contrato_id]
    add_index :estado_contrato, [:workflow_contrato_id]

    # Tabla que recoge la vinculacion del contrato con actividades
    create_table :contrato_x_actividad, force: true do |t|
      t.integer  :contrato_id,  null: false
      t.integer  :actividad_id, null: false 
      t.decimal  :importe,      null: false, precision: 24, scale: 2, default: 0.0
      t.timestamps
    end
    add_index :contrato_x_actividad, [:contrato_id]
    add_index :contrato_x_actividad, [:actividad_id]
  end

  def down
    drop_table :contrato_x_actividad
    drop_table :estado_contrato
    drop_table :contrato
  end
end
