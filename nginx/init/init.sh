#!/bin/sh
cd /opt/conf/

if [ $SSL -eq 1 ]; then
    cp default_ssl.conf /etc/nginx/conf.d/default.conf
else
    cp default.conf /etc/nginx/conf.d/default.conf
fi

sed -i "s/__PORT__/${PORT}/g" /etc/nginx/conf.d/default.conf
sed -i "s/__SERVER_NAME__/${SERVER_NAME}/g" /etc/nginx/conf.d/default.conf

exec "$@"
