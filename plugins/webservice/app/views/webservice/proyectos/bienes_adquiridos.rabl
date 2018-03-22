collection @gastos, :root => "bienes"

  node :pac do
    partial 'webservice/convenios/datos_pac', :object => @pac
  end if @pac


  attributes :emisor_factura => :proveedor
  attributes :concepto => :descripcion

  node :fecha do |bien|
    bien.fecha_informe ? bien.fecha_informe : bien.fecha
  end

  #node :importe_gasto do |bien|
  #  bien.gasto_x_proyecto.first(:conditions => {:proyecto_id => @proyecto.id}).importe
  #end
  #node :tasa_cambio do |bien|
  #  bien.gasto_x_proyecto.first(:conditions => {:proyecto_id => @proyecto.id}).tasa_cambio
  #end
  #node :moneda_gasto do |bien|
  #  bien.moneda.abreviatura if bien.moneda
  #end

  node :cantidad do
    1
  end

  node :pais do |bien|
    bien.pais.nombre if bien.pais
  end

  node :importe do |bien|
    bien.gasto_x_proyecto.first(:conditions => {:proyecto_id => @elemento.id}).importe * bien.gasto_x_proyecto.first(:conditions => {:proyecto_id => @elemento.id}).tasa_cambio
  end

