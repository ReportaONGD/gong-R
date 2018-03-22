# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2017 OEI 
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>. 
#
#################################################################################
#
#++
# Revisa las tareas que tienen fecha de fin prevista y genera correos
# a los involucrados 
#

namespace :tareas do
  desc "Revisa las fechas de finalizacion de las tareas"
  task :revisa_fin => :environment do
    # Recorre los tipos de tareas con fechas de aviso previo definidas
    TipoTarea.where("dias_aviso_finalizacion is not null").
              where("dias_aviso_finalizacion != ''").each do |tipo|
      # Recorre los dias definidos en el tipo de tarea...
      tipo.dias_aviso_finalizacion.split(/\D*,\D*/).each do |dia|
        dia_estimado = Date.today + dia.to_i.day
        #puts "-------> Buscamos tareas que finalicen en el dia: " + dia_estimado.inspect
        tipo.tarea.where(fecha_fin: dia_estimado).
                   joins(:estado_tarea).
                   where("estado_tarea.activo" => true).each do |tarea|
          # Si es una tarea de workflow, hacemos un llamamiento general
          # a todos los participantes en proyecto
          if tarea.definicion_estado_tarea
            tarea.proyecto.usuario.where(bloqueado: false).each do |usuario|
              Correo.finalizacion_tarea_workflow(usuario, tarea).deliver
            end
          # Cuando es una tarea normal, informamos solo
          # a los involucrados en la tarea
          else
            # Averigua los usuarios a los que mandarle el correo
            usuarios = []
            usuarios.push tarea.usuario if tarea.usuario && !tarea.usuario.bloqueado
            usuarios.push tarea.usuario_asignado if tarea.usuario_asignado && !tarea.usuario_asignado.bloqueado
            usuarios.compact!
            # Si no hay usuarios a quien enviarle el correo, repesca a los admins de proyecto o agente
            usuarios = Usuario.where(bloqueado: false).
                               joins(:usuario_x_proyecto).
                               where("usuario_x_proyecto.proyecto_id" => tarea.proyecto_id).
                               joins(usuario_x_proyecto: :rol_asignado).
                               where("rol.admin" => true) if tarea.proyecto && usuarios.blank?
            usuarios = Usuario.where(bloqueado: false).
                               joins(:usuario_x_agente).
                               where("usuario_x_agente.agente_id" => tarea.agente_id).
                               joins(usuario_x_agente: :rol_asignado).
                               where("rol.admin" => true) if tarea.agente && usuarios.blank?
            usuarios.each do |usuario|
              Correo.finalizacion_tarea(usuario, tarea).deliver
            end
          end
        end
      end
    end
  end

  desc "Asigna las tareas automaticas (si no existieran) a proyectos ya abiertos"
  task :crea_tareas_workflow => :environment do
    texto_comentario = "Tarea creada para notificaciones."
    # Recorre todos los proyectos en metaestado "Ejecucion" y "Justificacion"
    Proyecto.joins(:definicion_estado).
             where("definicion_estado.ejecucion IS TRUE or definicion_estado.reporte IS TRUE").each do |proyecto|
      proyecto.definicion_estado.definicion_estado_tarea.each do |tarea|
        if (tipo_tarea = tarea.tipo_tarea)
          if tipo_tarea.seguimiento_economico || tipo_tarea.seguimiento_tecnico
            fecha_inicio = proyecto.fecha_inicio_actividades
            fecha_fin = proyecto.fecha_fin_actividades
          elsif tipo_tarea.justificacion
            fecha_inicio = proyecto.fecha_inicio_justificacion
            fecha_fin = proyecto.fecha_fin_justificacion
          end
          # Si no existe la tarea relacionada o no hay fecha de finalizacion, la crea de nuevas
          unless fecha_fin.nil? || proyecto.tarea.find_by_definicion_estado_tarea_id(tarea.id)
            puts " * Creando tarea de tipo '#{tarea.tipo_tarea.nombre}' para el proyecto '#{proyecto.nombre}'"
            tarea_proyecto = Tarea.create( titulo: tarea.titulo, estado_tarea_id: tarea.estado_tarea_id,
                                           fecha_inicio: fecha_inicio, fecha_fin: fecha_fin,
                                           definicion_estado_tarea_id: tarea.id, proyecto_id: proyecto.id,
                                           descripcion: tarea.descripcion, tipo_tarea_id: tarea.tipo_tarea_id )
            Comentario.create(texto: texto_comentario, elemento_type: "Tarea", elemento_id: tarea_proyecto.id, sistema: true) if tarea_proyecto.errors.empty?
            puts "   ERROR: Problemas creando la tarea" unless tarea_proyecto.errors.empty?
          end
        end
      end
    end
  end

end
