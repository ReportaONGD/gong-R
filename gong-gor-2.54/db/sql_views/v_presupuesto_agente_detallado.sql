CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=CURRENT_USER SQL SECURITY DEFINER VIEW v_presupuesto_agente_detallado AS

SELECT
P.agente_id as implementador_id, AIMP.nombre as implementador_nombre,
PT.id as partida_id,PT.nombre as partida_nombre, PT.codigo as partida_codigo,
P.id as presupuesto_id,
P.moneda_id as moneda_id,
P.concepto as presupuesto_concepto,
P.proyecto_id as proyecto_id,
M.abreviatura as moneda_nombre,
SP.nombre as subpartida_nombre,
P.subpartida_id as subpartida_id,
P.empleado_id as empleado_id,
E.nombre as empleado_nombre,
PXP.proyecto_id as proyecto_imputado_id,
PXP.importe as importe_imputado,
PXP.importe * tasa_cambio as importe_imputado_moneda_base,
IFNULL(TC.tasa_cambio,0) as tasa_cambio,
PD.fecha_inicio,
PD.fecha_fin,
PD.mes,
PD.importe as importe,
PD.importe * tasa_cambio as importe_moneda_base

from 
presupuesto P
inner join presupuesto_detallado PD on P.id = PD.presupuesto_id
inner join moneda M on P.moneda_id = M.id
inner join agente AIMP on P.agente_id = AIMP.id
inner join partida PT on P.partida_id = PT.id
left join subpartida SP on SP.id = P.subpartida_id
left join tasa_cambio TC on P.tasa_cambio_id = TC.id
left join empleado E on P.empleado_id = E.id
left join presupuesto_x_proyecto PXP on PXP.presupuesto_id = P.id
