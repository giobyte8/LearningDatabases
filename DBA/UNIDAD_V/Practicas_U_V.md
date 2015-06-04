
# Practicas sobre Respaldo y recuperación.

## Contenido

 1. Respaldo en frio
 2. Respaldo en caliente
 3. RMAN

## Preparando el terreno
Para poder realizar las practicas, debemos poner en modo ARCHIVE LOG la base de datos, además a manera de prueba, crearemos los siguientes registros en la base de datos para tener datos que respaldar y recuperar.

##### Tablespace para pruebas

Para este ejercicio vamos a crear un par de tablas dentro de un tablespace para nuestras pruebas de respaldo y recuperación.

```SQL
-- Creamos un tablespace
CREATE TABLESPACE BACKUPME DATAFILE '/u01/gdatafiles/backupme.dbf01' SIZE 2M;

-- Creamos un par de tablas en el tablespace
CREATE TABLE LANGS(ID NUMBER, NAME VARCHAR(25)) TABLESPACE BACKUPME;
CREATE TABLE PEOPLE(ID NUMBER, NAME VARCHAR(100)) TABLESPACE BACKUPME;

-- Insertamos algunos valores de prueba
INSERT INTO LANGS VALUES(1, 'CSharp');
INSERT INTO LANGS VALUES(2, 'Python');
INSERT INTO LANGS VALUES(3, 'Java');
INSERT INTO LANGS VALUES(4, 'Javascript');

INSERT INTO PEOPLE VALUES(1, 'JOHN');
INSERT INTO PEOPLE VALUES(2, 'ALICE');
INSERT INTO PEOPLE VALUES(3, 'AMANDA');
```
Con los datos cargados en la DB, podemos comenzar a crear nuestros respaldos.


## Respaldo en frio

Para realizar el respaldo en frio de la base de datos, debemos terminar las transacciones actuales, mediante un commit.

```sql
COMMIT;
```

Los archivos a incluir en el respaldo son: **Archivos de control (Controlfiles)**, **Archivos de datos (Datafiles)** y los archivos **redo log**. Para saber cuantos tenemos, en que rutas y que nombre tienen podemos consultar las vistas `V$LOGFILE`, `V$DATAFILE` y `V$CONTROLFILE`, de la siguiente manera:

```sql
SELECT MEMBER FROM V$LOGFILE;
SELECT NAME FROM V$DATAFILE;
SELECT NAME FROM V$CONTROLFILE;
```

