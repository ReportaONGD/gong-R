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
/*!50003 CREATE*/ /*!50020 DEFINER=`gestor`@`localhost`*/ /*!50003 FUNCTION `genera_modelo182`(Ejercicio INT) RETURNS varchar(8192) CHARSET latin1
BEGIN

DECLARE Tmp VARCHAR(8192);

set Tmp=
(SELECT 
CONCAT( 
-- NIF DEL DECLARADO
	IFNULL(s.NIF,REPEAT(' ',9)),
-- NIF DEL REPRESENTANTE LEGAL DEL DECLARADO SI ES MENOR
 	IFNULL(s.NIF_representante,REPEAT(' ',9)),
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
 			(SELECT TRUNCATE(SUM(importe),0) FROM PAGO P WHERE p.socio_id=s.id AND especie=0 AND fecha_pago BETWEEN STR_TO_DATE(CONCAT('01,1,',Ejercicio),'%d,%m,%Y') AND STR_TO_DATE(CONCAT('31,12,',Ejercicio),'%d,%m,%Y') ),
 			11,'0'),
 		REPEAT('0',11) ),
-- IMPORTE PARTE FRACCIONARIA
 	IFNULL((SELECT RIGHT(FORMAT(SUM(importe),2),2) FROM PAGO P WHERE p.socio_id=s.id AND especie=0 AND fecha_pago BETWEEN STR_TO_DATE(CONCAT('01,1,',Ejercicio),'%d,%m,%Y') AND STR_TO_DATE(CONCAT('31,12,',Ejercicio),'%d,%m,%Y')),'00'),
-- MARCA DE PAGO EN ESPECIE: BLANCO PUES ESTE FICHERO SOLO DECLARA PAGOS EN DINERO
 	REPEAT(' ',1), 							
-- COMUNIDAD AUTONOMA 
	'XX',
-- DEDUCCION COMUNIDAD AUTONOMA
	'XXXXX',
-- NATURALEZA DLE SOCIO (LOOKUP EN NATURALEZA_SOCIO)
 	IFNULL((SELECT naturaleza_socio 
           FROM informacion_socio i 
          WHERE i.socio_id=s.id), ''),
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

	) AS XML_SOCIOS

FROM
socio s);

RETURN Tmp;

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
/*!50003 CREATE*/ /*!50020 DEFINER=`gestor`@`localhost`*/ /*!50003 FUNCTION `xml_socios_certificado_pago`(Ejercicio INT) RETURNS varchar(8192) CHARSET latin1
BEGIN

DECLARE Tmp Varchar(8192);

  set tmp=
  (SELECT  
    group_concat(
  '<SOCIO>',
-- EJERCICIO
    '<EJERCICIO>',
      Ejercicio,
    '</EJERCICIO>',
-- NIF DEL DECLARADO
    '<NIF>',
      IFNULL(s.NIF,REPEAT(' ',9)),
    '</NIF>',
-- NIF DEL REPRESENTANTE LEGAL DEL DECLARADO SI ES MENOR
    '<NIF_REPRESENTANTE>',
      IFNULL(s.NIF_representante,REPEAT(' ',9)),
    '</NIF_REPRESENTANTE>',
-- NOMBRE Y APELLIDOS DEL DECLARADO O RAZON SOCIAL SI ES UNA PERSONA JURIDICA
    '<NOMBRE>',
 			IFNULL(s.nombre,''),
    '</NOMBRE>',
    '<APELLIDO1>',
 			IFNULL(s.apellido1,''),
    '</APELLIDO1>',
    '<APELLIDO1>',
 			IFNULL(s.apellido2,''),
    '</APELLIDO1>',
-- PROVINCIA PARA DEDUCCION FISCAL
    '<PROVINCIA>',
      codigo_provincia_fiscal,
    '</PROVINCIA>',
-- IMPORTE
    '<IMPORTE>',
      IFNULL(								
        (
          SELECT ROUND(SUM(importe),2) FROM PAGO P 
          WHERE p.socio_id=s.id AND 
          fecha_pago BETWEEN STR_TO_DATE(CONCAT('01,1,',Ejercicio),'%d,%m,%Y') AND STR_TO_DATE(CONCAT('31,12,',Ejercicio),'%d,%m,%Y') 
          ) ,
        0 ),
    '</IMPORTE>',
  '</SOCIO>'
	) AS XML_SOCIOS

FROM
socio s

 HAVING (  
    SELECT SUM(importe) 
    FROM gor_socio.pago p 
    WHERE p.socio_id=3 
    AND fecha_pago BETWEEN STR_TO_DATE(CONCAT('01,1,',Ejercicio),'%d,%m,%Y') AND STR_TO_DATE(CONCAT('31,12,',Ejercicio),'%d,%m,%Y') 
      ) > 0
);

 RETURN concat 
  (
  '<socios ejercicio=',
  Ejercicio,
  '>',
  ifnull(Tmp,''),
  '<socios>');

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

-- Dump completed on 2010-05-14 13:00:12
