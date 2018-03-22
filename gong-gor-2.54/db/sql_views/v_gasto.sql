CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=CURRENT_USER SQL SECURITY DEFINER VIEW v_gasto AS

SELECT

A.id as financiador_id,A.nombre as financiador_nombre,
AI.id as implementador_id,AI.nombre as implementador_nombre,
PA.id as pais_id,PA.nombre as pais_nombre,
AC.id as actividad_id,AC.codigo as actividad_codigo,AC.descripcion as actividad_nombre,
PY.id as proyecto_id, PY.nombre as proyecto_nombre,
PT.id as partida_id,PT.nombre as partida_nombre,
SPT.id as subpartida_id,SPT.nombre as subpartida_nombre,
PTF.id as partida_proyecto_id,PTF.nombre as partida_proyecto_nombre,
G.id as gasto_id,
G.moneda_id as moneda_id,
M.abreviatura as moneda_nombre,
PY.moneda_id as moneda_base_id,
MAUX.nombre as moneda_base_nombre,
IFNULL(TC.tasa_cambio,0) as tasa_cambio,
G.fecha,
(IFNULL(GXAC.importe, GXP.importe) * IFNULL(GXA.importe, GXP.importe)/GXP.importe) as importe,
(IFNULL(GXAC.importe, GXP.importe) * IFNULL(GXA.importe, GXP.importe)/GXP.importe) * tasa_cambio  as importe_moneda_base

from gasto G
inner join gasto_x_proyecto GXP on G.id = GXP.gasto_id
inner join proyecto PY on GXP.proyecto_id = PY.id
left join gasto_x_agente GXA on G.id = GXA.gasto_id and GXA.proyecto_id = PY.id
left join gasto_x_actividad GXAC on GXA.gasto_id = GXAC.gasto_id and GXAC.proyecto_id = PY.id
left join agente A on GXA.agente_id = A.id
left join actividad AC on GXAC.actividad_id = AC.id
inner join agente AI on AI.id = G.agente_id
inner join moneda M on G.moneda_id = M.id
left join moneda MAUX on MAUX.id = PY.moneda_id
left join tasa_cambio TC on TC.id = GXP.tasa_cambio_id
inner join partida PT on G.partida_id = PT.id
left join pais PA on PA.id = G.pais_id
left join subpartida SPT on GXP.subpartida_id = SPT.id and SPT.proyecto_id = PY.id
left join (partida_x_partida_financiacion PXPA, partida_financiacion PTF) ON (PT.id = PXPA.partida_id and PTF.id = PXPA.partida_financiacion_id and PTF.proyecto_id = PY.id)
