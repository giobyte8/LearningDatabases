
-- *** *** PARTICIONES EN ORACLE *** ***

-- Para consultar un poco de teoria sobre este tema, dirijase 
-- a la sección correspondiente dentro del archivo README.md 
-- de la unidad.


-- *********************************************************** --

-- PARTICIONES POR RANGO

-- Creando una tabla particionada por rango
CREATE TABLE EMPLOYEE_BYRANGE(EMP_NO NUMBER(6), EMP_NAME VARCHAR(20))
PARTITION BY RANGE(EMP_NO) (PARTITION P1 VALUES LESS THAN(100), PARTITION P2
VALUES LESS THAN(200), PARTITION P3 VALUES LESS THAN(300), PARTITION P4 VALUES
LESS THAN(MAXVALUE));


-- Insertando registros en una tabla particionada
INSERT INTO EMPLOYEE_BYRANGE VALUES(51, 'PERTENEZCO A P1');
 -- Este registro ira a la particion P1

INSERT INTO EMPLOYEE_BYRANGE VALUES(99, 'PERTENEZCO A P1');
 -- Este registro ira a la particion P1

INSERT INTO EMPLOYEE_BYRANGE VALUES(100, 'PERTENEZCO A P2');
 -- Este registro ira a la particion P2

INSERT INTO EMPLOYEE_BYRANGE VALUES(299, 'WHERE I GO?');
 -- Este registro ira a la particion P3

INSERT INTO EMPLOYEE_BYRANGE VALUES(1500, 'PERTENEZCO A P4 < MAXVALUE');
 -- Este registro entra en el rango de P4, por lo tanto ira a P4


-- Consultando de una tabla particionada
SELECT * FROM EMPLOYEE_BYRANGE;
SELECT * FROM EMPLOYEE_BYRANGE PARTITION(P1);
SELECT * FROM EMPLOYEE_BYRANGE PARTITION(P4);


-- Agregar una partición a una tabla
ALTER TABLE EMPLOYEE_BYRANGE ADD PARTITION P5 VALUES LESS THAN(1000);
 -- NOTA: En este ejemplo, primero se debería eliminar la partición P4, dado que P4
 --       ya abarca todos los valores menores al MAXVALUE

-- Eliminando una partición (Se eliminaran tambien sus datos)
ALTER TABLE EMPLOYEE_BYRANGE DROP PARTITION P4;

-- Renombrando una partición
ALTER TABLE EMPLOYEE_BYRANGE RENAME PARTITION P5 TO PLAST;

-- Truncando una partición
ALTER TABLE EMPLOYEE_BYRANGE TRUNCATE PARTITION P5;

--Splitting una partición
ALTER TABLE EMPLOYEE_BYRANGE SPLIT PARTITION P2 AT(150) INTO (PARTITION P21, PARTITION P22);

-- Exchanging una partición
ALTER TABLE EMPLOYEE_BYRANGE EXCHANGE PARTITION P2 WITH TABLE EMPLOYEE_X;

-- Moviendo una partición
ALTER TABLE EMPLOYEE_BYRANGE MOVE PARTITION P21 TABLESPACE ABC_TBS;


-- ************************************************************* --

-- PARTICIONES POR LISTA

-- Crear una tabla particionada por listas
CREATE TABLE EMPLOYEE_BYLIST(EMP_NO NUMBER(6), EMP_NAME VARCHAR(20))
PARTITION BY LIST(EMP_NO) (PARTITION P1 VALUES(1, 2, 3, 4, 5), PARTITION P2
VALUES(6, 7, 8, 9, 10), PARTITION P3 VALUES(11, 12, 13, 14, 15));

-- Agregar uns partición
ALTER TABLE EMPLOYEE_BYLIST ADD PARTITION P4 VALUES(16, 17, 18, 19, 20);

/* NOTA: Las reglas para insertar y consultar de una tabla particionada asi como
         las reglas para agregar, eliminar, renombrar, truncar, exchange y mover una
         partición son las mismas que para las particiones POR RANGO.
*/


-- ************************************************************* --

-- PARTICIONES HASH

-- Crear una tabla particionada por HASH
--  NOTA: Solo debemos indicar el campo a particionar y el número de particiones
--  que necesitamos, Oracle utilizara algoritmos hash para distribuir los datos
--  de manera equitativa sobre las particiones.
CREATE TABLE EMPLOYEE_BYHASH(EMP_NO NUMBER(6), EMP_NAME VARCHAR(20))
PARTITION BY HASH(EMP_NO) PARTITIONS 5;

