#!/bin/bash

# all packages are installed as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# integrate with apache
a2dissite 000-default
a2ensite qlproxy

# replace the squid config
if [ ! -f /etc/squid3/squid.conf.default ]; then
    cp -f /etc/squid3/squid.conf /etc/squid3/squid.conf.default
fi
cp -f squid.conf /etc/squid3/squid.conf

# create squid storage for mimicked ssl certificates
SSL_DB=/var/spool/squid3_ssldb
if [ -d $SSL_DB ]; then
    rm -Rf $SSL_DB
fi

/usr/lib/squid3/ssl_crtd -c -s $SSL_DB
if [ $? -ne 0 ]; then
    echo "Error $? while initializing SSL certificate storage, exiting..."
    exit 1
fi
chown -R proxy:proxy $SSL_DB

# reset owner of installation path
chown -R qlproxy:qlproxy /opt/qlproxy

# restart all daemons
systemctl restart qlproxyd && systemctl restart apache2 && systemctl restart squid3
