#! /bin/bash
# Archivo menu servicios 0.6
# Realizdo por:
#	Adrià Moyá Massanet
# 	Ramses Leal Líndez
# 	Luís Eduardo Álvarez Domínguez

#Cargamos archivo funciones
. funciones.sh

directorioactual=`pwd`
null="/dev/null"
function listaBackup(){
	cd $directBackup
	#guardamos en una lista de los backups y lo mostramos
	ls -t1 *.bak >arch.txt 	
	echo "     0  Volver"
	cat -n arch.txt
}
function borrarYvolver(){
	rm arch.txt
	cd $directorioactual
	intro	
}

#opciones de servicio
function confmenu (){
case $1 in
	1) #Desinstalar
  	apt-get -y purge $aptget
	echo
	echo
	if test $? -eq 0 #Comprobamos que se desinstale correctamente
	then	  		
		echo "Se ha desinstalado CORRECTAMENTE."
		echo 
		
		#ofrecemos la posibilidad de borrar los backups
		echo -n "Quiere borrar los backups de configuracion? (s/n): "
		read preg
		if test $preg = "s"
		then
			rm -rf $directBackup
			echo "Backups borrados correctamente"
			intro
		fi			
	else
		echo "No se ha podido desinstalar, consulte con un administrador."
		intro	
	fi
	;;

	2) #Configuracion
	export archivo
	./configuracion_$servicio.sh
	;;

	3) #Por defecto
	cp -f $default $archivo	
	echo "Configuracion por defecto establecida"
	intro
	;;
	4) #Exportar
	bucle=0		
	while test $bucle -eq 0
	do
		echo
		echo "Se va a guardar la configuracion actual del servicio " $servicio
		echo -n "Introduce el nombre con el que quieres guardar la configuracion: "
		read copia
		echo

		#guardamos fecha_hora_nombre.bak
		archivofinal=`date -d today +%d_%m_%Y_%T_`$copia".bak"
		echo "Se va a guardar el archivo: " $archivofinal
		echo -n "¿Continuar? (s/n): "
		read continuar
		if test $continuar = "s"
		then

			echo

			#copiamos el archivo
			cp $archivo $directBackup/$archivofinal
			if test $? -eq 1
			then
				echo "No se ha podido guardar el archivo"
			else
				echo "Archivo guardado CORRECTAMENTE"
				bucle=1
			fi
		else
			bucle=1
		fi
	done
	intro		
	;;

	5) #Importar
	echo	
	#usamos funcion para ver backups
	listaBackup
	echo
	echo -n "Que configuracion quieres restaurar: "
	read conf
	
	if test $conf -eq 0
	then
		echo
	else
		confa=`sed -n "$conf"'p' arch.txt`

		echo
		
		cp $confa $archivo
		if test $? = 0
		then
			echo "Archivo restaurado correctamente"
		else
			echo "Se ha producido un error, no se ha restaurado correctamente"
		fi
	fi
	borrarYvolver	
	;;
	6) #Borrar Backup
	echo
	#usamos funcion para ver backups			
	listaBackup
	echo
	echo -n "Elige el archivo a borrar: "
	read borr
	
	if test $borr -eq 0
	then
		echo
	else
		borrar=`sed -n "$borr"'p' arch.txt`
		
		echo

		rm -rf $borrar
		if test $? = 0
		then
			echo "Archivo borrado correctamente"
		else
			echo "Se ha producido un error, no se ha restaurado correctamente"
		fi
	fi
	borrarYvolver	
	;;
	
	*)continue
	;;
esac
}

#Menu servicios
function menu2 (){
#iniciamos variables para cada servicio
case $1 in
	1) #DHCP
	servicio="DHCP"
	existe="/etc/dhcp3/dhcpd.conf"
	archivo="/etc/dhcp3/dhcpd.conf"
	aptget="dhcp3-server"
	directBackup="/etc/dhcp3/backup"
	default="/etc/dhcp3/backup/dhcpd.conf"	
	;;

	2) #SSH
	servicio="SSH"
	existe="/etc/init.d/ssh"
	archivo="/etc/ssh/sshd_config"
	aptget="openssh-server"
   	directBackup="/etc/ssh/backup"
	default="/etc/ssh/backup/sshd_config"
	;;

	3) #SAMBA	
	servicio="SAMBA"
	existe="/etc/init.d/smbd"
	archivo="/etc/samba/smb.conf"
	aptget="samba"
	directBackup="/etc/samba/backup"
	default="/etc/samba/backup/smb.conf"
	;;

	*) #Por defecto
	continue
	;;
esac

#Bucle menu servicios
i2=-1 #variable para mantener bucle
while test $i2 -ne 0
do
	clear
	echo "==============="
	echo "Servicio: $servicio"
	echo "==============="
	echo
	echo "0: Volver"
	
	#Comprobamos que exista el existe
	if test  -f $existe
	then	
		#menu si existe el $existe
		echo "1: Desinstalar"
		echo "2: Configurar"
		echo "3: Volver configuracion por defecto"
		echo "4: Exportar configuracion actual"

		ls $directBackup/*.bak 2> $null 1> $null		
		if test $? = 0
		then
			echo "5: Importar configuracion"
			echo "6: Borrar Backup"
		else
			echo -n
		fi 
		
	else	
		#menu si no existe el $existe
		echo "1: Instalar"
	fi

	echo
	echo -n "Elige opcion: "	
	read i2 #capturamos opcion

	#segun si esta instalado el servicio 
	if test  -f $existe
	then
		confmenu $i2
	else
		if test $i2 -eq 1
		then	
			#Instalamos la aplicacion, creamos directorio backup y
			#realizamos backup del/os existes de configuracion
			apt-get -y install $aptget 
			echo 
			echo
			if test $? -eq 0 #comprobamos si se ha instalado bien
			then
				if test -f $default
				then
					echo 
				else					
					mkdir $directBackup
					cp $archivo $directBackup
				fi				
				echo "Servicio instalado CORRECTAMENTE"
				
				#Posibilidad de redirigir al usuario a la configuracion
				#del servicio
				echo -n "Quiere configurar el servicio ahora? (s/n): "
				read preg 
				if test $preg = "s"
				then
					confmenu 2	
				fi
			else
				echo "El servicio NO se ha instalado"
				intro
			fi			

		fi
	fi
done
}

i=-1
while test $i -ne 0
do
	clear
	echo "============================"
	echo "Elige servicio a configurar:"
	echo "============================"
	echo
	echo "0: Salir"
	echo "1: DHCP"
	echo "2: SSH"
	echo "3: SAMBA"
	echo
	echo -n "Elige opcion: "	
	read i
		
	menu2 $i	
done
# Vaciamos variables
directorioactual=
directBackup=
aptget=
preg=
default=
existe=
bucle=
archivofinal=
copia=
continuar=
conf=
confa=
archivo=
borr=
borrar=
servicio=
i2=
i=
null=
clear
