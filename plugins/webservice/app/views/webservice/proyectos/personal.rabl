object @proyecto => :personal

child :personal => :personas do
  attributes :nombre, :categoria, :residencia, :tipo_contrato, :horas_imputadas, :salario_mensual, :meses, :salario_total
  node :tipo do |personal|
    personal.tipo_personal.codigo 
  end
  node :moneda do |personal|
    personal.moneda.abreviatura
  end
end

