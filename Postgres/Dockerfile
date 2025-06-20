FROM postgres:latest

# Instalar cron y utilidades
RUN apt-get update && \
    apt-get install -y cron

RUN apt-get update && apt-get install -y tzdata
ENV TZ=America/Costa_Rica

# Copiar script de backup
COPY Postgres/script/backup_full.sh /usr/local/bin/backup.sh

RUN chmod +x /usr/local/bin/backup.sh

# Agregar tarea cron (ej: full diario 1am)
RUN echo "05 1 * * * root /usr/local/bin/backup_full.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/backup \
 && chmod 0644 /etc/cron.d/backup \
 && crontab /etc/cron.d/backup

# Iniciar cron y el servidor postgres
CMD service cron start && docker-entrypoint.sh postgres
