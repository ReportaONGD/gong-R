class CreaNuevosIndices1 < ActiveRecord::Migration
  def change 
    # Asignacion de orden de factura de proyecto
    #  g = Gasto.last
    #  condiciones = ["proyecto_origen_id = ? AND agente_id = ?", g.proyecto_origen_id, g.agente_id]
    #  Gasto.where(condiciones).maximum(:orden_factura_proyecto)
    #  Antes: (194.5ms)
    add_index :gasto, [:proyecto_origen_id, :agente_id], name: :index_orden_factura_proyecto
    #  Despues: (0.5ms)

    # Busqueda de tasa de cambio
    #  g = Gasto.where("proyecto_origen_id is not null").last
    #  TasaCambio.tasa_cambio_para_gasto(g, Proyecto.find(g.proyecto_origen_id))
    #  Antes 1: TasaCambio Load (9.1ms) - Busqueda de TC solo para el pais del gasto
    #  Antes 2: TasaCambio Load (10.5ms) - Busqueda de TC en general
    add_index :tasa_cambio, [:etapa_id, :moneda_id, :pais_id, :objeto], name: :index_tasa_cambio_pais_moneda
    #  Despues 1: TasaCambio Load (0.2ms) - Busqueda de TC solo para el pais del gasto
    #  Despues 2: TasaCambio Load (0.2ms) - Busqueda de TC en general

    # Busqueda de mapeos contables desde el elemento contable
    # CuentaContable.where(elemento_contable_id: 1707, elemento_contable_type: "Proyecto")
    # Antes: (4.4ms)
    add_index :cuenta_contable, [:elemento_contable_id, :elemento_contable_type], name: :idx_cuenta_contable_elemento
    # Despues: (0.2ms)

    # Busca un gasto por referencia la contable de su implementador
    # Gasto.where(agente_id: 27, ref_contable: "CG13000582/126").count
    # Antes: (204.3ms)
    add_index :gasto, [:agente_id, :ref_contable], name: :idx_gasto_ref_contable
    # Despues: (0.3ms)
  end
end
