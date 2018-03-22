class CreateRelacionesIndicadorGeneral < ActiveRecord::Migration
  def change
    # Crea la relacion de programas marco con indicadores generales
    create_table :indicador_general_x_programa_marco, force: true do |t|
      t.integer :programa_marco_id, null: false
      t.integer :indicador_general_id, null: false
      t.timestamps
    end
    add_index :indicador_general_x_programa_marco, [:programa_marco_id, :indicador_general_id], name: "igxpm_idx"
    # Crea la tabla de relacion de proyectos con indicadores generales
    create_table :indicador_general_x_proyecto, force: true do |t|
      t.integer :proyecto_id, null: false
      t.integer :indicador_general_id, null: false
      t.string  :herramienta_medicion
      t.string  :fuente_informacion
      t.text    :contexto
      t.integer :valor_base_id
      t.integer :valor_objetivo_id
      t.timestamps
    end 
    add_index :indicador_general_x_proyecto, [:proyecto_id, :indicador_general_id], name: "igxp_idx"
    # Crea la tabla de valores medidos de indicadores generales
    create_table :valor_x_indicador_general, force: true do |t|
      t.integer :indicador_general_x_proyecto_id
      t.date    :fecha, null: false
      t.integer :valor, null: false, default: 0
      t.text    :comentario
      t.timestamps
    end
    add_index :valor_x_indicador_general, [:indicador_general_x_proyecto_id], name: "vxig_idx"
  end
end
