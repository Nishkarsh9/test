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
mkdir -p /home/app/utils
chown app:app /home/app/utils || true

export DYNO="php-test-${DUPLO_DOCKER_HOST:-$(cat /host_ip 2>/dev/null || echo "local_host")}-$REPLICA_ID"
gcpfoldername=${SERVER_FOLDER_NAME:-php-test}

if [ -f /home/app/utils/uniqgcp.sh ]; then
  source /home/app/utils/uniqgcp.sh
fi

if [ -f /home/app/utils/common_util.rake ]; then
  echo "[$(date)] Copying common_util.rake" >> $LOGFILE
  cp /home/app/utils/common_util.rake /home/app/webapp/lib/tasks/common_util.rake
  chown app:app /home/app/webapp/lib/tasks/common_util.rake
fi

# FIX: Added an existence check before changing ownership so it never throws an error
if [ -f /home/app/utils/gcpfoldername ]; then
  chown app:app /home/app/utils/gcpfoldername || true
fi
#####

# -------- Cron Setup --------
echo "[$(date)] Setting up cron" >> $LOGFILE
if [ -f /var/spool/cron/crontabs/root ]; then
  mv /var/spool/cron/crontabs/root /var/spool/cron/crontabs/app
fi
chown app:app /var/spool/cron/crontabs/app || true
chown -R app:app /home/app/webapp/log || true

# Start the cron background service
service cron start || true
echo "[$(date)] Cron started successfully" >> $LOGFILE

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

# -------- Startup Nginx Server --------
echo "[$(date)] Removing stock Nginx default configuration if present" >> $LOGFILE
# Clear the stock symlink to allow webapp.conf to take priority
rm -f /etc/nginx/sites-enabled/default

echo "[$(date)] startup.sh completed, launching Nginx foreground process" >> $LOGFILE

# FIX: Replaced non-existent /sbin/my_init with Nginx. 
# Since 'daemon off;' is configured, Nginx will stay in the foreground and keep the container alive.
exec nginx
