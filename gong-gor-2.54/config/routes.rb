Gor::Application.routes.draw do

  # Integrar esto con la autorizacion de gong
  use_doorkeeper do
    controllers :applications => 'oauth/applications'
  end
  namespace :api do
    get '/me' => "credentials#me"
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"


  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

  #map.root :seccion => "entrada", :controller => "usuario", :action => "entrada"
  root :to => 'usuario#entrada', :seccion => "entrada"

  # Helpers de rutas
  get 'entrada/', :seccion => 'entrada', :controller => 'usuario', :action => 'entrada', :as => 'entrada'
  match 'identifica/', :seccion => 'entrada', :controller => 'usuario', :action => 'identificacion', :as => 'identifica'
  get 'datos_personales/', :seccion => 'inicio', :controller => 'usuario', :action => 'datos_personales', :as => 'datos_personales'

  get 'programas_marco/', seccion: 'programas_marco', controller: 'programa_marco', action: 'listado_usuario', as: 'programas_marco'
  get 'programa_marco/:proyecto_id/', :seccion => 'programas_marco', :menu => 'resumen', :controller => 'info', :action => 'index', :as => 'programa_marco'
  get 'proyectos/', :seccion => 'proyectos', :controller => 'proyecto', :action => 'listado_usuario', :as => 'proyectos'
  get 'proyecto/:proyecto_id/', :seccion => 'proyectos', :menu => 'resumen', :controller => 'info', :action => 'index', :as => 'proyecto'
  get 'proyecto/:proyecto_id/gastos/', :seccion => 'proyectos', :menu => 'ejecucion_economica', :controller => 'gasto_proyectos', :action => 'index', :as => 'gastos_proyecto'
  get 'proyecto/:proyecto_id/gasto/:gasto_id/nota/:id', :seccion => 'proyectos', :menu => 'ejecucion_economica', :controller => 'gasto_proyectos', :action => 'nota_gasto', :as => 'nota_gasto_proyecto'
  get 'proyecto/:proyecto_id/ficha_resumen/', :seccion => 'proyectos', :menu => 'resumen',:controller => 'info', :action => 'ficha_resumen', :as => 'ficha_resumen'
  get 'agentes/', :seccion => 'agentes', :controller => 'agente', :action => 'listado_usuario', :as => 'agentes'
  get 'agente/:agente_id/', :seccion => 'agentes', :menu => 'resumen_agente', :controller => 'info', :action => 'index', :as => 'agente'
  get 'agente/:agente_id/gastos/', :seccion => 'agentes', :menu => 'gasto_agente', :controller => 'gasto_agentes', :action => 'index', :as => 'gastos_agente'
  get 'agente/:agente_id/gasto/:gasto_id/nota/:id', :seccion => 'agentes', :menu => 'gasto_agente', :controller => 'gasto_agentes', :action => 'nota_gasto', :as => 'nota_gasto_agente'
  get 'agente/:agente_id/contrato/:id/documento/:docu_id', seccion: 'agentes', menu: 'documentos_agente',
         controller: 'contrato', action: 'crear_documento_contrato', as: 'documento_contrato'
  get 'agente/:agente_id/contrato/:id/periodo/:periodo_id/nota/:docu_id', seccion: 'agentes', menu: 'documentos_agente',
         controller: 'contrato', action: 'crear_nota_pago_periodo', as: 'nota_pago_periodo'
  get 'documentos/', :seccion => 'documentos', :menu => 'documentos_generales', :controller => 'documento', :action => 'index'

  # Esto solo queda por compatibilidad. En el futuro hay que eliminarlo
  get 'administracion/autodestruccion/', :seccion => 'administracion', :controller => 'autodestruccion', :action => 'index'

  # Resto de mapeos
  #map.connect 'proyectos/:proyecto_id/:menu/:controller/:action/:id', :seccion => 'proyectos'
  match 'proyectos/:proyecto_id/:menu/:controller(/:action(/:id))', :seccion => 'proyectos' 
  #map.connect 'agentes/:agente_id/:menu/:controller/:action/:id', :seccion => 'agentes'
  match 'agentes/:agente_id/:menu/:controller(/:action(/:id))', :seccion => 'agentes'
  #map.connect 'administracion/:menu/:controller/:action/:id', :seccion => 'administracion'
  match 'administracion/:menu/:controller(/:action(/:id))', :seccion => 'administracion'
  #map.connect 'documentos/:menu/:controller/:action/:id', :seccion => 'documentos'
  match 'documentos/:menu/:controller(/:action(/:id))', :seccion => 'documentos'
  #map.connect 'socios/:menu/:controller/:action/:id', :seccion => 'socios'
  match 'socios/:menu/:controller(/:action(/:id))', :seccion => 'socios'
  #map.connect 'cuadrodemando/:menu/:variable1', :variable1 => nil, :seccion => 'cuadromando', :controller => 'cuadrodemando', :action => 'index'
  match 'cuadrodemando/:menu(/:variable1)' => 'cuadrodemando#index', :seccion => 'cuadromando'
  match 'mondrian/:variable1' => 'cuadrodemando#index', :seccion => 'cuadromando', :controller => 'cuadrodemando', :menu => 'economico'
  #map.connect ':seccion/:controller/:action/:id'
  match ':seccion/:controller(/:action(/:id))'
 
  # Esta ruta es para la subida de archivos desde el tinymce 
  post '/tinymce_assets' => 'documento#modificar_crear_imagen_datos_proyecto', :seccion => 'proyectos'

  # Por ultimo, las rutas de los plugins existentes
  Plugin.rutas_activas.each do |ruta|
    #logger.info "(GOR PLUGIN) Activando plugin '#{ruta.clase}'"
    puts "(GOR PLUGIN) Activando rutas del plugin '#{ruta.clase}'" if ENV['RAILS_ENV'] == 'development'
    mount eval("#{ruta.clase}::Engine"), at: "/#{ruta.codigo}"
  end
end
