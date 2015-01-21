#! /bin/bash
#Archivo configuracion ssh 0.5
#Realizado por:
#		Adrià Moyá Massanet

#cargamos las funciones
. funciones.sh

#Variables estaticas
p_conf="Quieres modificar la configuracion? (s/n): "
n_conf="Nueva Configuracion: "
e_conf="Configracion que quieres eliminar: "
archivoBan="/etc/issue.net"

function banner(){ 
#funciones del menu banner
clear
case $1 in
	1) #Mostrar Banner
	echo -n "Banner Actual: "
	cat $archivoBan
	echo
	intro
	;;
	2) #No mostrar Banner
	conf=`n_linea "Banner" $archivo`	
	mod_linea $conf "Banner" "#Banner" $archivo
	check
	echo
	intro
	;;
	3) #Mostrar Banner
	conf=`n_linea "#Banner" $archivo`	
	mod_linea $conf "#Banner" "Banner" $archivo
	check
	echo
	intro
	;;
	4) #Modificar Banner
	echo -n "Introduce el nuevo Banner: "
	read cadena
	echo $cadena > $archivoBan
	check
	echo
	intro
	;;
	*)
	continue
	;;
esac
}

function devuelve_cadena(){
#funcion para eliminar un usuario de la cadena
#$1 usuario a buscar
#$2 Cadena
Rcadena=$2
buscar=$1
shift
tam=$#
shift
for ((a=1; a<$tam ;a++))
do
	if test "$1" != "$buscar"
	then
		Rcadena="$Rcadena $1"
	fi
shift
done
echo $Rcadena
}

function check (){
#funcion para comprobar si se ha ejecutado bien la ultima modificacion
if test $? -eq 0
then
	echo "Modificacion efectuada"	
else
	echo "No se ha podido modificar, consulte con un administrador"
fi
}

function config_LA(){
#Menu de configuracion de  Listen Address
clear
echo "========================================================"
echo "SSH > Menu > Parametros > Puerto de escucha > Configurar"
echo "========================================================" 
echo
echo "*** Ejemplo ***"
echo "IPv4: 192.168.1.1"
echo "IPv6: ab15:0016::35"
echo
echo "0: Volver"
echo "1: Insertar"
echo "2: Borrar"
echo
echo "* Para volver a la configuracion por defecto borrar todas las direcciones"
echo
echo -n "Opcion: "
read conf
case $conf in 
	1) #Insertar Listen Address
	echo -n $n_conf
	read conf
	#Le añadimos la etiqueta ##LA_
	echo "##LA_$conf" >> $archivo
	echo "ListenAddress $conf" >> $archivo		
	#Comprobamos que se ha realizado correctamente
	check
	intro
	;;

	2) #Eliminar Listen Address
	echo "Configuracion: "
	cat -n ar.txt
	echo -n $e_conf

	#Capturamos la listen addres del archivo ar.txt
	read conf 
	cadena=`str_linea $conf ar.txt` 

	#capturamos la linea donde se encuentra la etiqueta
	conf=`n_linea $cadena $archivo`
	let cadena=$conf+1
	
	#Borramos las lineas
	borrar_lineas $conf $cadena $archivo
	#Comprobamos que se ha realizado correctamente
	check
	intro
	;;
	*)
	continue
	;;
esac
}

