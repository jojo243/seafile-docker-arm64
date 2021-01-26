FROM 	arm64v8/debian:stretch-slim

ENV 	MYSQL_MAJOR 5.5
ENV 	MYSQL_VERSION 5.5.9999+default
# add gosu for easy step-down from root
ENV 	GOSU_VERSION 1.7

RUN 	set -x \
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
		&& groupadd mysql && useradd -g mysql mysql \
		&& apt-get update && apt-get install -y --no-install-recommends \
			gnupg \
			dirmngr \
			ca-certificates \
			wget \
		&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
		&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
		&& export GNUPGHOME="$(mktemp -d)" \
		&& key=B42F6819007F00F88E364FD4036A9C25BF357DD4 \
		&& gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
			gpg --keyserver pgp.mit.edu:80 --recv-keys "$key" || \
			gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
			gpg --keyserver keyserver.pgp.com:80 --recv-keys "$key" || \
    			gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" \
    			gpg --keyserver ha.pool.sks-keyservers.net:80 --recv-keys "$key" \
		&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
		&& rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
		&& chmod +x /usr/local/bin/gosu \
		&& gosu nobody true \
		&& apt-get install -y --no-install-recommends \
# for MYSQL_RANDOM_ROOT_PASSWORD
			pwgen \
# for mysql_ssl_rsa_setup
			openssl \
# FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
# File::Basename
# File::Copy
# Sys::Hostname
# Data::Dumper
			perl \
# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
			mysql-server="${MYSQL_VERSION}" \
		&& rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
		&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
# ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
		&& chmod 777 /var/run/mysqld \
# comment out a few problematic configuration values
		&& find /etc/mysql/ -name '*.cnf' -print0 \
			| xargs -0 grep -lZE '^(bind-address|log)' \
			| xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/' \
# don't reverse lookup hostnames, they are usually another container
		&& echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf \
		&& apt-get purge -y --auto-remove ca-certificates wget gnupg dirmngr \
		&& rm -rf /var/lib/apt/lists/* \
		&& mkdir /docker-entrypoint-initdb.d \
		&& touch usr/local/bin/docker-entrypoint.sh \
		&& ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh

COPY 	docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT 	["docker-entrypoint.sh"]

EXPOSE 		3306
CMD 		["mysqld"]
