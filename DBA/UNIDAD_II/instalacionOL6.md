# Instalación y configuración de Oracle Linux 6.5

A continuación se detalla el proceso a seguir para instalar el sistema operativo Oracle Linux de manera que cumpla con lo requerido para instalar Oracle DBMS posteriormente.

#### Requerimientos para instalar con ambiente grafico.
 * 1 GB RAM
 * 10 GB HDD

#### Paso 1.
Realize una instalación en limpio del sistema insertando el disco de instalación y siguiendo las instrucciónes en pantalla, en el proceso configure la red para utilizar conección por DHCP o en su defecto configure la dirección IP estatica. El tipo de instalación a elegir en el asistente de instalación grafico es: "Basic Server", pero marque la opción "Customize now" y  **agregue los paquetes requeridos para el escritorio y herramientas basicas de desarrollo** (Utiles para la instalación de Oracle 11GR2). Una vez finalizada la instalación, reinicie y proceda al Paso 2.

#### Paso 2. Crear un usuario y agregarlo como sudoer
Para crear un usuario ejecute como root:

```bash
adduser -m giovanni
passwd giovanni
```

Damos permisos de sudo al usuario:
```bash
visudo
```

Este comando abrira un archivo de configuración con el editor vi, agregamos el usuario bajo la entrada donde esta el usuario de root, quedando un archivo similar a:
```bash
## The COMMANDS section may have other options added to it.
##
## Allow root to run any commands anywhere
root            ALL=(ALL)       ALL
giovanni        ALL=(ALL)       ALL # ESTA ES LA LINEA AGREGADA
```

*Ahora nuestro usuario tiene permisos para ejecutar comandos como root mediante sudo*

-----

Ahora podemos pasar a la siguiente sección para la [instalación de oracle 11GR2](./installO11GR2.md).