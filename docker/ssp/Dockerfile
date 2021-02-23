FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

RUN apt-get update &&\
        apt-get install -y apache2 php7.2 php7.2-ldap php7.2-mbstring libmcrypt4 sendmail

COPY ./pkg/self-service-password_1.3-1_all.deb /tmp/

RUN dpkg -i /tmp/self-service-password_1.3-1_all.deb

COPY ./conf/config.inc.php /usr/share/self-service-password/conf/config.inc.php

#RUN test -f /etc/php/7.2/apache2/php.ini && echo "date.timezone = Asia/Shanghai" >> /etc/php/7.2/apache2/php.ini

COPY ./conf/000-default.conf /etc/apache2/sites-available/000-default.conf

RUN chown -R www-data.www-data /etc/apache2/ /usr/share/

ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_PID_FILE=/var/run/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
ENV LC_CTYPE=en_US.UTF-8
ENTRYPOINT ["/usr/sbin/apache2"]
CMD ["-D", "FOREGROUND"]
EXPOSE 80
