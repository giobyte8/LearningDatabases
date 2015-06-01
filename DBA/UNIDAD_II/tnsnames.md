
## Conectando a base de datos remotas mediante SQLPLUS

Mediante SQLPLUS podemos conectarnos tanto a instancias locales como remotas de la base de datos, oracle almacena la configuración de dichas conexiones en el archivo tnsnames.ora.

Regularmente el archivo se encuentra en la ruta:

```bash
$ORACLE_HOME/network/admin/
```

#### Definir los servicios

En el tnsnames.ora del cliente, registramos una nueva instancia remota para conectarnos.
```
MYDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.100.24)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCL)
    )
  )
```
En este ejemplo `ORCL` es el nombre de la instancia remota y `192.168.100.24` es el host del servidor remoto.

#### Nota sobre el firewall
se requiere configurar el firewall tanto en el servidor como en el cliente para permitir establecer la conexión con la instancia remota. Por brevedad, puedes deshabilitarlo (Mala practica de seguridad).

Deshabilitarlo (Tanto en cliente como servidor) {Mala practica de seguridad}:
```bash
iptables -F
```

#### Activar el listener en el servidor
Del lado del servidor, debemos iniciar el servidor mediante:

```bash
lsnrctl start
```


#### Conexión desde el cliente

Ahora desde el cliente nos conectamos mediante:

```bash
sqlplus system/password@MYDB
```
En este ejemplo `password` representa el password del usuario SYSTEM en el servidor remoto.