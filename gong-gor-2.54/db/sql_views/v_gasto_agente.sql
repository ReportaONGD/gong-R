CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=CURRENT_USER SQL SECURITY DEFINER VIEW v_gasto_agente AS

SELECT
A.id as implementador_id, A.nombre as implementador_nombre,
PT.id as partida_id,PT.nombre as partida_nombre,
G.id as gasto_id,
G.moneda_id as moneda_id,
GXP.proyecto_id as proyecto_id,
P.nombre as proyecto_nombre,
E.nombre as empleado_nombre,
E.id as empleado_id,
M.abreviatura as moneda_nombre,
A.moneda_id as moneda_base_id,
MAUX.nombre as moneda_base_nombre,
IFNULL(TC.tasa_cambio,0) as tasa_cambio,
SP.id as subpartida_id,
SP.nombre as subpartida_nombre,
G.fecha,
GXP.importe as importe,
GXP.importe * tasa_cambio as importe_moneda_base,
GXP.importe * tasa_cambio / ESH.salario_hora as horas

FROM gasto G
inner join agente A on A.id = G.agente_id
inner join gasto_x_proyecto GXP on GXP.gasto_id = G.id
left join proyecto P on GXP.proyecto_id = P.id
inner join moneda M on G.moneda_id = M.id
inner join partida PT on G.partida_id = PT.id
inner join moneda MAUX on MAUX.id = A.moneda_id
left join tasa_cambio TC on TC.id = G.agente_tasa_cambio_id
left join subpartida SP on SP.id = G.subpartida_agente_id
left join empleado E on E.id = G.empleado_id
left join empleado_salario_hora ESH on (ESH.empleado_id = E.id AND ESH.fecha_inicio <= G.fecha AND ESH.fecha_fin >= G.fecha)
