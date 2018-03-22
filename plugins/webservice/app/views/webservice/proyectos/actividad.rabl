object @actividad

attributes :id, :codigo, :descripcion
node :estado_periodos do |actividad|
  actividad.estado_seguimiento(@fecha_fin)
end unless @solo_formulacion
child :presupuesto_x_partida_financiador => :recursos do
  attributes :partida_proyecto_nombre => :nombre
  attributes :suma_importe => :coste
end
attributes :suma_presupuesto => :total_coste_recursos
