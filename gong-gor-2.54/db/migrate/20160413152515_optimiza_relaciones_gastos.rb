class OptimizaRelacionesGastos < ActiveRecord::Migration
  def change
    # Primero, generamos indices para elementos comunes, pero que afectan al propio gasto
    add_index :usuario_x_proyecto, [:usuario_id, :proyecto_id]
    add_index :partida_financiacion, [:proyecto_id]
    add_index :partida_x_partida_financiacion, [:partida_id, :partida_financiacion_id], name: :index_partidas_x_financiacion
    add_index :proyecto_x_proyecto, [:proyecto_id, :proyecto_cofinanciador_id], name: :index_pxp_proyecto_cofinanciador
    add_index :estado, [:proyecto_id, :estado_actual], name: :index_estado_definicion_estado_proyecto
    # Especialmente, los comentarios de creaciones y modificaciones
    add_index :comentario, [:elemento_type, :elemento_id]
    # generamos indices para los elementos relacionados con el gasto
    add_index :gasto_x_proyecto, [:gasto_id, :proyecto_id]
    add_index :gasto_x_agente, [:gasto_id, :proyecto_id, :agente_id], name: :index_gxagt_gasto_proyecto_agente
    add_index :gasto_x_actividad, [:proyecto_id, :gasto_id, :actividad_id], name: :index_gxact_proyecto_gasto_actividad
    # y para los propios pagos
    add_index :pago, [:gasto_id]
  end
end
