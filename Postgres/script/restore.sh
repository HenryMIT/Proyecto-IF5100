#!/bin/bash
# Restaura desde backup FULL y archivos WAL
# Uso: ./restore.sh YYYYMMDD_HHMMSS

fecha=$1
if [ -z "$fecha" ]; then
    echo "[ERROR] Debes proporcionar una fecha del backup (ej: 20250615_020000)"
    exit 1
fi

echo "[INFO] Restaurando desde /backup/base/$fecha..."

docker stop postgreSQL
docker volume rm postgreData

mkdir -p temp_restore
tar -xf /backup/base/$fecha/base.tar.gz -C temp_restore
cp /scripts/recovery.conf temp_restore/

echo "[INFO] Listo para montar temp_restore como nuevo volumen de datos."
