
# Practicas sobre Respaldo y recuperación.

## Contenido

 1. Respaldo en frio
 2. Respaldo en caliente


## Respaldo en frio
...

## Respaldo en caliente

##### Limitaciones y restricciones

 * La base de datos debe estar operando en modo ARCHIVELOG para que el respaldo funcione
 * El respaldo debe realizarce durante periodos de baja actividad para el DBMS

##### El respaldo en caliente consiste de tres pasos:

 1. Los 'datafiles' de los tablespaces son respaldados
 2. Los 'redo log' archivados se respaldan
 3. El 'control file' es respaldado

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

##### Respaldo del tablespace.
Para respaldar el tablespace se utiliza la instrucción ```ALTER TABLESPACE [TBS_NAME] BEGIN BACKUP```, de esta manera la DB ubica a un tablespace en modo backup, la base de datos copia todos los data blocks con cambios hacia el stream de redo. Después de que un tablespace se lleva fuera del modo backup mediante ```ALTER TABLESPACE [TBS_NAME] END BACKUP``` o ```ALTER DATABASE END BACKUP``` la base de datos avanza el 'data file checkpoint' SCN hacia el actual 'database checkpoint' SCN.

Cuando se restaura un datafile respaldado de esta manera, la base de datos solicita el conjunto de 'redo log' apropiados para aplicar si un recovery es necesario. Los redo log contienen todos los cambios requeridos para restaurar los datafiles y hacerlos consistentes.