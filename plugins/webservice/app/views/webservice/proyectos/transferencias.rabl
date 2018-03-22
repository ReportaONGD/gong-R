object @proyecto => :transferencias

node :divisa do
  @transferencias[:divisa]
end

node :moneda_local do
  @transferencias[:monedas]
end
