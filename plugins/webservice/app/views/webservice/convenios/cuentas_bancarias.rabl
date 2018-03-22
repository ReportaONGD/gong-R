object @proyecto => :cuentas_bancarias 

node :pac do
  partial 'webservice/convenios/datos_pac', :object => @pac
end

child :libro => :cuentas do
  attributes :nombre, :cuenta, :tipo, :entidad, :iban, :swift

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

  node :intereses_financiador do |cuenta|
    @pac.transferencia.joins(:transferencia_x_agente).where(:tipo => "intereses",
         :libro_destino_id => cuenta.id, "transferencia_x_agente.agente_id" => @pac.agente.id ).sum("transferencia_x_agente.importe").to_f
  end

  node :intereses_total do |cuenta|
    @pac.transferencia.where(:tipo => "intereses", :libro_destino_id => cuenta.id).sum("importe_recibido").to_f
  end
end
