#Unidad III: Configuración y administración del espacio en disco.

##Contenido
 - 3.1 Estructuras lógicas de almacenamiento
   * Definición de espacio de almacenamiento
   * Tablespaces y Datafiles
     - Creando tablespaces
     - Administración de tablespaces
       * Locally Managed Tablespaces
       * Tablespaces administrados por el diccionario de datos
       * Migrando el tablespace de SYSTEM a Locally Managed
       * Tablespace de UNDO
       * Tablespaces temporales
       * Tablespaces en modo READ-ONLY
       * Tablespaces en modo OFFLINE
     - Administrando la configuración de almacenamiento
       * Redimensionando un tablespace
       * Habilitando la extensión automatica de DATAFILES
       * Cambiando el tamaño de un DATAFILE manualmente
       * Agregando datafiles a un tablespace
     - Métodos para mover un tablespace
       * Para tablespaces que no sean de SYSTEM
       * Tablespace de SYSTEM
     - Borrando tablespaces
   * Administración de tablespaces utilizando OMF
     - Operaciones con tablespaces utilizando OMF
 - 3.2 Segmentos

##Definición de espacio de almacenamiento
Oracle almacena los datos lógicamente en Tablespaces y fisicamente en Datafiles asociados con su correspondiente tablespace.

##Tablespaces y datafiles

