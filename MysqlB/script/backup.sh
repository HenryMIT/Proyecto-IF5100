#!/bin/bash

FECHA=$(date +%F_%H%M)
BACKUP_DIR="/backup"
NOMBRE_ARCHIVO="mysql_$FECHA.sql.gz"
USUARIO="root"
PASSWORD="admin"
BASE_DATOS="CR_chat"

# Esperar a que MySQL esté listo (máximo 60 segundos)
REINTENTOS=12
for i in $(seq 1 $REINTENTOS); do
    if mysqladmin ping -u"$USUARIO" -p"$PASSWORD" --silent; then
        echo "MySQL está listo. Iniciando backup..."
        break
    fi
    echo "Esperando a que MySQL inicie... intento $i"
    sleep 5
done

# Verificar si MySQL está disponible después del tiempo de espera
if ! mysqladmin ping -u"$USUARIO" -p"$PASSWORD" --silent; then
    echo "MySQL no está disponible después de $REINTENTOS intentos. Abortando backup." >&2
    exit 1
fi

# Realizar el backup
if mysqldump -u "$USUARIO" -p"$PASSWORD" --single-transaction "$BASE_DATOS" | gzip > "$BACKUP_DIR/$NOMBRE_ARCHIVO"; then
    echo "Backup realizado exitosamente: $BACKUP_DIR/$NOMBRE_ARCHIVO"
else
    echo "Error al realizar el backup" >&2
    exit 1
fi

# Eliminar backups antiguos dejando solo los 7 más recientes
cd "$BACKUP_DIR" || exit 1
ls -1t mysql_*.sql.gz | tail -n +8 | xargs -r rm --
