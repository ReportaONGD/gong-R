CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=CURRENT_USER SQL SECURITY DEFINER VIEW v_presupuesto_detallado AS

SELECT
A.id as financiador_id,A.nombre as financiador_nombre,
AC.id as actividad_id,AC.codigo as actividad_codigo,AC.descripcion as actividad_nombre,
P.agente_id as implementador_id, AIMP.nombre as implementador_nombre,
PA.id as pais_id,PA.nombre as pais_nombre,
PY.id as proyecto_id, PY.nombre as proyecto_nombre, PY.convenio_accion as convenio_accion,
PT.id as partida_id,PT.nombre as partida_nombre, PT.codigo as partida_codigo,
SP.id as subpartida_id, SP.nombre as subpartida_nombre,
PTF.id as partida_proyecto_id,PTF.nombre as partida_proyecto_nombre,
P.id as presupuesto_id,
P.moneda_id as moneda_id,
P.concepto as presupuesto_concepto,
DE.aprobado as proyecto_aprobado,
DE.cerrado as proyecto_cerrado,
M.abreviatura as moneda_nombre,
PY.moneda_id as moneda_base_id,
MAUX.nombre as moneda_base_nombre,
IFNULL(TC.tasa_cambio,0) as tasa_cambio,
PD.fecha_inicio,
PD.fecha_fin,
PD.mes,
(PD.importe * ( ( IFNULL(PXA.importe, P.importe) *  IFNULL(PXAC.importe, P.importe) ) /P.importe ) )/P.importe as importe,
((PD.importe * ( ( IFNULL(PXA.importe, P.importe) *  IFNULL(PXAC.importe, P.importe) ) /P.importe ) )/P.importe) * tasa_cambio as importe_moneda_base

FROM presupuesto P

inner join presupuesto_detallado PD on P.id = PD.presupuesto_id
inner join moneda M on P.moneda_id = M.id
inner join agente AIMP on P.agente_id = AIMP.id
inner join partida PT on P.partida_id = PT.id
left join presupuesto_x_actividad PXAC on P.id = PXAC.presupuesto_id
left join actividad AC on PXAC.actividad_id = AC.id
left join presupuesto_x_agente PXA on PXA.presupuesto_id = P.id
left join agente A on PXA.agente_id = A.id
left join tasa_cambio TC on P.tasa_cambio_id = TC.id
inner join proyecto PY on P.proyecto_id = PY.id
inner join moneda MAUX on MAUX.id = PY.moneda_id
inner join estado E on (PY.id = E.proyecto_id and E.estado_actual = 1)
inner join definicion_estado DE on E.definicion_estado_id = DE.id
left join pais PA on PA.id = P.pais_id
left join subpartida SP on SP.id = P.subpartida_id
left join (partida_x_partida_financiacion PXPA, partida_financiacion PTF) ON (PT.id = PXPA.partida_id and PTF.id = PXPA.partida_financiacion_id and PTF.proyecto_id = PY.id)
