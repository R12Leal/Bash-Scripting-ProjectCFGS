# Archivo funciones comunes 0.4
# Realizdo por:
#	Adrià Moyá Massanet
# 	Ramses Leal Líndez
# 	Luís Eduardo Álvarez Domínguez

function borrar_lineas (){
# Borrar conjunto de lineas
#$1 Linea de inicio $2 nº líneas a borrar $3 Archivo afectado	
sed -i "$1,$2"'d' $3
}		
#
function n_linea (){
# Devuelve nº de línea de una cadena 
# $1 cadena a buscar $2 archivo afectado
linea=`sed -n "/$1/=" $2`
echo $linea
linea=
}
# 
function mod_linea (){
# Función para modificar líneas en un archivo
# $1 linea $2 cadena a sustituir $3 cadena de substitucion $4 archivo afectado
sed -i -e "$1,$1s/$2/$3/g" $4
}
function str_linea (){
# Funcion para devolver la cadena de una linea
# $1 numero de linera $2 archivo
cadena=`sed -n "$1"'p' $2`
echo $cadena
cadena=
}

function intro(){ 
#funcion para poder mostrar
read -p "Pulse Intro para continuar"
}

