module Webservice::Swagger::ProyectosApi
	extend ActiveSupport::Concern
  include Swagger::Blocks
	
	included do
		
		#index
    swagger_path '/webservice/proyectos.{format}' do
      operation :get do 
        key :tags , ['Proyectos']
        key :description, 'proyectos existentes en estado de "informe"'
        key :proyectos, :proyectos

        parameter :format

        response 200 do
          key :description, 'Todos los proyectos'
          schema type: :array do
            items do
              key :'$ref', :Proyectos
            end
          end
        end
      end
    end

    #Datos Generales
    swagger_path '/webservice/proyectos/{proyecto_id}.{format}' do
      operation :get do 
        key :tags , ['Proyectos']
        key :description, 'Datos generales del convenio'

        parameter :format

        parameter :proyecto_id

        response 200 do
          key :description, 'Datos Generales'
          schema type: :array do
            items do
              key :'$ref', :ProyectosDatosGenerales
            end
          end
        end
      end
    end

    swagger_path '/webservice/proyectos/{proyecto_id}/matriz_seguimiento.{format}' do
      operation :get do 
        key :tags , ['Proyectos']
        key :description, 'Matriz de Seguimiento'
        key :proyectos, :proyectos
        
        parameter :format

        parameter :proyecto_id

        response 200 do
          key :description, 'All users'
          schema type: :array do
            items do
              key :'$ref', :Matriz
            end
          end
        end
      end
    end     

    swagger_path '/webservice/proyectos/{proyecto_id}/cronograma_seguimiento.{format}' do
      operation :get do 
        key :tags , ['Proyectos']
        key :description, 'Cronograma de seguimiento del PAC'
        key :proyectos, :proyectos
        
        parameter :format

        parameter :proyecto_id

        response 200 do
          key :description, 'Cronograma de seguimiento del PAC'
          schema type: :array do
            items do
              key :'$ref', :CronogramaSeguimiento
            end
          end
        end
      end
    end 
		
		swagger_path '/webservice/proyectos/{proyecto_id}/documentos_fuentes_verificacion.{format}' do
      operation :get do 
        key :tags , ['Proyectos']
        key :description, 'Listado de documentos de fuentes de verificación'
        key :proyectos, :proyectos
        
        parameter :format

        parameter :proyecto_id

        response 200 do
          key :description, 'All users'
          schema type: :array do
            items do
              key :'$ref', :DocumentosFuentesVerificacion
            end
          end
        end
      end
    end 


 		swagger_path '/webservice/proyectos/{proyecto_id}/resumen_financiero.{format}' do
      operation :get do 
        key :tags , ['Proyectos']
        key :description, 'Resumen Financiero'
        key :proyectos, :proyectos
        
        parameter :format

        parameter :proyecto_id

        response 200 do
          key :description, 'Resumen Financiero'
          schema type: :array do
            items do
              key :'$ref', :BalancePresupuestario
            end
          end
        end
      end
    end 

 		swagger_path '/webservice/proyectos/{proyecto_id}/balance_presupuestario_partidas.{format}' do
      operation :get do 
        key :tags , ['Proyectos']
        key :description, 'Seguimiento del presupuesto ejecutado por partidas'
        key :proyectos, :proyectos
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


        response 200 do
          key :description, 'All users'
          schema type: :array do
            items do
              key :'$ref', :BalancePresupuestario
            end
          end
        end
      end
    end 


   swagger_path '/webservice/proyectos/{proyecto_id}/tesoreria.{format}' do
      operation :get do 
        key :tags , ['Proyectos']
        key :description, 'Fetches all User items'
        key :proyectos, :proyectos
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


        response 200 do
          key :description, 'All users'
          schema type: :array do
            items do
              key :'$ref', :BalancePresupuestario
            end
          end
        end
      end
    end 

    swagger_path '/webservice/proyectos/{proyecto_id}/personal.{format}' do
      operation :get do 
        key :tags , ['Proyectos']
        key :description, 'Relacion de Personal'
        key :proyectos, :proyectos
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


        response 200 do
          key :description, 'All users'
          schema type: :array do
            items do
              key :'$ref', :Personal
            end
          end
        end
      end
    end 

    swagger_path '/webservice/proyectos/{proyecto_id}/transferencias_convenio.{format}' do
      operation :get do 
        key :tags , ['Proyectos']
        key :description, 'Transferencias desde la cuenta principal del convenio'
        key :proyectos, :proyectos
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


        response 200 do
          key :description, 'All users'
          schema type: :array do
            items do
              key :'$ref', :Transferencia
            end
          end
        end
      end
    end 

		swagger_path '/webservice/proyectos/{proyecto_id}/bienes_adquiridos.{format}' do
      operation :get do 
        key :tags , ['Proyectos']
        key :description, 'Bienes Adquiridos'
        key :proyectos, :proyectos
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


        response 200 do
          key :description, 'All users'
          schema type: :array do
            items do
              key :'$ref', :BienesAdquiridos
            end
          end
        end
      end
    end    

    swagger_path '/webservice/proyectos/{proyecto_id}/comprobantes.{format}' do
      operation :get do 
        key :tags , ['Proyectos']
        key :description, 'Listado de comprobantes'
        key :proyectos, :proyectos
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


        response 200 do
          key :description, 'All users'
          schema type: :array do
            items do
              key :'$ref', :Comprobante
            end
          end
        end
      end
    end         

  end
end