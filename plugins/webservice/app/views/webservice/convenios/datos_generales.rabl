object @proyecto => :convenio
attributes :identificador_financiador => :codigo
attributes :nombre, :titulo

node :gestor do
  @proyecto.gestor.nombre
end

node :ongd_agrupacion do
  @proyecto.ongd_agrupacion.collect{|p| p.nombre + (p.nombre_completo ? " (" + p.nombre_completo + ")" : "")}.join(", ")
end

node :sector_principal do
  @proyecto.proyecto_x_sector_intervencion.order("porcentaje DESC").first.sector_intervencion.nombre if @proyecto.proyecto_x_sector_intervencion.order("porcentaje DESC").first
end

node :sectores_secundarios do
  (@proyecto.proyecto_x_sector_intervencion.order("porcentaje DESC")[1..-1]||[]).collect{|p| p.sector_intervencion.nombre}.join(", ")
end

node :objetivo_estrategico_principal do
  @proyecto.area_actuacion.collect{|p| p.nombre}.join(", ")
end

node :pais do
  @proyecto.pais.collect{|p| p.nombre}.join(", ")
end

node :socio_local do
  @proyecto.socio_local.collect{|p| p.nombre + " (" + p.pais.nombre + (p.nombre_completo ? " / " + p.nombre_completo : "") + ")"}.join(", ") 
end

node :otras_entidades do
  @otros_financiadores.collect{|p| p.nombre + " (" + p.pais.nombre + (p.nombre_completo ? " / " + p.nombre_completo : "") + ")"}.join(", ")
end

node :poblacion_beneficiaria do
  @proyecto.dato_texto.joins(:definicion_dato).where("definicion_dato.nombre" => ["poblacion_beneficiaria","descripcion_poblacion_beneficiaria"]).collect{|p| p.dato}.join("")
end

attributes :fecha_de_inicio, :fecha_de_fin

attributes :duracion_meses => :duracion

node :pac do
  partial 'webservice/convenios/datos_pac', :object => @pac
end

glue @pac do
  child :resultado => :acciones do
    attributes :codigo, :descripcion
  end if @pac.convenio.convenio_accion == "resultado"

  child :objetivo_especifico => :acciones do
    attributes :codigo, :descripcion
  end unless @pac.convenio.convenio_accion == "resultado"
end

node :coste_total do
  @proyecto.presupuesto_total_con_tc
end

node :aportacion_financiador do
  @proyecto.presupuesto_total_con_tc(:financiador => @proyecto.agente)
end

node :aportacion_financiador_recibida do
  @pacs.collect{|pac| pac.transferencia.where(:tipo => "subvencion").includes("transferencia_x_agente","libro_destino").where("libro.moneda_id" => @proyecto.moneda_id, "transferencia_x_agente.agente_id" => @proyecto.agente).sum("importe_cambiado").to_f}.sum
end

node :aportacion_financiador_ejecutada do
  @pacs.collect{|pac| pac.gasto_total_con_tc(:financiador => pac.agente).to_f}.sum
end

node :presupuestado_total_pac do
  @pac.presupuesto_total_con_tc
end

node :ejecutado_total_pac do
  @pac.gasto_total_con_tc
end

node :presupuestado_financiador_pac do
  @pac.presupuesto_total_con_tc(:financiador => @pac.agente)
end

node :ejecutado_financiador_pac do
  @pac.gasto_total_con_tc(:financiador => @pac.agente)
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