function configurar(){
clear
case $1 in
	1)
	#configuracion del puerto ssh
	echo "================================"
	echo "SSH > Menu > Parametros > Puerto"
	echo "================================"
	echo
	echo "Puerto por defecto: 22"
	#Capturamos y mostramos el puerto actual
	numlin=`n_linea "Port" $archivo`	
	cadena=`str_linea $numlin $archivo`
	cadena=`echo $cadena | cut -d " " -f2`	
	echo "Puerto actual: $cadena"
	echo
	#pedimos confirmacion 
	echo -n $p_conf
	read sn	
	if test $sn = "s"
	then
		echo -n $n_conf
		read conf
		var="Port $conf"
		cadena=`str_linea $numlin $archivo`		
		mod_linea $numlin "$cadena" "$var" $archivo
		#Comprobamos que se ha realizado correctamente
		check
		intro
	else
		echo
	fi
	echo	
	;;

	2) #configuracion Listen Addres
	echo "==========================================="
	echo "SSH > Menu > Parametros > Puerto de escucha"
	echo "==========================================="
	echo
	echo "Por defecto: Escucha por todos las direcciones IP"
	echo -n "Configuracion actual: "
	numlin=`n_linea "ListenAddress" $archivo`	
	
	#Comprobamos que solo haya las posiciones 7 y 8
	#Significa que escucha todos los puertos
	if test "$numlin" = "7 8" 
	then
		echo "Escucha por todos las direcciones IP"
	else
		echo
		#Capturamos los listen address nuevos
		grep "##LA_" $archivo > ar.txt
		#Mostramos los listen address nuevos
		var=`cut -d "_" -f2 ar.txt| cat -n`
		echo "$var"
	fi
	echo
	#Pedimos si queremos cambiar la configuracion
	echo -n $p_conf
	read sn	
	if test $sn = "s"
	then
		config_LA
	fi	
	;;
	
	3) #Permitir root login
	echo "===================================="
	echo "SSH > Menu > Parametros > Root login"
	echo "===================================="
	echo
	echo "Por Defecto: yes"	
	
	#linea 26 posicion por defecto de PermitRootLogin	
	cadena=`str_linea /^PermitRootLogin/ $archivo | cut -d " " -f2`
	echo "Configuracin actual: $cadena"
	echo
	echo "0: Volver"
	echo "1: Permitir"
	echo "2: No permitir"
	echo
	echo -n "Opcion: "
	read var
	
	numlin=`n_linea "^PermitRootLogin" $archivo`	
	cadena=`str_linea $numlin $archivo`	
	if test $var -eq 1
	then
		
		var="PermitRootLogin yes"		
		mod_linea $numlin "$cadena" "$var" $archivo
		check
		intro
	else 
		if test $var -eq 2
		then
			var="PermitRootLogin no"		
			mod_linea $numlin "$cadena" "$var" $archivo
			check
			intro
		fi
	fi	
	;;

	4) #Permitir aplicaciones graficas
	echo "==============================================="
	echo "SSH > Menu > Parametros > Aplicaciones graficas"
	echo "==============================================="
	echo
	echo "Por defecto: yes"
	numlin=`n_linea "X11Forwarding" $archivo`
	cadena=`str_linea $numlin $archivo | cut -d " " -f2`
	echo "Configuracion actual: $cadena"
	echo
	echo "0: Volver"
	echo "1: Permitir"
	echo "2: No permitir"
	echo
	echo -n "Opcion: "
	read var

	cadena=`str_linea $numlin $archivo`
	if test $var -eq 1
	then
		var="X11Forwarding yes"			
		mod_linea $numlin "$cadena" "$var" $archivo
		check
		intro 
	else
		if test $var -eq 2
		then
		var="X11Forwarding no"
		mod_linea $numlin "$cadena" "$var" $archivo
		check
		intro
		fi
	fi
		
	;;

	5) #Usuarios permitidos
	i3=-1
	while test $i3 -ne 0
	do
		clear
		echo "=================================="
		echo "SSH > Menu > Parametros > Usuarios"
		echo "=================================="
		echo
		echo "*** El nombre de usuario puede ir seguido de una IP ***"
		echo "*** Asi solo se puede conectar ese usuario por esa IP ***"
		echo "*** Ejemplo usuario@192.168.1.1 ***"
		echo "*** AllowUsers no es un usuario ***"
		echo "*** Para volver a la configuracion por defecto borrar todos los usuarios ***"
		echo
		echo "Por defecto: Todos los usuarios"
		conf=`n_linea "AllowUsers" $archivo`
	
		#Comprobamos que la conf esta vacio
		if test -z $conf 
		then
			cadena="Todos los usuarios"
		else
			cadena=`str_linea $conf $archivo`
		fi
		echo "Configuracion actual: $cadena"
		echo
		echo "0: Volver"
		echo "1: Añadir Usuario"

		#el menu depende de que conf este vacio o no				
		if test -z $conf 
		then
			echo
		else
			echo "2: Eliminar Usuario"
			echo "3: Eliminar todos los usuarios"
			echo
		fi
		
		echo -n "Opcion: "
		read var
		if test $var -eq 1 #usuario nuevo
		then 
			echo -n "Nombre del usuario nuevo: "
			read opcion
			if test -z $conf 
			then
				echo "AllowUsers $opcion" >> $archivo
			else
				cadena=`str_linea $conf $archivo`
				mod_linea $conf "$cadena" "$cadena $opcion" $archivo
			fi
		else
			if test $var -eq 2 #borrar usuario
			then
				echo -n "Nombre del usuario a borrar: "
				read opcion
		
				#comprobamos que el usuario no es AllowUsers	
				if test $opcion = "AllowUsers"
				then
					echo "AllowUsers no es un usuario"
				else
					#capturamos la cadena con los usuarios
					cadena=`str_linea $conf $archivo`
		
					#borramos el usuario de la cadena
					cadena2=`devuelve_cadena $opcion $cadena`
					#modificamos la cadena
					numlin=`n_linea "$cadena" $archivo`
					mod_linea $numlin "$cadena" "$cadena2" $archivo
				fi
			else				
				if test $var -eq 3 #borrar todos los usuarios
				then
					borrar_lineas $conf $conf $archivo
				else 
					i3=0
				fi
			fi
		fi
	done	
	;;

	6)
	opcion=-1
	while test $opcion -ne 0
	do
		clear
		echo "==========================================="
		echo "SSH > Menu > Parametros > Banner de entrada"
		echo "==========================================="
		echo
		echo "0: Volver"
		echo "1: Ver banner actual"

		#comprobamos que el banner esta comentando
		#cambiamos el menu dependiendo de si esta comentado o no
		conf=`n_linea "#Banner" $archivo`		
		if test -z $conf
		then
			echo "2: No mostrar banner al conectar usuario"
		else
			echo "3: Mostrar banner al conectar usuario"
		fi
		echo "4: Modificar banner"
		echo 
		echo -n "Opcion: "
		read opcion
		banner $opcion
	done	
	;;
	*)
	continue
	;;
