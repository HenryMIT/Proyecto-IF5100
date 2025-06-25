#!/bin/bash

USUARIO="root"
PASSWORD="admin"
BASE_DATOS="CR_chat"
ARCHIVO="/backup/mysql_2025.sql.gz"

# Crear base de datos si no existe
mysql -u "$USUARIO" -p"$PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $BASE_DATOS;"

# Restaurar desde backup comprimido
if gunzip < "$ARCHIVO" | mysql -u "$USUARIO" -p"$PASSWORD" "$BASE_DATOS"; then
    echo "Restauración exitosa"
else
    echo "Error en la restauración" >&2
    exit 1
fi