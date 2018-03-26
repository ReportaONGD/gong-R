module Webservice::Swagger::ApiDocs
  extend ActiveSupport::Concern
  include Swagger::Blocks

	swagger_root do
	  key :swagger, '2.0'
	  
	  info do
	    key :version, '2.4.7'
	    key :title, 'Gong-R'
	    key :description, 'Plataforma de documentación y prueba de los  ' \
	                      'servicios web de Gong'
	    #key :termsOfService, 'http://helloreverb.com/terms/'
	    contact do
	      key :name, 'Contacto'
	    end
	    license do
	      key :name, 'MIT'
	    end
	  end
	  
	  tag do
	    key :name, 'Convenios'
	    key :description, 'Convenios'
	  end

	  tag do
	    key :name, 'Proyectos'
	    key :description, 'Proyectos'
	  end

		tag do
			key :name, 'Documentos'
			key :description, 'Documentos'
		end

	  
	  key :host, 'localhost:3000'
	  key :basePath, '/'
	  key :consumes, ['application/json','application/xml']
	  key :produces, ['application/json','application/xml']

    security_definition :gong_auth do
			key :type, :oauth2
      key :authorizationUrl, 'http://localhost:3000/oauth/authorize'
      key :flow, :implicit
      scopes do
			end
    end

		extend Webservice::Swagger::Parameters
		
    security do
      key :gong_auth, []
    end
	end

	# A list of all classes that have swagger_* declarations.
	SWAGGERED_CLASSES = [
		Convenios,
		Proyectos,
		Documentos,
		Webservice::ConveniosController,
		Webservice::ProyectosController,
		Webservice::DocumentosController,
	  self,
	].freeze

  def root_json
    Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