esac	
}
function opciones(){
i2=-1
case $1 in
	1) #Configuracion Manual
	while test $i2 -ne 0
	do
		
		clear
		echo "======================="
		echo "SSH > Menu > Parametros"
		echo "======================="
		echo
		echo "0: Volver"
		echo "1: Modificar puerto"
		echo "2: Modificar direcciones de escucha"
		echo "3: Permitir root login"
		echo "4: Ejecucion remota de aplicaciones graficas"
		echo "5: Permitir usuarios"
		echo "6: Opciones de banner de entrada"
		echo
		echo -n "Elige opcion: "
		read i2
		configurar $i2
	done
	;;
	2)
	clear	
	echo "================================="
	echo "SSH > Menu > Configuracion actual"
	echo "================================="
	echo
	
	#Mostramos el estado del servidor
	service ssh status > ar.txt	
	echo -n "Estado del servidor: "
	cat ar.txt | cut -d " " -f2 | cut -d "/" -f1
	rm ar.txt

	#Capturamos puerto
		numlin=`n_linea "Port" $archivo`	
		cadena=`str_linea $numlin $archivo`
		cadena=`echo $cadena | cut -d " " -f2`
		echo "Puerto: $cadena"
	
	#Capturamos root login	
		numlin=`n_linea "^PermitRootLogin" $archivo`					
		cadena=`str_linea $numlin $archivo | cut -d " " -f2`
		echo "Permitir root login: $cadena"

	#Aplicaciones graficas
		numlin=`n_linea "X11Forwarding" $archivo`
		cadena=`str_linea $numlin $archivo | cut -d " " -f2`
		echo "Ejecucion remota de aplicaciones graficas: $cadena"

	#Capturamos los usuarios permitidos
		conf=`n_linea "AllowUsers" $archivo`
		#Comprobamos que conf esta vacio
		if test -z $conf 
		then
			cadena="Todos los usuarios"
		else
			cadena=`str_linea $conf $archivo`
		fi
		echo "Permitir usuarios: $cadena"

	#Direcciones de escucha	
		
		echo -n "Direcciones de escucha: "
		#Comprobamos que solo haya las posiciones 7 y 8
		#Significa que escucha todos los puertos
		numlin=`n_linea "ListenAddress" $archivo`
		if test "$numlin" = "7 8" 
		then
			echo "Escucha por todos las direcciones IP"
		else
			echo
			#Capturamos los listen address nuevos
			grep "##LA_" $archivo > ar.txt
			#Mostramos los listen address nuevos
			cat -n ar.txt
		fi
	
	#Banner
		echo -n "Banner: "
		conf=`n_linea "#Banner" $archivo`		
		if test -z $conf
		then
			echo "Mostrar "
		else
			echo "No mostrar"
		fi
	
	echo
	intro
	;;

	3) #Reiniciar servicio
	echo
	service ssh restart > /dev/null 2> /dev/null
	if test $? -eq 0
	then
		echo "Servicio reiniciado correctamente"
	else
		echo "No se ha podido reiniciar el servicio"
	fi	
	intro
	;;

	4) #Iniciar servicio
	echo
	service ssh start > /dev/null 2> /dev/null	
	if test $? -eq 0
	then
		echo "Servicio iniciado correctamente"
	else
		echo "No se ha podido iniciar el servicio"
	fi
	intro
	;;

	5) #Parar servicio
	echo
	service ssh stop > /dev/null 2> /dev/null
	if test $? -eq 0
	then
		echo "Servicio parado correctamente"
	else
		echo "No se ha podido parar el servicio"
	fi
	intro
	;;

	*)
	continue
	;;
esac
}

#Menu principal
i=-1
while test $i -ne 0
do
	clear
	echo "=========="
	echo "SSH > Menu"
	echo "=========="
	echo
	echo "0: Volver"
	echo "1: Configuracion"
	echo "2: Ver configuracion"
	echo "3: Reiniciar servicio"
	echo "4: Iniciar servicio"
	echo "5: Parar servicio"
	echo
	echo -n "Elige opcion: "
	read i	
	
	opciones $i
done
#Limpiamos variables
i=
i2=
i3=
iLA=
opcion=
confssh=
numlin=
cadena=
cadena2=
p_conf=
n_conf=
sn=
conf=
var=
Rcadena=
buscar=
tam=
archivoBan=
e_conf=
