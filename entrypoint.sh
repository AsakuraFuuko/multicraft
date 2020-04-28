#!/bin/bash

# Set umask for Unraid
umask 000

NEWINSTALL=0

# Create the multicraft folders that will be persistent
mkdir -p /multicraft/jar
mkdir -p /multicraft/data
mkdir -p /multicraft/servers
mkdir -p /multicraft/templates
mkdir -p /multicraft/configs
mkdir -p /multicraft/html

# Change multicraft owner to nobody:users
chown -R nobody:users /multicraft/


#######

## Multicraft Daemon Config

#######
if [ ! -f /multicraft/configs/multicraft.conf ]; then
    NEWINSTALL=1
    echo "[$(date +%Y-%m-%d_%T)] - No multicraft daemon config file detected, creating new one from multicraft.conf.dist"
    cp -f /opt/multicraft/multicraft.conf.dist /multicraft/configs/multicraft.conf

    # Update multicraft config file with docker variables
    sed -i -E "s|^user\s=\s(\S*)|user = nobody:users|" /multicraft/configs/multicraft.conf
    sed -i -E "s|^#password\s=\s(\S*)|password = ${daemonpwd}|" /multicraft/configs/multicraft.conf
    sed -i -E "s|^#id\s=\s(\S*)|id = ${daemonid}|" /multicraft/configs/multicraft.conf
    sed -i -E "s|^#allowSymlinks\s=\s(\S*)|allowSymlinks = true|" /multicraft/configs/multicraft.conf
    sed -i -E "s|^#ftpPasvPorts\s=\s(\S*)|ftpPasvPorts = 6000-6005|" /multicraft/configs/multicraft.conf
    sed -i -E "s|^#ftpNatIp\s=\s(\S*)|ftpNatIp = ${FTPNatIP}|" /multicraft/configs/multicraft.conf
    if [ "$dbengine" == "mysql" ]; then
        sed -i -E "s|^#database\s=\s(m\S*)|database = mysql:host=${mysqlhost};dbname=${mysqldbname}|" /multicraft/configs/multicraft.conf
        sed -i -E "s|^#dbUser\s=\s(\S*)|dbUser = ${mysqldbuser}|" /multicraft/configs/multicraft.conf
        sed -i -E "s|^#dbPassword\s=\s(\S*)|dbPassword = ${mysqldbpass}|" /multicraft/configs/multicraft.conf
    elif [ "$dbengine" == "sqlite" ]; then
        sed -i -E "s|^#database\s=\s(s\S*)|database = sqlite:daemon.db|" /multicraft/configs/multicraft.conf
    else
        echo "[$(date +%Y-%m-%d_%T)] - No database engine specified. Please edit config files manually."
    fi
    sed -i -E "s|^baseDir\s=\s(\S*)|baseDir = /opt/multicraft|" /multicraft/configs/multicraft.conf
    sed -i -E "s|^#ftpIp\s=\s(\S*)|ftpIp = 0.0.0.0|" /multicraft/configs/multicraft.conf

    # Copy config file to the Multicraft folder
    install -C -o nobody -g users /multicraft/configs/multicraft.conf /opt/multicraft/multicraft.conf
else
    echo "[$(date +%Y-%m-%d_%T)] - Multicraft daemon config file already exist! Installing config file."
    install -C -o nobody -g users /multicraft/configs/multicraft.conf /opt/multicraft/multicraft.conf
fi

#######

## Multicraft Panel Config

