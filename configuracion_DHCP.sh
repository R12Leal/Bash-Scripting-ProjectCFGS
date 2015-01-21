#! /bin/bash
#Version 0.5
. funciones.sh
archivoserver="/etc/default/dhcp3-server"
#Funcion que modifica todas las caracteristicas de la red al ser cambiada la ip del servidor
function modDhcp(){
# $1 = interfaz, $2 = nueva IP, $3 = rango de red, 
# $4 = rango inicio, $5 = rango fin, $6 = mascara de red, $7 = broadcast, $8 = dns
	linicial=`n_linea "#Configuracion" $archivo`
	#Modifica la interfaz que se esta usando
	leth=`n_linea "INTERFACES=" $archivoserver`
	interfaz=`str_linea $leth $archivoserver|cut -d"=" -f 2`
	mod_linea $leth $interfaz "\"$1\"" $archivoserver
	#Modifica la ip del servidor dhcp
	let linea=$linicial+3
	ipserver=`str_linea $linea $archivo |cut -c 16-`
	mod_linea $linea $ipserver "$2;" $archivo
	#Modifica la subnet (Rango de la red)
	let linea=$linicial+5
	subnetAnterior=`str_linea $linea $archivo |cut -d" " -f 2`	
	mod_linea $linea $subnetAnterior $3 $archivo
	#Modifica la ip de broadcast de la red
	let linea=$linicial+2
	broadcastAnterior=`str_linea $linea $archivo |cut -d" " -f 3`
	mod_linea $linea $broadcastAnterior "$7;" $archivo
	#Modifica la netmask
	let linea=$linicial+5
	netmaskAnterior=`str_linea $linea $archivo |cut -d" " -f 4`
	mod_linea $linea $netmaskAnterior $6 $archivo
	#Modifica la subnet-mask
	let linea=$linicial+1
	subnetmaskAnterior=`str_linea $linea $archivo |cut -d" " -f 3`
	mod_linea $linea $subnetmaskAnterior "$6;" $archivo
	#Modifica la ip inicial del rango de direcciones
	let linea=$linicial+6
	inicioRango=`str_linea $linea $archivo |cut -d" " -f 2`
	mod_linea $linea $inicioRango $4 $archivo
	#Modifica la ip final del rango de direcciones
	let linea=$linicial+6
	finRango=`str_linea $linea $archivo |cut -d" " -f 3`
	mod_linea $linea $finRango "$5;" $archivo
	#Modifica la ip dns usada por el servidor
	let linea=$linicial+7
	dns=`str_linea $linea $archivo |cut -d" " -f 3`
	mod_linea $linea $dns "$8;" $archivo
	#Modifica la ip de la interfaz usada por el DHCP para que coincida
	ifconfig $1 $2 netmask $6
	/etc/init.d/dhcp3-server restart
	echo "Servicio configurado correctamente"
	intro
}
function nuevoDhcp(){
# $1 = interfaz, $2 = nueva IP, $3 = rango de red, 
# $4 = rango inicio, $5 = rango fin, $6 = mascara de red, $7 = broadcast, $8 = dns
echo "#Configuracion" >> $archivo
echo "option subnet-mask $6;" >> $archivo
echo "option broadcast-address $7;" >> $archivo
echo "option routers $2;" >> $archivo
echo "" >> $archivo
echo "subnet $3 netmask $6 {" >> $archivo
echo "range $4 $5;" >> $archivo
echo "option domain-name-servers $8;" >> $archivo
echo "}" >> $archivo
leth=`n_linea "INTERFACES=" $archivoserver`
interfaz=`str_linea $leth $archivoserver|cut -d"=" -f 2`
mod_linea $leth $interfaz "\"$1\"" $archivoserver
ifconfig $1 $2 netmask $6
/etc/init.d/dhcp3-server restart
echo "Servicio configurado correctamente"
intro
}
function modRango(){
# $1 = Ip de inicio , $2 ip final
	linicial=`n_linea "#Configuracion" $archivo`
	let linea=$linicial+6
	antes=`str_linea $linea $archivo`
	despues="range $1 $2;"
	mod_linea $linea "$antes" "$despues" "$archivo"
	echo "Rango modificado correctamente"
	intro
}
function modDNS(){
# $1 = ip del servidor DNS
	#Modifca la ip del dns usado por el servidor DHCP
	linicial=`n_linea "#Configuracion" $archivo`
	let linea=$linicial+7
	mod_linea $linea $dnsAnterior "$1" $archivo
	echo "DNS modificado correctamente"
	intro
}
function menu2(){
	case $1 in
		1) #Modificar ip del servidor DHCP
			clear
			#Le pedimos que seleccione la interfaz sobre la que ira el DHCP
			echo "==========================================================="
			echo "DHCP > Configuracion > desde 0"
			echo
			echo "Al configurar desde 0 el servidor DHCP deberas elegir la "
			echo "interfaz y modificar la ip, mascara de red y broadcast del"
			echo "interfaz usado por el dhcp para transmitir el servicio." 
			echo "Tambien deberas introducir un nuevo rango de ips que el" 
			echo "servicio otorgara a los clientes"
			echo "==========================================================="
			echo
			echo "Elige el interfaz desde el que transmitra el servidor"
			echo "Disponibles:"
			ifconfig -s |grep eth > interfaces
			cat -b interfaces |cut -d" " -f 6
			echo
			echo -n "Elige una opcion: "
			read opcion
			interfaz=`str_linea $opcion interfaces |cut -c 1-4`
			echo
			clear
			#Le pedimos que asigne una ip para el servidor DHCP
			echo "=============================================================="
			echo "DHCP > Configuracion > desde 0"
			echo "=============================================================="
			echo "Asigna una ip a la interfaz, dicha ip sera la ip del servidor."
			echo "Al elegir la ip se le asignara la mascara dependiendo de la"
			echo "clase de ip que sea (A,B,C)."
			echo "=============================================================="
			echo "            Clase C     Clase A    Clase B"
			echo "Ejemplo: 192.168.0.1 o 10.0.0.1 o 128.1.0.1"
			echo
			echo -n "ip: "
			read newip
			#Guardamos la nueva ip en un archivo que usaremos mas adelante
			echo $newip > iprouter
			#Capturamos el primer octeto de bits para determinar su clase
			red=`cut -d"." -f 1 iprouter`
			#Comprobamos si es de clase A
			if test $red -lt 128
				then
					#Capturamos los bits de red
					red=`cut -d"." -f 1 iprouter`
					#Declaramos cual sera su rango
					rango=$red.0.0.0
					#Declaramos cual sera su mascara
					netmask=255.0.0.0
					#Declaramos cual sera su broadcast
					broadcast=$red.255.255.255
					clear
					#Le pedimos que introduzca el rango
					#de ips que quiere otorgar
					echo "========================================================================"
					echo "DHCP > Configuracion > desde 0"
					echo "========================================================================"
					echo "A continuacion debe introducir una ip de inicio y una ip final para que"
					echo "el servidor DHCP sepa que rango de direcciones puede repartir."
					echo "========================================================================"
					echo
					echo "Ejemplos:"
					echo "ip de inicio: 10.0.0.10"
					echo "ip final: 10.0.0.100"
					echo
					echo "En este caso el servidor repartiria de la ip 10.0.0.10 a la 10.0.0.100"
					echo
					echo -n "ip de inicio?: "
					read rangoInicio
					echo -n "ip final?: "
					read rangoFin
				else
					#Comprobamos si es de clase B
					if test $red -gt 127 -a $red -lt 192
					then
						#Capturamos los bits de red
						red=`cut -d"." -f 1-2 iprouter`
						#Declaramos cual sera su rango
						rango=$red.0.0
						#Declaramos cual sera su mascara
						netmask=255.255.0.0
						#Declaramos cual sera su broadcast
						broadcast=$red.255.255
						clear
						#Le pedimos que introduzca el rango
						#de ips que quiere otorgar
						echo "========================================================================"
						echo "DHCP > Configuracion > desde 0"
						echo "========================================================================"
						echo "A continuacion debe introducir una ip de inicio y una ip final para que"
						echo "el servidor DHCP sepa que rango de direcciones puede repartir."
						echo "========================================================================"
						echo
						echo "Ejemplos:"
						echo "ip de inicio: 128.1.0.10"
						echo "ip final: 128.1.0.100"
						echo
						echo "En este caso el servidor repartiria de la ip 128.1.0.10 a la 128.1.0.100"
						echo
						echo -n "ip de inicio?: "
						read rangoInicio
						echo -n "ip final?: "
						read rangoFin
					else
						#Compramos si es de clase C
						if test $red -gt 191 -a $red -lt 224
						then
							#Capturamos los bits de red
							red=`cut -d"." -f 1-3 iprouter`
							#Declaramos cual sera su rango
							rango=$red.0
							#Declaramos cual sera su mascara
							netmask=255.255.255.0
							#Declaramos cual sera su broadcast
							broadcast=$red.255
							clear
							#Le pedimos que introduzca el rango
							#de ips que quiere otorgar
							echo "========================================================================"
							echo "DHCP > Configuracion > desde 0"
							echo "======================================================================="
							echo "A continuacion debe introducir una ip de inicio y una ip final para que"
							echo "el servidor DHCP sepa que rango de direcciones puede repartir."
							echo "========================================================================"
							echo
							echo "Ejemplos:"
							echo "ip de inicio: 192.168.0.10"
							echo "ip final: 192.168.0.100"
							echo
							echo "En este caso el servidor repartiria de la ip 192.168.0.10 a la 192.168.0.100"
							echo
							echo -n "ip de inicio?: "
							read rangoInicio
							echo -n "ip final?: "
							read rangoFin
						else
							#Si la ip que introduce no es valida
							#le avisara y parara el proceso de
							#configuracion
							echo "Direccion introducida no valida, debe ser de clase A, B o C."
							intro
							break;
						fi
					fi
				fi
			clear
			#Le pedimos que introduzca una DNS
			echo "========================================================"
			echo "DHCP > Configuracion > desde 0"
			echo "========================================================"
			echo "A continuacion debe introducir la direccion IP de su DNS"
			echo "========================================================"
			echo
			echo "Ejemplo: 8.8.8.8 (DNS de Google)"
			echo
			echo -n "ip?: "
			read dns
			clear
			#Mostramos el resultado de la configuracion del servidor
			echo "============================================="
			echo "DHCP > Configuracion > desde 0"
			echo "============================================="
			echo "La configuracion del servidor DHCP queda asi:"
			echo "============================================="
			echo "Interfaz que usara el servidor: $interfaz"
			echo "Direccion IP statica del servidor: $newip"
			echo "Rango de la red: $rango"
			echo "Ip Inicial: $rangoInicio"
			echo "Ip Final: $rangoFin"
			echo "Mascara de red: $netmask"
			echo "Broadcast de la red: $broadcast"
			echo "DNS: $dns"
			echo
			echo -n "Es correcta la configuracion? (s/n): "
			read opcion
			if test $opcion = "s"
			then
				if test $testnew -lt 112
				then
					#Lanzamos la funcion para modificar una 
					#configuracion nueva desde 0
					nuevoDhcp $interfaz $newip $rango $rangoInicio $rangoFin $netmask $broadcast $dns
				else
					#Lanzamos la funcion para modificar una 
					#configuracion existente desde 0
					modDhcp $interfaz $newip $rango $rangoInicio $rangoFin $netmask $broadcast $dns					
				fi
			fi
			rm interfaces
			rm iprouter
		;;
		2) #Modificar rango de IPs que otorga el DHCP
			clear
			#Capturamos el inicio y final del rango de ips que otorga
			#el servidor actualmente
			linicial=`n_linea "#Configuracion" $archivo`
			let linea=$linicial+6
			inicioRango=`str_linea $linea $archivo |cut -d" " -f 2`
			finRango=`str_linea $linea $archivo |cut -d" " -f 3`
			#Le quitamos el ; del final de la linea
			let length=`expr length $finRango`-1
			finRango=`expr substr $finRango 1 $length`			
			echo "========================================================================"
			echo "DHCP > Configuracion > Rango de IPs"
			echo "========================================================================"
			echo "A continuacion debe introducir una ip de inicio y una ip final para que"
			echo "el servidor DHCP sepa que rango de direcciones puede repartir."
			echo "========================================================================"
			echo
			echo "			Rango actual"
			echo "	Ip de inicio: $inicioRango"
			echo "	Ip final: $finRango"
			echo
			echo -n "ip de inicio?: "
			read rangoInicio
			echo -n "ip final?: "
			read rangoFin
			modRango $rangoInicio $rangoFin
		;;
		3) #Modificar direccion DNS
			clear
			#Capturamos la DNS anterior para mostrarla en el menu
			linicial=`n_linea "#Configuracion" $archivo`
			let linea=$linicial+7
			dnsAnterior=`str_linea $linea $archivo |cut -d" " -f 3`
			#Le quitamos el ; del final de la linea
			let length=`expr length $dnsAnterior`-1
			dnsAnterior=`expr substr $dnsAnterior 1 $length`
			echo "========================================================"
			echo "DHCP > Configuracion > DNS"
			echo "========================================================"
			echo "A continuacion debe introducir la direccion IP de su DNS"
			echo "========================================================"
			echo
			echo "DNS anterior: $dnsAnterior"
			echo
			echo -n "ip?: "
			read dns
			modDNS $dns
		;;
		4) #Mostrar Configuracion Actual
			clear
			linicial=`n_linea "#Configuracion" $archivo`
			let linea=$linicial+3
			ipserver=`str_linea 115 $archivo |cut -c 16-`
			#Le quitamos el ; del final de la linea
			let length=`expr length $ipserver`-1
			ipserver=`expr substr $ipserver 1 $length`
			let linea=$linicial+5
			subnetAnterior=`str_linea $linea $archivo |cut -d" " -f 2`
			netmaskAnterior=`str_linea $linea $archivo |cut -d" " -f 4`
			let linea=$linicial+2
			broadcastAnterior=`str_linea $linea $archivo |cut -d" " -f 3`
			#Le quitamos el ; del final de la linea
			let length=`expr length $broadcastAnterior`-1
			broadcastAnterior=`expr substr $broadcastAnterior 1 $length`
			let linea=$linicial+6
			inicioRango=`str_linea $linea $archivo |cut -d" " -f 2`
			finRango=`str_linea $linea $archivo |cut -d" " -f 3`
			#Le quitamos el ; del final de la linea
			let length=`expr length $finRango`-1
			finRango=`expr substr $finRango 1 $length`
			leth=`n_linea "INTERFACES=" $archivoserver`
			interfaz=`str_linea $leth $archivoserver|cut -d"=" -f 2`
			#Le quitamos los "" del final de la linea
			let length=`expr length $interfaz`-2
			interfaz=`expr substr $interfaz 2 $length`
			let linea=$linicial+7
			dns=`str_linea $linea $archivo |cut -d" " -f 3`
			#Le quitamos el ; del final de la linea
			let length=`expr length $dns`-1
			dns=`expr substr $dns 1 $length`
			#Mostramos el resultado de la configuracion del servidor
			echo "============================================="
			echo "DHCP > Configuracion > Actual"
			echo "============================================="
			echo "La configuracion actual del servidor DHCP es:"
			echo "============================================="
			echo "Interfaz que usara el servidor: $interfaz"
			echo "Direccion IP statica del servidor: $ipserver"
			echo "Rango de la red: $subnetAnterior"
			echo "Ip Inicial: $inicioRango"
			echo "Ip Final: $finRango"
			echo "Mascara de red: $netmaskAnterior"
			echo "Broadcast de la red: $broadcastAnterior"
			echo "DNS: $dns"
			echo
			intro
		;;
		*)continue
		;;
	esac
}
i=-1
	while test $i -ne 0
	do
	#Comprobamos si el servidor ha sido configurado anteriormente
	testnew=`wc -l $archivo |cut -d" " -f 1`
		if test $testnew -lt 112
			#Menu que se lanza si el servidor no ha sido configurado nunca	
		then
			clear
			echo "========================================================"
			echo "DHCP > Configuracion"
			echo "========================================================"
			echo "Bienvenido al menu de configuracion del servidor DHCP."
			echo
			echo "Es la primera vez que se ejecuta el dhcp asi que debera"
			echo "configurar todos los aspectos del servidor para que este"
			echo "funcione correctamente."
			echo "========================================================"
			echo
			echo "0. Volver"
			echo "1. Configurar servidor"
			echo
			echo -n "Elige una opcion:"
			read i
			#Lanzamos la opcion elegida
			menu2 $i
		else
			#Menu que se lanza si el servidor ya tiene una configuracion
			while test $i -ne 0
			do
				clear
				echo "========================================================"
				echo "DHCP > Configuracion"
				echo "========================================================"
				echo "Bienvenido al menu de configuracion del servidor DHCP."
echo "======================================================"
				echo
				echo "0. Volver"
				echo "1. Configurar servidor desde 0"
				echo "2. Modificar rango de IPs que otorga el DHCP"
				echo "3. Modificar direccion DNS"
				echo "4. Mostrar configuracion actual"
				echo
				echo -n "Elige una opcion: "
				read i
				#Lanzamos la opcion elegida
				menu2 $i
			done
		fi
	done
#Vaciamos variables
i=
testnew=
dns=
dnsAnterior=
rangoInicio=
rangoFin=
inicioRango=
finRango=
interfaz=
newip=
rango=
rangoInicio=
rangoFin=
netmask=
broadcast=
opcion=
red=
ipserver=
subnetAnterior=
netmaskAnterior=
broadcastAnterior=
subnetmaskAnterior=
antes=
despues=
length=
leth=
linea=
linicial=
