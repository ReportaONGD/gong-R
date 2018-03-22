Webservice::Engine.routes.draw do
  get 'proyectos', :controller => 'proyectos', :action => 'index', :seccion => 'proyectos'
  get 'proyectos/:proyecto_id', :controller => 'proyectos', :action => 'datos_generales', :seccion => 'proyectos'
  get 'proyectos/:proyecto_id/:action(/:seguimiento_periodo_id)',    :controller => 'proyectos',  :seccion => 'proyectos'
  get 'convenios', :controller => 'convenios', :action => 'index', :seccion => 'proyectos'
  get 'convenios/:proyecto_id', :controller => 'convenios', :action => 'datos_generales', :seccion => 'proyectos'
  get 'convenios/:proyecto_id/:action(/:seguimiento_periodo_id)',    :controller => 'convenios',  :seccion => 'proyectos'

  get 'documentos/:proyecto_id', :controller => 'documentos', :action => "documentos"
  get 'documentos/:proyecto_id/documento/:documento_id', :controller => 'documentos', :action => "documento"

  get 'api-docs', to: 'api_docs#index'
end
