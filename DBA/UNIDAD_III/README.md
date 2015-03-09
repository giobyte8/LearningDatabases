
<h1> Unidad III <br/> Configuración y administración del espacio en disco. </h1>

<h2> Tablespaces </h2>

  <p>
    Oracle almacena los datos de manera logica dentro de <i>Tablespaces</i>
    y de manera fisica utilizando <i>datafiles</i> asociados con su correspondiente tablespace.
  </p>
  <span><i>Cada datafile, se asocia con un y solo un tablespace.</i></span>

  ![Imagen de relación entre tablespaces y datafiles](img/tablespacesanddatafiles.gif)

  <br><span>Databases, tablespaces y datafiles mantienen una relación muy estrecha:</span>
  <ul>
    <li>Una base de datos Oracle consiste de al menos dos unidades de almacenamiento
      logico llamadas tablespaces, en los cuales, se almacena de manera colectiva todos
      los datos de la Database. Deberan existir al menos los tablespaces SYSTEM y SYSAUX.
    </li>
    <li>Cada tablespace en una base de datos Oracle consiste de uno o mas archivos llamados
      *datafiles*, que son estructuras fisicas almacenadas en el sistema operativo.
    </li>
    <li>Toda la información de la base de datos es almacenada en datafiles que conforman
      cada uno de los tablespaces de la base de datos.
    </li>
  </ul>

  <span><i>Puede consultar mas detalles sobre tablespaces, datafiles y Control files en
    la [documentación oficial.]
    (http://docs.oracle.com/cd/B28359_01/server.111/b28318/physical.htm#CNCPT003)
  </i></span>

  <h4>Creando tablespaces</h4>
  <p>
    En oracle, los tablespaces son creados mediante el comando: `CREATE TABLESPACE`,
    pasando como parametros: el nombre del tablespace, la ruta donde se almacenara y
    el tamaño que tendra el nuevo tablespace.
  </p>
  ```sql
  CREATE TABLESPACE <nombre-tablespace> DATAFILE '/ruta/al/tablespace' SIZE 5M;
  ```
  <span>
    En el [archivo de ejercicios](tablespaces.sql) se muestra detalladamente como crear tablespaces de diferentes tamaños, tanto en el disco local como en discos externos.
  </span>

<br>
<h2> Particiones </h2>
  <p>
	  El particionamiento de tablas permite que una tabla sea subdividida en piezas mas pequeñas, donde cada pieza es llamada: 'Partición'.
  </p>

  <h4> Cuando particionar una tabla. </h4>
	<ul>
    <li>Las tablas de más de 2 GB deben ser consideradas para particionarse</li>
    <li>Tablas con datos históricos. (Podriamos almacenar los de cada semana/mes/año en una partición diferente.)
		</li>
		<li>Cuando el contenido de una tabla debe distribuirse en diferentes medios de     almacenamiento.
		</li>
  </ul>

  <h4> Ventajas del particionamiento </h4>
	<ul>
		<li>Reduce tiempo inactividad en mantenimiento, mientras se mantienen unas particiones, otras siguen disponibles al usuario.
		</li>
		<li>Reduce tiempo de inactividad por falta de datos. (La falta de una partición no afecta a las demas).
		</li>
		<li>Independencia de partición, permite el uso concurrente de varias particiones para diversos fines.
		</li>
	</ul>

  <h4>Llaves particionadas</h4>
	<p>
	  Dentro de una tabla particionada, cada fila corresponde exclusivamente a una particion (Solo una), <i>la llave de particionamiento</i> se compone de una o mas columnas que determinan a que partición pertenece cada fila.
	</p>

  <h4> Tipos de particiones </h4>
  <ul>
    <li>Range partitions:</li>
    <li>List partitions</li>
    <li>Hash partitions</li>
  </ul>
  <h6>Particiones por rango</h6>
	<p>
	  El particionamiento por rango mapea datos a particiones basandose en el rango de valores de la llave de particionamiento que usted establece para cada partición, es el tipo de partición mas comun y es usado frecuentemente con fechas. Por ejemplo, para almacenar los datos de cada mes en una partición separada.
	</p>
	<h6>Particiones por lista</h6>
	<p>
	  Permite indicar especificamente que valores iran a cada partición de la tabla indicando una lista de valores discretos validos para cada partición. Este tipo de particionamiento es muy util cuando los datos para una partición no se pueden indicar a través de un rango, por ejemplo para almacenar en una partición los datos de Norteamerica, entrarian en la lista solo los valores 'México', 'USA' y 'Canada'.
  </p>

  <h6>Particiones hash</h6>
	<p>
	  Este tipo de particionamiento distribuye los datos de manera uniforme a través de todas las particiones, dando aproximadamente el mismo tamaño a cada partición. Es muy util para distribuir datos uniformemente a través de diferentes medios de almacenamiento. Especialmente cuando los datos no tienen una llave de particionamiento obvia para distribuirse.
	</p>

  <h6>Subparticiones</h6>
	<p>
	  El particionado compuesto o 'subparticionamiento', es una combinación de los metodos de distribución de datos ya mencionados. Una tabla es particionada por alguno de los tres metodos y luego cada partición es a su vez subdividida en particiones utilizando un segundo metodo.
	</p><br>

  <span>En el archivo: [Ejercicios de particionamiento](Particiones.sql), se muestra como crear y manipular cada uno de los tres tipos de particiones, particionar por multiples columnas y subparticionamiento. Tambien se muestra como consultar metadatos sobre tablas particionadas (Cuantas particiones hay, como se llaman, que datos almacenan, a que tablespace pertenecen etc...</span>

  <span>Puede consultar la documentación oficial sobre el concepto de particionado en el enlace siguiente: [Conceptos de particionamiento](http://docs.oracle.com/cd/B28359_01/server.111/b32024/partition.htm).
	</span>


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


  <h2>Administración de tablespaces</h2>
  <h4>Locally Managed Tablespaces</h4>
  <p>
    Los tablespaces administrados localmente almacenan y administran toda la información correspondiente a los extents en el tablaspace a través de bitmaps. Lo cual proporciona los siguientes beneficios:
  </p>
  <ul>
    <li>Operaciones concurrentes rapidas. Asignación y desasignación de espacio modifica recursos administrados localmente.</li>
	<li>Rendimiento mejorado</li>
	<li>La asignación de espacio se simplifica, debido a que cuando se especifica la clausula ```AUTOALLOCATE``` la base de datos automaticamente elige el tamaño apropiado para cada extent.</li>
	<li>Reduce el contenido de las tablas del diccionario de datos</li>
	<li>No se generan registros de UNDO cuando ocurre una asignación o liberación</li>
	<li>No se requiere 'coalesce'</li>
  </ul>
  <p>
    Todos los tablespace, incluyendo el tablespace SYSTEM pueden ser localmente administrados. El paquete DBMS_SPACE_ADMIN proporcina procedimientos de mantenimiento para tablespaces localmente administrados.
  </p>

```sql
CREATE TABLESPACE USERTSPACE DATAFILE '/u01/oradata/userdata01.dbf' SIZE 500M EXTENT MANAGEMENT LOCAL UNIFORM SIZE 128K;
```
<span>Puede revisar la [documentación oficial](http://docs.oracle.com/cd/B28359_01/server.111/b28310/tspaces002.htm#ADMIN11360) sobre tablespaces localmente administrados para mas información</span>

  <br><h4>Tablespaces administrados por el diccionario de datos.</h4>
  <ul>
    <li>Los extents son administrados por el diccionario de datos</li>
	<li>Las tablas correspondientes son actualizadas cuando un extent es utilizado o liberado</li>
	<li>Cada segmento del tablspace puede tener una clausula diferente de almacenamiento.</li>
  </ul>
```sql
CREATE TABLESPACE TSPACE_DICTIONARY DATAFILE '/u01/oradata/userdata01.dbf' SIZE 500M EXTENT MANAGEMENT DICTIONARY DEFAULT STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);
```

  <br><h4>Migrando el tablespace SYSTEM a Locally managed</h4>
  <p>
    Utilize el paquete DBMS_SPACE_ADMIN para migrar el tablespace SYSTEM de administrado por diccionario a localmente administrado. La siguiente instrucción realiza la migración:
  </p>
```sql
EXECUTE DBMS_SPACE_ADMIN.TABLESPACE_MIGRATE_TO_LOCAL('SYSTEM');
```
  <span>Antes de realizar la migración deben cumplirse las siguientes condiciones:</span>
  <ul>
    <li>La base de datos debe tener un 'defaul temporary tablespace' que no sea SYSTEM</li>
	<li>No debe haber segmentos de ROLLBACK en el tablespace administrado por diccionario</li>
	<li>Deber haber al menos un segmento de ROLLBACK en linea en un tablespace localmente administrado, o si se utiliza administración de UNDO automatica, un tablespace de UNDO debe estar online.</li>
	<li>Todos los tablespaces que no sean el el tablespace que contiene el espacio de UNDO (el tablespace que contiene el segmento de ROLLBACK o el tablespace de UNDO) deben estar en modo READ-ONLY.</li>
	<li>El sistema debe estar en modo restringido</li>
	<li>Debe haber un respaldo en frio de la base de datos</li>
  </ul>
  <span>Todas estas condiciones, excepto el respaldo en frio, son forzadas por el procedimiento ```TABLESPACE_MIGRATE_TO_LOCAL```</span>
  <p>
    <b>NOTA:</b> Despues de que el tablespace de SYSTEM sea migrado a localmente administrado, cualquier tablespace administrado por diccionario no podra ponerse en read/write. Si necesita utilizar tablespaces administrados por diccionario en modo read/write, entonces Oracle recomienda que primero se migren dichos tablespaces a localmente administrados antes de migrar el tablespace SYSTEM.
  </p>

  <h4>Tablespace de UNDO</h4>
  <ul>
    <li>Se utiliza para almacenar los segmentos de UNDO</li>
	<li>No puede contener objetos de base de datos, esta reservado para datos de undo administrados por el systema.</li>
	<li>Es localmente administrado (locally managed)</li>
	<li>Solo puede utilizar las clausulas DATAFILE y EXTENT MANAGEMENT</li>
  </ul>
```sql
CREATE UNDO TABLESPACE UNDOTSPACE DATAFILE '/u01/oradata/undodata01.dbf' SIZE 40M;
```
   <span>Se puede crear mas de un tablespace de undo, pero solo uno puede estar activo en cualquier momento</span>

  <h4>Tablespaces temporales</h4>
  <ul>
    <li>Usados para operaciones de ordenamiento</li>
	<li>Pueden compartirse con multiples usuarios</li>
	<li>No puede contener ningun objeto permanente</li>
	<li>Se recomienda administrar los extents localmente (locally managed)</li>
  </ul>
```sql
CREATE TEMPORARY TABLESPACE TEMPTSPACE TEMPFILE '/u01/oradata/temp01.dbf' SIZE 20M EXTENT MANAGEMENT LOCAL UNIFORM SIZE 4M;
```
  <span>Se recomienda que UNIFORM SIZE sea un multiplo de SORT_AREA_SIZE para mejorar el rendimiento.</span>

  <h6>Default temporary tablespace</h6>
  <ul>
    <li>Especifica el tablespace temporal de la base de datos</li>
	<li>Puede ser creado utilizando: ```CREATE DATABASE``` | ```ALTER DATABASE``` </li>
	<li>No puede ser borrado hasta que no se defina uno nuevo</li>
	<li>No se puede poner fuera de linea si esta activo</li>
  </ul>

  <h6>Creando un default temporary tablespace</h6>
  <span>Durante la creacion de la base de datos</span>
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

  <br><span>Despues de haber creado la base de datos:</span>
```sql
ALTER DATABASE DEFAULT TEMPORARY TABLESPACE DEF_TEMP2;
```

  <br><span>Para encontrar el DEFAULT TEMPORARY TABLESPACE, puede revisar las propiedades de la base de datos</span>
  ```SELECT * FRO DATABASE_PROPERTIES;```


  <h4>Tablespaces en READ-ONLY</h4>
  <p>
    Poner un tablespace en modo READ-ONLY evita operaciones de escritura en los datafiles del tablespace, el proposito principal del modo READ-ONLY es evitar la necesidad de realizar respaldos y recuperacióñ de enormes porciones estaticas de la base de datos, tambien sirve como un modo de proteger datos historicos de modo que los usuarios no puedan modificarlos. Poner un tablespace en READ-ONLY evita updates sobre todas las tablas del tablespace sin importar el nivel de privilegios que tenga el usuario.
  </p>
  <ul>
    <li>Causan un checkpoint</li>
	<li>Los datos solo se accesan para operaciones de lectura</li>
	<li>Se puede hacer ```DROP``` de items tales como TABLAS o INDICES, pero NO SE PUEDEN CREAR O ALTERAR OBJETOS.</li>
	<li>Se pueden ejecutar instrucciones que alteren la descripción del archivo en el diccionario de datos tales como: ```ALTER TABLE```, ```ADD``` or ```ALTER TABLE ... MODIFY```, pero no se podra utilizar la nueva descripción hasta que el tablespace se ponga en READ/WRITE.</li>

```sql
ALTER TABLESPACE SOMETSPACE READ ONLY;
```

  <h4>Tablespaces en modo OFFLINE</h4>
  ...
  <ul>
   <li>No se puede acceder a los datos</li>
   <li>Los tablespaces siguientes no se pueden poner fuera de linea:
     <ul>
       <li> Tablespace de SYSTEM </li>
	   <li> Tablespaces con segmentos activos de UNDO </li>
	   <li> Tablespaces temporales </li>
	 </ul></li>
  </ul>

  <span>Para poner un tablespace fuera de linea:</span>
```sql
ALTER TABLESPACE SOMETSPACENAME OFFLINE;
```

  <span>Para volver a poner ONLINE un tablespace que esta en OFFLINE</span>
```sql
ALTER TABLESPACE SOMETSPACENAME ONLINE;
```

  <h4>Adminnistrando la configuración de almacenamiento</h4>
  <span>Utilizando el comando ```ALTER TABLESPACE``` para cambiar configuraciones de almacenamiento</span>
```sql
ALTER TABLESPACE SOMETSPACE MINIMUM EXTENT 2M;
```

```sql
ALTER TABLESPACE SOMETSPACE DEFAULT STORAGE (INITIAL 2M NEXT 2M MAXEXTENTS 999);
```
  <br><span>Las configuraciones de almacenamiento para administración local no pueden ser modificadas.</span>

  <h6>Redimensionando un tablespace</h6>
  <ul>
    <li>Cambiar el tamaño del DATAFILE
	  <ul>
	    <li>Automáticamente usando ```AUTOEXTEND```</li>
		<li>Manualmente usando ```ALTER DATABASE```</li>
	  </ul></li>
	<li>Agregando un DATAFILE mediante ```ALTER TABLESPACE```</li>
  </ul>

  <h6> Habilitando la extensión automatica de DATAFILES </h6>
  <p>
    Se puede realizar de automáticamente durante los comandos: ```CREATE DATABASE``` ```CREATE TABLESPACE``` ```ALTER TABLESPACE ... ADD DATAFILE```
  </p>
```sql
CREATE TABLESPACE SOMETSPACE DATAFILE '/u01/oradata/userdata01.dbf' SIZE 200M AUTOEXTEND ON NEXT 10M MAXSIZE 500M;
```
  <p>
    Consulte la vista ```DBA_DATA_FILES``` para determinar cuando ```AUTOEXTEND``` esta habilitado.
  </p>

  <h6>Cambiando el tamaño de un DATAFILE manualmente</h6>
  <ul>
    <li> Manualmente incrementando o decrementando el tamaño de un datafile usando ```ALTER DATABASE```.</li>
	<li> Agregando espacio a un DATAFILE (sin crear nuevos DATAFILES) </li>
  </ul>
```sql
ALTER DATABASE DATAFILE '/u03/oradata/somedata02.dbf' RESIZE 200M;
```

  <h6>Agregando DATAFILES a un tablespace</h6>
  <ul>
    <li>Incrementar el tamaño del tablespace añadiendo datafiles</li>
	<li>A través de la sentencia ADD DATAFILE</li>
  </ul>
```sql
ALTER TABLESPACE usertspace ADD DATAFILE '/u03/oradata/userdata03.dbf' SIZE 30M;
```

  <h4>Metodos para mover tablespaces</h4>

  <h6>Para tablespaces que no sean SYSTEM</h6>
  <p>
    A través del comando ```ALTER TABLESPACE```.
	<ul>
	  <li>El tablespace debe estar en modo OFFLINE</li>
	  <li>Se debe copiar el DATAFILE al destino antes de ejecutar el comando</li>
	</ul>
  </p>
```sql
ALTER TABLESPACE usertspace RENAME DATAFILE '/u01/oradata/usertspace01.dbf' TO '/u02/oradata/usertspace01.dbf';
```

  <h6>Tablespace de SYSTEM</h6>
  <p>
    A través del comando ```ALTER TABLESPACE```. Con ciertas condiciones:
	<ul>
	  <li>La base de datos debe estar en MOUNT</li>
	  <li>La fuente del DATAFILE debe existir</li>
	</ul>
  </p>
```sql
ALTER DATABASE RENAME FILE '/u01/oradata/system01.dbf' TO '/u03/oradata/system01.dbf';
```

  <h4>Borrando tablespaces</h4>
  <ul>
    <li>En los siguientes casos NO SE PUEDE BORRAR un tablespace:
	  <ul>
	    <li>Si es el tablespace de SYSTEM</li>
		<li>Si tiene segmentos activos</li>
	  </ul></li>
	<li>La clausula ```INCLUDE CONTENTS``` borra los segmentos.</li>
	<li>```INCLUDING CONTENTS AND DATAFILES``` borra los segmentos y los datafiles.</li>
	<li>```CASCADE CONSTRAINS``` borra todas las restricciones de integridad referencial.</li>
  </ul>
```sql
DROP TABLESPACE usertspace INCLUDING CONTENTS AND DATAFILES;
```

  <h2>Administrando tablespaces utilizando OMF</h2>
  <p>
    <b>Oracle Managed Files (OMG)</b> Es un servicio que automatiza la creación, nombramiento, localización y eliminación de archivos de base de datos tales como archivos de control, logs de REDO, datafiles entre otros, basado en algunos parametros de inicialización. Este servicio puede simplificar muchos aspectos de la administración de base de datos eliminando la necesidad de implementar sus propias politicas para dichas tareas.
  </p>

  <ul>
    <li>Defina el parametro ```DB_CREATE_FILE_DEST```, por alguno de los siguientes metodos:
	  <ul>
	    <li>En el archivo de inicialización de parametros</li>
		<li>Definiendolo de forma dinamica con ```ALTER SYSTEM```:
```sql
ALTER SYSTEM SET DB_CREATE_FILE_DEST = '/u02/oradata/dba_orcl';
```</li></ul></li>
    <li>Cuando se crea el tablespace:</li>
	  <ul>
	    <li>El archivo DATAFILE es creado automáticamente y almacenado en la ruta DB_CREATE_FILE_DEST.</li>
		<li>El tamaño por default es 100M</li>
		<li>AUTOEXTEND es definido como UNLIMITED</li>
	  </ul>

  <h4>Operaciones con tablespaces utilizando OMF</h4>
  <br><span>-- Creando un tablespace</span>
```sql
CREATE TABLESPACE USERTSPACE DATAFILE SIZE 20M;
```

  <br><span>-- Agregando un DATAFILE OMF a un tablespace existente</span>
```sql
ALTER TABLESPACE usertspace ADD DATAFILE;
```

  <br><span>--Cambiando dinamicamente la localización por default del archivo:</span>
```sql
ALTER SYSTEM SET DB_CREATE_FILE_DEST = '/u01/oradata/db01';
```

  <br><span>-- Borrando un tablespace incluyendo los archivos del sistema operativo</span>
```sql
DROP TABLESPACE usertspace INCLUDING CONTENTS AND DATAFILES;
```

  <h2>Obteniendo información sobre tablespaces</h2>
  <span>Consultando los siguientes objetos:</span>
  <ul>
    <li>Información del tablespace</li>
	  <ul>
	    <li>DBA_TABLESPACES</li>
		<li>V$TABLESPACE</li>
	  </ul>
	<li>Información de los datafiles</li>
	  <ul>
	    <li>DBA_DATA_FILES</li>
		<li>V$DATAFILE</li>
	  </ul>
	<li>Información de los archivos temporales</li>
	  <ul>
	    <li>DBA_TEMP_FILES</li>
		<li>V$TEMPFILE</li>
	  </ul>



// CREACION DE SEGMENTOS DIFERIDOS
// SELECT SEGMENT_CREATED, TABLE_NAME FROM USER_TABLES;
// DIFERENTES TIPOS DE SEGMENTOS QUE HAY EN LA BASE DE DATOS (TAREA)