*Cada datafile, se asocia con un y solo un tablespace.*
![Imagen de relación entre tablespaces y datafiles](http://i.imgur.com/WYpmdCk.gif)

Databases, tablespaces y datafiles mantienen una relación muy estrecha:

 - Una base de datos Oracle consiste de al menos dos unidades de almacenamiento logico llamadas tablespaces, en los cuales, se almacena de manera colectiva todos los datos de la Database. Deberan existir al menos los tablespaces SYSTEM y SYSAUX.
 - Cada tablespace en una base de datos Oracle consiste de uno o mas archivos llamados *datafiles*, que son estructuras fisicas almacenadas en el sistema operativo.
 - Toda la información de la base de datos es almacenada en datafiles que conforman cada uno de los tablespaces de la base de datos.

Puedes consultar mas detalles sobre tablespaces, datafiles y Control files en la [documentación oficial.] (http://docs.oracle.com/cd/B28359_01/server.111/b28318/physical.htm#CNCPT003)

###Creando tablespaces
En oracle, los tablespaces son creados mediante el comando: `CREATE TABLESPACE`, pasando como parametros: el nombre del tablespace, la ruta donde se almacenara y el tamaño que tendra el nuevo tablespace.

```sql
CREATE TABLESPACE <nombre-tablespace> DATAFILE '/ruta/al/tablespace' SIZE 5M;
```
En el [archivo de ejercicios](tablespaces.sql) se muestra detalladamente como crear tablespaces de diferentes tamaños, tanto en el disco local como en discos externos.

###Administración de tablespaces

####Locally Managed Tablespaces
Los tablespaces administrados localmente almacenan y administran toda la información correspondiente a los extents en el tablaspace a través de bitmaps. Lo cual proporciona los siguientes beneficios:

 - Operaciones concurrentes rapidas. Asignación y desasignación de espacio modifica recursos administrados localmente.
 - Rendimiento mejorado
 - La asignación de espacio se simplifica, debido a que cuando se especifica la clausula ```AUTOALLOCATE``` la base de datos automaticamente elige el tamaño apropiado para cada extent.
 - Reduce el contenido de las tablas del diccionario de datos.
 - No se generan registros de UNDO cuando ocurre una asignación o liberación.
 - No se requiere 'coalesce'.

Todos los tablespace, incluyendo el tablespace SYSTEM pueden ser localmente administrados. El paquete DBMS_SPACE_ADMIN proporcina procedimientos de mantenimiento para tablespaces localmente administrados.

```sql
CREATE TABLESPACE USERTSPACE DATAFILE '/u01/oradata/userdata01.dbf' SIZE 500M EXTENT MANAGEMENT LOCAL UNIFORM SIZE 128K;
```
Puedes revisar la [documentación oficial](http://docs.oracle.com/cd/B28359_01/server.111/b28310/tspaces002.htm#ADMIN11360) sobre tablespaces localmente administrados para mas información.

####Tablespaces administrados por el diccionario de datos.

 - Los extents son administrados por el diccionario de datos.
 - Las tablas correspondientes son actualizadas cuando un extent es utilizado o liberado.
 - Cada segmento del tablspace puede tener una clausula diferente de almacenamiento.

```sql
CREATE TABLESPACE TSPACE_DICTIONARY DATAFILE '/u01/oradata/userdata01.dbf' SIZE 500M EXTENT MANAGEMENT DICTIONARY DEFAULT STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);
```

####Migrando el tablespace SYSTEM a Locally managed
Utilize el paquete DBMS_SPACE_ADMIN para migrar el tablespace SYSTEM de administrado por diccionario a localmente administrado. La siguiente instrucción realiza la migración:

```sql
EXECUTE DBMS_SPACE_ADMIN.TABLESPACE_MIGRATE_TO_LOCAL('SYSTEM');
```
Antes de realizar la migración deben cumplirse las siguientes condiciones:

 - La base de datos debe tener un 'defaul temporary tablespace' que no sea SYSTEM.
 - No debe haber segmentos de ROLLBACK en el tablespace administrado por diccionario
 - Deber haber al menos un segmento de ROLLBACK en linea en un tablespace localmente administrado, o si se utiliza administración de UNDO automatica, un tablespace de UNDO debe estar online.
 - Todos los tablespaces que no sean el el tablespace que contiene el espacio de UNDO (el tablespace que contiene el segmento de ROLLBACK o el tablespace de UNDO) deben estar en modo READ-ONLY.
 - El sistema debe estar en modo restringido
 - Debe haber un respaldo en frio de la base de datos

Todas estas condiciones, excepto el respaldo en frio, son forzadas por el procedimiento ```TABLESPACE_MIGRATE_TO_LOCAL```

**NOTA:** Despues de que el tablespace de SYSTEM sea migrado a localmente administrado, cualquier tablespace administrado por diccionario no podra ponerse en read/write. Si necesita utilizar tablespaces administrados por diccionario en modo read/write, entonces Oracle recomienda que primero se migren dichos tablespaces a localmente administrados antes de migrar el tablespace SYSTEM.

####Tablespace de UNDO

 - Se utiliza para almacenar los segmentos de UNDO.
 - No puede contener objetos de base de datos, esta reservado para datos de undo administrados por el systema.
 - Es localmente administrado (locally managed).
 - Solo puede utilizar las clausulas DATAFILE y EXTENT MANAGEMENT.

```sql
CREATE UNDO TABLESPACE UNDOTSPACE DATAFILE '/u01/oradata/undodata01.dbf' SIZE 40M;
```
Se puede crear mas de un tablespace de undo, pero solo uno puede estar activo en cualquier momento

####Tablespaces temporales

 - Usados para operaciones de ordenamiento.
 - Pueden compartirse con multiples usuarios.
 - No puede contener ningun objeto permanente.
 - Se recomienda administrar los extents localmente (locally managed).

```sql
CREATE TEMPORARY TABLESPACE TEMPTSPACE TEMPFILE '/u01/oradata/temp01.dbf' SIZE 20M EXTENT MANAGEMENT LOCAL UNIFORM SIZE 4M;
```
Se recomienda que UNIFORM SIZE sea un multiplo de SORT_AREA_SIZE para mejorar el rendimiento.

#####Default temporary tablespace

 - Especifica el tablespace temporal de la base de datos.
 - Puede ser creado utilizando: ```CREATE DATABASE``` | ```ALTER DATABASE```
 - No puede ser borrado hasta que no se defina uno nuevo.
 - No se puede poner fuera de linea si esta activo.

#####Creando un default temporary tablespace
Durante la creacion de la base de datos

```sql
CREATE DATABASE DBA01
LOGFILE
GROUP 1 ('/$HOME/ORADATA/u01/redo01.log') SIZE 100M,
GROUP 2 ('/$HOME/ORADATA/u02/redo02.log') SIZE 100M,
MAXLOGFILES 5
MAXLOGMEMBERS 5
MAXLOGHISTORY 1
MAXDATAFILES 100
MAXINSTANCES 1
DATAFILE '/$HOME/ORADATA/u01/system01.dbf' SIZE 325M
UNDO TABLESPACE undotbs DATAFILE '/$HOME/ORADATA/u02/undotbs01.dbf' SIZE 200
DEFAULT TEMPORARY TABLESPACE temp  TEMPFILE '/$HOME/ORADATA/u03/temp01.dbf' SIZE 4M
CHARACTER SET US7ASCII
```

Despues de haber creado la base de datos:
```sql
ALTER DATABASE DEFAULT TEMPORARY TABLESPACE DEF_TEMP2;
```

Para encontrar el DEFAULT TEMPORARY TABLESPACE, puedes consultar las propiedades de la base de datos

```sql
SELECT * FROM DATABASE_PROPERTIES;
```

####Tablespaces en READ-ONLY.

Poner un tablespace en modo READ-ONLY evita operaciones de escritura en los datafiles del tablespace, el proposito principal del modo READ-ONLY es evitar la necesidad de realizar respaldos y recuperacióñ de enormes porciones estaticas de la base de datos, tambien sirve como un modo de proteger datos historicos de modo que los usuarios no puedan modificarlos. Poner un tablespace en READ-ONLY evita updates sobre todas las tablas del tablespace sin importar el nivel de privilegios que tenga el usuario.

 - Causan un checkpoint.
 - Los datos solo se accesan para operaciones de lectura.
 - Se puede hacer ```DROP``` de items tales como TABLAS o INDICES, pero NO SE PUEDEN CREAR O ALTERAR OBJETOS.
 - Se pueden ejecutar instrucciones que alteren la descripción del archivo en el diccionario de datos tales como: ```ALTER TABLE```, ```ADD``` or ```ALTER TABLE ... MODIFY```, pero no se podra utilizar la nueva descripción hasta que el tablespace se ponga en READ/WRITE.

```sql
ALTER TABLESPACE SOMETSPACE READ ONLY;
```

####Tablespaces en modo OFFLINE

 - No se puede acceder a los datos.
 - Los tablespaces siguientes no se pueden poner fuera de linea:
   * Tablespace de SYSTEM.
   * Tablespaces con segmentos activos de UNDO.
   * Tablespaces temporales.

**Para poner un tablespace fuera de linea:**
```sql
ALTER TABLESPACE SOMETSPACENAME OFFLINE;
```

Para volver a poner ONLINE un tablespace que esta en OFFLINE
```sql
ALTER TABLESPACE SOMETSPACENAME ONLINE;
```

###Administrando la configuración de almacenamiento.
Utilizando el comando ```ALTER TABLESPACE``` para cambiar configuraciones de almacenamiento
```sql
ALTER TABLESPACE SOMETSPACE MINIMUM EXTENT 2M;
```
```sql
ALTER TABLESPACE SOMETSPACE DEFAULT STORAGE (INITIAL 2M NEXT 2M MAXEXTENTS 999);
```

Las configuraciones de almacenamiento para administración local no pueden ser modificadas.

####Redimensionando un tablespace

 - Cambiar el tamaño del DATAFILE
    * Automáticamente usando ```AUTOEXTEND```
    * Manualmente usando ```ALTER DATABASE```
 - Agregando un DATAFILE mediante ```ALTER TABLESPACE```

####Habilitando la extensión automatica de DATAFILES
Se puede realizar de automáticamente durante los comandos: 
```CREATE DATABASE```
```CREATE TABLESPACE```
```ALTER TABLESPACE ... ADD DATAFILE```

```sql
CREATE TABLESPACE SOMETSPACE DATAFILE '/u01/oradata/userdata01.dbf' SIZE 200M AUTOEXTEND ON NEXT 10M MAXSIZE 500M;
```

Consulte la vista ```DBA_DATA_FILES``` para determinar cuando ```AUTOEXTEND``` esta habilitado.

####Cambiando el tamaño de un DATAFILE manualmente

 - Manualmente incrementando o decrementando el tamaño de un datafile usando ```ALTER DATABASE```.
 - Agregando espacio a un DATAFILE (sin crear nuevos DATAFILES).

```sql
ALTER DATABASE DATAFILE '/u03/oradata/somedata02.dbf' RESIZE 200M;
```

####Agregando DATAFILES a un tablespace
 - Incrementar el tamaño del tablespace añadiendo datafiles.
 - A través de la sentencia ADD DATAFILE.

```sql
ALTER TABLESPACE usertspace ADD DATAFILE '/u03/oradata/userdata03.dbf' SIZE 30M;
```

###Metodos para mover tablespaces

####Para tablespaces que no sean SYSTEM

A través del comando ```ALTER TABLESPACE```.
 - El tablespace debe estar en modo OFFLINE.
 - Se debe copiar el DATAFILE al destino antes de ejecutar el comando.

```sql
ALTER TABLESPACE usertspace RENAME DATAFILE '/u01/oradata/usertspace01.dbf' TO '/u02/oradata/usertspace01.dbf';
```

####Tablespace de SYSTEM
A través del comando ```ALTER TABLESPACE```. Con ciertas condiciones:
 - La base de datos debe estar en MOUNT
 - La fuente del DATAFILE debe existir

```sql
ALTER DATABASE RENAME FILE '/u01/oradata/system01.dbf' TO '/u03/oradata/system01.dbf';
```

###Borrando tablespaces

 - La clausula ```INCLUDE CONTENTS``` borra los segmentos.
 - ```INCLUDING CONTENTS AND DATAFILES``` borra los segmentos y los datafiles.
 - ```CASCADE CONSTRAINS``` borra todas las restricciones de integridad referencial.
 - En los siguientes casos NO SE PUEDE BORRAR un tablespace:
   * Si es el tablespace de SYSTEM.
   * Si tiene segmentos activos.

```sql
DROP TABLESPACE usertspace INCLUDING CONTENTS AND DATAFILES;
```

##Administrando tablespaces utilizando OMF
**Oracle Managed Files (OMF)** Es un servicio que automatiza la creación, nombramiento, localización y eliminación de archivos de base de datos tales como archivos de control, logs de REDO, datafiles entre otros, basado en algunos parametros de inicialización. Este servicio puede simplificar muchos aspectos de la administración de base de datos eliminando la necesidad de implementar sus propias politicas para dichas tareas.

Defina el parametro ```DB_CREATE_FILE_DEST```, por alguno de los siguientes metodos:
 * En el archivo de inicialización de parametros
 * Definiendolo de forma dinamica con ```ALTER SYSTEM```:
   ```sql
   ALTER SYSTEM SET DB_CREATE_FILE_DEST = '/u02/oradata/dba_orcl';
   ```
 * Cuando se crea el tablespace:
   - El archivo DATAFILE es creado automáticamente y almacenado en la ruta DB_CREATE_FILE_DEST.
   - El tamaño por default es 100M
   - AUTOEXTEND es definido como UNLIMITED

####Operaciones con tablespaces utilizando OMF

-- Creando un tablespace
```sql
CREATE TABLESPACE USERTSPACE DATAFILE SIZE 20M;
```

-- Agregando un DATAFILE OMF a un tablespace existente
```sql
ALTER TABLESPACE usertspace ADD DATAFILE;
```

--Cambiando dinamicamente la localización por default del archivo:
```sql
ALTER SYSTEM SET DB_CREATE_FILE_DEST = '/u01/oradata/db01';
```

-- Borrando un tablespace incluyendo los archivos del sistema operativo.
```sql
DROP TABLESPACE usertspace INCLUDING CONTENTS AND DATAFILES;
```

##Obteniendo información sobre tablespaces
Consultando los siguientes objetos:

 - Información del tablespace
   * DBA_TABLESPACES
   * V$TABLESPACE
 - Información de los datafiles
   * DBA_DATA_FILES
   * V$DATAFILE
 - Información de los archivos temporales
   * DBA_TEMP_FILES
   * V$TEMPFILE

##Particiones
El particionamiento de tablas permite que una tabla sea subdividida en piezas mas pequeñas, donde cada pieza es llamada: 'Partición'.

###Cuando particionar una tabla.
 - Las tablas de más de 2 GB deben ser consideradas para particionarse
 - Tablas con datos históricos. (Podriamos almacenar los de cada semana/mes/año en una partición diferente.)
 - Cuando el contenido de una tabla debe distribuirse en diferentes medios de     almacenamiento.

###Ventajas del particionamiento
 - Reduce tiempo inactividad en mantenimiento, mientras se mantienen unas particiones, otras siguen disponibles al usuario.
 - Reduce tiempo de inactividad por falta de datos. (La falta de una partición no afecta a las demas).
 - Independencia de partición, permite el uso concurrente de varias particiones para diversos fines.
 - Llaves particionadas

Dentro de una tabla particionada, cada fila corresponde exclusivamente a una particion (Solo una), *la llave de particionamiento* se compone de una o mas columnas que determinan a que partición pertenece cada fila.

###Tipos de particiones
 - Range partitions:
 - List partitions
 - Hash partitions

######Particiones por rango
El particionamiento por rango mapea datos a particiones basandose en el rango de valores de la llave de particionamiento que usted establece para cada partición, es el tipo de partición mas comun y es usado frecuentemente con fechas. Por ejemplo, para almacenar los datos de cada mes en una partición separada.

######Particiones por lista
Permite indicar especificamente que valores iran a cada partición de la tabla indicando una lista de valores discretos validos para cada partición. Este tipo de particionamiento es muy util cuando los datos para una partición no se pueden indicar a través de un rango, por ejemplo para almacenar en una partición los datos de Norteamerica, entrarian en la lista solo los valores 'México', 'USA' y 'Canada'.

######Particiones hash
Este tipo de particionamiento distribuye los datos de manera uniforme a través de todas las particiones, dando aproximadamente el mismo tamaño a cada partición. Es muy util para distribuir datos uniformemente a través de diferentes medios de almacenamiento. Especialmente cuando los datos no tienen una llave de particionamiento obvia para distribuirse.

######Subparticiones
El particionado compuesto o 'subparticionamiento', es una combinación de los metodos de distribución de datos ya mencionados. Una tabla es particionada por alguno de los tres metodos y luego cada partición es a su vez subdividida en particiones utilizando un segundo metodo.


En el archivo: [Ejercicios de particionamiento](Particiones.sql), se muestra como crear y manipular cada uno de los tres tipos de particiones, particionar por multiples columnas y subparticionamiento. Tambien se muestra como consultar metadatos sobre tablas particionadas (Cuantas particiones hay, como se llaman, que datos almacenan, a que tablespace pertenecen etc...

Puede consultar la documentación oficial sobre el concepto de particionado en el enlace siguiente: [Conceptos de particionamiento](http://docs.oracle.com/cd/B28359_01/server.111/b32024/partition.htm).

<h2> Segmentos</h2>
  <p>
    <b>Abstract:</b><br>Son asignados para almacenar tablas, indices, particiones, vistas materializadas, es decir, a cualquier estructura logica que almacena datos fisicos oracle le asigna un segmento, el cual solo puede estar asociado a un tablespace. Los segmentos deben contener al menos un <i>extends</i>
  </p>

  <br><p>
    Oracle asigna espacio logico para todos los datos en la DB. Las unidades de espacio de asignación son: Data Blocks, Extends y Segmentos.
  <p>
  <span>En la imagen se muestra la relación entre dichas unidades.</span><br>
  ![Relación entre datablocks, extends y Segments](img/segment_extend_datablock.gif)
  <br>
  <p>
    En el nivel mas fino de granularidad, Oracle almacena datos en <b>datablocks</b> que representan un número especifico de bits en el disco fisico.
  </p>
  <p>
    El siguiente nivel de espacio logico son los <b>extend</b>. Que son un número especifico de <i>datablocks</i> continuos asignados para almacenar un tipo especifico de información
  </p>
  <p>
    El siguiente nivel son los <b>segmentos</b>. Un segmento es un conjunto de <i>extends</i> que han sido asignados a una estructura de datos especifica y estan todos en el mismo <i>tablespace</i>. Por ejemplo, cada dato de una tabla es almacenado en el <i>segmento de datos</i> correspondiente a la tabla, a su vez, cada indice de la tabla es almacenado en el <i>segmento de indice</i> correspondiente. Si la tabla o indice estan particionados, cada partición es almacenada en su propio segmento.
  </p>
  <p>
  Oracle asigna espacio para los segmentos en unidades de un extend, cuando los extends de un segmento estan llenos, oracle asigna otro extend para ese segmento. Un segmento y todos sus extends son almacenados en el mismo tablespace, dentro de un tablespace un segmento puede incluir extends de mas de un datafile, es decir, los segmentos pueden abarcar varios <i>datafiles</i>, sin embargo cada extend solo puede tener datos de un datafile.
  </p>

  <br><h6>Segmentos de datos</h6>
  <span>Un solo segmento de datos contiene información para alguno de los siguientes:</span>
    <ul>
    <li>Una tabla que no esta particionada o clusterizada</li>
    <li>Una partición. (De una tabla pariticionada)</li>
    <li>Un cluster de tablas</li>
  </ul>
  <span>Oracle crea el segmento de datos en el momento en que se crea la tabla o cluster mediante la sentencia ```CREATE``` </span>
  <p>
    Los parametros de storage para una tabla o cluster determinan comos e asignaran extends a su segmento de datos. Usted puede configurar esos parametros directamente en la sentencia ```CREATE``` o ```ALTER```. Dichos parametros afectan la eficiencia de recuperación y almacenamiento de datos para el segmento asociado con el objeto creado o alterado.
  </p>

  <br><h6>Segmentos de indice</h6>
  <p>
    Cada indice no particionado tiene su propio segmento de indice, un indice particionado tiene un segmento de indice para cada partición. Oracle crea un segmento de indice al ejecutar la instrucción ```CREATE INDEX```, en esta instrucción se pueden especificar los parametros de storage para los extends del indice asi como el tablespace en el cual crear el segmento de indice. (Los segmentos de una tabla y un indice asociado no necesitan residir en el mismo tablespace).
  </p>

  <br><h6>Segmentos temporales</h6>
  <p>
    Cuando se procesan queries, a menudo oracle requiere de espacio de trabajo temporal durante las etapas intermedias de la interpretación de SQL. Oracle asigna automaticamente este espacio en disco en forma de <i>'Segmento temporal'</i>. Si hay manera de realizar la operación en memoria, entonces Oracle no requiere de un segmento temporal.
  </p>

  <span>Las siguientes operaciones a requieren ocasionalmente de un segmento temporal</span>
  <ul>
    <li>```CREATE INDEX ... ```  </li>
  <li>```SELECT ... ORDER BY```</li>
  <li>```SELECT DISTINCT ...```</li>
  <li>```SELECT ... GROUP BY```</li>
  <li>```SELECT ... UNION```   </li>
  <li>```SELECT ... INTERSECT```</li>
  <li>```SELECT ... MINUS ```   </li>
  </ul>

  <p>
    <b>Asignación de segmentos temporales para consultas</b>
  <br>Oracle asigna segmentos temporales para consultas, según sea necesario durante una sesion de usuario y los libera cuando la consulta termina. Los cambios en los segmentos temporales nos e regitran en el registro redo a excepción de las operaciones de gestion de espacio en el segmento temporal. <br> La base de datos crea segmentos temporales en el espacio de tablas temporal asignado al usuario.
  </p>
  <p>
    <b>Asignación de segmentos temporales para tablas e indices temporales</b>
  <br> Oracle tambien asigna segmentos temporales para las tablas temporales y sus indices. Las tablas temporales almacenan datos que existen sólo para la duración de una sesión o transacción.
  </p>
  <p>
    Debido a la frecuencia con que se produce la asignación y liberación de segmentos temporales, lo mejor es <b>crear un tablespace especial para segmentos temporales</b>.
  </p>

  <br><h6>Segmentos de UNDO</h6>
  <p>
    Oracle mantiene información para revertir cambios hechos a la base de datos, esta información consiste de registros de las acciones de las transacciones, colectivamente conocidos como <b>undo</b>. Undo se almacena en <i>segmentos de undo</i> dentro de un <i>undo tablespace</i>. Oracle utiliza la información de undo para lo siguiente:
  </p>
  <ul>
    <li>Rollback de una transacción activa</li>
  <li>Recuperar una transacción terminada</li>
  <li>Proporcionar lectura coherente</li>
  <li>Recuperar de corrupciones logicas</li>
  </ul>
  <p>
    Oracle proporciona un mecanismo completamente automatizado conocido como <b>Administración de UNDO automatica</b>. para administrar espacio e información de UNDO. En este modo de administración, para todas las sesiones actuales, el servidor automaticamente administra segmentos y espacio de undo en el tablespace de undo.
  </p>
  <p>
   <b>ROLLBACK  TRANSACTION</b><br> Cuando se emite una instrucción ROLLBACK, los registros de UNDO se utilizan para deshacer cambios sin confirmar hechos por transacciones en la base de datos. Durante la recuperación de la base de datos, los registros de undo son utilizados para deshacer cualquier cambio sin confirmar aplicado de los logs redo hacia los datafile. Los registros de UNDO proporcionan lectura coherente manteniendo una imagen anterior de los datos para usuarios que intentan acceder a los datos al mismo tiempo que otro usuario esta modificandolos.
   </p>

  <br><h4>Segmentos diferidos</h4>
  <p>
    Normalmente cuando se crea una tabla o indice oracle crea los segmentos correspondientes para tales objetos, asignando espacio en disco inicial para dichas estructuras.
  </p>
  <p>
   A partir de la version <b>11g R2</b> existe una funcionalidad que permite la creación de segmentos diferidos, es decir, se crean los objetos en la base de datos pero no se les asigna espacio en disco mientras no sea necesario. Cuando el usuario inserta la primera fila en una tabla o partición oracle crea los segmentos correspondientes. Usted puede utilizar el paquete DBMS_SPACE_ADMIN para manejar segmentos de objetos vacios, el paquete permite realizar lo siguiente:
  </p>
  <ul>
    <li>Materializar segmentos manualmente para tablas vacias o particiones que no tienen segmentos creados.</li>
  <li>Retirar los segmentos de tablas vacias o particiones que actualmente tienen un segmento vacio asignado.</li>
  </ul>
  <p>
    La utilización de segmentos diferidos se puede configurar a nivel de todo el sistema (a través de un parametro de init.ora), a nivel de cada sesión o incluso a nivel de cada sentencia de DDL.
  </p>

  <h6>Activar DEFERRED SEGMENTS</h6>
  <p>
    A nivel de todo el sistema:
```sql
ALTER SYSTEM SET DEFERRED_SEGMENT_CREATION = [TRUE | FALSE]
```

   A nivel de la sesión actual:
```sql
ALTER SESSION SET DEFERRED_SEGMENT_CREATION = [TRUE | FALSE]
```

``` sql> SHOW PARAMETER SEGMENT ```

<span>En el archivo [ejercicios de segmentos](segmentos.sql) se muestra a detalle como activar la creación de segmentos diferidos, como consultar los segmentos creados y algunos metadatos relacionados.</span>


// CREACION DE SEGMENTOS DIFERIDOS
// SELECT SEGMENT_CREATED, TABLE_NAME FROM USER_TABLES;
// DIFERENTES TIPOS DE SEGMENTOS QUE HAY EN LA BASE DE DATOS (TAREA)