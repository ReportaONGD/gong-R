object @elemento => params[:action].to_sym

node :pac do
  partial 'webservice/convenios/datos_pac', :object => @pac
end if @pac

attributes :duracion_meses => :duracion

child :resultado do
  attributes :codigo, :descripcion
  child :actividad do
    attributes :codigo, :nombre
    child :actividad_detallada_prevision => :previsiones  do
      attributes :mes_proyecto => :mes
    end
    child :actividad_detallada_seguimiento => :seguimientos do
      attributes :mes_proyecto => :mes
    end
  end
end

child @elemento.actividad.all(:conditions => {"resultado_id" => nil}), :root => "actividad" do
  attributes :codigo, :nombre
  child :actividad_detallada_prevision => :previsiones  do
    attributes :mes_proyecto => :mes
  end
  child :actividad_detallada_seguimiento => :seguimientos do
    attributes :mes_proyecto => :mes
  end
end
