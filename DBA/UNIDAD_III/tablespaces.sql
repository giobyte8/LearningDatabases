
-- *** *** TABLESPACES EN ORACLE *** ***

-- CREANDO TABLESPACES

/**
 * Crear un tablespace llamado: 'GTABLESPACE1' con una dimensión de 10M y
 * almacenarlo en: /u01/oradata/gtablespace1.dbf' 
 */ 
CREATE TABLESPACE GTABLESPACE1 DATAFILE '/u01/oradata/gtablespace1.dbf' SIZE 10M;