#######
if [ ! -f /multicraft/configs/panel.php ]; then
    echo "[$(date +%Y-%m-%d_%T)] - No Multicraft Panel config file found. Creating new one from config.php.dist";
    cp -f /var/www/html/multicraft/protected/config/config.php.dist /multicraft/configs/panel.php

    if [ "$dbengine" == "mysql" ]; then
        # Set Panel settings.
        sed -i -E "/^\s*'panel_db'\s=>\s'(s\S*),/a 'panel_db_pass' => '${mysqldbpass}'," /multicraft/configs/panel.php
        sed -i -E "/^\s*'panel_db'\s=>\s'(s\S*),/a 'panel_db_user' => '${mysqldbuser}'," /multicraft/configs/panel.php
        sed -i -E "/^\s*'panel_db'\s=>\s'(s\S*),/a 'panel_db' => 'mysql:host=${mysqlhost};dbname=${mysqldbname}'," /multicraft/configs/panel.php

        # Remove Panel SQLite settings
        sed -i -E "s|^\s*'panel_db'\s=>\s'(s\S*),||" /multicraft/configs/panel.php

        # Set daemon settings
        sed -i -E "/^\s*'daemon_db'\s=>\s'(s\S*),/a 'daemon_db_pass' => '${mysqldbpass}'," /multicraft/configs/panel.php
        sed -i -E "/^\s*'daemon_db'\s=>\s'(s\S*),/a 'daemon_db_user' => '${mysqldbuser}'," /multicraft/configs/panel.php
        sed -i -E "/^\s*'daemon_db'\s=>\s'(s\S*),/a 'daemon_db' => 'mysql:host=${mysqlhost};dbname=${mysqldbname}'," /multicraft/configs/panel.php

        # Remove Daemon SQLite settings
        sed -i -E "s|^\s*'daemon_db'\s=>\s'(s\S*),||" /multicraft/configs/panel.php

    elif [ "$dbengine" == "sqlite" ]; then
        sed -i -E "s|^\s*'panel_db'\s=>\s'(\S*),|'panel_db' => 'sqlite:/multicraft/data/panel.db',|" /multicraft/configs/panel.php
        sed -i -E "s|^\s*'daemon_db'\s=>\s'(\S*),|'daemon_db' => 'sqlite:/multicraft/data/daemon.db',|" /multicraft/configs/panel.php
    else
        echo "[$(date +%Y-%m-%d_%T)] - No database engine specified. Please edit config files manually."
    fi

    sed -i -E "s|^\s*'daemon_password'\s=>\s'(\S*),|'daemon_password' => '${daemonpwd}',|" /multicraft/configs/panel.php

    # Copy config file to the panel folder.
    chown nobody:users /multicraft/configs/panel.php
    chmod 777 /multicraft/configs/panel.php
    ln -s /multicraft/configs/panel.php /var/www/html/multicraft/protected/config/config.php


else
    echo "[$(date +%Y-%m-%d_%T)] - Multicraft Panel config file found. Creating symbolic link"
    chown nobody:users /multicraft/configs/panel.php
    chmod 777 /multicraft/configs/panel.php
    ln -s /multicraft/configs/panel.php /var/www/html/multicraft/protected/config/config.php
fi

#######

## Apache Config

#######
if [ ! -f /multicraft/configs/apache.conf ]; then
    echo "[$(date +%Y-%m-%d_%T)] - No Apache config file found. Creating one from template."

    cp /etc/apache2/sites-enabled/000-default.conf /multicraft/configs/apache.conf
    rm /etc/apache2/sites-enabled/000-default.conf

    ln -s /multicraft/configs/apache.conf /etc/apache2/sites-enabled/000-default.conf

else
    echo "[$(date +%Y-%m-%d_%T)] - Apache Config File found. Creating symbolic link"

    # If config file already exist in sites-enabled, delete it first.
    if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
        rm /etc/apache2/sites-enabled/000-default.conf
    fi

    ln -s /multicraft/configs/apache.conf /etc/apache2/sites-enabled/000-default.conf
fi


# Start apache2
service apache2 start

# If new install
if [ "$NEWINSTALL" == 1 ]; then

    cp -r /opt/multicraft/jar/* /multicraft/jar
    chown -R nobody:users /multicraft/jar

    cp -r /opt/multicraft/templates/* /multicraft/templates
    chown -R nobody:users /multicraft/templates

    rm -r /opt/multicraft/jar
    rm -r /opt/multicraft/templates

else
    # Remove install.php since it is not needed.
    rm /var/www/html/multicraft/install.php
fi

# Remove data folder to replace with symlink
if [ -d /opt/multicraft/data ]; then
rm -r /opt/multicraft/data
fi
ln -s /multicraft/data /opt/multicraft/data
echo "[$(date +%Y-%m-%d_%T)] - Symlinked Data"

if [ -d /opt/multicraft/jar ]; then
rm -r /opt/multicraft/jar
fi
ln -s /multicraft/jar /opt/multicraft/jar
echo "[$(date +%Y-%m-%d_%T)] - Symlinked Jar"

if [ -d /opt/multicraft/servers ]; then
rm -r /opt/multicraft/servers
fi
ln -s /multicraft/servers /opt/multicraft/servers
echo "[$(date +%Y-%m-%d_%T)] - Symlinked Servers"

if [ -d /opt/multicraft/templates ]; then
rm -r /opt/multicraft/templates
fi
ln -s /multicraft/templates /opt/multicraft/templates
echo "[$(date +%Y-%m-%d_%T)] - Symlinked Templates"

# Start and stop Multicraft to set permissions
/opt/multicraft/bin/multicraft start
sleep 1

# Set data folder permissions
chmod -R 777 /multicraft

# Tail the multicraft logs
tail -f /opt/multicraft/multicraft.log