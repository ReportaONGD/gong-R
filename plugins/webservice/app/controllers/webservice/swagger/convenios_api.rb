module Webservice::Swagger::ConveniosApi
	extend ActiveSupport::Concern
  include Swagger::Blocks
	
	included do
    swagger_path '/webservice/convenios.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Convenios existentes en estado de "informe"'
        key :convenios, :convenios

        parameter :format

        parameter :financiador_nombre

        response 200 do
          key :description, 'Todos los convenios'
          schema type: :array do
            items do
              key :'$ref', :Convenios
            end
          end
        end
      end
    end

    swagger_path '/webservice/convenios/{proyecto_id}.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Datos generales del convenio'

        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id

        response 200 do
          key :description, 'Datos Generales'
          schema type: :array do
            items do
              key :'$ref', :ConveniosDatosGenerales
            end
          end
        end
      end
    end

    swagger_path '/webservice/convenios/{proyecto_id}/matriz_formulacion_pac.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Matriz planificada del PAC'
        key :convenios, :convenios
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


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

    swagger_path '/webservice/convenios/{proyecto_id}/matriz_seguimiento_pac.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Matriz ejecutada del PAC'
        key :convenios, :convenios
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


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

    swagger_path '/webservice/convenios/{proyecto_id}/matriz_seguimiento_acumulada.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Matriz acumulada del Convenio'
        key :convenios, :convenios
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


        response 200 do
          key :description, 'Matriz acumulada del Convenio'
          schema type: :object do
            items do
              key :'$ref', :Matriz
            end
          end
        end
      end
    end 

    swagger_path '/webservice/convenios/{proyecto_id}/cronograma_seguimiento.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Cronograma de seguimiento del PAC'
        key :convenios, :convenios
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


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

    swagger_path '/webservice/convenios/{proyecto_id}/resumen_presupuestario_acciones.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Resumen presupuestario del PAC por Acciones'
        key :convenios, :convenios
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


        response 200 do
          key :description, 'Resumen presupuestario del PAC por Acciones'
          schema type: :array do
            items do
              key :'$ref', :BalancePresupuestario
            end
          end
        end
      end
    end 

    swagger_path '/webservice/convenios/{proyecto_id}/resumen_presupuestario_paises.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Resumen presupuestario del PAC por Países'
        key :convenios, :convenios
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


        response 200 do
          key :description, 'All users'
          schema type: :array do
            items do
              key :'$ref', :ResumenPresupuestarioPorPaises
            end
          end
        end
      end
    end 

    swagger_path '/webservice/convenios/{proyecto_id}/resumen_presupuestario_otros_financiadores.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Resumen presupuestario del PAC por Países'
        key :convenios, :convenios

        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


        response 200 do
          key :description, 'All users'
          schema type: :array do
            items do
              key :'$ref', :ResumenPresupuestarioOtrosFinanciadores
            end
          end
        end
      end
    end     

    swagger_path '/webservice/convenios/{proyecto_id}/gasto_pac_partidas_y_financiadores.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Gasto en el PAC por partidas y financiadores'
        key :convenios, :convenios
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


        response 200 do
          key :description, 'All users'
          schema type: :array do
            items do
              key :'$ref', :GastoPartidasFinanciadores
            end
          end
        end
      end
    end 

    swagger_path '/webservice/convenios/{proyecto_id}/gasto_acumulado_partidas_y_financiadores.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Gasto acumulado en el Convenio por partidas y financiadores'
        key :convenios, :convenios
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


        response 200 do
          key :description, 'All users'
          schema type: :array do
            items do
              key :'$ref', :GastoPartidasFinanciadores
            end
          end
        end
      end
    end 

    swagger_path '/webservice/convenios/{proyecto_id}/balance_presupuestario_partidas.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Seguimiento del presupuesto ejecutado por partidas'
        key :convenios, :convenios
        
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

    swagger_path '/webservice/convenios/{proyecto_id}/balance_presupuestario_acciones.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Seguimiento del presupuesto ejecutado por acciones'
        key :convenios, :convenios
        
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

    swagger_path '/webservice/convenios/{proyecto_id}/cuentas_bancarias.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Cuentas Bancarias'
        key :convenios, :convenios
        
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
   
    swagger_path '/webservice/convenios/{proyecto_id}/tesoreria.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Fetches all User items'
        key :convenios, :convenios
        
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

    swagger_path '/webservice/convenios/{proyecto_id}/personal.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Relacion de Personal'
        key :convenios, :convenios
        
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

    swagger_path '/webservice/convenios/{proyecto_id}/transferencias_convenio.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Transferencias desde la cuenta principal del convenio'
        key :convenios, :convenios
        
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

    swagger_path '/webservice/convenios/{proyecto_id}/transferencias_paises.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Resto de transferencias y operaciones de cambio'
        key :convenios, :convenios
        
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

    swagger_path '/webservice/convenios/{proyecto_id}/comprobantes.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Listado de comprobantes'
        key :convenios, :convenios
        
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



    swagger_path '/webservice/convenios/{proyecto_id}/documentos_fuentes_verificacion.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Listado de documentos de fuentes de verificación'
        key :convenios, :convenios
        
        parameter :format

        parameter :proyecto_id

        parameter :seguimiento_periodo_id


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

    swagger_path '/webservice/convenios/{proyecto_id}/bienes_adquiridos.{format}' do
      operation :get do 
        key :tags , ['Convenios']
        key :description, 'Bienes Adquiridos'
        key :convenios, :convenios
        
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
  end
end
