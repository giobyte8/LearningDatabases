
# Caracteristicas básicas de RMAN


## Summary
 * Preparación del ambiente

** Prueba sobre tablespace **
 * Creando respaldos
 * Falla provocada
 * Restauración y recuperación del fallo

** Prueba sobre la base de datos completa **
 * Creando respaldos
 * Falla provocada
 * Restauración y recuperación del fallo


 * Problemas frecuentes | FAQ


## Preparando el ambiente

Para probar las caracteristicas basicas de RMAN, crearemos un usuario y le asignaremos un tablespace para sus datos. Crearemos un par de tablas, para respaldar, eliminar y posteriormente recuperar desde RMAN.

#### Activar el modo ARCHIVELOG

Verificamos el estado actual de la base de datos.
```sql
SELECT DBID, NAME, LOG_MODE FROM V$DATABASE;

-- Podemos verificar también con el siguiente comando:
ARCHIVE LOG LIST;
```

Si el ARCHIVELOG no esta activado:
```sql
ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='location=/u01/archive_log_offline' SCOPE=SPFILE;
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;

-- Cambiamos el modo de operación de la DB y abrimos para operación normal.
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
```

Podemos forzar el cambio de redo logs para verificar el modo ARCHIVELOG
```sql
ALTER SYSTEM SWITCH LOGFILE;
```


#### Usuario y tablespace

Creamos el tablespace para las pruebas.
```sql
CREATE TABLESPACE RDEMO DATAFILE '/u01/app/oracle/oradata/orcl/rdemo.dbf' SIZE 5M;
```

Creamos el usuario
```SQL
CREATE USER RGIO IDENTIFIED BY RGIO DEFAULT TABLESPACE RDEMO;
GRANT CREATE SESSION TO RGIO;
GRANT CREATE TABLE TO RGIO;
ALTER USER RGIO QUOTA UNLIMITED ON RDEMO;
```

#### Esquema para las pruebas

```sql
CREATE TABLE GOT_CHARACTERS(
	FIRST_NAME VARCHAR2(50),
	LAST_NAME VARCHAR2(50)
);

-- A few random data
INSERT INTO GOT_CHARACTERS VALUES('John', 'Snow');
INSERT INTO GOT_CHARACTERS VALUES('Arya', 'Stark');
INSERT INTO GOT_CHARACTERS VALUES('Tyrion', 'Lannister');

-- Check the data
SELECT * FROM GOT_CHARACTERS;
```




# Prueba sobre tablespace

## Creando respaldos.

```bash
~$ rman
```

```bash
# Entramos a la base de datos
RMAN> CONNECT TARGET /

# Revisamos datafiles y temporary files de la base de datos.
RMAN> REPORT SCHEMA;

# Creamos un respaldo del tablespace rdemo
RMAN> BACKUP TABLESPACE RDEMO;

# El respaldo ahora debe existir
RMAN> LIST BACKUP;

# Validamos el respaldo logicamente.
RMAN> BACKUP VALIDATE TABLESPACE RDEMO;
```

## Fallo provocado.

Eliminamos el archivo del tablespace para forzar un fallo.
```bash
~$ rm /u01/app/oracle/oradata/orcl/rdemo.dbfs
```

Reiniciamos la base de datos e intentamos acceder a los datos.
```sql
SHUTDOWN IMMEDIATE;
STARTUP;
SELECT * FROM RGIO.GOT_CHARACTERS;
-- La consulta fallara debido a la perdida de datos
```

## Restauración y recuperación del fallo

Desde RMAN ejecutamos
```bash
# Ponemos offline el tablespace a recuperar
RMAN> SQL 'ALTER TABLESPACE RDEMO OFFLINE';

# Restauramos el archivo perdido
RMAN> RESTORE TABLESPACE RDEMO;

# Recuperamos el tablespace
RMAN> RECOVER TABLESPACE RDEMO;

# Ponemos el tablespace online para operacióñ normal.
RMAN> SQL 'ALTER TABLESPACE RDEMO ONLINE';
```

Ahora podemos verificar la restauración de los datos.
```sql
SELECT LAST_NAME FROM RGIO.GOT_CHARACTERS;
```

# Prueba sobre la base de datos completa

## Creando respaldos
Creamos un respaldo de toda la base de datos desde RMAN
```bash
RMAN> BACKUP DATABASE PLUS ARCHIVELOG;

# Verificamos el respaldo (Opcional)
RMAN> BACKUP VALIDATE DATABASE ARCHIVELOG ALL;
```

## Falla provocada
Eliminamos los datafiles de la base de datos.
```bash
cd /u01/app/oracle/oradata/orcl/
rm example01.dbf rdemo.dbf system01.dbf temp01.dbf undotbs01.dbf users01.dbf
```

Con cualquier query o DML podemos verificar que la base de datos ya no funciona.


## Restauración y recuperación del fallo
```bash
#RMAN> RESTORE DATABASE PREVIEW SUMMARY;

# Recuperación de la base de datos
# -----------------------------------

# Iniciamos en modo mount
RMAN> STARTUP FORCE MOuNT;

# Restauramos los archivos de la base de datos desde el respaldo
RMAN> RESTORE DATABASE;

# Recuperamos la base de datos
RMAN> RECOVER DATABASE;

# Iniciamos la base de datos para operaciones normales
RMAN> ALTER DATABASE OPEN;
```


## FAQ | Problemas frecuentes.

** ORA-32001 **
Write to spfile request but no spfile is in use.

```sql
CREATE SPFILE FROM PFILE;
SHUTDOWN IMMEDIATE;
STARTUP;
SHOW PARAMETER SPFILE;
```


















