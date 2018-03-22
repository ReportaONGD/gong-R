object @elemento => params[:action].to_sym 

node :pac do
  partial 'webservice/convenios/datos_pac', :object => @pac
end if @pac

child :objetivo_general do
  attributes :descripcion
  node :hipotesis do
    []
  end
  node :indicador do
    []
  end
end

child :objetivo_especifico do
  attributes :id, :codigo, :descripcion

  child :comentario => :comentarios do
    attributes :texto, :created_at
  end unless @solo_formulacion
  child :hipotesis do
    attributes :descripcion
  end
  child :indicador do
    extends 'webservice/proyectos/indicador'
  end
  child :resultado do
    attributes :id, :codigo, :descripcion
    child :comentario => :comentarios do
      attributes :texto, :created_at
    end unless @solo_formulacion
    child :hipotesis do
      attributes :descripcion
    end
    child :indicador do
      extends 'webservice/proyectos/indicador'
    end
    child :actividad do
      extends 'webservice/proyectos/actividad'
    end
    attributes :suma_presupuesto => :total_coste_recursos
  end
end

child @elemento.actividad.all(:conditions => {"resultado_id" => nil}), :root => "actividad" do
  extends 'webservice/proyectos/actividad'
end

