#!/bin/bash
export PGPASSWORD="$POSTGRES_PASSWORD"
pgbackrest --stanza=demo --type=diff backup