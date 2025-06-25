FROM mysql:8.0-debian

RUN apt-get update && apt-get install -y tzdata cron gzip && \
    rm -rf /var/lib/apt/lists/*

ENV TZ=America/Costa_Rica

RUN mkdir -p /backup /var/log/mysqlbackup

COPY script/backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

RUN echo "00 1 * * * bash /usr/local/bin/backup.sh >> /var/log/mysqlbackup/cron.log 2>&1" > /etc/cron.d/mysql-backup && \
    chmod 0644 /etc/cron.d/mysql-backup && \
    crontab /etc/cron.d/mysql-backup

RUN touch /var/log/mysqlbackup/cron.log

CMD ["bash", "-c", "cron && exec docker-entrypoint.sh mysqld"]
