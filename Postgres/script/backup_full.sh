#!/bin/bash
export PGPASSWORD="$POSTGRES_PASSWORD"

pg_dump -h localhost -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > /backup/pg_$(date +%F_%H%M).sql.gz

ls -1t /backups/pg_*.sql.gz | tail -n +8 | xargs rm -f
