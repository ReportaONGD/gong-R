object @proyecto => :tesoreria

child :libro => :cuentas do
  attributes :id, :nombre, :cuenta, :tipo, :entidad, :iban, :swift

  node :pais do |cuenta|
    cuenta.pais.nombre if cuenta.pais
  end

  node :gestor do |cuenta|
    cuenta.agente.nombre
  end

  node :moneda_abreviatura do |cuenta|
    cuenta.moneda.abreviatura if cuenta.moneda
  end

  node :moneda_nombre do |cuenta|
    cuenta.moneda.nombre if cuenta.moneda
  end

  node :subvencion do |cuenta|
    @proyecto.transferencia.joins(:transferencia_x_agente).where(:tipo => "subvencion",
         :libro_destino_id => cuenta.id, :fecha_recibido => @fecha_inicio..@fecha_fin,
         "transferencia_x_agente.agente_id" => @proyecto.agente.id ).sum("transferencia_x_agente.importe")
  end
  node :otras_aportaciones do |cuenta|
    @proyecto.transferencia.joins(:transferencia_x_agente).where(:tipo => "subvencion",
         :libro_destino_id => cuenta.id, :fecha_recibido => @fecha_inicio..@fecha_fin,
         "transferencia_x_agente.agente_id" => (@proyecto.financiador - [@proyecto.agente])).sum("transferencia_x_agente.importe")
  end
  node :remesas_enviadas do |cuenta|
    @proyecto.transferencia.where(:tipo => ["transferencia","cambio","retirada","ingreso","adelanto","devolucion"],
         :libro_origen_id => cuenta.id, :fecha_enviado => @fecha_inicio..@fecha_fin).sum(:importe_enviado)
  end
  node :remesas_recibidas do |cuenta|
    @proyecto.transferencia.where( :tipo => ["transferencia","cambio","retirada","ingreso","adelanto","devolucion"],
         :libro_destino_id => cuenta.id, :fecha_recibido => @fecha_inicio..@fecha_fin).sum(:importe_cambiado)
  end
  # Los intereses tambien los filtramos para solo el financiador principal
  node :intereses do |cuenta|
    @proyecto.transferencia.joins(:transferencia_x_agente).where(:tipo => "intereses",
         :libro_destino_id => cuenta.id, :fecha_recibido => @fecha_inicio..@fecha_fin,
         "transferencia_x_agente.agente_id" => @proyecto.agente.id ).sum("transferencia_x_agente.importe")
  end
  node :iva_recuperado do |cuenta|
    @proyecto.transferencia.where(:tipo => "iva",
         :libro_destino_id => cuenta.id, :fecha_recibido => @fecha_inicio..@fecha_fin).sum(:importe_cambiado)
  end
  node :pagos do |cuenta|
    Pago.joins(:gasto => :gasto_x_proyecto).where("gasto_x_proyecto.proyecto_id" => @proyecto.id, :libro_id => cuenta.id, :fecha => @fecha_inicio..@fecha_fin).sum(:importe)
  end
  node :reintegros do |cuenta|
    # El reintegro debe ser unico, pues solo aparece una linea
    @proyecto.transferencia.where(:tipo => "reintegro", :libro_origen_id => cuenta.id, :fecha_enviado => @fecha_inicio..@fecha_fin).sum(:importe_enviado)
  end
  node :tipo_cambio do |cuenta|
    tcg=TasaCambio.tasa_cambio_para_gasto(Gasto.new(:moneda_id => cuenta.moneda_id, :pais_id => cuenta.pais_id, :fecha => @fecha_fin), @proyecto)
    tcg ? tcg.tasa_cambio : (0.0).to_d
  end
  #cuenta.arqueo( [@proyecto], @fecha_inicio, @fecha_fin)[:totales]
end

