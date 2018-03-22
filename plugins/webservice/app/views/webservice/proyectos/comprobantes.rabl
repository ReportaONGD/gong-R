collection @gastos, :root => "comprobantes"

  attributes :emisor_factura => :emisor
  attributes :concepto

  node :fecha do |comprobante|
    comprobante.fecha_informe ? comprobante.fecha_informe : comprobante.fecha
  end

  node :moneda do |comprobante|
    comprobante.moneda.abreviatura if comprobante.moneda
  end

  node :pais do |comprobante|
    comprobante.pais.nombre if comprobante.pais
  end

  node :partida do |comprobante|
    comprobante.partida_proyecto_codigo_nombre(@elemento)
  end

  node :orden_factura do |comprobante|
    comprobante.gasto_x_proyecto.first(:conditions => {:proyecto_id => @elemento.id}).orden_factura
  end

  node :importe do |comprobante|
    comprobante.gasto_x_proyecto.first(:conditions => {:proyecto_id => @elemento.id}).importe
  end

  node :tasa_cambio do |comprobante|
    comprobante.gasto_x_proyecto.first(:conditions => {:proyecto_id => @elemento.id}).tasa_cambio
  end

  node :ejecutor do |comprobante|
    comprobante.agente.nombre if comprobante.agente
  end

  node :financiado_aecid do |comprobante|
    comprobante.gasto_x_agente.where(:agente_id => @elemento.agente).sum("gasto_x_agente.importe")
  end

  node :financiado_ongd do |comprobante|
    comprobante.gasto_x_agente.where(:agente_id => @elemento.ongd_agrupacion).sum("gasto_x_agente.importe")
  end

  node :financiado_otros do |comprobante|
    comprobante.gasto_x_agente.where(:agente_id => (@elemento.financiador - @elemento.ongd_agrupacion - [@elemento.agente])).sum("gasto_x_agente.importe")
  end

