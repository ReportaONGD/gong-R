class ChangeComentarioToPolimorfic < ActiveRecord::Migration
  def up
    errores = []
    # Crea los campos para el polimorfismo
    add_column :comentario, :elemento_type, :string, null: false
    add_column :comentario, :elemento_id, :integer, null: false
    #add_column :comentario, :elemento, :references, polymorphic: true, index: true

    # Recarga y sincroniza las referencias
    Comentario.reset_column_information
    elementos = ["tarea", "documento", "objetivo_especifico", "resultado", "actividad", "subactividad", "indicador", "fuente_verificacion", "presupuesto", "gasto"]
    Comentario.all.each do |comentario|
      elemento_type = nil
      elemento_id = nil
      elementos.each do |elemento|
        if comentario.send(elemento + "_id")
          elemento_type = elemento.classify
          elemento_id = comentario.send(elemento + "_id") 
        end
      end
      comentario.update_attributes(elemento_type: elemento_type, elemento_id: elemento_id) if elemento_type && elemento_id
      puts "------> Error al guardar el comentario: " + comentario.errors.inspect unless comentario.errors.empty?
      errores.push comentario unless elemento_type && elemento_id
    end

    # Si no se han producido errores, elemina los campos de referencia antiguos
    if errores.empty?
      elementos.each do |elemento|
        remove_column :comentario, (elemento + "_id").to_sym
      end
    else
      puts "--------> Al crear el polimorfismo se han producido errores con los comentarios con ids: " + errores.collect{|c| c.id.to_s}.join(", ")
    end
  end

  def down
    errores = []
    elementos = ["tarea", "documento", "objetivo_especifico", "resultado", "actividad", "subactividad", "indicador", "fuente_verificacion", "presupuesto", "gasto"]
    # Crea los campos de referencia antiguos
    elementos.each do |elemento|
      add_column :comentario, (elemento + "_id").to_sym, :integer
    end

    # Recarga y sincroniza las referencias
    Comentario.reset_column_information
    Comentario.all.each do |comentario|
      if elementos.include?(comentario.elemento_type.underscore)
        nombre_campo = comentario.elemento_type.underscore + "_id"
        comentario.update_attributes(nombre_campo.to_sym => comentario.elemento_id) if comentario.elemento_type && comentario.elemento_id
        puts "------> Error al guardar el comentario: " + comentario.errors.inspect unless comentario.errors.empty?
        erores.push comentario unless comentario.elemento_type && comentario.elemento_id
      end
    end

    # Elimina los campos del polimorfismo si no hay errores
    if errores.empty?
      remove_column :comentario, :elemento_type
      remove_column :comentario, :elemento_id  
    else
      puts "--------> Al eliminar el polimorfismo se han producido errores con los comentarios con ids: " + errores.collect{|c| c.id.to_s}.joins(", ")
    end
  end
end
