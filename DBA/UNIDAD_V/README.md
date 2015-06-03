#Unidad V | Respaldo y recuperación.

## Contenido

 1. Respaldos y recuperación
      1 Sobre el modo ARCHIVE a la hora de los Backups
      1 Principios de Backup
 2. Backups fisicos
      2.1 Backups de Sistema Operativo
      2.2 Backups de la base de datos en frio
      2.3 Backups de la base de datos en caliente
 3. Backups logicos
 4. Flashback area
 5. Recover, RMAN ...
 6. Practicas sobre 'Respaldo y recuperación'


## Respaldos y recuperación.

Para conseguir un funcionamiento seguro de la DB y tener una estrategia de recuperación eficaz ante fallos criticos, se debe implementar una estrategia de copias de seguridad, backup y de recuperación. El primer paso es definir las caracteristicas fundamentales de la implementación, luego es establecer los planes de copias de seguridad y recuperación que nos permitan asegurar los objetivos.

Los *backups* se pueden clasificar en **físicos** y **lógicos**. Los físicos se realizan cuando se copian los ficheros que soportan a la DB. entre estos se encuentra los *backups de SO*, los *backups en frio* y los *backups en caliente*.
Los ** backups lógicos ** solo extraen los datos de las tablas utilizando comandos SQL y se realizan con la utilidad *export/import*.

### Sobre el modo ARCHIVE en el tema de respaldos y recuperación.
Una de las deciciones más importantes que un DBA debe tomar, es si arrancar o no en modo ARCHIVELOG.

**Ventajas**.

 * Aunque se pierdan los ficheros de datos, siempre se puede recuperar la DB con una copia antigua de los ficheros de datos y los ficheros de *redo log* archivados.
 * Es posible realizar *backups* en caliente.

**Desventajas**

 * Se necesitará más espacio en disco
 * El trabajo del DBA se incrementa al tener que determinar el destino del archivado de los *redo log*.

### Principios de backup

Un *backup* válido **es una copia de la información sobre la DB necesaria para reconstruirla a partir de un estado no utilizable de la misma**. Normalmente, si la estrategia de *backup* se basa en la copia de los archivos de datos y en el archivado de los *redo log*, se han de tener copias de los archivos de datos, de los archivos de control, de los archivos *redo log* activos y también de los archivados. **Si se pierde uno de los ficheros redo log archivados, se dice que se tiene un agujero en la secuencia de archivos**. Esto **invalida el backup**, pero permite a la DB ser llevada hasta el principio del agujero realizando una recuperación incompleta.

#### Reglas básicas de backup y diseño de la DB

Antes de nada, es muy importante entender ciertas reglas que determinan la situación de los archivos y otras consideraciones que afectarán al esquema de *backup*.

Es recomendable **archivar los redo log en disco, copiarlos a cinta, pero siempre en un disco diferente del que soporta los ficheros de datos y de redo log activos.**

Los archivos copia **no deben estar en el mismo dispositivo que los originales**. No siempre hay que pasar las copias a cinta, ya que si se dejan en un disco se acelera la recuperación. Ademas, si se pasan a cinta y se mantienen en disco, se puede sobrebibir a diversos fallos de dispositivo.

Se deberían **mantener diferentes copias de los archivos de control, colocadas en diferentes discos con diferentes controladores.**

Los archivos **redo log en linea deben estar multiplexados**, con un minimo de 2 miembros por grupo, residiendo cada miembro en un disco distinto.

Siempre que **la estructura de la DB cambie** debido a la inclusión, borrado o renombrado de un fichero de datos o de redo log, se debe **copiar el fichero de control, ya que almacenan la estructura de la DB.** Además, cada archivo añadido también debe ser copiado. El fichero de control puede ser copiado mientras la DB está abierta con el siguiente comando:

```SQL
ALTER DATABASE BACKUP CONTROLFILE TO 'DESTINO';
```

