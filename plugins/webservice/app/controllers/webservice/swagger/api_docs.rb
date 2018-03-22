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
	    # externalDocs do
	    #   key :description, 'Find more info here'
	    #   key :url, 'https://swagger.io'
	    # end
	  end

	  tag do
	    key :name, 'Proyectos'
	    key :description, 'Proyectos'
	    # externalDocs do
	    #   key :description, 'Find more info here'
	    #   key :url, 'https://swagger.io'
	    # end
	  end

		tag do
			key :name, 'Documentos'
			key :description, 'Documentos'
			# externalDocs do
			#   key :description, 'Find more info here'
			#   key :url, 'https://swagger.io'
			# end
		end

	  
	  key :host, 'localhost:3000'
	  key :basePath, '/'
	  key :consumes, ['application/json','application/xml']
	  key :produces, ['application/json','application/xml']

    security_definition :gong_auth do
			key :type, :oauth2
      key :authorizationUrl, 'http://localhost:3000/oauth/authorize'
      # key :tokenUrl, 'http://localhost:3000/oauth/token'
      # key :oauth2RedirectUrl, "http://localhost:3000sss/api/oauth2-redirect.html"
      # key :redirectUrl, "http://localhost:3000sss/api/oauth2-redirect.html"
      key :flow, :implicit
      scopes do
			end
    end

		security_definition :gong_auth1 do
			key :type, :oauth2
			key :authorizationUrl, 'http://localhost:3000/oauth/authorize'
			# key :tokenUrl, 'http://localhost:3000/oauth/token'
			# key :oauth2RedirectUrl, "http://localhost:3000sss/api/oauth2-redirect.html"
			# key :redirectUrl, "http://localhost:3000sss/api/oauth2-redirect.html"
			key :flow, :accessCode
			scopes do
			end
		end

		security_definition :gong_auth2 do
			key :type, :oauth2
			key :authorizationUrl, 'http://localhost:3000/oauth/authorize'
			# key :tokenUrl, 'http://localhost:3000/oauth/token'
			# key :oauth2RedirectUrl, "http://localhost:3000sss/api/oauth2-redirect.html"
			# key :redirectUrl, "http://localhost:3000sss/api/oauth2-redirect.html"
			key :flow, :password
			scopes do
			end
		end

		security_definition :gong_auth3 do
			key :type, :oauth2
			key :authorizationUrl, 'http://localhost:3000/oauth/authorize'
			# key :tokenUrl, 'http://localhost:3000/oauth/token'
			# key :oauth2RedirectUrl, "http://localhost:3000sss/api/oauth2-redirect.html"
			# key :redirectUrl, "http://localhost:3000sss/api/oauth2-redirect.html"
			key :flow, :application
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
