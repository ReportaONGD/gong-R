module Webservice::Swagger::Parameters
  def self.extended(base)
    base.parameter :financiador_nombre do
      key :name, :financiador_nombre
      key :in, :query
      key :type, :string
      key :description, 'Nombre del Financiador'
    end

    base.parameter :format do
      key :name, :format
      key :in, :path
      key :description, 'Formato'
      key :required, true
      key :type, :string
      key :enum, ['json', 'xml']
    end

    base.parameter :proyecto_id do
      key :name, :proyecto_id
      key :type, :integer
      key :in, :path
      key :description, 'Id Proyecto'
    end

    base.parameter :seguimiento_periodo_id do
      key :name, :seguimiento_periodo_id
      key :type, :integer
      key :in, :query
      key :description, 'Seguimiento Periodo Id'
    end

    base.parameter :documento_id do
      key :name, :documento_id
      key :type, :integer
      key :in, :path
      key :description, 'Id Documento'
    end

  end
end
