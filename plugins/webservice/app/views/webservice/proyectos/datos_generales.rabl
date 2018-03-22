object @proyecto
attributes :identificador_financiador => :codigo
attributes :nombre, :titulo

node :gestor do
  @proyecto.gestor.nombre
end

node :ongd_agrupacion do
  @proyecto.ongd_agrupacion.collect{|p| p.nombre + (p.nombre_completo ? " (" + p.nombre_completo + ")" : "")}.join(", ")
end

node :pais do
  @proyecto.pais.collect{|p| p.nombre}.join(", ")
end

node :socio_local do
  @proyecto.socio_local.collect{|p| p.nombre + (p.nombre_completo ? " (" + p.nombre_completo + ")" : "")}.join(", ") 
end

node :coste_total do
  @proyecto.presupuesto_total_con_tc 
end

node :aportacion_financiador do
  @proyecto.presupuesto_total_con_tc(:financiador => @proyecto.agente)
end

node :aportacion_ongd do
  @proyecto.presupuesto_total_con_tc(:financiador => @proyecto.ongd_agrupacion)
end

child @otros_financiadores => :otras_aportaciones do
  node :nombre do |p|
    p.nombre + (p.nombre_completo ? " (" + p.nombre_completo + ")" : "")
  end
  node :importe do |p|
    @proyecto.presupuesto_total_con_tc(:financiador => p)
  end
end

attributes :fecha_de_inicio, :fecha_de_fin

attributes :duracion_meses => :duracion

node :subvencion_ejecutada do
  @proyecto.gasto_total_con_financiador @proyecto.agente
end

node :moneda_base do 
  Moneda.find(@proyecto.moneda_id).abreviatura if @proyecto.moneda_id
end

node :divisa do 
  Moneda.find(@proyecto.moneda_intermedia).abreviatura if @proyecto.moneda_intermedia
end

child :moneda => :monedas do
  attributes :id, :abreviatura, :nombre
end

