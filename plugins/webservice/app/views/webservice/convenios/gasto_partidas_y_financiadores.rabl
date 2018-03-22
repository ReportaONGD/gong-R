object @proyecto => :total_ejecutado

node :pac do
  partial 'webservice/convenios/datos_pac', :object => @pac
end

node ( params[:action] == "gasto_pac_partidas_y_financiadores" ? :ejecutado_pac : :acumulado_convenio ) do
  @ejecutado
end
