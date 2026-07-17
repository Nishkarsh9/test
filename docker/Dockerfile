FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Create the application user
RUN useradd -m -s /bin/bash app

#### Install Python 3.8 & System Dependencies ####
RUN apt-get update && apt-get install -y \
    software-properties-common \
    gnupg2 \
    ca-certificates \
    curl \
    build-essential \
    && add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update && apt-get install -y \
    python3.8 \
    python3.8-dev \
    python3.8-distutils \
    vim \
    nginx \
    cron \
    && rm -rf /var/lib/apt/lists/*
###############################################

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2 && \
    update-alternatives --set python3 /usr/bin/python3.8

### Application Setup ###
COPY --chown=app:app . /home/app/webapp
WORKDIR /home/app/webapp

# Nginx Routing Infrastructure Setup
COPY ./docker/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf
RUN rm -f /etc/nginx/sites-enabled/default

# App Layout & Logs Synchronization
RUN mkdir -p /home/app/webapp/log
RUN rm -rf /var/log/nginx && ln -s /home/app/webapp/log /var/log/nginx

# Cron Configurations 
RUN chmod 777 /var/spool/cron/crontabs
RUN cat ./docker/crontab >> /var/spool/cron/crontabs/root 2>/dev/null || true
RUN chmod 600 /var/spool/cron/crontabs/root 2>/dev/null || true

# Boot Scripts Setup
COPY ./docker/install_dependencies.sh /home/app/webapp/install_dependencies.sh
COPY ./docker/startup.sh /home/app/webapp/startup.sh
RUN chmod 755 /home/app/webapp/*.sh
RUN chmod 755 /home/app/webapp/cronjob/*.sh 2>/dev/null || true
#########

### Global System Dependencies Control ###
USER root
RUN /home/app/webapp/install_dependencies.sh --setuser app || true

RUN echo "updating chown  ........" && chown -R app:app /home/app
#########

EXPOSE 80
ENTRYPOINT ["/home/app/webapp/startup.sh"]
