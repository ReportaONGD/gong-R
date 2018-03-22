object @proyecto => params[:action]

node :pac do
  partial 'webservice/convenios/datos_pac', :object => @pac
end

node :periodo do
  @periodo
end

node :acumulado do
  @acumulado
end if @acumulado

node :total do
  @total
end if @total