Tomando en cuenta las reglas anteriores, los siguientes puntos pueden considerarse un ejemplo de **estrategia de backup**.

 1. Activar el modo ARCHIVELOG
 2. Realizar un backup al menos una vez a la semana si la DB se puede parar, En otro caso, realizar *backups* en caliente cada dia.
 3. Copiar todos los archivos redo log archivados cada cuatro horas. El tamaño y el número de ellos dependerá de la tasa de transacciones.
 4. Efectuar un export de la DB semanalmente en modo RESTRICT.


## Backups fisicos

Son aquellos que copian fisicamente los archivos de la DB. Existen dos opciones, en frio y en caliente. Se dice que el backup es en frio cuando los archivos se copian con la DB detenida. En caliente es cuando se copian los ficheros con la DB abierta y operativa.

### Backups del SO.
Este tipo de *backup* es el más sencillo de ejecutar, aunque **consume mucho tiempo y hace inaccesible al sistema mientras se lleva a cabo**. Aprovecha el backup del SO para almacenar también todos los dicheros de la DB. Los pasos para este tipo de backup son:

 1. Parar la DB.
 2. Arrancar en modo superusuario.
 3. Realizar copia de todos los ficheros del sistema de archivos del SO.
 4. Arrancar el sistema en modo normal y luego la DB.

### Backups en frio
Los *backups* en frio **implican parar la DB en modo normal y copiar todos los ficheros sobre los que se asienta.** Antes de parar la DB se deben detener todas las aplicaciones que estén trabajando con una conexión a la DB. Una vez hecho el respaldo de los archivos la DB se puede arrancar de nuevo.

El primer paso es parar la DB con el comando shutdown normal. Si la DB se tiene que parar con *immediate* o *abort* debe rearrancarse con el modo *RESTRICT* y vuelta a parae en modo normal. Después se copian los archivos de datos, los de redo log y los de control, además de los redo log archivados y aún no copiados.

### Backups en caliente
Los *backups* en caliente **se realizan mientras la DB está abierta y operativa en modo ARCHIVELOG**. Este tipo de respaldo consiste en **copiar todos los ficheros correspondientes a un tablespace determinado, los archivos redo log archivados y los archivos de control**. Esto se hace para cada *tablespace* de la DB.

Si la implantación de DB requiere disponibilidad de la misma 24/7, no se pueden realizar backups en frio. Para realizarun backup en caliente debemos trabajar con la DB en modo ARCHIVELOG. El procedimiento de backup en caliente es bastante parecido al frio.

##### Comandos para respaldo en caliente.
Existen dos comandos adicionales: ```BEGIN BACKUP``` antes de comenzar y ```END BACKUP``` al finalizar el *backup*. Por ejemplo, antes y después de efectuar un backup del tablespace users, se deberían ejecutar las sentencias:

```SQL
ALTER TABLESPACE USERS BEGIN BACKUP;
ALTER TABLESPACE USERS END BACKUP;
```

Asi como el *backup* en frio permitia realizar una copia de toda la DB al tiempo, en los backups en caliente la unidad de tratamiento es el *tablespace*. El backup en caliente **consiste en la copia de los ficheros de datos (por tablespace), el actual fichero de control y todos los dicheros redo log archivados creados durante el periodo de backup**. También se necesitaran todos los archivos redo log archivados despues del backup en caliente para conseguir una recuperación total.

## Backups lógicos con EXPORT/IMPORT
Estas utilidades permiten al DBA **hacer copias de determinados objetos de la DB, así como restaurarlos o moverlos de una DB a otra.** Estas herramientas utilizan comandos SQL para obtener el contenido de los objetos y escribirlos/leerlos a los archivos de respaldo.

Una ves que se ha planeado una estrategia de backup y se ha probado, **conviene automatizarla para facilitar su ejecución en tiempo y forma.**

