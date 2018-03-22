-- MySQL dump 10.13  Distrib 5.1.30, for apple-darwin9.4.0 (i386)
--
-- Host: localhost    Database: gor_socio
-- ------------------------------------------------------
-- Server version	5.1.30
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping routines for database 'gor_socio'
--
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 FUNCTION `genera_modelo_182`(Ejercicio INT) RETURNS mediumtext CHARSET latin1
BEGIN

DECLARE tmp mediumtext;

set tmp=
(SELECT 
GROUP_CONCAT( 
-- NIF DEL DECLARADO
	IFNULL(LPAD(s.NIF,9,'0'),REPEAT(' ',9)),
-- NIF DEL REPRESENTANTE LEGAL DEL DECLARADO SI ES MENOR
 	IFNULL(LPAD(s.NIF_representante,9,'0'),REPEAT(' ',9)),
-- NOMBRE Y APELLIDOS DEL DECLARADO O RAZON SOCIAL SI ES UNA PERSONA JURIDICA
 	RPAD(
 		CONCAT(
 			IFNULL(s.apellido1,'')	,
 			REPEAT(' ',1), 
 			IFNULL(s.apellido2,'')	,
 			REPEAT(' ',1), 
 			IFNULL(s.nombre,'')
 			)
 		,40,' '),
-- PROVINCIA PARA DEDUCCION FISCAL
 	IFNULL(codigo_provincia_fiscal,''),
-- CLAVE
	'X',
-- PORCENTAJE DEDUCCION
	'XXXXX',
-- IMPORTE: PARTE ENTERA
 	IFNULL(								
 		LPAD(
 			(SELECT TRUNCATE(SUM(importe),0) FROM pago_socio p WHERE p.socio_id=s.id 
      AND especie=0 
      AND fecha_pago BETWEEN STR_TO_DATE(CONCAT('01,1,',Ejercicio),'%d,%m,%Y') AND STR_TO_DATE(CONCAT('31,12,',Ejercicio),'%d,%m,%Y') 
      ),
 			11,'0'),
 		REPEAT('0',11) ),
-- IMPORTE PARTE FRACCIONARIA
    IFNULL((SELECT RIGHT(CONVERT(FORMAT(SUM(importe),2),CHAR),2) FROM pago_socio p WHERE p.socio_id=s.id 
    AND especie=0 
    AND fecha_pago BETWEEN STR_TO_DATE(CONCAT('01,1,',Ejercicio),'%d,%m,%Y') AND STR_TO_DATE(CONCAT('31,12,',Ejercicio),'%d,%m,%Y')),'00'),
-- MARCA DE PAGO EN ESPECIE: BLANCO PUES ESTE FICHERO SOLO DECLARA PAGOS EN DINERO
 	REPEAT(' ',1), 							
-- COMUNIDAD AUTONOMA 
	'XX',
-- DEDUCCION COMUNIDAD AUTONOMA
	'XXXXX',
-- NATURALEZA DEL SOCIO (F persona fisica, J persona juridica, E entidad en regimen de atribucion de rentas) PENDIENTE DEL IF
 	IFNULL(('X'), ''),
-- REVOCACIÓN: BLANCO PUES ESTE FICHERO SOLO DECLARA PAGOS DINERARIOS
	REPEAT(' ',1), 							
-- EJERCICIO DE LA REVOCACIÓN: BLANCOS PUES ESTE FICHERO SOLO DECLARA PAGOS DINERARIOS
	REPEAT(' ',4), 
-- TIPO DEL BIEN REVOCADO: BLANCOS PUES ESTE FICHERO SOLO DECLARA PAGOS DINERARIOS
	REPEAT(' ',1),
-- IDENTIFICACION DEL BIEN REVOCADO: BLANCOS PUES ESTE FICHERO SOLO DECLARA PAGOS DINERARIOS
	REPEAT(' ',20),
-- FILLER
	REPEAT(' ',19)

	SEPARATOR '\n') AS XML_SOCIOS

FROM
socio s

WHERE
 			(SELECT SUM(importe) FROM pago_socio p WHERE p.socio_id=s.id 
      AND especie=0 
      AND fecha_pago BETWEEN STR_TO_DATE(CONCAT('01,1,',Ejercicio),'%d,%m,%Y') AND STR_TO_DATE(CONCAT('31,12,',Ejercicio),'%d,%m,%Y') )
      >0
);

 RETURN tmp;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 FUNCTION `xml_dame_pago_de_un_socio`(socio_id INT) RETURNS longtext CHARSET latin1
BEGIN

DECLARE tmp longtext;

  set tmp=
  (select group_concat(
    '<pago ',
      'concepto="',ifnull(concepto,''),'" ',
      'fecha_emision="',ifnull(fecha_emision,''),'" ',
      'fecha_pago="',ifnull(fecha_pago,''),'" ',
      'especie="',ifnull(especie,0),'" ',
      'importe="',ifnull(importe,0),'" ',
      ifnull(concat('comentario="',comentario,'" '),''), 
    '/>'
    SEPARATOR '')
  FROM pago_socio p 
  WHERE p.socio_id=socio_id
  );

 RETURN tmp;
 
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 FUNCTION `xml_socios`() RETURNS longtext CHARSET latin1
BEGIN

