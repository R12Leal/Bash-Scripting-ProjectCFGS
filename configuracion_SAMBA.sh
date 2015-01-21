#! /bin/bash
# configuracion_SAMBA.sh 0.9
# Script para configurar el servicio SAMBA
# Realizado por: Ramsés Leal
# Grupo de Trabajo: Adrià Moyà - Luis Álvarez - Ramsés Leal
#
# Funciones generales de la aplicación
. funciones.sh
# Funciones para servicio SAMBA
function recursos_compartidos (){
	echo "==================================="		
	echo " Recursos compartidos SAMBA        "		
	echo "==================================="				
		# Filtramos mediante grep para que nos devuelva los distintos nombres de recursos
		# creados en el sistema y se guarda en un fichero oculto llamado .rc
		echo
		grep "^#--" $archivo >> .rc
		# Comprobamos si el archivo creado esta vacío.
		# Si no esta vacío nos listará por numero todas la lineas que se encuentren en el archivo mediante la orden CAT.
		# En caso contrario significa que no existen recursos condigurados en el servidor y muestra un mensaje informativo.
		if test -s .rc
		then
			cat -n .rc 
		else					
			echo "==================================="
			echo "No puede modificar,borrar o mostrar"
			echo "no exite recursos compartidos en el"
			echo "servidor actualmente"
			echo "==================================="
		fi
}
# Función para eliminar el archivo generado con la funcion recursos_compartidos.
function borrar_ficheros_generados (){
	# orden para borrar dicho archivo oculto.
		rm .rc
}
# Función para crear usuarios de recursos compartidos.
function add_usuario_samba (){
	# orden para crear usuario: mediante modificadores indicamos que es de sistema
	# no le creará una carpeta en home, su login estará desabilitado y también el 
	# password para acceder al sistema.
	adduser --system --no-create-home --disabled-login --disabled-password $1 > $s_null
	# Comprobamos que los datos introducidos son idénticos
	echo
	passwd1="1"
	passwd2="2"
	while test ! "$passwd1" = "$passwd2"
	do
		echo -n "Introduzca password por favor: "
		read passwd1
		echo -n "Repita de nuevo password por favor: "
		read passwd2
		if test ! "$passwd1" = "$passwd2"
		then
			echo
			echo "Los datos introducidos no coinciden"
			echo
		fi
	done
	passwd_total=$passwd2
	# Introducimos una contraseña que solo es valida para el servicio SAMBA para el usuario
	# creado anteriormente.	
	(echo $passwd_total; echo $passwd_total ) | smbpasswd -s -a $1 > $s_null
	# Comprobamos que la orden se ha ejecutado correctamente.
 	if test $? -eq 0
	then
		echo 
		echo "Usuario "$1" añadido a SAMBA"
	else
		echo
		echo "Se ha producido un error en la ejecución, contacte con administrador"
	fi 
}
# Función para comprobar si el valor que le es pasado es un número.
function isnum (){
	let var=$1*$1 2> /dev/null
	if test $? -eq 0
	then
		echo true
	else
		echo false
	fi
}
# Función que contiene las opciones para configurar el servicio SAMBA.
function conf_samba (){	
	# Utilizamos CASE para redirigir las opciones:
	case $1 in	
		1) # Comprobar recursos compartidos.
		clear
		echo "===================================" 
		echo " Menú SAMBA > Recursos actuales    "  
		# Solo nos muestra los recursos compartidos que el usuario ha configurado 
		# Llamando a las funciones recursos_compartidos y borrar_ficheros_generados.
		recursos_compartidos
		borrar_ficheros_generados		
		echo
		# función INTRO 		
		intro
		;;
		2) # Configuración Global del Servicio
		# Esta opción nos permite configurar el servicio SAMBA para que los recursos
		# funcionen correctamente. Una vez configurado se podrá acceder de nuevo pero
		# solo para reconfigurar el nombre del servidor.
		clear
		echo "==============================================="
		echo " Menú SAMBA > Configuración Global             "		
		echo "==============================================="
		echo " Bienvenido a la configuración Global de SAMBA."
		echo " La configuración se realizará automáticamente "
		echo "==============================================="
		echo			
		echo -n "Desea Comenzar el proceso de configuración? (s/n): "
		read configuracion
			# Condición IF para comprobar si desea realizar la configuración global.
			if test $configuracion = "s"
				then
				# Variable que contiene una etiqueta que será añadida al archivo de configuración
				# para conocer si SAMBA se encuentra configurado correctamente.
				etiqueta="##--ServicioConfigurado--##"
				# En la variable $li_servicio guardamos la línea donde se encuentra la etiqueta
				# creada anteriormente.
				li_servicio_configurado=`n_linea "$etiqueta" $archivo`
				# Condición IF en la cual comprobamos mediante el modificador -z si la variable
				# esta vacía o no. Si esta vacía significa que no existe la etiqueta en el archivo,
				# por tanto no se ha configurado el servicio y comenzará la configuración				
				if test -z $li_servicio_configurado
					then					
					echo
					echo "Introduzca nombre identificativo del servidor"
					echo -n "(Este nombre será visible desde S.O. Windows): "
					read nombre_servidor
						# Variables: contienen la cadena de parámetros de la configuración.
						security="#   security = user"
						serv_string="   server string = %h server (Samba, Ubuntu)"
						workg="   workgroup = WORKGROUP"     									
						# Variables que llamando a la funcion n_linea obtiene
						# la línea donde esta ubicada la cadena. Se le pasa
						# como parámetros la cadena y el archivo.					
						li_security=`n_linea "$security" $archivo`
						li_sname=`n_linea "$serv_string" $archivo`
						li_workgroup=`n_linea "$workg" $archivo`
						# Variables que contienen las cadenas de texto para reemplazar.
						ch_security="security=share"					
						ch_server_string="server string = "$nombre_servidor
						ch_workg="#workgroup=workgroup"
						# Llamamos a la función mod_linea para realizar las oportunas
						# modificaciones para que el servicio funcione.					
						echo "##--ServicioConfigurado--##" >> $archivo
						mod_linea "$li_security" "$security" "$ch_security" $archivo					
						mod_linea "$li_sname" "$serv_string" "$ch_server_string" $archivo
						mod_linea "$li_workgroup" "$workg" "$ch_workg" $archivo
						# Borramos recursos por defectos que crea el servidor.
						# [Print$]
						linea_print=`n_linea "\[print$\]" $archivo`
						if test ! -z $linea_print
						then					
							let intervalo_print=$linea_print+5
							borrar_lineas "$linea_print" "$intervalo_print" $archivo
						fi						
						# [Printers]
						linea_printers=`n_linea "\[printers\]" $archivo`
						if test ! -z $lineas_printers
						then
							let intervalo_printers=$linea_printers+7
							borrar_lineas "$linea_printers" "$intervalo_printers" $archivo
						fi						
						# Regresamos a Menú Principal
						echo					
						echo "La configuración se ha ejecutado correctamente"
						# función INTRO
						intro					
					else
					# En caso contrario significa que la etiqueta existe en el
					# servidor y que el servicio se configuró anteriormente.
					# Nos informa con un mensaje y solo nos permite cambiar el nombre que se
					# mostrará en los S.O. Windows.
						clear
						echo "==============================================="
						echo " Menú SAMBA > Configuración Global             "		
						echo "==============================================="
						echo " La configuración del servicio esta completada."
						echo " Una vez realizada la configuración básica de  "
						echo " SAMBA solo se permite el cambio de nombre que "
						echo " que será mostrado en los S.O. Windows"
						echo "==============================================="
						echo
						echo -n "Desea reconfigurar el nombre del servidor SAMBA? (s/n): "
						read reconfiguracion
							# Condición IF para comprobar si el usuario desea reconfigurar el nombre.
							if test $reconfiguracion = "s" 
							then	
								# Obtenemos el nuevo nombre que el usuario desea configurar
								echo
								echo "Introduzca el nuevo nombre identificativo del servidor"
								echo -n "(Este nombre será visible desde S.O. Windows): "
								read nom_servidor
								# Primero con la variable $nservidor obtenemos en que línea se encuentra el texto.
								# Después con la variable $cdn_servidor obtenemos la cadena concreta de esa linea.
								# La última variable $nom_servidor contiene el texto a substituir.
								nservidor=`n_linea 'server string = ' $archivo`
								cdn_servidor=`str_linea $nservidor $archivo`
								nom_servidor="server string = "$nom_servidor
								# Por último llamamos a la función mod_linea pasándole como parámetros la línea
								# la antigua cadena, la cadena por la cual vamos a substituir y el archivo de
								# de configuración del servicio SAMBA.
								mod_linea "$nservidor" "$cdn_servidor" "$nom_servidor" $archivo
								# Reiniciamos el servicio SAMBA.
								service smbd restart > $s_null
								# Informamos al usuario que el proceso tuvo éxito
								echo 
								echo "Se ha configurado en nuevo nombre del servidor SAMBA"
								echo
								# función INTRO
								intro			
							fi								
					fi			
				fi
		;;
		3) # Añadir recurso compartido.
		# Esta opción nos permite añadir un recurso compartido en el servidor.
		# Se puede añadir un recurso publico o bien un recurso privado (usuario-contraseña).
		# Menú para añadir el recurso.
		clear
		echo "================================"
		echo " Menú SAMBA > Añadir recurso    "
		echo "================================"
		echo "0 - Volver"			
		echo "1 - Recurso compartido Público"
		echo "2 - Recurso compartido Privado"
		echo "================================"				
		echo
		echo -n "Elige tipo de recurso: "
		read recurso
			case $recurso in
				1) # Recurso compartido Público.
				clear
				echo "====================================================================="
				echo " Menú SAMBA >> Añadir recurso >> Recurso compartido público          " 
				echo "====================================================================="
				echo "Un recurso compartido público será accesible por todos los usuarios."
				echo "Puede definir si desea que los usuarios tengan permiso de lectura o"
				echo "bien permiso de escritura."
				echo "====================================================================="
				echo
				# Obtenemos parámetros principales para la nueva configuración
				echo -n "Introduce nombre del recurso nuevo: "
					read nombre_recurso
				# Comprobamos que el nombre de recurso está 
				# definido ya en el archivo de configuración
				nl_existe=`n_linea "\[$nombre_recurso\]" $archivo`
					if test ! -z $nl_existe
					then
						echo
						echo "---------------------------------------------------------------------"
						echo "El nombre de recurso "$nombre_recurso" introducido ya existe"
						echo "Debe modificar los datos antes de poder añadir el nuevo recurso."
						echo "---------------------------------------------------------------------"
						nombre_recurso=
					fi			
				#
				echo
				echo -n "Introduce comentario para el recurso: "
					read comentario
				echo
				echo -n "Indica la ruta que será compartida: "
					read path
					# Comprobamos que el directorio introducido no existe.
					# Si no existe le indicamos al usuario que la ruta no 
					# se encuentra en el sistema y que deberá modificarla posteriormente.
					if test ! -d "$path"
					then
						echo
						echo "---------------------------------------------------------------------"
						echo "La ruta "$path" no existe en el sistema."
                                                echo "Debe modificar los datos antes de poder añadir el nuevo recurso."
						echo "---------------------------------------------------------------------"	
						path=
					fi
				echo
				echo "Permisos de recurso:'solo lectura'(r) o 'lectura y escritura'(w)"
				echo -n "AVISO: Cualquier otro carácter no configura ningún permiso: "
				read rw
				# IF que determinará dependiendo de la respuesta del usuario que
				# contendrá la variable write.
					if test "$rw" = "r"
					then
						write="writable=no"
					elif test "$rw" = "w"
					then
						write="writable=yes"
					elif test -z "$rw"
					then
						write=
					else
						write=
					fi
				# Mostramos información introducida del usuario para proporcionarle una forma
				# de poder modificar en caso de que el usuario tenga un error intruciendo datos.
				op_publico=-1
				while test -z $op_publico || test $op_publico -ne 5 || test "$isnum" = "false" 
				do
				# Menú con los datos correspondientes introducidos por el usuario. 
				clear
				echo "====================================================================="
				echo " Menú SAMBA > Añadir recurso > Recurso compartido público            " 		
				echo "====================================================================="
				echo " La configuración de recurso público es la siguiente:                "
				echo "====================================================================="
				echo
				echo -e "1 - Nombre del nuevo recurso: \e[1;34m"$nombre_recurso"\e[0m"
				echo -e "2 - Comentario: \e[1;34m"$comentario"\e[0m"
				echo -e "3 - Ruta: \e[1;34m"$path"\e[0m"
					if test "$rw" = "r"
					then
						echo -e "4 - Permisos: \e[1;34m'Solo lectura'\e[0m"
					elif test "$rw" = "w"
					then
						echo -e "4 - Permisos: \e[1;34m'Lectura y escritura'\e[0m"
					elif test -z "$rw"
					then
						echo -e "4 - Permisos: \e[1;34m'Sin Permiso' (Obligatorio incluir permiso)\e[0m"
					else
						echo -e "4 - Permisos: \e[1;34m'Sin Permiso' (Obligatorio incluir permiso)\e[0m"
					fi 
				echo "5 - Finalizar y añadir recurso"
				echo
				echo "====================================================================="
				echo
				echo -n "Puede modificar los parámetros o finalizar introduciendo el número: "
				read op_publico
				# Comprobamos que el valor introducido sea un numero con la funcion isnum.
				isnum=`isnum $op_publico`
				# Case que contiene las opciones para realizar las modificaciones que 
				# el usuario desee realizar.
				case $op_publico in
						1) # Nombre de recurso a introducir de nuevo.
							echo 
							echo -n " - Nombre del nuevo recurso: "
							read nombre_recurso
							# Comprobamos de nuevo que el nombre de recurso existe en el archivo de configuración.
								nl_existe=`n_linea "\[$nombre_recurso\]" $archivo`
								if test ! -z $nl_existe
								then
									echo
									echo "---------------------------------------------------------------------"
									echo "El nombre de recurso "$nombre_recurso" introducido ya existe"
									echo "Por favor introduzca un nombre de recurso que no esté configurado."
									echo "---------------------------------------------------------------------"	
									nombre_recurso=
								fi			
							echo
							# función INTRO
							intro
						;;
						2) # Comentario a introducir de nuevo.
							echo 
							echo -n " - Comentario del nuevo recurso: "
							read comentario
							echo
							# función INTRO
							intro
						;;
						3) # Ruta del recurso compartido a introducir de nuevo.
							echo 
							echo -n " - Ruta del nuevo recurso: "
							read path
							# Comprobamos de nuevo que la ruta existe en el sistema.
							if test ! -d "$path"
							then
								echo
								echo "---------------------------------------------------------------------"
								echo "La ruta "$path" no existe en el sistema."
                                               			echo "Por favor introduzca un ruta que exista en su sistema."
								echo "---------------------------------------------------------------------"	
								path=
							fi
							echo
							# función INTRO
							intro
						;;
						4) # Permisos del recurso compartido a introducir de nuevo.
							echo 
							echo " - Permisos del nuevo recurso: "
							echo "   Permiso de 'Solo lectura' - r"
							echo "   Permiso de 'Lectura y escritura' - w"
							echo "   AVISO: Cualquier otro carácter no configura ningún permiso."
							echo
							echo -n "Eliga permiso: "
							read rw
							# Condición IF para determinar los permisos del recurso.
								if test "$rw" = "r"
								then
									write="writable=no"
								elif test "$rw" = "w"
								then
									write="writable=yes"
								elif test -z "$rw"
								then
									write=
								else
									write=
								fi	
							echo
							# función INTRO
							intro						
						;; 
						5) # Continuar con la ejecución
						   # En caso de que las variables se encuentren vacías significa que no estan
						   # los datos necesarios para añadir el recurso nuevo. Por tanto regresará
						   # al principio del bucle hasta que estén configurados correctamente.
							if test ! -z "$nombre_recurso" -a "$comentario" -a "$path" -a "$write"
							then
								# Salimos del bucle y continuamos con la ejecución.
								continue
							else
								echo
								echo "faltan parámetros por indicar.Por favor añada estos datos..."
								echo
								# función INTRO
								intro
								# Cambiamos la variabale op_publico para regresar al principio
								# del bucle.
								op_publico=-1
							fi
						;;
					esac									
				done
				# Cambiamos los permisos de la ruta indicada por el usuario.
				chmod 777 $path
				# Variables que contienen las cadenas que serán escritas en el fichero
				# de configuración del servicio SAMBA.
				recurso="["$nombre_recurso"]"
				comment="comment="$comentario
				ruta="path="$path
				publico="public=yes"
				invitado="guest ok=yes"
				# Por último redireccionamos para que se produzca la escritura en el archivo.
				echo "#--"$nombre_recurso >> $archivo						
				echo $recurso >> $archivo
				echo $comment >> $archivo
				echo $ruta >> $archivo
				echo $publico >> $archivo
				echo $write >> $archivo
				echo $invitado >> $archivo
				echo "#valid_user=usuario" >> $archivo
				# Informamos al usuario del proceso y le indicamos si desea reiniciar
				# el servicio para que se apliquen los cambios.
				echo
				echo "La configuración se ha realizado correctamente."
				echo						
				echo "Reiniciando servicio SAMBA...."
				# Orden para reninicar el servicio SAMBA.
				service smbd restart > $s_null
				echo
				echo "Servicio SAMBA reiniciado correctamente"
				echo
				# función INTRO
				intro
				;;	
				2) # Recurso Privado.
				clear
				echo "============================================================="
				echo " Menú SAMBA > Añadir recurso > Recurso compartido privado    " 
				echo "============================================================="	
				echo "Un recurso compartido privado será accesible con validación. "
				echo "Los usuarios deberán introducir un usuario y contraseña.     "
				echo "============================================================="
				echo							
				echo -n "Introduce un nombre de usuario: "	
				read usuario_samba
				# Llamamos a la función add_usuario_samba para que cree el 
				# el nombre de usuario  introducido con una contraseña solo 
				# para el servicio SAMBA.
				add_usuario_samba $usuario_samba
				# Obtenemos parámetros principales para la nueva configuración.
				echo
				echo -n "Introduce nombre de recurso: "
				read recurso_privado
					nl_existe_p=`n_linea "\[$recurso_privado\]" $archivo`
					if test ! -z $nl_existe_p
					then
						echo
						echo "---------------------------------------------------------------------"
						echo "El nombre de recurso "$recurso_privado" introducido ya existe"
						echo "Debe modificar los datos antes de poder añadir el nuevo recurso."
						echo "---------------------------------------------------------------------"
						recurso_privado=
					fi			
				echo
				echo -n "Introduce comentario de recurso: "
				read comentario_privado
				echo
				echo -n "Indica la ruta que será compartida: "
				read path_privado
				# Comprobamos que el directorio introducido no existe.
				# Si no existe le indicamos al usuario que la ruta no 
				# se encuentra en el sistema y que deberá modificarla posteriormente.
					if test ! -d "$path_privado"
					then
						echo
						echo "---------------------------------------------------------------------"
						echo "La ruta "$path_privado" no existe en el sistema."
                                                echo "Debe modificar los datos antes de poder añadir el nuevo recurso."
						echo "---------------------------------------------------------------------"	
						path_privado=
					fi
				echo
				echo "Permisos de recurso:'solo lectura'(r) o 'lectura y escritura'(w)"
				echo -n "AVISO: Cualquier otro carácter no configura ningún permiso: "
				read rw_privado
				# IF que determinará dependiendo de la respuesta del usuario que
				# contendrá la variable write.
					if test "$rw_privado" = "r"
					then
						write_privado="writable=no"
					elif test "$rw_privado" = "w"
					then
						write_privado="writable=yes"
					elif test -z "$rw_privado"
					then
						write_privado=
					else
						write_privado=
					fi
				# Mostramos información introducida del usuario para proporcionarle una forma
				# de poder modificar en caso de que el usuario tenga un error intruciendo datos.
				op_privado=-1
				while test -z $op_privado || test $op_privado -ne 6 || test "$isnum" = "false"
				do
				# Menú con los datos correspondientes introducidos por el usuario. 
				clear
				echo "============================================================="
				echo " Menú SAMBA > Añadir recurso > Recurso compartido privado    " 
				echo "============================================================="
				echo " La configuración de recurso privado es la siguiente:        "
				echo "============================================================="
				echo
				echo -e "1 - Nombre del nuevo recurso: \e[1;34m"$recurso_privado"\e[0m"
				echo -e "2 - Comentario: \e[1;34m"$comentario_privado"\e[0m"
				echo -e "3 - Ruta: \e[1;34m"$path_privado"\e[0m"
					if test "$rw_privado" = "r"
					then
						echo -e "4 - Permisos: \e[1;34m'Solo lectura'\e[0m"
					elif test "$rw_privado" = "w"
					then 
						echo -e "4 - Permisos: \e[1;34m'Lectura y escritura'\e[0m"
					elif test -z "$rw_privado"
					then
						echo -e "4 - Permisos: \e[1;34m'Sin Permiso' (Obligatorio incluir permiso)\e[0m"
					else
						echo -e "4 - Permisos: \e[1;34m'Sin Permiso' (Obligatorio incluir permiso)\e[0m"
				fi
				echo -e "5 - Usuario de acceso al recurso: \e[1;34m"$usuario_samba"\e[0m" 
				echo -e "6 - Finalizar y añadir recurso"
				echo
				echo "============================================================="
				echo
				echo -n "Puede modificar los parámetros o finalizar introduciendo el número: "
				read op_privado
				# Comprobamos que el valor introducido sea un numero con la funcion isnum.
				isnum=`isnum $op_privado`
				# Case que contiene las opciones para realizar las modificaciones que 
				# el usuario desee realizar.
				case $op_privado in
					1) # Nombre de recurso a introducir de nuevo.
						echo 
						echo -n " - Nombre del nuevo recurso: "
						read recurso_privado
						# Comprobamos de nuevo que el nombre de recurso existe en el archivo de configuración.
						nl_existe_p=`n_linea "\[$recurso_privado\]" $archivo`
						if test ! -z $nl_existe_p
						then
							echo
							echo "---------------------------------------------------------------------"
							echo "El nombre de recurso "$recurso_privado" introducido ya existe"
							echo "Por favor introduzca un nombre de recurso que no esté configurado."
							echo "---------------------------------------------------------------------"
							recurso_privado=
						fi			
						echo
						# función INTRO
						intro
						;;
						2) # Comentario a introducir de nuevo.
						echo 
						echo -n " - Comentario del nuevo recurso: "
						read comentario_privado
						echo
						# función INTRO
						intro
						;;
						3) # Ruta del recurso compartido a introducir de nuevo.
						echo 
						echo -n " - Ruta del nuevo recurso: "
						read path_privado
						# Comprobamos de nuevo que la ruta existe en el sistema.
						if test ! -d "$path_privado"
						then
							echo
							echo "---------------------------------------------------------------------"
							echo "La ruta "$path_privado" no existe en el sistema."
                                                	echo "Por favor introduzca un ruta que exista en su sistema."
							echo "---------------------------------------------------------------------"	
							path_privado=
						fi
						echo
						# función INTRO
						intro
						;;
						4) # Permisos del recurso compartido a introducir de nuevo.
						echo 
						echo " - Permisos del nuevo recurso: "
						echo "   Permiso de 'Solo lectura' - r"
						echo "   Permiso de 'Lectura y escritura' - w"
						echo "   AVISO: Cualquier otro carácter no configura ningún permiso."
						echo
						echo -n "Eliga permiso: "
						read rw_privado
						# Condición IF para determinar los permisos del recurso.
							if test "$rw_privado" = "r"
							then
								write_privado="writable=no"
							elif test "$rw_privado" = "w"
							then
								write_privado="writable=yes"
							elif test -z "$rw_privado"
							then
								write_privado=
							else
								write_privado=
							fi
						echo
						# función INTRO
						intro
						;;
						5) # Usuario del recurso compartido a introducir de nuevo.
						echo 
						echo -n " - Usuario del nuevo recurso: "
						read usuario_samba
						echo
						# función INTRO
						intro
						;; 
						6) # Continuar con la ejecución
						# En caso de que las variables se encuentren vacías significa que no estan
						# los datos necesarios para añadir el recurso nuevo. Por tanto regresará
						# al principio del bucle hasta que estén configurados correctamente.
						if test ! -z "$recurso_privado" -a "$comentario_privado" -a "$path_privado" -a "$write_privado" -a "$usuario_samba"
						then
							# Salimos del bucle y continuamos con la ejecución.
							continue
						else
							echo
							echo "faltan parámetros por indicar.Por favor añada estos datos..."
							echo
							# función INTRO
							intro
							# Cambiamos la variabale op_publico para regresar al principio
							# del bucle.
							op_privado=-1
						fi
						;;
					esac										
					done
				# Cambiamos los permisos de la ruta indicada por el usuario.
				chmod 777 $path_privado
				# Variables que contienen las cadenas que serán escritas en el fichero
				# de configuración del servicio SAMBA.					
				recurso_priv="["$recurso_privado"]"
				comment_privado="comment="$comentario_privado
				ruta_privado="path="$path_privado
				publico_privado="public=yes"
				invitado_privado="guest ok=no"
				usuario="valid users="$usuario_samba
				# Por último redireccionamos para que se produzca la escritura en el archivo.
				echo "#--"$recurso_privado >> $archivo						
				echo $recurso_priv >> $archivo
				echo $comment_privado >> $archivo
				echo $ruta_privado >> $archivo
				echo $publico_privado >> $archivo
				echo $write_privado >> $archivo
				echo $invitado_privado >> $archivo
				echo $usuario >> $archivo	
				# Informamos al usuario del proceso y le indicamos si desea reiniciar
				# el servicio para que se apliquen los cambios.
				echo						
				echo "La configuración se ha realizado correctamente."
				echo						
				echo "Reiniciando servicio SAMBA...."
				# Orden para reninicar el servicio SAMBA.
				service smbd restart > $s_null
				echo
				echo "Servicio SAMBA reiniciado correctamente"
				echo
				# función INTRO
				intro
				;;
				*) # Default
				continue
				;;
				esac
		;;
		4) # Borrar recurso compartido
		clear
		echo "===================================" 
		echo " Menú SAMBA > Borrar recurso       "
		# Invocamos a a la función recursos_compartidos que nos devolverá la lista
		# numerada de los recursos compartidos que tengamos configurados.		
		recursos_compartidos
		# Condición IF que comprueba si el archivo esta vacío o no.
		if test ! -s .rc
		then
			# En este caso, si el archivo esta vacío, significa que no existe ningún recurso compartido
			# y mostramos mensaje para regresar al menú de configuración.
			echo
			# función INTRO
			intro
			borrar_ficheros_generados
		else
			# En este caso, el archivo no esta vacío, por tanto existen recursos compartidos
			# y pedimos al usuario que introduzca el recurso a eliminar.
			echo 
			echo -n "Que recurso compartido desea eliminar?: "
			read eliminar
			# Comprobamos cuantas lineas tiene el archivo que contiene los recursos compartidos.
			total_lineas=`wc -l .rc | cut -d " " -f 1`
			# Función para comprobar si el valor introducido es un numero.
			isnum=`isnum $eliminar`
			if test ! -z $eliminar && test $isnum = "true" && test $eliminar -le $total_lineas
			then 
				# Esta variable contiene el resultado obtenido con la función str_linea, que coge
				# el texto del número de linea que ha introducido el usuario. El número se especifica
				# en la función recursos compartidos.
				texto_recurso=`str_linea "$eliminar" .rc`							
				# Mensaje que indica que recurso será eliminado del servicio
				echo
				read -p "El recurso "$texto_recurso" será eliminado. INTRO para comenzar: "	
				# Esta variable contiene el resultado obtenido con la función n_linea, que devuelve el número
				# de linea donde se encuentra el texto almacenado en la variable $texto_recurso.
				num_linea=`n_linea "$texto_recurso" "$archivo"`
				# Esta variable contiene el intervalo de lineas que deberá borrar. Le sumamos 7, ya 
				# que tanto un recurso compartido o como un recurso público tienen 7 líneas en total  
				# configuradas. Le sumamos 7 a partir de la línea en la cuál ha encontrado el $texto_recurso.			
				let intervalo=$num_linea+7
				# Borramos todas líneas con la función borrar_lineas, pasándole como parámetros el $num_linea,
				# el intervalo y el archivo de configuración del servicio.
				borrar_lineas $num_linea $intervalo "$archivo"
				# Orden que reinicia el servicio SAMBA
				service smbd restart > $s_null				
				# Borramos los archivos generados.				
				borrar_ficheros_generados	
				# Mensaje Informativo de borrado completo.
				echo
				echo "Se ha borrado correctamente el recurso "$texto_recurso
				echo  
				# función INTRO
				intro
			fi
			borrar_ficheros_generados							
		fi
		;;
		*) # Default
		continue
		;;
	esac
}
#
clear
# Configuración de Servicio SAMBA
# Comprobamos que el servicio se encuentre instalado. Evitamos que realizen
# las acciones ejecutando directamente este script. Comprobamos si existe el
# script que inicia el servicio SAMBA con la variable $daemon.
daemon="/etc/init.d/smbd"
# la variable $s_null contiene /dev/null (periférico nulo) que si se redirecciona 
# no proporciona ningún dato sobre las órdenes que se ejecutan.
s_null="/dev/null"
#
# sudo su ./configuracion_SAMBA.sh
if test -f $daemon
then
i=-1
while test $i -ne 0
do
		# Menú Principal de configuración SAMBA
		clear
		echo "================================================="
		echo " Bienvenido a la configuración de servicio SAMBA"
		echo "================================================="
		echo		
		echo "0: Volver"
		echo "1: Mostrar recursos compartidos"
		echo "2: Configuración automática y Global de SAMBA"
		echo "3: Añadir nuevo recurso compartido"
		echo "4: Borrar recurso compartido"
		echo
		echo "================================================="
		echo " AVISO: Si es la primera vez que accede al menú  "
		echo " de configuración de SAMBA o bien restauró el    "
		echo " archivo de configuración debe realizar la       "
		echo " configuración global del servicio (Opción 2)    " 
		echo "================================================="
		echo
		echo -n "Elige una opción: " 
		read i
		# invoca a la función conf_samba pasando como parámetro el número escogido por el usuario
		conf_samba $i	
done
else
	echo "El Servicio SAMBA no se encuentra instalado"
	read -p "Debe iniciar el script principal"
	exit
fi
# Una vez regresemos al menú de servicios liberaremos las variables creadas
i=
etiqueta=
li_servicio_configurado=
security=
serv_string=
workg=
li_security=
li_sname=
li_workgroup=
ch_security=
ch_server=
ch_workg=
linea_print=
intervalo_print=
linea_printers=
intervalo_printers=
reconfiguracion=
nservidor=
cdn_servidor=
nom_servidor=
recurso=
nombre_recurso=
comentario=
path=
rw=
recurso=
comment=
ruta=
publico=
invitado=
write=
confirmar=
usuario=
recurso_privado=
comentario_privado=
path_privado=
rw_privado=
recurso_priv=
comment_privado=
ruta_privado=
publico_privado=
invitado_privado=
usuario=
write_privado=
eliminar=
texto_recurso=
num_linea=
intervalo=
daemon=
s_null=
nl_existe_p=
nl_existe=
op_publico=
op_privado=
usuario_samba=
isnum=
total_lineas=
passwd1=
passwd2=
passwd_total=
