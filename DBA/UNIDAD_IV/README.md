#Operación y mantenibilidad

##Contenido
 * [Bitacoras](#bitacoras)
   * [Funciones especificas de las bitacoras](#funciones-especificas-de-las-bitacoras)
 * [Redo Log](#redo-log)
   * [Contenido de un Redo Log](#contentido-de-un-redo-log)
   * [Como oracle database escribe al Redo Log](#como-oracle-database-escribe-al-redo-log)
   * [Redo Log File Activo (Actual) e inactivos](redo-log-file-activo-actual-e-inactivos)
   * [Log Switches y Log Sequence Numbers](#log-switches-y-log-sequence-numbers)
 * [Planificación del Redo Log](#planeaci%C3%B3n-del-redo-log)
   * Multiplexeo de los Redo Log Files
   * Colocando miembros del Redo Log en discos diferentes
   * Planeando el tamaño de los Redo Log Files
   * Planeando el tamaño de bloque de los Redo Log Files
   * Decidiendo el número de Redo Log Files
   * Controlando el Archive Lag
 * Grupos y miembros del redo log
   * Creando Redo Log Groups
   * Creando Redo Log Members
   * Reubicando y renombrando Redo Log Members
   * Dropping de Redo Log Groups y Members
 * Forzando Log Switches
 * Vistas del diccionario de datos para el REDO LOG
 * El modo **ARCHIVE LOG** y como activarlo
   * Que es el Archived Redo Log
   * NOARCHIVELOG vs ARCHIVELOG
   * Controlando el *archiving*
   * Consultando información sobre el Archived Redo Log
 * Practicas con Oracle 11GR2
   * Activando el Archived Redo Log paso a paso **(ARCHIVELOG)**
   * Activando el **multiplexeo** del Redo Log
   * Resolución de examen.
 * Referencias externas

##Bitacoras
En muchos DBMS la bitacora registra todo tipo de consultas realizadas incluyendo aquellas que no modifican los datos. La operación ROLLBACK esta basada en el uso de una bitacora.

EL DBMS mantiene una bitacora o diario donde se registran los detalles de todas las operaciones de actualización. En particular los valores inicial y final del objeto modificado. Esta bitacora puede estar almacenada en disco o en cinta.

Por lo tanto, si resulta necesario anular alguna modificación especifica el sistema puede utilizar la entrada correspondiente de la bitacora para restaurar el valor original del objeto.

###Funciones especificas de las bitacoras
**La estructura mas usada para grabar las modificaciones de la base de datos es la bitacora**

Cada registro de la bitacora representa una alteración a la base de datos y contiene lo siguiente:
 * Nombre de la transacción
 * Valor antiguo
 * Valor nuevo

Es fundamental que cada vez que **se realice una modificación** a la base de datos se cree un registro en la bitacora antes de que se genere la alteración en la base de datos.

Las operaciones **COMMIT** y **ROLLBACK** establecen lo que se conoce como **punto de sincronización** lo cual representa el limite entre una transacción y otra o el final de una unidad lógica de trabajo.

Las unicas operaciones que establecen un **punto de sincronización** son **COMMIT**, **ROLLBACK** y el **inicio de un programa**

##REDO Log
La estructura crucial para operaciones de recuperación de la base de datos es el **redo log**, que consiste de dos o mas archivos preasignados para almacenar todos los cambios hechos a la base de datos conforme ocurren. Toda instancia de la base de datos Oracle, tiene un redo log asociado para proteger la base de datos en caso de alguna falla de la instancia.


###Contentido de un REDO Log

Los archivos de REDO estan llenos de **registros redo** , un registro redo se compone de un grupo de **vectores de cambio**, cada uno de los cuales es la descripción de un cambio hecho a un (y solo un) bloque en la base de datos. Por ejemplo, si se cambia el valor del campo ```SALARY``` en la tabla ```EMPLOYEE```, se genera un *registro redo* que contiene los vectores de cambio que describen los cambios a el bloque de segmento de datos de la tabla, el bloque de segmento de datos de undo y la tabla de transacción de los segmentos de undo.

Los *registros redo* almacenan información que se puede utilizar para reconstruir todos los cambios hechos a una base de datos,  incluyendo segmentos de undo. Por lo tanto, el redo Log también proteje datos de ROLLBACK. Cuando se recupera la base de datos utilizando datos de redo, la base de datos lee los vectores de cambio en los registros redo y se aplican los cambios a los bloques reelevantes.

Los *registros redo* son almacenados de manera circular en el **redo log buffer** de la SGA (System Global Area) y son escritos a uno de los archivos *redo log* por un proceso en segundo plano denominado **Log Writer(LGWR)**. Cada vez que una transacción es *Committed* (Confirmada | Asegurada), LGWR escribe los registros redo de la transacción desde el redo log buffer a un redo log file y asigna un **system change number (SCN)** para identificar los registros redo de cada transacción confirmada. Solo cuando todos los registros redo asociados con la transacción estan seguros en disco dentro de los *logs online* se notifica al proceso del usuario que la transacción ha sido *committed | confirmada | asegurada*.

Los registros redo también pueden ser escritos a un redo log file antes de que la transacción correspondiente sea committed/confirmada, si el redo log buffer se llena u otra transacción es committed/confirmada, LGWR vacia todos los registros de redo en el redo log buffer hacia un redo log file, incluso aunque algunos registros redo no hayan sido committed/confirmados, si es necesario la base de datos puede hacer ROLLBACK de esos cambios.

###Como Oracle database escribe al Redo Log

El *redo log* de una base de datos consiste de dos o más *redo log files*. La base de datos requiere un minimo de dos archivos para garantizar que uno este siempre disponible para escritura mientras el otro esta siendo archivado. (Si la base de datos esta en modo **ARCHIVELOG**).

LGWR escribe en los redo log files de manera circular, cuando el actual redo log file se llena, LGWR comienza a escribir en el siguiente redo log file disponible. Cuando el último redo log file disponible se llena, LGWR regresa al primer redo log file y escribe en el, inciando de nuevo el ciclo.

Los redo log files que ya estan llenos, se hacen disponibles para ser reutilizados dependiendo de si el *archiving* esta habilitado o no:

 * Si la base de datos esta en modo **NOARCHIVELOG**, un redo log file que ya esta lleno se hace disponible despues de que los cambios registrados en él ya han sido escritos a los datafiles.
 * Si la base de datos esta en modo **ARCHIVELOG**, un redo log file lleno se hace disponible para el LGWR despues de que los cambios registrados en el han sido escritos a los datafiles **Y** después de que el redo log file ha sido archivado.


**Uso circular de los Redo Log Files por LGWR:**

*Los números del lado derecho indican el orden en que LGWR escribe a cada archivo en cada ciclo.*

![Reuse of Redo Log Files by LGWR](http://i.imgur.com/tN0dJZi.gif)


###Redo Log File Activo (Actual) e inactivos

Oracle utiliza solo un redo log file al momento de almacenar registros redo escritos desde el redo log buffer. Al redo log file al que LGWR esta activamente escribiendo es llamado el **current** redo log file.

Los redo log files requeridos para la recuperación de la instancia son llamados **active** redo log files. Los redo log files que ya no son necesarios para la recuperación de la instancia son llamados **inactive** redo log files.

Si la base de datos esta en modo **ARCHIVELOG**, entonces no se puede reutlizar o sobreescribir un log file *activo online* hasta que uno de los procesos archivadores en segundo plano (ARCn) haya archivado sus contenidos. Si la base de datos esta en modo **NOARCHIVELOG**, entonces cuando el último redo log file esta lleno, LGWR continua sobreescribiendo el siguiente log file en la secuencia cuando este se vuelve inactivo.

###Log Switches y Log Sequence Numbers

Un **Log Switch** es el punto en el cual la base de datos deja de escribir a un redo log file y comienza a escribir en otro. Normalmente, un **log switch** ocurre cuando el redo log file current/actual esta completamente lleno y la escritura debe continuar al siguiente redo log file. Sin embargo, se puede configurar que un log switch ocurra en intervalos regulares, independientemente de si el actual redo log file esta completamente lleno o no. También se pueden forzar **log switches** manualmente.

Oracle asigna a cada redo log file un nuevo **log sequence number** cada vez que  un log switch ocurre y LGWR comienza a escribir a redo log file. Cuando la base de datos archiva los redo log files, el log archivado mantiene su *log sequence number*.

Cada redo log file online o archivado es identificado como unico mediante su log sequence number. Durante una falla critica, para la recuperación la instancia aplica los redo log files en orden ascendente usando el **log sequence number** de los redo log files necesarios.


##Planeación del Redo Log

Considere las directrices aqui mencionadas durante la planeación del redo log de una instancia de base de datos. Consulte los siguientes topicos:

 * Multiplexeo de los Redo Log Files
 * Colocando miembros del Redo Log en discos diferentes
 * Planeando el tamaño de los Redo Log Files
 * Planeando el tamaño de bloque de los Redo Log Files
 * Decidiendo el número de Redo Log Files
 * Controlando el Archive Lag

###Multiplexeo de los Redo Log Files

Para proteger contra una falla que involucre al redo log mismo. Oracle permite un redo log **multiplexado**, lo que significa que dos o más copias identicas de el redo log pueden ser automaticamente mantenidas en ubicaciones diferentes. Para obtener el mayor beneficio, dichas ubicaciones deberían permanecer en discos diferentes. Pero incluso aunque todas las copias del redo log esten en el mismo disco, la redundancia ayuda a proteger contra errores de I/O, corrupción de archivos, etc, *eliminando un solo punto de falla del redo log*.

El **multiplexeo** se implementa definiendo grupos de redo log files. Un **grupo** consiste de un redo log file y sus copias multiplexadas. Cada copia identica se dice ser un **member/miembro** del grupo. Cada grupo de redo log se define por un número, tales como *group1, group2, group3 ...* y así sucesivamente.

**Redo Log Files multiplexados:**

![Redo Log Files multiplexados](http://i.imgur.com/FI6gna3.gif)

En la figura ```A_LOG1``` y ```B_LOG1``` son miembros del group1. ```A_LOG2``` y ```B_LOG2``` son miembros del group2. Los miembros de un grupo deben tener el mismo tamaño.

Cada miembro de un log file group es concurrentemente activo, o sea, concurrentemente escrito por el LGWR, como se indica por los log sequence numbers identicos asignados por el LGWR. En los grupos de la imagen, primero el LGWR escribe concurrentemente tanto a ```A_LOG1``` y ```B_LOG1```. Después escribe concurrentemente a ```A_LOG2``` y ```B_LOG2``` y asi sucesivamente. LGWR nunca escribe concurrentemente a miembros de grupos diferentes (Como por ejemplo ```A_LOG1``` y ```B_LOG2```).

> **NOTA**
> Oracle recomienda multiplexar el redo log de la base de datos. La perdida de los datos del redo log puede ser catastrofica en caso de requerir un recovery. Notese que cuando se multiplexea el redo log aumenta el monto de operaciones I/O de la base de datos. Dependiendo de la configuración esto podría impactar en el rendimiento.

*Consulte la sección [activando el multiplexeo del redo log]() para un detallado paso a paso.*

###Colocando miembros del Redo Log en discos diferentes

Cuando se activa un redo log multiplexado. Situe a los miembros de un grupo en discos fisicos diferentes. Si un disco falla entonces solo un miembro del grupo se hace no disponible al LGWR y el resto de los miembros permancen disponibles, de manera que la instancia continua su funcionamiento.

Los Datafiles deberían también ser colocados en discos diferentes a los redo log files para reducir la contención en la escritura de *data blocks* y *redo records*.

###Planeando el tamaño de los Redo Log Files.
Cuando se asigne el tamaño de los redo log files, considere si se archivara el redo log. Los redo log files deberían ser de cierto tamaño a modo de que un grupo lleno pueda ser archivado a una sola unidad de almacenamiento offline (cinta o disco). dejando el menor monto posible de espacio sin usar en el dispositivo externo.

Todos los miembros del grupo deben ser del mismo tamaño, miembros de grupos diferentes pueden tener diferentes tamaños, sin embargo, no hay ninguna ventaja en variar el tamaño entre grupos. Si los checkpoints no estan configurados para ocurrir entre log switches, haz todos los grupos del mismo tamaño para garantizar que los checkpoints ocurran en intervalos regulares.

*El tamaño minimo permitido para un redo log file es de 4MB*

###Planeando el tamaño de bloque de los Redo Log Files
A diferencia de el *database block size*, que puede ser de entre 2K y 32K, los redo log files siempre tienen por default un tamaño de bloque igual al tamaño fisico de sector del disco, historicamente este ha sido de 512 bytes.

Revise la [documentación oficial](http://docs.oracle.com/cd/E11882_01/server.112/e25494/onlineredo.htm#ADMIN12891) para más información sobre el tamaño de bloque de los redo log files.

###Decidiendo el número de Redo Log Files
La mejor manera de determinar el número apropiado de redo log files para una instancia es probar con diferentes configuraciones. La configuración optima tiene el menor número de grupos posible sin obstaculizar al LGWR para escribir información al redo log.

Revise la [documentación oficial](http://docs.oracle.com/cd/E11882_01/server.112/e25494/onlineredo.htm#ADMIN11314) para más información sobre el número de archivos redo.

###Controlando el Archive Lag
Se puede forzar a que todos los hilos de redo habilitados switcheen sus *current logs* a intervalos de tiempo regulares. En una configuración primary/standby, los cambios se hacen disponibles a la *standby database* archivando los redo logs en el *primary site* y luego enviandolos a la *standby database*.

Revise la [documentación oficial](http://docs.oracle.com/cd/E11882_01/server.112/e25494/onlineredo.htm#ADMIN11315) para más información sobre el 'Archive Lag'.

##Grupos y miembros del Redo Log

Planee el redo log de la base de datos y cree todos los grupos y miembros necesarios durante la creación de la base de datos, sin embargo, podría haber situaciones donde se necesite crear grupos o miembros adicionales. Por ejemplo, agregar grupos a un redo log puede corregir problemas de disponibilidad de rego log groups.

Para crear redo log groups y members, se requiere el privilegio ```ALTER DATABASE```. Una base de datos puede tener hasta ```MAXLOGFILES``` groups.

###Creando Redo Log Groups

Para crear un nuevo grupo de redo log files, utilice la instrucción ```ALTER DATABASE``` junto con la clausula ```ADD LOGFILE```.

La siguiente sentencia agrega un nuevo grupo de redo log files a la base de datos:
```SQL
ALTER DATABASE ADD LOGFILE ('/oracle/dbs/log1c.rdo', 'oracle/dbs/log2c.rdo') SIZE 100M;
```

También se puede especificar el número que identifica al grupo mediante la clausula ```GROUP```:
```SQL
ALTER DATABASE ADD LOGFILE GROUP 10 ('/oracle/dbs/log1c.rdo', '/oracle/dbs/log2c.rdo') SIZE 100M BLOCKSIZE 512;
```

Utilice números de grupo consecutivos para no utilizar espacio inecesario en los *control files* de la base de datos.

En la sentencia anterior la clausula ```BLOCKSIZE``` es opcional.

###Creando Redo Log Members

En algunos casos podría no ser necesario crear un grupo completo de Redo Log Files. Podría ya existir un grupo pero no estar completo debido a que uno o más archivos fueron *dropped* o debido a una falla de disco. En este caso, se pueden agregar nuevos miembros a un grupo existente.

Para crear nuevos miembros para un grupo existente se utiliza la clausula ```ALTER DATABASE``` junto con ```ADD LOGFILE MEMBER```. La siguiente sentencia agrega un nuevo redo log file al redo log group número 2.

```sql
ALTER DATABASE ADD LOGILE MEMBER '/oracle/dbs/log2b.rdo' TO GROUP 2;
```

Notese que los nombres de los miembros nuevos deben ser especificados, pero no neccesariamente el tamaño de los mismos. El tamaño de los miembros nuevos es determinado en base al de los miembros existentes en el grupo.

Cuando se utiliza la sentencia ```ALTER DATABASE``` alternativamente se puede también identificar el grupo destino especificando todos los miembros del grupo en la clausula ```TO```, como se muestra en el siguiente ejemplo:

```SQL
ALTER DATABASE ADD LOGFILE MEMBER '/oracle/dbs/log2c.rdo' TO ('/oracle/dbs/log2a.rdo', '/oracle/dbs/log2b.rdo');
```

> ** NOTA **
> Podría notarse que el status del nuevo log member se muestra como ```INVALID```. Esto es normal y sera cambiado a activo (blank) cuando sea usado por primera vez.

###Reubicando y renombrando Redo Log Members

Se pueden utilizar comandos del sistema operativo para mover los redo logs, luego mediante la clausula ```ALTER DATABASE``` informar a la base de datos sobre los nuevos nombres/ubicación de los archivos. Este procedimiento es necesario por ejemplo, si el disco actualmente usado para algunos redo log files va a ser inhabilitado permanentemente o si los data files y varios redo log files permancen en el mismo disco y van a ser separados para reducir la contención.

Para renombrar miembros del redo log se requiere el privilegio ```ALTER DATABASE```. Adicionalmente se deben tener permisos en el sistema operativo para poder copiar los archivos al destino y privilegios para abrir y respaldar la base de datos.

Antes de reubicar los redo log files, o realizar cualquier otro cambio estructural a la base de datos, se debe respaldar completamente la base de datos en caso de experimentar problemas mientras se realizan las operaciones. Como precaución despues de renombrar o reubicar un monto de redo log files, respalde inmediatamente el *control file* de la base de datos.

Utilice los siguientes pasos para reubicar redo logs. El ejemplo utilizado para ilustrar los pasos asume lo siguiente:

 * Los log files estan ubicados en dos discos ```diska``` y ```diskb```.
 * El redo log esta duplexado, un grupo consiste de los miembros: ```/diska/logs/log1a.rdo``` y ```/diskb/logs/log1b.rdo```, y el segundo grupo se conforma por los miembros ```/diska/logs/log2a.rdo``` y ```/diskb/logs/log2b.rdo```.
 * Los redo log files ubicados en el ```diska``` deben ser reubicados al ```diskc```. Los nuevos nombre de archivos reflejaran la nueva ubicación: ```/diskc/logs/log1c.rdo``` y ```/diskc/logs/log2c.rdo```.

** Pasos para renombrar los redo log files **

1. Dar de baja la base de datos: ```SHUTDOWN```
2. Copiar los redo log files a la nueva ubicación mediante comandos del sistema operativo.
   ```mv /diska/logs/log1a.rdo /diskc/logs/log1c.rdo```
   ```mv /diska/logs/log2a.rdo /diskc/logs/log2c.rdo```
3. Iniciar la base de datos, poner en mount, pero no en open.
```SQL
CONNECT / as SYSDBA
STARTUP MOUNT
```
4. Renombrar los redo log members.
   Utilizar el comando ```ALTER DATABASE``` junto con ```RENAME FILE``` para renombrar.
```SQL
ALTER DATABASE 
  RENAME FILE '/diska/logs/log1a.rdo', '/diska/logs/log2a.rdo' 
           TO '/diskc/logs/log1c.rdo', '/diskc/logs/log2c.rdo';
```

5. Abrir la base de datos para operación normal.
   Las alteraciones al redo log toman efecto cuando la base de datos es abierta.
```SQL
ALTER DATABASE OPEN;
```

###Dropping de Redo Log Groups y Members

En algunos casos se requiere eliminar un grupo entero de redo log members. Por ejemplo, para reducir el número de grupos en el redo log de una instancia. En una situación diferente podría requerirse eliminar uno o mas miembros especificos de un grupo, posiblemente debido a una falla de disco de modo que la base de datos no intente escribir a los archivos inaccesibles. En otras situaciones algunos redo log files podrían volverse inecesarios, por ejemplo, un archivo podría estar almacenado en una ubicación erronea.

####Dropping Log Groups
Para eliminar un redo log group se requiere el privilegio ```ALTER DATABASE```, antes de eliminar un redo log group considere las siguientes limitaciones y precauciones:

 * Una instancia requiere al menos dos grupos de redo log files, independientemente del número de miembros en cada grupo.
 * Solo se puede eliminar un redo log group si este esta inactivo. Si se desea eliminar el *current group* force primero un *log switch*.
 * Asegurese de que un redo log group este archivado (Si el 'archiving' esta habilitado) antes de eliminarlo. Para comprobar esto revise la vista ```V$LOG```.
```SQL
SELECT GROUP#, ARCHIVED, STATUS FROM V$LOG;
```
       GROUP# ARC STATUS
            1 YES ACTIVE
            2 NO  CURRENT
            3 YES INACTIVE
            4 YES INACTIVE

Elimine un redo log group mediante la clausula ```ALTER DATABASE``` junto con ```DROP LOGFILE```.

La siguiente sentencia elimina el redo log group número 3:

```SQL
ALTER DATABASE DROP LOGFILE GROUP 3;
```

*Cuando se elimina un redo log group de la base de datos y no se esta utilizando Oracle Managed Files, los archivos no son eliminados del sistema operativo. Después de eliminar un redo log group, asegurese de eliminar los redo log files mediante comandos del sistema.*

*Cuando se utiliza Oracle Managed Files, esta tarea es realizada automaticamente*

####Dropping Redo Log Members

Se requiere el privilegio ```ALTER DATABASE``` para eliminar un miembro de algun redo log group. Considere los siguiente antes de eliminar un redo log member:

 * It is permissible to drop redo log files so that a multiplexed redo log becomes temporarily asymmetric. For example, if you use duplexed groups of redo log files, you can drop one member of one group, even though all other groups have two members each. However, you should rectify this situation immediately so that all groups have at least two members, and thereby eliminate the single point of failure possible for the redo log.
 * An instance always requires at least two valid groups of redo log files, regardless of the number of members in the groups. (A group comprises one or more members.) If the member you want to drop is the last valid member of the group, you cannot drop the member until the other members become valid. To see a redo log file status, use the ```V$LOGFILE``` view. A redo log file becomes ```INVALID``` if the database cannot access it. It becomes ```STALE``` if the database suspects that it is not complete or correct. A stale log file becomes valid again the next time its group is made the active group.
 * You can drop a redo log member only if it is not part of an active or current group. To drop a member of an active group, first force a log switch to occur.
 * Make sure the group to which a redo log member belongs is archived (if archiving is enabled) before dropping the member. To see whether this has happened, use the V$LOG view.

Para eliminar un redo log member especifico utilice la clausula ```ALTER DATABASE``` junto con ```DROP LOGFILE MEMBER```. La siguiente instruccion elimina el redo log ```/oracle/dbs/log3c.rdo```:

```SQL
ALTER DATABASE DROP LOGFILE MEMBER '/oracle/dbs/log3c.rdo';
```

Cuando se elimina un redo log member, el archivo de sistema operativo no es eliminado del disco, solamente se actualizan los ```control files``` de la base de datos para eliminar el member de la estructura de la base de datos. Utilice comandos del sistema operativo para eliminar el redo log file.

Para eliminar un miembro de un grupo activo, primero se debe forzar un ```log switch```.

##Forzando Log Switches

Un Log Switch ocurre cuando el LGWR deja de escribir en un redo log group y comienza a escribir en otro. Por default un Log Switch ocurre automaticamente cuando el *current redo log file group* se llena.

Se puede forzar un Log Switch para hacer inactivo el grupo actualmente activo para operaciones de mantenimiento del redo log. Por ejemplo, si se desea eliminar el redo log group actual pero no es posible hasta que el grupo este inactivo o si el redo log group actual debe ser archivado en un momento especifico antes de estar completamente llenos los redo log files. Esta configuración es util en redo logs con enormes redo log files que tardan demasiado tiempo en llenarse.

Para forzar un **Log Switch** se debe tener el privilegio ```ALTER SYSTEM```. Uselo junto con ```SWITCH LOGFILE```. La siguiente sentencia forza un ** Log Switch **:

```SQL
ALTER SYSTEM SWITCH LOGFILE;
```

##Vistas del diccionario de datos para el REDO LOG

Las siguientes vistas propircionan información sobre Redo Logs.

| Vista             | Descripción                                                      |
|-------------------|------------------------------------------------------------------|
| ```V$LOG```       | Muestra la información sobre el redo log file del control file   |
| ```V$LOGFILE```   | Identifica redo log groups y member y el status de los members   |
|```V$LOGHISTORY``` | Contiene información del log history                             |

El siguiente query muestra la información del control file sobre el redo log de una base de datos.

```SQL
SELECT * FROM V$LOG;
```
    GROUP# THREAD#   SEQ   BYTES  MEMBERS  ARC STATUS     FIRST_CHANGE# FIRST_TIM
    ****** ******* ***** *******  *******  *** *********  ************* *********
         1       1 10605 1048576        1  YES ACTIVE          11515628 16-APR-00
         2       1 10606 1048576        1  NO  CURRENT         11517595 16-APR-00
         3       1 10603 1048576        1  YES INACTIVE        11511666 16-APR-00
         4       1 10604 1048576        1  YES INACTIVE        11513647 16-APR-00

Para ver los nombres de todos los miembros de un grupo, utilice un query similar al siguiente:

```SQL
SELECT * FROM V$LOGFILE;
```

    GROUP#   STATUS  MEMBER
	------  -------  ----------------------------------
         1           D:\ORANT\ORADATA\IDDB2\REDO04.LOG
         2           D:\ORANT\ORADATA\IDDB2\REDO03.LOG
    	 3           D:\ORANT\ORADATA\IDDB2\REDO02.LOG
         4           D:\ORANT\ORADATA\IDDB2\REDO01.LOG

Si ```STATUS``` es *blank* para un miembro, entonces el archivo esta en uso.

## El modo ARCHIVELOG y como activarlo

### Que es el Archived Redo Log

Oracle database permite guardar uno o mas grupos de redo log files llenos a uno o mas destinos externos/offline, conocidos colectivamente como los ** archived redo log **. El proceso de convertir redo log files en *archived redo log files* es conocido como ** archiving ** este proceso solo es posible si la base de datos esta corriendo en ** modo **  ```ARCHIVELOG```. Se puede elgir ** archiving ** automatico o manual.

Un *archived redo log file* es una copia de uno de los miembros llenos de algún *redo log group*. Por ejemplo, si se multiplexea el redo log, y el group1 contiene archivos miembros identicos ```a_log1``` y ```b_log1```, entonces el proceso archivados ** (ARCn) ** archivara uno de esos archivos miembro. En caso de que el ```a_log1``` se corrompa, entonces *(ARCn)* seguira archivando ```b_log1``` que es una copia identica. El *archived redo log* contiene una copia identica de cada group creado desde que se activo el *archiving*.

Cuando la base de datos esta en modo ```ARCHIVELOG```, el proceso LGWR no puede reusar ni sobreescribir un redo log group hasta que este haya sido archivado. El proceso en segundo plano (ARCn) automatiza las operaciones de *archiving* cuando el *automatic archiving* esta habilitado. La base de datos inicia multiples procesos archivadores conforme son necesarios para garantizar que el archiveo de los redo log file llenos no falle en segundo plano.

Los ** archived redo logs ** se pueden utilizar para:

 * Recuperar una base de datos
 * Actualizar una standby database
 * Obtener información sobre el historial de la base de datos mediante la utilidad LogMiner

### NOARCHIVELOG vs ARCHIVELOG

La decisión de si activar o no el archiving de los redo log file groups llenos depende de los requerimientos de confiabilidad y disponibilidad de la aplicación que se ejecuta sobre la base de datos. Si no se puede permitir la perdida de datos en caso de la falla de algún disco, utilice el modo ```ARCHIVELOG```. El archiving de un redo log group lleno puede requerir de operaciones administrativas extra.

#### Corriendo una base de datos en modo NOARCHIVELOG

Cuando se ejecuta una base de datos en modo ```NOARCHIVELOG``` cada redo log group se vuelve disponible para reuso y sobreescritura despues de haber llenado y haber ocurrido un Log Switch.

El modo ```NOARCHIVELOG``` protege a la base de datos de una falla de instancia pero no de una falla de medios. Solo los cambios mas recientes hechos a la base de datos (Que permanecen en los redo log files en linea) pueden ser usados para recuperar la instancia.

En modo ```NOARCHIVELOG``` no se pueden realizar respaldos de tablespaces en modo online, no se pueden utilizar respaldos de tablespaces tomados anteriormente en modo ```ARCHIVELOG```. Para restaurar una base de datos corriendo en modo ```NOARCHIVELOG``` solo se pueden utilizar respaldos completos de TODA la base de datos tomados anteriormente mientras la base de datos estuvo cerrada. Por lo tanto si se decide operar la base de datos en modo ```NOARCHIVELOG``` se deben realizar respaldos completos en intervalos regulares y frecuentes.

#### Corriendo una base de datos en modo ARCHIVELOG

Cuando se ejecuta una base de datos en modo ```ARCHIVELOG``` el archivo de control de la base de datos indica que un redo log group lleno no puede ser reutilizado por el LGWR hasta que haya sido archivado completamente. Un redo log group se hace disponible para ser archivado justo despues de que ocurra un redo log switch.

El archiving de los redo log files llenos tiene ciertas ventajas:

 * Un respaldo de la base de datos, junto con los redo log files online y archivados, garantiza que se puede recuperar todas las transacciones que hayan sido *committed* en caso de alguna falla de disco o de sistema operativo.
 * Si se mantienen los logs archivados disponibles, se puede utilizar un respaldo tomado mientras la base de datos esta abierta y en operación normal.
 * Se puede mantener una *standby database* actualizada con su base de datos original aplicando continuamente los redo logs archivados originales al *standby*

Se puede configurar una instancia para archivar los redo log groups llenos automaticamente o se puede realizar manualmente. Por conveniencia y eficiencia se recomienda realizarlo de manera automatica.

La imagen ilustra como el proceso (ARCn) archiva los redo log groups llenos.
![ARCHIVING REDO LOG](http://i.imgur.com/CUXKJTJ.gif)

### Controlando el archiving

 * Asignando el modo inicial de archiving
 * Cambiando el modo de archiving de la base de datos
 * Realizando archiving manual
 * Ajustando el número de procesos de archiving

#### Asignando el modo inicial de archiving

Se realiza durante la creación de la base de datos ```CREATE DATABASE```. Usualmente se puede utilizar el modo default ```NOARCHIVELOG``` durante la creación de la base de datos, debido a que no hay necesidad de guardar la información generada durante este proceso.

#### Cambiando el modo de archiving de la base de datos

Se realiza mediante ```ALTER DATABASE``` junto con ```ARCHIVELOG``` o ```NOARCHIVELOG```. Para cambiar el modo de archiving se debe estar conectado a la base de datos con privilegios de administrador (```AS SYSDBA```).

Los siguientes pasos cambian el modo de archiving de ```NOARCHIVELOG``` a ```ARCHIVELOG```:

1. Dar de baja la instancia: ```SHUTDOWN IMMEDIATE```.
2. **Respaldar la base de datos**. Antes de realizar cualquier cambio mayor a la base de datos siempre respalde para protejer contra cualquier problema.
3. Edite el archivo de parametros de inicialización para incluir el parametro que especifica el destino para los redo log files archivados o hagalo desde la base de datos con una instrucción similar a: ```ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='location=C:archive_log_offline' SCOPE=SPFILE;```.
4. Inicie la instancia en modo ```MOUNT``` no ```OPEN```:
   ```STARTUP MOUNT```. Para habilitar o deshabilitar el archiving la DB debe estar montada pero no abierta.
5. Cambie el modo de archiving de la base de datos. Luego abra la base de datos para operaciones normales.
```SQL
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
```
6. Dar de baja la base de datos. ```SHUTDOWN IMMEDIATE```.
7. Respalde la base de datos.
   Cambiar el modo de archiving de la base de datos actualiza el control file. Despues de cambiar el modo de archiving se deben respaldar todos los datafiles y controlfiles. Cualquier respaldo anterior no sirve mas debido a que fue tomado en modo ```NOARCHIVELOG```.

#### Realizando archiving manual.

@TODO: Add brief overview from original source here.
[Documentación oficial](http://docs.oracle.com/cd/E11882_01/server.112/e25494/archredo.htm#ADMIN11336)

#### Ajustando el número de procesos de archiving.

El parametro de inicialización ```LOG_ARCHIVE_MAX_PROCESSES``` especifica el número de procesos ARCn que la base de datos arranca inicialmente. El default son 4 procesos.

La siguiente instrucción configura la base de datos para arrancar 6 ARCn procesos al iniciar.

```SQL
ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=6;
```

La instrucción también tiene un efecto inmediato sobre la instancia que esta en ejecución. Incremente o decrementa el número de procesos ARCn en ejecución a 6.

### Consultando información sobre el Archived Redo Log

Se puede ver información sobre el Archived Redo Log utilizando vistas dinamicas de rendimiento o mediante el comando ```ARCHIVE LOG LIST```.

** Vistas del Archived Redo Log **

| Vista dinamica de rendimiento | Descripción                                              |
|-------------------------------|----------------------------------------------------------|
| ```V$DATABASE```              | Muestra si la base de datos esta en ```ARHIVELOG``` o ```NOARCHIVELOG```, también indica se se ha especificado el modo ```MANUAL```.             |
| ```V$ARCHIVED_LOG```          | Muestra información historia sobre logs archivados       |
| ```V$ARCHIVE_DEST```          | Describe la instancia actual, los destinos de archive y el valor, modo y status actual de tales destinos                                              |
| ```V$ARCHIVE_PROCESSES```     | Muestra información sobre el estado de los procesos de archiving de la instancia.                                                                 |
| ```V$BACKUP_REDOLOG```        | Contiene información sobre cualquier respaldo de los logs archivados.                                                                                |
| ```V$LOG```                   | Muestra todos los redo log groups de la base de datos e indica cuales necesitan ser archivados.                                                    |
| ```V$LOG_HISTORY```           | Contiene información historica del log, tal como que logs han sido archivados y el rango SCN de cada log archivado.                                  |

Por ejemplo, el siguiente query muestra que redo log group requiere archiving:

```SQL
SELECT GROUP#, ARCHIVED FROM SYS.V$LOG;
```
    GROUP#     ARC
    --------   ---
           1   YES
           2   NO

Para ver el modo de archiving actual, consulte la vista ```V$DATABASE```:

```SQL
SELECT LOG_MODE FROM SYS.V$DATABASE;
```
    LOG_MODE
    ------------
    NOARCHIVELOG

### El comando ARCHIVE LOG LIST

Este comando muestra información sobre el modo de archiving de la instancia:

```SQL
ARCHIVE LOG LIST
```
    Database log mode              Archive Mode
    Automatic archival             Enabled
    Archive destination            D:\oracle\oradata\IDDB2\archive
    Oldest online log sequence     11160
    Next log sequence to archive   11163
    Current log sequence           11163

Esto nos da toda la información necesaria sobre la configuración del modo de archiving de la instancia. El resultado anterior indica que:

 * La base de datos esta en modo ```ARCHIVELOG```.
 * El modo *automatic archiving* esta habilitado
 * El destino del redo log archivado es: *D:\oracle\oradata\IDDB2\archive*
 * El redo log lleno mas antiguo tiene un número de secuencia de 11160
 * El siguiente redo log group llenado a archivar tiene un número de secuencia de 11163
 * El actual redo log file tiene un número de secuencia d 11163.


## Practicas con Oracle 11GR2

### Activando el Archived Redo Log paso a paso (ARCHIVELOG)

* Comprobamos cual es el estado actual de la base de datos:
```SQL
ARCHIVE LOG LIST
```
    Database log mode	       No Archive Mode
    Automatic archival	       Disabled
    Archive destination	       USE_DB_RECOVERY_FILE_DEST
    Oldest online log sequence     5
    Current log sequence	       7

* Una vez confirmado que la base de datos no esta ya en modo ```ARCHIVELOG```, asignamos la carpeta de destino de los redo log offline.
```SQL
ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=/u01/logs/offline/' SCOPE=SPFILE;
```

* Ahora debemos detener la base de datos y ponerla en modo mount para establecer el modo ```ARCHIVELOG```.
```SQL
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
```

* Indicamos a oracle que debe iniciarse desde ahora en modo ```ARCHIVELOG``` y abrimos la base de datos para operación normal.
```SQL
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
```

* A partir de ahora la base de datos esta en modo ```ARCHIVELOG```. Podemos comprobarlo mediante el comando ```ARCHIVE LOG LIST``` o mediante el query ```SELECT NAME, LOG_MODE FROM V$DATABASE```.

* Se puede comprobar el archiveo de los redo log files forzando un Log Switch: ```ALTER SYSTEM SWITCH LOGFILE;```.

### Activando el multiplexeo del Redo Log

* Comprobamos el estado actual del archiving de los redo log files
```SQL
SELECT * FROM V$LOGFILE
```

* Ejecutamos ```ALTER DATABASE``` para generar miembros en cada grupo de redo log files.
```SQL
ALTER DATABASE ADD LOGFILE MEMBER '/u01/logs/log2b.rdo' TO GROUP 1;
ALTER DATABASE ADD LOGFILE MEMBER '/u01/logs/log2a.rdo' TO GROUP 1;
ALTER DATABASE ADD LOGFILE MEMBER '/u01/logs/log3a.rdo' TO GROUP 2;
ALTER DATABASE ADD LOGFILE MEMBER '/u01/logs/log3b.rdo' TO GROUP 2;
```

* Revisamos la vista para confirmar que el nuevo miembro ha sido añadido al grupo.
```SQL
SELEC * FROM V$LOGFILE;
```


## Referencias externas

 * Documentación oficial de Oracle: [Managing the Redo Log](http://docs.oracle.com/cd/E11882_01/server.112/e25494/onlineredo.htm#ADMIN007)
 * Documentación oficial de Oracle: [Managing Archived Redo Logs](http://docs.oracle.com/cd/E11882_01/server.112/e25494/archredo.htm#ADMIN008)
 * Otros enlaces
 * ...




