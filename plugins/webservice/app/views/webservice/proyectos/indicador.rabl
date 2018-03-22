object @indicador
attributes :id, :codigo, :descripcion

child :variable_indicador, :root => "variable" do
  attributes :nombre, :herramienta_medicion, :fuente_informacion, :contexto
  node :linea_base do |variable_indicador|
    variable_indicador.valor_base.valor if variable_indicador.valor_base
  end 
  node :meta_final do |variable_indicador|
    variable_indicador.valor_objetivo.valor if variable_indicador.valor_objetivo
  end
  node :estado_periodos do |variable_indicador|
    variable_indicador.estado_seguimiento(@fecha_fin)
  end unless @solo_formulacion
end

child :fuente_verificacion do
  attribute :indicador_id => :id
  attributes :codigo, :descripcion
  attributes :completada unless @solo_formulacion
end

child :comentario do
  attributes :texto => :texto
  node :fecha, :type => :date do |comentario|
    comentario.created_at.to_date.to_formatted_s(:db)
  end
end unless @solo_formulacion
