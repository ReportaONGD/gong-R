module Swagger::ProyectosSchema
  extend ActiveSupport::Concern
  include Swagger::Blocks


  included do
    #Models
    swagger_schema :Documento do
      property :id do
        key :type, :integer
        key :format, :int64
      end
      property :nombre do
        key :type, :string
      end
      property :descripcion do
        key :type, :string
      end
    end

    swagger_schema :Personal do
      property :nombre do
        key :type, :string
      end
      property :categoria do
        key :type, :string
      end
      property :residencia do
        key :type, :string
      end
      property :tipo_contrato do
        key :type, :string
      end
      property :horas_imputadas do
        key :type, :integer
        key :format, :int32
      end
      property :salario_mensual do
        key :type, :number
        key :format, :double
      end
      property :meses do
        key :type, :integer
        key :format, :int32
      end
      property :salario_total do
        key :type, :number
        key :format, :double
      end

      property :tipo do
        key :type, :number
        key :format, :double
      end
      property :moneda do
        key :type, :string
      end     

    end

    swagger_schema :Financiador do
      property :nombre do
        key :type, :string
      end
      property :total_presupuestado do
        key :type, :number
        key :format, :double
      end
      property :total_ejecutado do
        key :type, :number
        key :format, :double
      end     

    end

    swagger_schema :Recurso do
      property :nombre do
        key :type, :string
      end
      property :coste do
        key :type, :number
        key :format, :double
      end
    end

    swagger_schema :PeriodoJustificacion do
      property :id  do
        key :type, :integer
        key :format, :int64
      end
      property :fecha_inicio do
        key :type, :date
      end
      property :fecha_fin do
        key :type, :date
      end
      property :descripcion do
        key :type, :string
      end
      property :tipo_periodo do
        key :type, :string
      end

    end

    swagger_schema :Moneda do
      property :id  do
        key :type, :integer
        key :format, :int64
      end
      property :nombre do
        key :type, :string
      end
      property :abreviatura do
        key :type, :string
      end
    end

    swagger_schema :Pac do
      property :nombre do
        key :type, :string
      end
      property :titulo do
        key :type, :string
      end
      property :fecha_de_inicio do
        key :type, :date
      end
      property :fecha_de_fin do
        key :type, :date
      end
      property :identificador_financiador  do
        key :type, :integer
        key :format, :int64
      end
    end

    swagger_schema :Actividad do
      property :id do
        key :type, :integer
        key :format, :int64
      end
      property :codigo do
        key :type, :string
      end
      property :descripcion do
        key :type, :string
      end
      property :estado_periodos do
        key :type, :string
      end
      property :suma_presupuesto do
        key :type, :integer
        key :format, :int64
      end
      property :identificador_financiador  do
        key :type, :date
      end
      property :recursos do
        key :type, :array
        items do
          key :'$ref' , :Recurso
        end
      end
    end

    swagger_schema :Hipotesis do
      property :id do
        key :type, :integer
        key :format, :int64
      end
      property :descripcion do
        key :type, :string
      end
    end

    swagger_schema :FuenteVerificacion do
      property :id do
        key :type, :integer
        key :format, :int64
      end
      property :codigo do
        key :type, :string
      end
      property :descripcion do
        key :type, :string
      end
    end

    swagger_schema :Indicador do
      property :id do
        key :type, :integer
        key :format, :int64
      end      
      property :codigo do
        key :type, :string
      end
      property :descripcion do
        key :type, :string
      end
      property :variable do
        key :type, :array
      end
      property :fuente_verificacion do
        key :type, :array
        items do
          key :'$ref', :FuenteVerificacion
        end
      end      
    end

    swagger_schema :Objetivo do
      property :descripcion do
        key :type, :string
      end
      property :hipotesis do
        key :type, :array
        items do
          key :'$ref', :Hipotesis
        end
      end
      property :indicador do
        key :type, :array
        items do
          key :'$ref', :PeriodoJustificacion
        end
      end
    end

   swagger_schema :Resultado do
      property :id do
        key :type, :integer
        key :format, :int64
      end
      property :codigo do
        key :type, :string
      end    
      property :descripcion do
        key :type, :string
      end
      property :total_coste_recursos do
        key :type, :number
        key :format, :double
      end
      property :indicador do
        key :type, :array
        items do
          key :'$ref', :PeriodoJustificacion
        end
      end
      property :actividad do
        key :type, :array
        items do
          key :'$ref', :Actividad
        end
      end
    end

    swagger_schema :ObjetivoGeneral do
      allOf do
        schema do
          key :'$ref', :Objetivo
        end
      end
    end

    swagger_schema :ObjetivoEspecifico do
      allOf do
        schema do
          key :'$ref', :Objetivo
        end
        schema do
          property :resultado do
            key :type, :array
            items do
              key :'$ref', :Resultado
            end
          end
          property :actividad do
            key :type, :array
            items do
              key :'$ref', :Actividad
            end
          end         

        end
      end
    end

    swagger_schema :ProyectosDatosGenerales do
      property :codigo do
        key :type, :string
      end
      property :gestor do
        key :type, :string
      end
      property :ongd_agrupacion do
        key :type, :string
      end
      property :pais do
        key :type, :string
      end
      property :socio_local do
        key :type, :string
      end
      property :coste_total do
        key :type, :number
        key :format, :double
      end
      property :aportacion_financiador do
        key :type, :number
        key :format, :double
      end
      property :aportacion_ongd do
        key :type, :number
        key :format, :double
      end
  
      property :otras_aportaciones do
        key :type, :object
        property :nombre do
          key :type, :string
        end
        property :descripcion do
          key :type, :number
          key :format, :double
        end
      end
      property :fecha_de_inicio do
        key :type, :date
      end
      property :fecha_de_fin do
        key :type, :date
      end
      property :duracion do
        key :type, :integer
        key :format, :int32
      end
      property :subvencion_ejecutada do
        key :type, :number
        key :format, :double
      end
      property :moneda_base do
        key :type, :string
      end
      property :divisa do
        key :type, :string
      end
      property :monedas do
        key :type, :array
        items do
          key :'$ref', :Moneda
        end
      end
    end

    swagger_schema :Matriz do
      property :pac do
        key :'$ref', :Pac
      end

      property :objetivo_general do
        key :'$ref', :Objetivo
      end

      property :objetivo_especifico do
        key :type, :array
        items do
          key :'$ref', :ObjetivoEspecifico
        end
      end
    end

    swagger_schema :CronogramaSeguimiento do
      property :pac do
        key :'$ref', :Pac
      end
      
      property :duracion do
        key :type, :string
      end

      property :resultado do
        key :type, :object
       
        property :codigo do
          key :type, :string
        end
        property :descripcion do
          key :type, :string
        end
        property :actividad do
          key :type, :object
          property :codigo do
            key :type, :string
          end
          property :descripcion do
            key :type, :string
          end
          property :previsiones do
            key :type, :array
            items do
              key :type, :object
              property :mes do
                key :type, :integer
                key :format, :int32
              end
            end
          end
          property :seguimientos do
            key :type, :array
            items do
              key :type, :object
              property :mes do
                key :type, :integer
                key :format, :int32
              end
            end
          end
        end
      end
    end

    swagger_schema :BalancePresupuestario do
      property :presupuestado do
        key :type, :number
        key :format, :double
      end
      property :ejecutado do
        key :type, :number
        key :format, :double
      end     
    end

    swagger_schema :ResumenPresupuestarioPorPaises do
      property :pac do
        key :'$ref', :Pac
      end    
      property :financiadores do
        key :type, :array
        items do
          key :'$ref', :Financiador
        end
      end
    end

    swagger_schema :ResumenPresupuestarioOtrosFinanciadores do
      property :pac do
        key :'$ref', :Pac
      end    
      property :financiadores do
        key :type, :array
        items do
          key :'$ref', :Financiador
        end
      end
    end


    swagger_schema :GastoPartidasFinanciadores do
      property :pac do
        key :'$ref', :Pac
      end    
      property :ejecutado_pac do
        key :type, :number
        key :format, :double
      end
      property :acumulado_convenio do
        key :type, :number
        key :format, :double
      end  
    end

    swagger_schema :Transferencia do
      property :divisa do
        key :type, :string
      end
      property :moneda_local do
        key :type, :string
      end  
    end

    #El tipo de este modelo hay que verficarlo bien
    swagger_schema :Comprobante do
     
      property :emisor do
        key :type, :string
      end
      property :concepto do
        key :type, :string
      end

      property :fecha do
        key :type, :date
      end
      property :moneda do
        key :type, :string
      end
      property :pais do
        key :type, :string
      end
      property :partida do
        key :type, :string
      end
      property :orden_factura do
        key :type, :integer

      end
      property :importe do
        key :type, :number
        key :format, :double
      end
      property :tasa_cambio do
        key :type, :string
      end
      property :ejecutor do
        key :type, :string
      end

      property :financiado_aecid do
        key :type, :string
      end
      property :financiado_ongd do
        key :type, :string
      end
      property :financiado_otros do
        key :type, :string
      end

    end

    swagger_schema :DocumentosFuentesVerificacion do
      property :codigo do
        key :type, :string
      end
      property :descripcion do
        key :type, :string
      end
      property :fuentes do
        key :type, :array
        items do
          key :'$ref', :Documento
        end
      end

    end

    swagger_schema :BienesAdquiridos do
      property :pac do
        key :'$ref', :Pac
      end    
      property :proveedor do
        key :type, :string
      end
      property :descripcion do
        key :type, :string
      end
      property :fecha do
        key :type, :date
      end
      property :cantidad do
        key :type, :integer
        key :format, :int32
      end
      property :pais do
        key :type, :string
      end
      property :importe do
        key :type, :number
        key :format, :double
      end              
    end

    #Outputs

    swagger_schema :Proyectos do
      property :id do
        key :type, :integer
        key :format, :int64
      end
      property :nombre do
        key :type, :string
      end
      property :titulo do
        key :type, :string
      end
      property :identificador_financiador do
        key :type, :string
      end
      property :fecha_de_inicio do
        key :type, :string
      end
      property :fecha_de_fin do
        key :type, :string
      end
      property :es_convenio do
        key :type, :boolean
      end
      property :financiador_principal_id do
        key :type, :integer
        key :format, :int64
      end
      property :financiador_principal_nombre do
        key :type, :string
      end
      property :gestor_id do
        key :type, :integer
        key :format, :int64
      end
      property :gestor do
        key :type, :string
      end
      property :estado_del_proyecto do
        key :type, :string
      end

      property :seguimiento_periodos do
        key :type, :array
        items do
          key :'$ref', :PeriodoJustificacion
        end
      end
    end

  end
end
