#!/bin/bash
set -e

LOGFILE=/home/app/webapp/log/startup.log
mkdir -p /home/app/webapp/log # Ensure log directory exists for the very first echo
echo "[$(date)] Starting startup.sh" >> $LOGFILE

# -------- Nginx Virtual Host Config  --------
echo "[$(date)] Copying PHP Nginx Virtual Host configuration" >> $LOGFILE
cp ./docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf

# -------- Nginx Worker Config --------
worker_processes=${WORKER_PROCESSES:-8}
echo "[$(date)] Configuring Nginx workers (WORKER_PROCESSES=$worker_processes)" >> $LOGFILE
cp ./docker/nginx.conf /etc/nginx/nginx.conf
sed -i "s/<<WORKER_PROCESSES>>/$worker_processes/g" /etc/nginx/nginx.conf
echo "[$(date)] Nginx configuration done" >> $LOGFILE
#####

# -------- Environment Setup --------
# FIX: Ensure the utilities directory exists so file writes don't crash the container
mkdir -p /home/app/utils
chown app:app /home/app/utils || true

export DYNO="php-test-${DUPLO_DOCKER_HOST:-$(cat /host_ip 2>/dev/null || echo "local_host")}-$REPLICA_ID"
gcpfoldername=${SERVER_FOLDER_NAME:-php-test}

# Kept safely commented out as per your layout, but will not crash if uncommented now
# echo "${HOSTNAME}-${REPLICA_ID}" > /home/app/utils/servername
# echo $gcpfoldername > /home/app/utils/gcpfoldername

if [ -f /home/app/utils/uniqgcp.sh ]; then
  source /home/app/utils/uniqgcp.sh
fi

if [ -f /home/app/utils/common_util.rake ]; then
  echo "[$(date)] Copying common_util.rake" >> $LOGFILE
  cp /home/app/utils/common_util.rake /home/app/webapp/lib/tasks/common_util.rake
  chown app:app /home/app/webapp/lib/tasks/common_util.rake
fi
chown app:app /home/app/utils/gcpfoldername || true
#####

# -------- Cron Setup --------
echo "[$(date)] Setting up cron" >> $LOGFILE
if [ -f /var/spool/cron/crontabs/root ]; then
  mv /var/spool/cron/crontabs/root /var/spool/cron/crontabs/app
fi
chown app:app /var/spool/cron/crontabs/app || true
chown -R app:app /home/app/webapp/log || true
echo "[$(date)] Current crontab:" >> $LOGFILE
crontab -l >> $LOGFILE || true
service cron status >> $LOGFILE || true


# -------- Log Directories --------
echo "[$(date)] Creating log directories" >> $LOGFILE
mkdir -p /logs /home/app/webapp/log
chown -R app:app /logs /home/app/webapp/log || true
chmod -R 755 /logs /home/app/webapp/log
echo "[$(date)] Log directories ready" >> $LOGFILE

# -------- Remove GCP Key --------
rm -f /home/app/webapp/config/gcp.key
echo "[$(date)] Removed GCP key if existed" >> $LOGFILE

# -------- PHP-FPM Service Startup --------
echo "[$(date)] Starting PHP-FPM background engine" >> $LOGFILE
service $(ls /etc/init.d/ | grep php) start >> $LOGFILE 2>&1 || service php-fpm start >> $LOGFILE 2>&1 || true

# -------- Startup Container --------
echo "[$(date)] Stopping cron before init" >> $LOGFILE
service cron stop || true

echo "[$(date)] startup.sh completed, launching my_init" >> $LOGFILE
exec /sbin/my_init
