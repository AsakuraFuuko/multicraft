FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN usermod -u 99 nobody
RUN usermod -g 100 nobody
RUN usermod -d /home nobody
RUN usermod -a -G users www-data
RUN chown -R nobody:users /home
RUN echo "Asia/Shanghai" | tee /etc/timezone
RUN apt-get update -q && apt-get install -qy \
    apache2 \
    php \
    wget \
    php-mysql \
    php-sqlite3 \
    php-gd \
    sudo \
    zip \
    unzip \
    openjdk-8-jre-headless \
    && rm -rf /var/lib/apt/lists/*
RUN wget http://www.multicraft.org/download/linux64 -O /tmp/multicraft.tar.gz && \
    tar xvzf /tmp/multicraft.tar.gz -C /tmp && \
    rm /tmp/multicraft.tar.gz
COPY 000-default.conf /etc/apache2/sites-enabled/000-default.conf 
RUN mkdir -p /scripts/
COPY install.sh /scripts/install.sh 
RUN chmod +x /scripts/install.sh && \
    /scripts/install.sh
COPY entrypoint.sh /scripts/entrypoint.sh 
RUN chmod +x /scripts/entrypoint.sh
EXPOSE 80
EXPOSE 21
EXPOSE 25565
EXPOSE 19132-19133/udp
EXPOSE 25565/udp
EXPOSE 6000-6005
VOLUME [/multicraft]
ENV daemonpwd=none
ENV daemonid=1
ENV dbengine=sqlite
ENV mysqlhost=192.168.2.2
ENV mysqldbname=multicraft
ENV mysqldbuser=multicraft
ENV mysqldbpass=multicraft
ENV FTPNatIP=192.168.2.2
CMD ["/scripts/entrypoint.sh"]
