#!/bin/bash
export PGPASSWORD="$POSTGRES_PASSWORD"
pg_dump -h serverPG -U admin CR_Chat | gzip > /backup/pg_$(date +%F_%H%M).sql.gz

ls -1t /backup/pg_*.sql.gz | tail -n +8 | xargs rm -f