/* NOTA: Las operaciones de insercion y consulta se ralizan igual que en
         los tipos de particionado anteriores (RANGO, LISTA) 
*/

-- Agregando particiones
ALTER TABLE EMPLOYEE_BYHASH ADD PARTITION P8;

/* NOTA: Las operaciones de renombrar, truncar exchanging, mover particiones
         se realizan igual que en los tipos anteriores de particionado.
*/


-- ************************************************************* --
-- PARTICIONANDO POR MULTIPLES COLUMNAS
-- NOTA: Revisar el enlace: http://docs.oracle.com/cd/E18283_01/server.112/e16541/part_admin001.htm#i1008909
--       para comprender el particionamiento por multiples columnas.         

CREATE TABLE DEMO_MULTCOLS(
  YEAR NUMBER,
  MONTH NUMBER,
  DAY NUMBER,
  INSTANCE NUMBER, /* Asumamos que solo puede ser 1 | 2 */
  OTHER VARCHAR(50))
PARTITION BY RANGE (YEAR, INSTANCE) (
  PARTITION DATA2009_INST1 VALUES LESS THAN (2009, 2),
  PARTITION DATA2009_INST2 VALUES LESS THAN (2009, 3), -- Dos valores consecutivos iguales (se convierte en <=)
  PARTITION DATA2010_INST1 VALUES LESS THAN (2010, 2),
  PARTITION DATA2010_INST2 VALUES LESS THAN (2010, 3), -- Dos valores consecutivos iguales (se convierte en <=)
  PARTITION DATA2011_INST1 VALUES LESS THAN (2011, 2),
  PARTITION DATA2011_INST2 VALUES LESS THAN (2011, 3)  -- Dos valores consecutivos iguales (se convierte en <=)
);

INSERT INTO DEMO_MULTCOLS VALUES(2009, 1, 31, 1, 'OTRO DATO');
-- Este registro ira a la partición DATA2009_INST1

INSERT INTO DEMO_MULTCOLS VALUES(2009, 1, 31, 2, 'OTRO DATO');
-- Este registro ira a la partición DATA2009_INST2

INSERT INTO DEMO_MULTCOLS VALUES(2010, 1, 31, 1, 'OTRO DATO');
-- Este registro ira a la partición DATA2010_INST1

INSERT INTO DEMO_MULTCOLS VALUES(2010, 1, 31, 2, 'OTRO DATO');
-- Este registro ira a la partición DATA2010_INST2

INSERT INTO DEMO_MULTCOLS VALUES(2011, 1, 31, 1, 'OTRO DATO');
-- Este registro ira a la partición DATA2011_INST1

INSERT INTO DEMO_MULTCOLS VALUES(2011, 1, 31, 2, 'OTRO DATO');
-- Este registro ira a la partición DATA2011_INST2



-- ************************************************************* --
-- SUBPARTICIONES

CREATE TABLE DEMO_SUBPARTITIONS (
  YEAR NUMBER,
  MONTH NUMBER,
  DAY NUMBER,
  INSTANCE NUMBER, /* Asumamos que este campo solo puede ser 1 | 2 */
  OTHER VARCHAR(50))
  PARTITION BY RANGE (YEAR)
    SUBPARTITION BY LIST (INSTANCE)
      SUBPARTITION TEMPLATE(
        SUBPARTITION i1 VALUES (1),
        SUBPARTITION i2 VALUES (2),
        SUBPARTITION iX VALUES (DEFAULT)
      )
  (
    PARTITION DATA_2009 VALUES LESS THAN (2010),
    PARTITION DATA_2010 VALUES LESS THAN (2011),
    PARTITION DATA_2011 VALUES LESS THAN (2012)
  );

INSERT INTO DEMO_SUBPARTITIONS VALUES(2009, 11, 26, 1, 'OTRO DATO');
INSERT INTO DEMO_SUBPARTITIONS VALUES(2009, 09, 18, 2, 'OTRO DATO');
INSERT INTO DEMO_SUBPARTITIONS VALUES(2011, 01, 31, 1, 'OTRO DATO');

-- TODO: Consultas por subpartición, a que partición ira cada registro, describir la tabla creada


-- *************************************************************** --
-- Consultando metadatos sobre tablas particionadas.



