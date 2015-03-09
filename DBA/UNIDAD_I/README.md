# Unidad I: Conceptos basicos.

## 1.1 Administrador de base de datos (DBA)
El DBA conntribuye con su trabajo al funcionamiento eficaz de todos los sistemas que se ejecutan con la base de datos. Además ofrece asistencia técnica a quienes interactúan con la Base de Datos.

#### Concepto de base de datos
Una Base de Datos es un programa residente en memoria, que se encarga de gestionar todo el tratamiento de entrada, salida, protección y elaboracióñ de la información que se almacena.

### 1.1.1 Funciones de un DBA

 * Instalación y actualización del Oracle Server y de todos sus productos asociados.
 * Asignación de recursos para la utilización de Oracle: memoria, espacio en disco, perfiles de usuario etc.
 * Ajuste de la Base de Datos para conseguir el rendimiento optimo esperado.
 * Estrategias de copia de seguridad y recuperación.
 * Enlace con el Servicio Mundial de Asistencia al Cliente de Oracle (Oracle Worldwide Support) para resolver problemas técnicos que requieran la intervención de Oracle.
 * Colaboración con el personal de administración del sistema y desarrolladores de aplicaciones

### 1.1.2 Relación del DBA con otras areas de sistemas
En sistemas muy complejos cliente/servidor y de tres capas, la base de datos es sólo uno de los elementos que determinan la experiencia de los usuarios en linea y programas desatendidos. **El rendimiento es una de las mayores motivaciones de los DBA** para coordinarse con los especialistas de otras areas fuera de las lineas burocráticas tradicionales.

Uno de los deberes menos respetados por el DBA es **El desarrollo y soporte a pruebas** mientras que alguino de los encargados lo consideran como la responsabilidad mas importante del DBA. Las actividades incluyen la colecta de datos en producción para realizar las pruebas con ellos, consultar a los desarrolladores respecto al desempeño y hacer cambios a los diseños de las tablas de manera que se puedan proporcionar nuevos tipos de almacenamientos para las funciones de los programas.

## 1.2 Análisis de los manejadores de base de datos
El manejador de base de datos es la porcion mas importante del software de base de datos. Un DBMS es una colección de numerosas rutinas de software interelacionadas, cada una de las cuales es responsable de alguna tarea especifica.

*Microsoft SQL Server, Oracle DB y MySQL Server* son sistemas de gestión o manejadores de base de datos, existen muchos como:

 * MySQL
 * PosgreSQL
 * Microsoft SQL Server
 * Oracle DB
 * Firebird
 * mSQL (MiniSQL)
 * IBM DB2
 * IBM Informix
 * SQLite
 * Sybase ASE
 * Paradox
 * dBase
 * Microsoft Visual FoxPro
 * Microsoft Access

### Análisis de manejadores
Existen ventajas y desventajas entre ellos que los hacen apropiados para situaciones diferentes de gestion de base de datos. Estas diferencias son cruciales a la hora de elefir un sistema gestor de base de datos.

Analizaremos las ventajas y desventajas de los mas populares y usados, Microsoft SQL Server, Oracle DB y MySQL Server.

##### MySQL
A diferencia de SQL Server, es un servidor multi-hilo de código abierto, confiable, poderoso, compacto y multiplataforma, puede utilizarse gratuitamente.

###### Ventajas.
 * Software gratuito
 * Velocidad y robustez
 * Multiproceso (Es decir, puede utilizar varias CPU si estan disponibles)
 * Multiplataforma
 * Sistema de contraseñas flexible y seguro

##### SQL Server
Microsoft SQL Server constituye la alternativa de Microsoft a otros sitemas gestores de DB.

###### Ventajas.
 * Soporte de transaciones
 * Escalabilidad, estabilidad y seguridad
 * Soporte de procedimientos almacenados
 * Permite trabajar en modo *cliente/servidor*, donde la información se aloja en el servidor y los clientes de red solo acceden a dicha informacióñ
 * Permite administrar información de otros servidores.

###### Desventajas.
 * Es muy costoso

##### Oracle
Es desarrollado por Oracle Corporation. Se considera como uno de los DBMS mas completos.

###### Ventajas.
 * Soporte de transacciones
 * Estabilidad
 * Escalabilidad
 * Soporte multiplataforma

###### Desventajas.
 * Politicas de seguridad en el suministro de parches de actualización.


## 1.3 Consideraciones para elegir un DBMS

#### Disponibilidad de soporte para este DBMS
 * Debe considerarse si es posible determinar el costo de un especialista en dicho gestor de base de datos o si el gestor brinda soporte en linea o via remota.
 * Si las aplicaciones que van a consumir los datos son de misión critica y se requiere alta disponibilidad no es recomendable usar un DBMS poco conocido o nuevo en el mercado.

#### Carga de transacciones para la base de datos
Si voy a necesitar soporte para una gran carga de transacciones (mayor a 200 usuarios simultaneos) es necesario pensar en algo robusto y bien probado en el mercado.

#### Sistema operativo a utilizar
Esta comprobado que ciertos DBMS desarrollados como Open Source, se ejecutan a una velocidad mucho mayor en sistemas tipo Unix que en Servidores Windows, asi que debería tenerse en cuenta el sistema operativo que se utilizara para la base de datos.

## 1.4 Nuevas tecnologías y aplicaciones de los sistemas de base de datos.
Los sistemas orientados a datos se distinguen por que los datos no son de una aplicación si no de una Organización entera que consumira los datos. Las aplicaciónes se integran, hay estructuras logicas y fisicas. El concepto de relación cobra importancia.

Las bases de datos eliminan las inconsistencias que se producen por la utilización de los mismos datos lógicos desde procesos independientes.

No solo deben almacenarse entidades y atributos, si no también deben almacenarse interrelaciones entre los datos.

La redundancia debe ser controlada, pero se admite cierta redundancia por motivos de eficiencia.

La definición y descripción del conjunto de datos contenido en la base de datos debe ser unica e integrada con los mismos datos.

La actualización y recuperación de la base de datos debe realizarse mediante procesos incluidos en el DBMS de modo que se mantenga la integridad, seguridad y confidencialidad de la base de datos.