# Instalar Oracle 11GR2 sobre Oracle Linux 6

#### Archivo hosts
El archivo 'etc/hosts' debe contener un nombre completamente calificado para la maquina.

`<IP-ADDRESS>	<fully-qualified-machine-name> <machine-name>`

Por ejemplo:
```bash
127.0.0.1       localhost.localdomain  localhost
192.168.0.181   ol6-112.localdomain    ol6-112
```

#### Prerequisitos de oracle
Utilice la configuración automatica para configurar parametros y requisitos de oracle antes de instalar:

```bash
# yum install oracle-rdbms-server-11gR2-preinstall
```

#### Configuración adicional
Configure password para usuario oracle

` # passwd oracle `

Configure el archivo "/etc/security/limits.d/90-nproc.conf" de la siguiente manera:
```bash
# Change this
*      soft    nproc    1024

# To this
*	   - 	   nproc 	16384
```

Configura la seguridad como permisiva, editando el archivo "/etc/selinux/config" asegurandote de que la bandera SELINUX quede de la siguiente manera:

` SELINUX=permissive `

Una vez hechos estos cambios, ** reinicia el servidor **.

Crea los directorios para la instalación de oracle:
```bash
~# mkdir -p /u01/app/oracle/product/11.2.0/db_1
~# chown -R oracle:oinstall /u01
~# chmod -R 775 /u01
```

Logueate como root y lanza el siguiente comando:

` # xhost +<machine-name> `

Example: ` # xhost +localhost `

Logueate como usuario oracle y agrega las siguientes lineas al final del archivo ".bash_profile"

```bash
# Oracle Settings
TMP=/tmp; export TMP
TMPDIR=$TMP; export TMPDIR

ORACLE_HOSTNAME=localhost.localdomain; export ORACLE_HOSTNAME
ORACLE_UNQNAME=DB11G; export ORACLE_UNQNAME
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1; export ORACLE_HOME
ORACLE_SID=DB11G; export ORACLE_SID

PATH=/usr/sbin:$PATH; export PATH
PATH=$ORACLE_HOME/bin:$PATH; export PATH

LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH
```

#### Instalación
Logueate como usuario oracle y ejecuta:

` DISPLAY=<machine-name>:0.0; export DISPLAY `

Inicia Oracle Universal Installer (OUI) dirigiendote a la carpeta 'database' y ejecutando:

`./runInstaller	`

Procede con la instalación mediante el Oracle Universal Installer







