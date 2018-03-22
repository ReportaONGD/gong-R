CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=CURRENT_USER SQL SECURITY DEFINER VIEW v_presupuesto_agente AS

SELECT
P.agente_id as implementador_id, AIMP.nombre as implementador_nombre,
E.id as etapa_id,E.nombre as etapa_nombre,
P.id as presupuesto_id,
P.moneda_id as moneda_id,
P.proyecto_id as proyecto_id,
M.abreviatura as moneda_nombre,
AIMP.moneda_id as moneda_base_id,
MAUX.nombre as moneda_base_nombre,
SP.nombre as subpartida_nombre,
P.subpartida_id as subpartida_id,
IFNULL(TC.tasa_cambio,0) as tasa_cambio,
P.importe as importe,
P.importe * tasa_cambio as importe_moneda_base,
PT.id as partida_id

FROM presupuesto P
inner join moneda M on P.moneda_id = M.id
inner join agente AIMP on P.agente_id = AIMP.id
inner join etapa E on E.id = P.etapa_id
inner join partida PT on P.partida_id = PT.id
left join moneda MAUX on MAUX.id = AIMP.moneda_id
left join subpartida SP on SP.id = P.subpartida_id
left join tasa_cambio TC on P.tasa_cambio_id = TC.id
