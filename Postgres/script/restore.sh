#!/bin/bash
export PGPASSWORD="$POSTGRES_PASSWORD"
psql -h serverPG -U admin -d CR_Chat -f /backup/pg_2025.sql
