-- MySQL dump 10.13  Distrib 5.1.30, for apple-darwin9.4.0 (i386)
--
-- Host: localhost    Database: gor_dev
-- ------------------------------------------------------
-- Server version	5.1.30
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping routines for database 'gor_dev'
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
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 FUNCTION `xml_actividad_de_un_gasto`(gasto_id INT) RETURNS varchar(4096) CHARSET latin1
BEGIN
  DECLARE tmp VARCHAR(4096);
  set tmp=
  (SELECT  
    group_concat(
      '<actividad>',
        '<actividad_id>',a.id,'</actividad_id>',  
        '<actividad_codigo>',a.codigo,'</actividad_codigo>',  
        '<actividad_porcentaje>',gxa.porcentaje,'</actividad_porcentaje>',  
      '</actividad>'
      ) as tmp
    FROM
      gor_dev.actividad a,
      gor_dev.gasto_x_actividad gxa
    WHERE
      a.id=gxa.actividad_id
      and gxa.gasto_id = gasto_id );
  return tmp;
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
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 FUNCTION `xml_actividad_de_un_ppto`(ppto_id INT) RETURNS varchar(4096) CHARSET latin1
BEGIN
  DECLARE tmp VARCHAR(4096);
  set tmp=
  (SELECT  
    group_concat(
      '<actividad>',
        '<actividad_id>',a.id,'</actividad_id>',  
        '<actividad_codigo>',a.codigo,'</actividad_codigo>',  
        '<actividad_porcentaje>',pxa.porcentaje,'</actividad_porcentaje>',  
      '</actividad>'
      ) as tmp
    FROM
      gor_dev.actividad a,
      gor_dev.presupuesto_x_actividad pxa
    WHERE
      a.id=pxa.actividad_id
      and pxa.presupuesto_id = ppto_id );
  return tmp;
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
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 FUNCTION `xml_financiador_de_un_gasto`(gasto_id INT) RETURNS varchar(4096) CHARSET latin1
BEGIN

  DECLARE tmp VARCHAR(4096);
  set tmp=
    (SELECT  
      group_concat(
        '<financiador>',
          '<financiador_id>',a.id,'</financiador_id>',  
          '<financiador_nombre>',a.nombre,'</financiador_nombre>',  
          '<financiador_porcentaje>',gxa.porcentaje,'</financiador_porcentaje>',  
        '</financiador>'
    ) as tmp
    FROM
      gor_dev.agente a,
      gor_dev.gasto_x_agente gxa
    WHERE
      a.id=gxa.agente_id
      and gxa.gasto_id = gasto_id); 

return tmp;
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
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 FUNCTION `xml_financiador_de_un_ppto`(ppto_id INT) RETURNS varchar(4096) CHARSET latin1
BEGIN

  DECLARE tmp VARCHAR(4096);
  set tmp=
    (SELECT  
      group_concat(
        '<financiador>',
          '<financiador_id>',a.id,'</financiador_id>',  
          '<financiador_nombre>',a.nombre,'</financiador_nombre>',  
          '<financiador_porcentaje>',pxa.porcentaje,'</financiador_porcentaje>',  
        '</financiador>'
    ) as tmp
    FROM
      gor_dev.agente a,
      gor_dev.presupuesto_x_agente pxa
    WHERE
      a.id=pxa.agente_id
      and pxa.presupuesto_id = ppto_id); 

return tmp;
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
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 FUNCTION `xml_gastos_de_un_proyecto`(proyecto_id INTEGER) RETURNS varchar(4096) CHARSET latin1
BEGIN

  DECLARE tmp VARCHAR(4096);

  set tmp=(SELECT  
    group_concat(
    '<gasto>',
      '<id>',g.id,'</id>',
      '<fecha>',g.fecha,'</fecha>'
      '<concepto>FALTA</concepto>',
      '<ccc>',l.cuenta,'</ccc>',
      '<importe>',g.cantidad,'</importe>',
      '<impuestos>',g.impuestos,'</impuestos>',
      '<porcentaje>',gxp.porcentaje,'</porcentaje>',
      '<partida_id>',g.partida_id,'</partida_id>',
      '<partida_codigo>',par.codigo,'</partida_codigo>',
      IFNULL(gor_dev.xml_actividad_de_un_gasto(g.id),''),
      IFNULL(gor_dev.xml_financiador_de_un_gasto(g.id),''), 
    '</gasto>'
    ) 
FROM 
  gor_dev.gasto g,
  gor_dev.proyecto p, 
  gor_dev.gasto_x_proyecto gxp,
  gor_dev.libro l,
  gor_dev.partida par
WHERE 
  p.id=proyecto_id and 
  p.id=gxp.proyecto_id and 
  g.id=gxp.gasto_id and
  g.libro_id=l.id and
  g.partida_id=par.id
  )
;
  SET tmp= concat(
    '<?xml version="1.0" encoding="ISO-8859-1"?><gastos proyecto_id="',
    proyecto_id,
    '">',
    IFNULL(tmp,''),
    '</gastos>'
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
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 FUNCTION `xml_ppto_de_un_proyecto`(proyecto_id INTEGER) RETURNS varchar(4096) CHARSET latin1
BEGIN

  DECLARE tmp VARCHAR(4096);

  set tmp=(SELECT  
    group_concat(
    '<linea_ppto>',
      '<id>',p.id,'</id>',
      '<fecha_ini>',p.fecha_inicio,'</fecha_ini>'
      '<fecha_fin>',p.fecha_fin,'</fecha_fin>'
      '<cantidad>',p.cantidad,'</cantidad>',
      '<concepto>FALTA</concepto>',
      '<coste_unit>FALTA</coste_unit>',
      '<agente_id>',p.agente_id,'</agente_id>',
      '<agente_nombre>',a.nombre,'</agente_nombre>',
      '<moneda_id>',p.moneda_id,'</moneda_id>',
      '<moneda_codigo>',m.abreviacion,'</moneda_codigo>',
      '<partida_id>',p.partida_id,'</partida_id>',
      '<partida_codigo>',par.codigo,'</partida_codigo>',
      IFNULL(gor_dev.xml_actividad_de_un_ppto(p.id),''),
      IFNULL(gor_dev.xml_financiador_de_un_ppto(p.id),''), 
    '</linea_ppto>'
    ) 
FROM 
  gor_dev.presupuesto p,
  gor_dev.agente a, 
  gor_dev.presupuesto_x_proyecto pxp, 
  gor_dev.moneda m,
  gor_dev.partida par
WHERE 
  p.id=pxp.presupuesto_id
  and p.agente_id = a.id
  and p.moneda_id=m.id
  and p.partida_id=par.id
  and pxp.proyecto_id=proyecto_id
  )
;
  SET tmp= concat(
    '<?xml version="1.0" encoding="ISO-8859-1"?><ppto proyecto_id="',
    proyecto_id,
    '">',
    IFNULL(tmp,''),
    '</ppto>'
    );

  RETURN tmp;
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

-- Dump completed on 2010-05-07 12:38:07
