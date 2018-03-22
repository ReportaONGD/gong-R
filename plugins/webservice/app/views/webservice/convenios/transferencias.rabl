object @proyecto => params[:action]

node :pac do
  partial 'webservice/convenios/datos_pac', :object => @pac
end

node :pais do
  @paises
end if @paises

node :periodos do
  @periodos
end if @periodos
