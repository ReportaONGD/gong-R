class CreateProveedores < ActiveRecord::Migration
  def up
    # Crea la tabla donde se recogen los proveedores
    create_table :proveedor, :force => true do |t|
      t.string :nombre, :null => false
      t.string :nif, :null => false
      t.string :descripcion
      t.text :observaciones
      t.integer :agente_id, :null => false
      t.integer :pais_id
      t.boolean :activo, :null => false, :default => true
      t.timestamps
    end
    add_index :proveedor, [:id]
    add_index :proveedor, [:agente_id]

    # Crea la vinculacion de proveedores y gastos
    add_column :gasto, :proveedor_id, :integer

    # Recarga y sincroniza la referencia
    Gasto.reset_column_information
    puts ">>>>>>>>>>>>> Asignando proveedor a todos los gastos (puede tardar un poco)..."    
    Gasto.all.each do |gasto|
      # Hacemos este lio para evitar una invocacion a gasto.emisor_factura que nos devolveria
      # la llamada al metodo nuevo de compatibilidad y no el valor del campo
      emisor = gasto.read_attribute(:emisor_factura)
      nombre = emisor.blank? ? gasto.dni_emisor : emisor
      unless nombre.blank?
        proveedor = Proveedor.find_or_create_by_nombre_and_nif_and_agente_id(nombre, gasto.dni_emisor, gasto.agente_id)
        proveedor.update_attributes(pais_id: gasto.pais_id) if gasto.pais && proveedor.pais_id.nil?
        # Actualizamos el gasto evitando las validaciones
        gasto.update_column(:proveedor_id, proveedor.id)
        puts "----------> ERROR actualizando el gasto!: " + gasto.errors.inspect unless gasto.errors.empty?
      end
    end

    # Elimina los campos antiguos de proveedor en los gastos
    remove_column :gasto, :emisor_factura
    remove_column :gasto, :dni_emisor
  end

  def down
    # Crea los campos de proveedor en gastos
    add_column :gasto, :emisor_factura, :string
    add_column :gasto, :dni_emisor, :string

    # Actualiza esquema y rellena la info de proveedores
    Gasto.reset_column_information
    puts ">>>>>>>>>>>>> Asignando proveedor a todos los gastos (puede tardar un poco)..."
    Gasto.all.each do |gasto|
      proveedor = gasto.proveedor
      # Actualizamos el gasto evitando que los plugins nos bloqueen la modificacion
      gasto.update_column(:emisor_factura, proveedor.nombre) if proveedor
      gasto.update_column(:dni_emisor, proveedor.nif) if proveedor
    end
 
    # Elimina la tabla de vinculacion con proveedores
    remove_column :gasto, :proveedor_id
    # Elimina la tabla de proveedores
    drop_table :proveedor
  end
end
