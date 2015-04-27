
# Examen UNIDAD IV.

## Mostrar mediante una consulta cuantos tipos de segmentos tiene el usuario SYS.

```SQL
SELECT DISTINCT SEGMENT_TYPE FROM DBA_SEGMENTS;
```
    SEGMENT_TYPE
    ------------------
    LOBINDEX
    INDEX PARTITION
    TABLE PARTITION
    NESTED TABLE
    ROLLBACK
    LOB PARTITION
    LOBSEGMENT
    INDEX
    TABLE
    CLUSTER
    TYPE2 UNDO

    11 rows selected.

## Ejemplificar el funcionamiento de ROLLBACK al momento de eliminar una tabla.

```
CREATE TABLE DEMOROLLBACK(ID NUMBER, NAME VARCHAR(5)) TABLESPACE GIOTBS;

SQL> SELECT * FROM DEMOROLLBACK;

no rows selected

SQL> INSERT INTO DEMOROLLBACK VALUES(1, 'HELLO');

1 row created.

SQL> SAVEPOINT INSDEMO;

Savepoint created.

SQL> DELETE FROM DEMOROLLBACK;

1 row deleted.

SQL> SELECT * FROM DEMOROLLBACK;

no rows selected

SQL> ROLLBACK TO INSDEMO;

Rollback complete.

SQL> SELECT * FROM DEMOROLLBACK;

	ID NAME
---------- -----
	 1 HELLO
```

## Consultar los indices del usuario OE y dehabilitarlos (mostrar el status nuevamente)

```SQL
SPOOL /u01/logs/disbla-indexes.sql
SELECT 'ALTER INDEX ' || OE.INDEX_NAME || ' UNUSABLE;' FROM DBA_INDEXES OE WHERE OWNER='OE';
SPOOL OFF;

@/u01/logs/disbla-indexes.sql

SELECT STATUS, INDEX_TYPE FROM DBA_INDEXES WHERE OWNER='OE';
```

Lob indexes no pueden ser dropeados o ALTER.


## Reorganizar los indices de OE mediante un nuevo tablespace OE_IDX

```SQL
SELECT 'ALTER INDEX "OE".' || OE.INDEX_NAME || ' REBUILD TABLESPACE OE_IDX;' FROM DBA_INDEXES OE WHERE OWNER='OE';

CREATE TABLESPACE OE_IDX DATAFILE '/u01/tbsps/oe_idx01.dbf' SIZE 50M;

@/home/oracle/rbindexes.sql

SELECT STATUS FROM DBA_INDEXES WHERE OWNER='OE';
```

## Crear un indice de tipo invisible en el usuario HR

```
SQL> ALTER USER HR IDENTIFIED BY HR ACCOUNT UNLOCK;

User altered.

SQL> CONN HR
Enter password: 
Connected.

SQL> CREATE INDEX GIOIDX ON JOBS(JOB_TITLE) INVISIBLE;

Index created.

SQL> SELECT INDEX_NAME, VISIBILITY FROM USER_INDEXES WHERE INDEX_NAME='GIOIDX';

INDEX_NAME		       VISIBILIT
------------------------------ ---------
GIOIDX			       INVISIBLE

```

## Activar el modo ARCHIVELOG en la base de datos.

* Verificar el estado actual mediante ```ARCHIVE LOG LIST```.
* Definir el parametro ```LOG_ARCHIVE_DEST_1```=```'LOCATION=/PATH/TO/DIR' SCOPE=SPFILE;
  En caso de no existir un SPFILE, crearlo mediante CREATE SPFILE FROM PFILE. RESTART DB
* Iniciar en modo mount
* ```ALTER DATABASE ARCHIVELOG```
* ```ALTER DATABASE OPEN```
* ```ALTER DATABASE SWITCH LOGFILE```

## Realizar el multiplexado de los redo logs

 * Verificar el estado actual en ```V$LOGFILE```
 * Agregar miembros a los grupos:

```SQL
ALTER DATABASE ADD LOGFILE MEMBER '/u01/logs/loga1.rdo' TO GROUP 1;
ALTER DATABASE ADD LOGFILE MEMBER '/u01/logs/logb1.rdo' TO GROUP 2;

SELECT GROUP#, MEMBERS FROM V$LOG;
```