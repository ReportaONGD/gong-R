class AnadirAGastoOrdenFacturaProyecto < ActiveRecord::Migration
  def up
    add_column :gasto, :orden_factura_proyecto, :integer
    Gasto.reset_column_information
    puts "--------> Actualizando numeracion de facturas en proyecto abiertos... puede tardar un rato..."
    # Con esta migracion numeramos todos los gastos del sistemas que estén en proyectos activos, aprobados
    Proyecto.all.each do |proyecto|
      estado = proyecto.estado_actual.definicion_estado if proyecto.estado_actual
      if estado and estado.aprobado and !estado.cerrado
        #Para agente implementador dentro del proyecto
        proyecto.implementador.each do |implementador|
          # Solo numeramos los gastos gestionados desde el propio proyecto
          condiciones = {
            "gasto.proyecto_origen_id" => proyecto.id,
            "gasto.agente_id" => implementador.id
          }
          i = 1
          proyecto.gasto.where(condiciones).each do |gasto|
            gasto.update_column :orden_factura_proyecto, i.to_s
            i = i + 1
          end
        end
      end
    end
  end

  def down
    remove_column :gasto, :orden_factura_proyecto
  end
end
