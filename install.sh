#! /bin/bash
# Archivo Instalacion de servicios
# Realizdo por:
#	Adrià Moyá Massanet
# 	Ramses Leal Líndez
# 	Luís Eduardo Álvarez Domínguez

#Cambiamos la propiedad a root
chown root:root servicios.sh funciones.sh configuracion_SSH.sh configuracion_DHCP.sh configuracion_SAMBA.sh

#Comprobamos que funcione
if test $? -eq 0
then
	echo "Propiedad de los archivos modificada correctamete"	
else
	echo "No se ha podido cambiar la propiedad del fichero, eres super usuario?"
	exit
fi

#Cambiamos los permisos para que sea solo de root
chmod 770  servicios.sh funciones.sh configuracion_SSH.sh configuracion_DHCP.sh configuracion_SAMBA.sh

#Comprobamos que funcione
if test $? -eq 0
then
	echo "Permisos de los archivos modificados correctamente"	
else
	echo "No se han podido cambiar los permisos, eres super usuario?"
	exit
fi

#En caso de que todo haya ido bien borramos el instalador
rm install.sh