DECLARE tmp longtext;

  set tmp=
  (
  SELECT  
    group_concat(
  '<socio ',
-- ID
    'id="',s.id,'" ',
-- NIF DEL DECLARADO
    'nif="',IFNULL(s.NIF,REPEAT(' ',9)),'" ',
-- NIF DEL REPRESENTANTE LEGAL DEL DECLARADO SI ES MENOR
    'nif_representante="',IFNULL(s.NIF_representante,REPEAT(' ',9)),'" ',
-- NOMBRE Y APELLIDOS DEL DECLARADO O RAZON SOCIAL SI ES UNA PERSONA JURIDICA
    'nombre="',IFNULL(s.nombre,''),'" ',
    'apellido1="',IFNULL(s.apellido1,''),'" ',
    'apellido2="',IFNULL(s.apellido2,''),'" ',
-- TRATAMIENTO
    'tratamiento="',IFNULL(s.tratamiento,''),'" ',
-- SEXO
    'sexo="',IFNULL(s.sexo,''),'" ',
-- FECHA NACIMIENTO
    'fecha_nacimiento="',IFNULL(s.fecha_nacimiento,''),'" ',
-- DIRECCION
    'direccion="',IFNULL(s.direccion,''),'" ',
-- CODIGO POSTAL
    'codigo_postal="',IFNULL(s.codigo_postal,''),'" ',
-- LOCALIDAD
    'localidad="',IFNULL(s.localidad,''),'" ',
-- MUNICIPIO
    'municipio="',IFNULL(s.municipio,''),'" ',
-- PROVINCIA
    'provincia="',IFNULL(s.provincia,''),'" ',
-- PROVINCIA PARA DEDUCCION FISCAL
    'provincia_fiscal="',IFNULL(s.codigo_provincia_fiscal,''),'" ',
-- PAIS
    'pais="',IFNULL(s.pais,''),'" ',
-- EMAIL
    'email="',IFNULL(s.email,''),'" ',
-- TELEFGONO FIJO
    'telefono_fijo="',IFNULL(s.telefono_fijo,''),'" ',
-- TELEFONO MOVIL
    'telefono_movil="',IFNULL(s.telefono_movil,''),'" ',
-- COMENTARIOS
    'comentarios="',IFNULL(s.comentarios,''),'" ',
-- FECHA ALTA
    'fecha_alta="',IFNULL(i.fecha_alta,''),'" ',
-- FECHA BAJA
    'fecha_baja="',IFNULL(i.fecha_baja,''),'" ',
-- MOTIVO BAJA
    'motivo_baja="',IFNULL(i.motivo_baja,''),'" ',
-- TIPO CUOTA ID
    'tipo_cuota_socio_id="',IFNULL(i.tipo_cuota_socio_id,''),'" ',
-- TIPO CUOTA
    'tipo_cuota_socio="',IFNULL((SELECT t.tipo_cuota FROM tipo_cuota_socio t WHERE i.tipo_cuota_socio_id=t.id),''),'" ',
-- IMPORTE CUOTA
    'importe_cuota="',IFNULL(i.importe_cuota,''),'" ',
-- CALENDARIO PAGOS
    'calendario_pagos="',IFNULL(i.calendario_pagos,''),'" ',
-- ENVIAR PERIODICA
    'enviar_periodica="',IFNULL(i.enviar_periodica,''),'" ',
-- ENVIAR PUNTUAL
    'enviar_puntual="',IFNULL(i.enviar_puntual,''),'" ',
-- ENVIAR 182
    'enviar_182="',IFNULL(i.enviar_182,''),'" ',
-- CARTA BIENVENIDA
    'fecha_carta_bienvenida="',IFNULL(i.fecha_carta_bienvenida,''),'" ',
-- ENVIO DOCUMENTAICON
    'fecha_envio_documentacion="',IFNULL(i.fecha_envio_documentacion,''),'" ',
-- ENVIO CARNE
    'fecha_envio_carne="',IFNULL(i.fecha_envio_carne,''),'" ',
-- FORMA PAGO ID
    'forma_pago_socio_id="',IFNULL(i.forma_pago_socio_id,''),'" ',
-- FORMA PAGO
    'forma_pago_socio="',IFNULL((SELECT forma_pago FROM forma_pago_socio f WHERE  f.id=i.forma_pago_socio_id),''),'" ',
-- NATURALEZA SOCIO ID
    'naturaleza_socio_id="',IFNULL(s.naturaleza_socio_id,''),'" ',
-- NATURALEZA SOCIO
    'naturaleza_socio="',IFNULL((select n.naturaleza from naturaleza_socio n WHERE n.id=s.naturaleza_socio_id),''),'" ',
-- CERRAR EL SOCIO
    ' >',
-- PAGOS
  IFNULL(xml_dame_pago_de_un_socio(s.id),''),
  '</socio>'
	SEPARATOR ''
  ) AS xml_socios

FROM
socio s, informacion_socio i
WHERE s.id=i.socio_id


);

 RETURN concat 
  (
  '<socios fecha_creacion="',
  CURRENT_TIMESTAMP,
  '">',
  ifnull(tmp,''),
  '</socios>');

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-05-20 10:04:36
