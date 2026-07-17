#!/bin/bash
set -e

LOGFILE=/home/app/webapp/log/startup.log
mkdir -p /home/app/webapp/log
echo "[$(date)] Starting Python Stack startup.sh" >> $LOGFILE

# -------- Nginx Virtual Host Config --------
echo "[$(date)] Copying Nginx Virtual Host configuration" >> $LOGFILE
cp ./docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf

# -------- Nginx Worker Config --------
worker_processes=${WORKER_PROCESSES:-8}
echo "[$(date)] Configuring Nginx workers (WORKER_PROCESSES=$worker_processes)" >> $LOGFILE
cp ./docker/nginx.conf /etc/nginx/nginx.conf
sed -i "s/<<WORKER_PROCESSES>>/$worker_processes/g" /etc/nginx/nginx.conf

# Clean fallback configurations to isolate port loops cleanly
rm -f /etc/nginx/sites-enabled/default
echo "[$(date)] Nginx configuration done" >> $LOGFILE

# -------- Cron Setup --------
echo "[$(date)] Setting up cron" >> $LOGFILE
if [ -f /var/spool/cron/crontabs/root ]; then
  mv /var/spool/cron/crontabs/root /var/spool/cron/crontabs/app
fi
chown app:app /var/spool/cron/crontabs/app || true
service cron start || true

# Fix absolute directory bounds permissions
chown -R app:app /home/app/webapp/log || true

# -------- Start Python Application Server --------
echo "[$(date)] Launching local Python background execution loop..." >> $LOGFILE

# UPDATED: Launches your Python backend process in the background, listening on port 5000
python3.8 main.py >> /home/app/webapp/log/app.log 2>&1 &

# -------- Startup Nginx Server --------
echo "[$(date)] Web app stack loaded. Starting Nginx foreground engine..." >> $LOGFILE
exec nginx
