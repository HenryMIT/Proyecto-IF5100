FROM postgres:latest

# Instalar cron y utilidades
RUN apt-get update && \
    apt-get install -y cron postgresql-client
RUN apt-get update && apt-get install -y tzdata
ENV TZ=America/Costa_Rica

RUN apt-get update && \
    apt-get install -y pgbackrest
    
RUN mkdir -p /backup /var/log/pgbackrest
COPY Postgres/script/pgbackrest.conf /etc/pgbackrest.con

COPY Postgres/script/backup_full.sh /usr/local/bin/backup_full.sh
COPY Postgres/script/backup_diff.sh /usr/local/bin/backup_diff.sh
COPY Postgres/script/restore.sh /usr/local/bin/restore.sh

RUN chmod +x /usr/local/bin/backup_full.sh /usr/local/bin/backup_diff.sh

RUN echo "*/5 * * * * bash /usr/local/bin/backup_full.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/backup_full
RUN chmod 0644 /etc/cron.d/backup_full

RUN echo "*/10 * * * * bash pgbackrest --stanza=demo --type=diff backup" > /etc/cron.d/pgbackrest-diff
RUN chmod 0644 /etc/cron.d/pgbackrest-diff

RUN touch /var/log/cron.log

CMD service cron start && docker-entrypoint.sh postgres

RUN crontab /etc/cron.d/backup_full 
