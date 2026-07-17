FROM php:5.6-fpm-stretch

RUN useradd -m -s /bin/bash app

RUN echo "deb http://archive.debian.org/debian stretch main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security stretch/updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "Acquire::Check-Valid-Until \"false\";" > /etc/apt/apt.conf.d/99no-check-valid-until
##########################################

RUN apt-get update && apt-get install -y \
    libmagickwand-dev \
    vim \
    nginx \
    cron \
    libfcgi-bin \
    && rm -rf /var/lib/apt/lists/*
###

###
COPY --chown=app:app . /home/app/webapp
WORKDIR /home/app/webapp
COPY ./docker/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf

# Kept to match your folder structure (can contain PHP environment variables instead)
ADD ./docker/php-env.conf /etc/nginx/main.d/php-env.conf
RUN mkdir -p /home/app/webapp/log
RUN rm -rf /var/log/nginx
RUN ln -s /home/app/webapp/log /var/log/nginx
RUN chmod 777 /var/spool/cron/crontabs
RUN cat ./docker/crontab >> /var/spool/cron/crontabs/root
RUN chmod 600  /var/spool/cron/crontabs/root

# Using install_dependencies.sh (for composer/php setup)
COPY ./docker/install_dependencies.sh /home/app/webapp/install_dependencies.sh
COPY ./docker/startup.sh /home/app/webapp/startup.sh
RUN chmod 755 /home/app/webapp/*.sh
RUN chmod 755 /home/app/cronjob/*.sh
#########

###
USER app
RUN ls /home/app/webapp
RUN /home/app/webapp/install_dependencies.sh --setuser app
##
USER root
RUN echo "updating chown  ........"
RUN chown -R app:app /home/app
#########

EXPOSE 80
ENTRYPOINT ["/home/app/webapp/startup.sh"]