Este tipo de backups copian el contenido de la DB pero sin almacenar la posición física de los datos. **Se realizan con la herramienta export que copia los datos y la definición de la DB en un fichero en formato interno de Oracle**.

Para realizar un export la DB debe estar abierta. Export asegura la consistencia en la tabla, aunque no entre tablas. **Si se requiere la consistencia entre todas las tablas de laDB, entonces no se debe realizar ninguna transacción durante el proceso de export**. Esto se puede conseguir si se abre la DB en modo ```RESTRICT```.

#### Ventajas de realizar un export

 * Se puede detectar la corrupción en los bloques de datos, ya que el proceso de export fallará
 * Protege de fallos de usuario, por ejemplo si se borra una fila o toda una tabla por error es fácil recuperarla por medio de un *import*.
 * Se puede determinar los datos a exportar con gran flexibilidad.
 * Se pueden realizar *exports* completos, incrementales y acumulativos.
 * Los backups realizados con export **son portables y sirven como formato de intercambio de datos entre DBs y entre máquinas**.

#### Desventajas

 * Los backups lógicos con export son mucho mas lentos que los *backups* fisicos.

#### Modos de export
Existen tres modos de realizar una exportación de datos.

** Modo tabla **
Exporta las definiciones de tabla, los datos, los derechos del propietario, los indices del propiertario, las restricciones de la tablay los disparadores asociados a la tabla.

** Modo usuario **
Exporta todo lo del modo de Tabla más los *clusters*, enlaces de DB, vistas, sinónimos privados, secuencias, procedimientos, etc del usuario.

** Modo DB Entera **
Además de todo lo del modo usuario, exporta los roles, todos los sinónimos, los privilegios del sistema, las definiciones de los tablespaces, las cuotas en los tablespaces, las definiciones de los segmentos de rollback, las opciones de auditoria del sistema, todos los diaparadores y los perfiles.

El modo **DB Entera** puede ser dividido en tres casos: Completo, Acumulativo e Incremental. Estos dos últimos se toman menos tiempo que el completo y permiten exportar solo los cámbios en los datos y en las definiciones.

*Completo:* Exporta todas las tablas de la DB e inicializa la información sobre la exportación incremental de cada tabla. Después de una exportación completa, no se necesitan los ficheros de exportaciones acumulativas e incrementales de la DB anteriores.

```SQL
EXP USERID=SYSTEM/MANAGER FULL=Y INCTYPE=COMPLETE CONSTRAINTS=Y FILE=FULL_EXPORT_FILENAME;
```

*Acumulativo:* Exporta solo las tablas que han sido modificadas o creadas desde la última exportación Acumulatia o Completa, y registra los detalles de exportación para cada tabla exportada. Después de una exportación acumulativa, no se necesitan los ficheros de exportaciones incrementales de la DB anteriores.

```SQL
EXP USERID=SYSTEM/MANAGER FULL=Y INCTYPE=CUMULATIVE CONSTRAINTS=Y FILE=CUMULATIVE_EXPORT_FILENAME;
```

*Incremental:* Exporta todas las tablas modificadas o creadas desde la última exportación Incremental, Acumulativa o Completa y registra los detalles de exportación para cada tabla exportada. Son interesantes en entornos en los que muchas tablas permanecen estáticas por periodos largos de tiempo, mientras que otras varian y necesitan ser copiadas. Este tipo de exportación es útil cuando hay que recuperar rápidamente una tabla borrada por accidente.

```SQL
EXP USERID=SYSTEM/MANAGER FULL=Y INCTYPE=INCREMENTAL CONSTRAINTS=Y FILE=INCREMENTAL_EXPORT_FILENAME;
```

La **politica de exportación** puede ser la siguiente: realizar una exportación completa el dia 1 (por ejemplo el domingo), y luego realizar exportaciones incrementales el resto de la semana. De este modo de lunes a sábado sólo se exportarán aquellas tablas modificadas, ahorrando tiempo en el proceso.