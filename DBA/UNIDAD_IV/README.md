#Operación y mantenibilidad

##Contenido
 * [Bitacoras](#bitacoras)
   * [Funciones especificas de las bitacoras](#funciones-especificas-de-las-bitacoras)
 * Redo Log
   * Contenido de un Redo Log
   * Como oracle database escribe al Redo Log
   * Redo Log File Activo (Actual) e inactivos
   * Log Switches y Log Sequence Numbers
 * Planificación del Redo Log
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
 * Activando el **multiplexeo** del Redo Log
 * El modo **ARCHIVE LOG** y como activarlo
 * Referencias externas

##Bitacoras
En muchos DBMS la bitacora incluye todo tipo de consultas incluyendo aquellas que no modifican los datos. La operación ROLLBACK esta basada en el uso de una bitacora.

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

Los archivos de REDO estan llenos de ** registros redo **, un registro redo se compone de un grupo de **vectores de cambio**, cada uno de los cuales es la descripción de un cambio hecho a un (y solo un) bloque en la base de datos. Por ejemplo, si se cambia el valor del campo ```SALARY``` en la tabla ```EMPLOYEE```, se genera un *registro redo* que contiene los vectores de cambio que describen los cambios a el bloque de segmento de datos de la tabla, el bloque de segmento de datos de undo y la tabla de transacción de los segmentos de undo.

Los *registros redo* almacenan información que se puede utilizar para reconstruir todos los cambios hechos a una base de datos,  incluyendo segmentos de undo. Por lo tanto, el redo Log también proteje datos de ROLLBACK. Cuando se recupera la base de datos utilizando datos de redo, la base de datos lee los vectores de cambio en los registros redo y se aplican los cambios a los bloques reelevantes.

Los *registros redo* son almacenados de manera circular en el **redo log buffer** de la SGA (System Global Area) y son escritos a uno de los archivos *redo log* por un proceso en segundo plano denominado **Log Writer(LGWR)**. Cada vez que una transacción es *Committed* (Confirmada | Asegurada), LGWR escribe los registros redo de la transacción desde el redo log buffer a un redo log file y asigna un **system change number (SCN)** para identificar los registros redo de cada transacción confirmada. Solo cuando todos los registros redo asoiados con la transacción estan seguros en disco dentro de los *logs online* se notifica al proceso del usuario que la transacción ha sido *committed | confirmada | asegurada*.

Los registros redo también pueden ser escritos a un redo log file antes de que la transacción correspondiente sea committed/confirmada, si el redo log buffer se llena u otra transacción es committed/confirmada, LGWR vacia todos los registros de redo en el redo log buffer hacia un redo log file, incluso aunque algunos registros redo no hayan sido committed/confirmados, si es necesario la base de datos puede hacer ROLLBACK de esos cambios.

###Como Oracle database escribe al Redo Log

El *redo log* de una base de datos consiste de dos o más *redo log files*. La base de datos requiere un minimo de dos archivos para garantizar que uno este siempre disponible para escritura mientras el otro esta siendo archivado. (Si la base de datos esta en modo **ARCHIVELOG**).

LGWR escribe en los redo log files de manera circular, cuando el actual redo log file se llena, LGWR comienza a escribir en el siguiente redo log file disponible. Cuando el último redo log file disponible se llena, LGWR regresa al primer redo log file y escribe en el, inciando de nuevo el ciclo.

Los redo log files que ya estan llenos, se hacen disponibles para ser reutilizados dependiendo de si *archiving* esta habilitado o no:

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

##Creando grupos y miembros del Redo Log


## Referencias externas

 * Documentación oracle sobre REDO Logs
 * Documetnación oracle sobre
 * Otros enlaces
 * ...






