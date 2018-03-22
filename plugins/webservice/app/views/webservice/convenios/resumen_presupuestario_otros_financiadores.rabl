object @proyecto => params[:action]

node :pac do
  partial 'webservice/convenios/datos_pac', :object => @pac
end

child @otros_financiadores, :root => "financiadores" do
  node :nombre do |financiador|
    financiador.nombre 
  end
  node :total_presupuestado do |financiador|
    @pac.presupuesto_total_con_tc(:financiador => financiador).to_f
  end
  node :total_ejecutado do |financiador|
    @pac.gasto_total_con_tc(:financiador => financiador).to_f
  end
  #node :estado do |financiador|
  #  @pac.presupuesto_total_con_tc(:financiador => financiador).to_f <= @pac.gasto_total_con_tc(:financiador => financiador).to_f ? "ejecutado" : "en proceso"
  #end
end

