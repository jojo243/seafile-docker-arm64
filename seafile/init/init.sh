#!/bin/bash

# Wait for mysql to start up...
sleep 10

create_gunicorn() {
	mkdir -p /haiwen/seafile-server-latest/seahub/thirdpart/bin
	cat <<EOF > /haiwen/seafile-server-latest/seahub/thirdpart/bin/gunicorn
#!/usr/bin/python3
# -*- coding: utf-8 -*-
import re
import sys
from gunicorn.app.wsgiapp import run
if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw|\.exe)?$', '', sys.argv[0])
    sys.exit(run())
EOF
}

minor_upgrade() {
    ./minor-upgrade.sh <<EOF
dummy
EOF
}

fix_permissions() {
    chown -R seafile:seafile /haiwen/ || return 1
    chown -R seafile:seafile /data/
}

do_upgrade() {
    echo "Upgrading Seafile folder, please wait..."
    rm -r seafile-server || return 1
    cp -r /usr/src/seafile-server . || return 1
    cd seafile-server/upgrade || return 1
    minor_upgrade || return 1
    create_gunicorn || return 1
    fix_permissions || return 1
    echo "Upgrade done, now start Seafile with 'make' or 'make 2'"
}

if [[ -d "seafile-server-latest" ]]; then
    if [[ -n "$1" && "$1" = "upgrade" ]]; then
        do_upgrade || echo "Upgrade failed."
        exit 0
    else
        echo "Seafile directory already exists, skipping creation..."
    fi
else
    # Copy the source
    cp -r /usr/src/seafile-server .
    cd seafile-server

    # Init mysql databases
    ./setup-seafile-mysql.sh auto \
      --server-name seafile \
      --server-ip ${SERVER_NAME}:${PORT} \
      --seafile-dir /data/seafile-data/ \
      --mysql-host ${MYSQL_HOST} \
      --mysql-port ${MYSQL_PORT} \
      --mysql-user ${MYSQL_USER} \
      --mysql-user-passwd ${MYSQL_PASSWORD} \
      --mysql-user-host % \
      --mysql-root-passwd ${MYSQL_ROOT_PASSWORD}
    cd ..
    # sed -i "s|thirdpart/gunicorn|thirdpart/gunicorn/app/wsgiapp.py|" seafile-server/seahub.sh

    # admin.txt
    cat <<EOF > conf/admin.txt
{
	"email": "${ADMIN_EMAIL}",
	"password": "${ADMIN_PASSWORD}"
}
EOF

    if [ -d "seafile-server-latest" ]; then
	    true
    else
	    echo "Something went wrong! Restarting..."
	    exit 1
    fi

    # gunicorn.conf.py
    sed -i "s/127.0.0.1/0.0.0.0/g" conf/gunicorn.conf.py

    if [ ${SSL} -eq 1 ]; then
        SCHEME=https
    else
        SCHEME=http
    fi

    # Perform some changes (according to https://manual.seafile.com/deploy/https_with_nginx.html -> Scroll down to 'Modify settings to use https')
    # seahub_settings.py
    echo "FILE_SERVER_ROOT = '${SCHEME}://${SERVER_NAME}:${PORT}/seafhttp'" >> conf/seahub_settings.py

    # ccnet.conf
    LINENUMBER=$(sed -n '/^SERVICE_URL/=' conf/ccnet.conf)
    sed -i "/^SERVICE_URL/d" conf/ccnet.conf
    sed -i "${LINENUMBER}iSERVICE_URL = ${SCHEME}://${SERVER_NAME}:${PORT}" conf/ccnet.conf

    # seafdav.conf
    # sed -i "s/enabled = false/enabled = true/" conf/seafdav.conf
    # sed -i "s|share_name = /|share_name = /seafdav|" conf/seafdav.conf
    # seafile.conf
    #LINENUMBER=$(sed -n '/\[fileserver\]/=' conf/seafile.conf)
    #echo "Linenumber1 = $LINENUMBER"
    #if [ -z "${LINENUMBER}" ]; then
    #	LINENUMBER=2
    #else
	#LINENUMBER=$(expr ${LINENUMBER} + 1)
    #fi
    #echo "Linenumber2 = $LINENUMBER"
    #sed -i "${LINENUMBER}ihost = 127.0.0.1" conf/seafile.conf

    # gunicorn
    create_gunicorn
    # create symlinks in /usr/local/bin
    # for i in `ls /haiwen/seafile-server-latest/seafile/bin`; do ln -s /haiwen/seafile-server-latest/seafile/bin/$i /usr/local/bin/$i; done

    fix_permissions
    ln -s /data/seafile-data seafile-data
fi

# TODO: implement upgrade procedure somehow?
# PYTHON=/usr/local/bin/python3 seafile-server/upgrade/upgrade_7.0_7.1.sh || exit 0

cd seafile-server-latest
# for i in `ls /haiwen/seafile-server-latest/seafile/bin`; do ln -s /haiwen/seafile-server-latest/seafile/bin/$i /usr/local/bin/$i; done
# ls -la /usr/local/bin

su -m seafile -c "./seafile.sh start"
sleep 5
su -m seafile -c "./seahub.sh start"

exec "$@"
