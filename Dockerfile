#FROM debian:stretch
FROM phusion/baseimage:0.9.22
MAINTAINER 0815chr1s

#ENV MY_DOMAIN=home.sengsoft.de

# Install dependencies
RUN apt-get update && apt-get upgrade -y --force-yes && apt-get install -y --force-yes --no-install-recommends apt-utils
RUN apt-get -y --force-yes install \
git



#RUN cd /opt
#RUN git clone https://github.com/letsencrypt/letsencrypt
#RUN cd letsencrypt
##RUN letsencrypt-auto --help

#RUN ./letsencrypt-auto certonly --rsa-key-size 4096 -d ${MY_DOMAIN}

#RUN a2enmod proxy proxy_http
#RUN service apache2 restart
#RUN cd /etc/apache2/sites-available/
#sudo nano home.sengsoft.conf

 
#RUN cd /etc/apache2/sites-enabled
#sudo ln -s ../sites-available/home.sengsoft.conf .

##user für proxy zugriff
#sudo htpasswd -c -s /etc/fhem-htpasswd chris

#RUN a2enmod ssl proxy_html
#RUN apachectl configtest
#RUN service apache2 start

#EXPOSE 80

#crontab -e
#0 4 * * * sudo service apache2 stop && sudo /opt/letsencrypt/letsencrypt-auto renew && sudo service apache2 restart
#0 1 * * 1,5 sh /opt/backup.sh



ENV DEBIAN_FRONTEND noninteractive
ENV LETSENCRYPT_HOME /etc/letsencrypt
ENV DOMAINS "test.test.de"
ENV WEBMASTER_MAIL "test@test.de"

# Manually set the apache environment variables in order to get apache to work immediately.
RUN echo $WEBMASTER_MAIL > /etc/container_environment/WEBMASTER_MAIL && \
    echo $DOMAINS > /etc/container_environment/DOMAINS && \
    echo $LETSENCRYPT_HOME > /etc/container_environment/LETSENCRYPT_HOME

CMD ["/sbin/my_init"]

# Base setup
# ADD resources/etc/apt/ /etc/apt/
RUN apt-get -y update && \
    apt-get install -q -y curl apache2 && \
    apt-get install -q -y python-letsencrypt-apache && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# configure apache
ADD config/mods-available/proxy_html.conf /etc/apache2/mods-available/
ADD config/conf-available/security.conf /etc/apache2/conf-available/
RUN echo "ServerName localhost" >> /etc/apache2/conf-enabled/hostname.conf && \
    a2enmod ssl headers proxy proxy_http proxy_html xml2enc rewrite usertrack remoteip && \
    a2dissite 000-default default-ssl && \
    mkdir -p /var/lock/apache2 && \
    mkdir -p /var/run/apache2

# configure runit
RUN mkdir -p /etc/service/apache
ADD config/scripts/run_apache.sh /etc/service/apache/run
ADD config/scripts/init_letsencrypt.sh /etc/my_init.d/
ADD config/scripts/run_letsencrypt.sh /run_letsencrypt.sh
RUN chmod +x /*.sh && chmod +x /etc/my_init.d/*.sh && chmod +x /etc/service/apache/*

ADD config/crontab /etc/crontab

# Stuff
EXPOSE 80
EXPOSE 443
VOLUME [ "$LETSENCRYPT_HOME", "/etc/apache2/sites-available", "/var/log/apache2" ]

