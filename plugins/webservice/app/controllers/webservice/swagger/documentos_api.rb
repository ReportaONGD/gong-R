module Webservice::Swagger::DocumentosApi
	extend ActiveSupport::Concern
  include Swagger::Blocks
	
	included do
    swagger_path '/webservice/documentos/{proyecto_id}.{format}' do
      operation :get do 
        key :tags , ['Documentos']
        key :description, 'Documentos de proyecto'
        key :documentos, :documentos

        parameter :format
        parameter :proyecto_id

        response 200 do
          key :description, 'Todos los documentos'
          schema type: :array do
            items do
              key :'$ref', :DocumentoFichero
            end
          end
        end
      end
    end

    swagger_path '/webservice/documentos/{proyecto_id}/documento/{documento_id}' do
      operation :get do
        key :tags , ['Documentos']
        key :description, 'Documento de proyecto'
        key :documentos, :documentos

        parameter :format
        parameter :proyecto_id
        parameter :documento_id

        response 200 do
          key :description, 'Documento'
        end
      end
    end

  end
end
