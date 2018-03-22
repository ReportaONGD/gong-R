module Swagger::DocumentosSchema
  extend ActiveSupport::Concern
  include Swagger::Blocks


  included do
    #Models
    swagger_schema :DocumentoFichero do
      property :id do
        key :type, :integer
        key :format, :int64
      end
      property :adjunto_file_name do
        key :type, :string
      end
      property :adjunto_content_type do
        key :type, :string
      end
      property :descripcion do
        key :type, :string
      end
      property :tipo do
        key :type, :string
      end
    end
  end
end
