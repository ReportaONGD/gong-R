class AddConvocatoriaToProyecto < ActiveRecord::Migration
  def up
    # Crea la vinculacion desde proyectos hacia convocatorias
    add_column :proyecto, :convocatoria_id, :integer, :null => false
    Proyecto.reset_column_information
    # Genera las convocatorias de los proyectos ya existentes (solo proyectos y convenios, no pacs)
    Proyecto.where(:convenio_id => nil).each do |proyecto|
      financiador = Agente.find_by_id proyecto.agente_id
      nombre_financiador = financiador ? financiador.nombre : "Sin Financiador"
      anno = proyecto.fecha_convocatoria ? proyecto.fecha_convocatoria.year.to_s : "General"
      nombre = nombre_financiador + "-" + anno
      convocatoria = Convocatoria.find_or_create_by_codigo_and_nombre_and_agente_id(nombre, nombre, proyecto.agente_id)
      convocatoria.update_column(:fecha_publicacion, proyecto.fecha_convocatoria) if proyecto.fecha_convocatoria
      proyecto.update_column(:convocatoria_id, convocatoria.id) if convocatoria 
    end
    # Para los PACs le pone la convocatoria del convenio
    Proyecto.where("convenio_id IS NOT NULL").each do |pac|
      pac.update_column(:convocatoria_id, pac.convenio.convocatoria_id)
    end
    remove_column :proyecto, :fecha_convocatoria
  end

  def down
    add_column :proyecto, :fecha_convocatoria, :date
    Proyecto.reset_column_information
    # Reestablece las fechas de convocatoria
    Proyecto.all.each do |proyecto|
      proyecto.update_column(:fecha_convocatoria, proyecto.convocatoria.fecha_publicacion) if proyecto.convocatoria
    end
    remove_column :proyecto, :convocatoria_id
  end
end
