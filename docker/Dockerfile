FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Create the application user
RUN useradd -m -s /bin/bash app


#### Install PHP 5.6 & System Dependencies ####
RUN apt-get update && apt-get install -y \
    software-properties-common \
    gnupg2 \
    ca-certificates \
    curl \
    && add-apt-repository ppa:ondrej/php -y \
    && apt-get update && apt-get install -y \
    php5.6-fpm \
    php5.6-curl \
    php5.6-xml \
    php5.6-mbstring \
    php5.6-bcmath \
    php5.6-mysql \
    libmagickwand-dev \
    vim \
    nginx \
    cron \
    libfcgi-bin \
    && rm -rf /var/lib/apt/lists/*
###############################################

# Configure PHP-FPM execution directories
RUN mkdir -p /run/php && chown www-data:www-data /run/php

### Application Setup ###
COPY --chown=app:app . /home/app/webapp
WORKDIR /home/app/webapp
COPY ./docker/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf

# Kept to match your existing folder structure 
ADD ./docker/php-env.conf /etc/nginx/main.d/php-env.conf
RUN mkdir -p /home/app/webapp/log
RUN rm -rf /var/log/nginx && ln -s /home/app/webapp/log /var/log/nginx

# Cron Configuration
RUN chmod 777 /var/spool/cron/crontabs
RUN cat ./docker/crontab >> /var/spool/cron/crontabs/root 2>/dev/null || true
RUN chmod 600 /var/spool/cron/crontabs/root 2>/dev/null || true

# Boot Scripts
COPY ./docker/install_dependencies.sh /home/app/webapp/install_dependencies.sh
COPY ./docker/startup.sh /home/app/webapp/startup.sh
RUN chmod 755 /home/app/webapp/*.sh
RUN if [ -d /home/app/webapp/cronjob ]; then chmod 755 /home/app/webapp/cronjob/*.sh; fi
#########

### Permissions Management ###
USER app
RUN /home/app/webapp/install_dependencies.sh --setuser app || true

USER root
RUN echo "updating chown  ........" && chown -R app:app /home/app
#########

EXPOSE 80
ENTRYPOINT ["/home/app/webapp/startup.sh"]
