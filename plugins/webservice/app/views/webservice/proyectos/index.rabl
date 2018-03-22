collection @proyectos => :proyecto
attributes :id, :nombre, :titulo, :identificador_financiador, :fecha_de_inicio, :fecha_de_fin
attributes :convenio? => :es_convenio

node :financiador_principal_id do |proyecto|
  proyecto.convocatoria.agente.id
end

node :financiador_principal_nombre do |proyecto|
  proyecto.convocatoria.agente.nombre
end

node :gestor_id do |proyecto|
  proyecto.gestor.id
end

node :gestor do |proyectos|
  proyectos.gestor.nombre
end

node :estado_del_proyecto do |proyecto|
    proyecto.estado_actual.definicion_estado.nombre
end

child :periodo_justificacion => :seguimiento_periodos do |proyecto|
  attributes :id
  attributes :fecha_inicio, :fecha_fin, :descripcion
  node :tipo_periodo do |periodo|
    TipoPeriodo.find(periodo.tipo_periodo_id).nombre
  end
end