Ahora debemos detener la base de datos (No sin antes asegurarnos de tener los archivos mas acutuales mediante `ALTER SYSTEM SWITCH LOG` y `COMMIT`. Luego mediante herramientas del sistema operativo, podemos copiar todos los archivos consultados a un respaldo.

```bash
tar -cvf /u02/backup.tar.gz datafile1 datafile2 ... controlfile1, controlfile2 ...
```
Incluyendo en el comando los nombres de todos los archivos que se van a respaldar. Una vez finalizada la creación del archivo, podemos levantar la base de datos. nuestro respaldo esta listo.


## Respaldo en caliente

##### Limitaciones y restricciones

 * La base de datos debe estar operando en modo ARCHIVELOG para que el respaldo funcione
 * El respaldo debe realizarce durante periodos de baja actividad para el DBMS

##### El respaldo en caliente consiste de tres pasos:

 1. Los 'datafiles' de los tablespaces son respaldados
 2. Los 'redo log' archivados se respaldan
 3. El 'control file' es respaldado


##### Respaldo del tablespace.
Para respaldar el tablespace se utiliza la instrucción ```ALTER TABLESPACE [TBS_NAME] BEGIN BACKUP```, de esta manera la DB ubica a un tablespace en modo backup, la base de datos copia todos los data blocks con cambios hacia el stream de redo. Después de que un tablespace se lleva fuera del modo backup mediante ```ALTER TABLESPACE [TBS_NAME] END BACKUP``` o ```ALTER DATABASE END BACKUP``` la base de datos avanza el 'data file checkpoint' SCN hacia el actual 'database checkpoint' SCN.

Cuando se restaura un datafile respaldado de esta manera, la base de datos solicita el conjunto de 'redo log' apropiados para aplicar si un recovery es necesario. Los redo log contienen todos los cambios requeridos para restaurar los datafiles y hacerlos consistentes.

#### Creando el respaldo
A continuación vamos a crear un respaldo en caliente del tablespace `BACKUPME`. Antes de iniciar el respaldo vamos a insertar un registro en una tabla perteneciente a nuestro tablespace para comprobar el respaldo de los datos.

```sql
INSERT INTO LANGS VALUES(5, 'PERL');
COMMIT;
ALTER TABLESPACE BACKUPME BEGIN BACKUP;
```

Luego, mediante herramientas del sistema operativo respaldamos el datafile del tablespace.
```bash
tar -cvf /u02/backups/backupme_datafile.tar.gz /u01/datafiles/backupme01.dbf
```

Una vez respaldado el datafile, activamos nuevamente el tablespace mediante:
```sql
ALTER TABLESPACE BACKUPME END BACKUP;
```

Listo, nuestro respaldo esta listo y podemos repetirlo para tantos tablespaces como sea necesario.

## RMAN (Recovery Manager)
RMAN por sus siglas en ingles (Recovery Manager), es una utileria de oracle incluida a partir de la versión 8i, se utiliza para realizar respaldos, restauraciones y operaciones de recuperación.

RMAN cuenta con un catalogo, el cual contiene: 
 * Los backups realizados
 * Los backup-pieces set y 
 * los ficheros (Datafiles, control files, archive logs) con indicación del SCN que hay en cada backup piece set.
 * Target database: La base de datos que va a ser respaldada, restaurada o recuperada.

#### Ventajas de RMAN

 * Se puede recuperar la DB hasta la última transacción
 * No es necesario dar de baja la DB para trabajar con RMAN
 * Se puede recuperar la DB hasta un punto en el tiempo definido por el usuario
 * Permite migrar datafiles entre plataformas de sistema operativo distinto
 * La consistencia de datos esta garantizada
 * Este tipo de respaldo incluye todos los datafiles, los controlfiles y los logfiles, no hay posibilidad de que alguna tabla o vista no entre en el backup.

#### Desventajas de RMAN

 * Requiere mas espacio en disco
 * Un mal diseño de estrategia de respaldo puede saturar rapidamente los discos
 * Nada excluido. (No se puede restaurar solo una tabla, es necesario restaurar toda la DB)

### Configuración del ambiente para RMAN

##### 1 La DB debe estar en modo archivelog
##### 2. Creación del catalogo de RMAN.
Creamos el tablespace para el catalogo de RMAN:
```sql
CREATE TABLESPACE TBSRMAN DATAFILE '/u01/datafiles/rman01.dbf' SIZE 5G;
```

##### 3. Se crea un usuario para RMAN
```sql
CREATE USER RMAN IDENTIFIED BY RMAN DEFAULT TABLESPACE TBSRMAN QUOTA UNLIMITED ON TBSRMAN;
```

Se otorgan privilegios de sesión y sobre el catalogo de recuperación
```sql
GRANT CREATE SESSION TO RMAN;
GRANT RECOVERY_CATALOG_OWNER TO RMAN
```

##### 4. Conexión al catalogo
Se realiza una conexión al catalgo de RMAN, en nuestro caso:
```bash
rman target / catalog RMAN/RMAN@ORCL
```
Donde RMAN/RMAN son: Usuario/passwd

Ahora creamos el catalogo de RMAN (Primera vez)
```sql
CREATE CATALOG;
```

Una vez que la DB esta en modo ARCHIVELOG y que el catalogo ha sido creado, registramos la base de datos.

```bash
export ORACLE_SID=ORCL;
rman TARGET / CATALOG RMAN/RMAN@ORCL;
register database;
```

##### 5. Report Schema
Finalmente solicitamos a RMAN un reporte de los archivos fisicos del esquema.
```sql
resport schema;
```


## DATAPUMP

expdp hr DIRECTORY=dpump_dir1 DUMPFILE=tables.dmp
TABLES=employees,jobs,departments

expdp hr DIRECTORY=dpump_dir1 DUMPFILE=tables_part.dmp
TABLES=sh.sales:sales_Q1_2000,sh.sales:sales_Q2_2000

## FLASHBACK

DB_FLASHBACK_RETENTION_TARGET
DB_RECOVERY_FILE_DEST
DB_RECOVERY_FILE_DEST_SIZE