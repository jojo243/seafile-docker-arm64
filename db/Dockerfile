FROM	alpine:edge

ARG 	MYSQL_VERSION

RUN 	set -x \
		&& mkdir -p /run/mysqld && mkdir -p /dbinit.d \
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
		&& apk add --no-cache \
			mysql=${MYSQL_VERSION} \
			mysql-client=${MYSQL_VERSION}

COPY 	init/init.sh /init.sh
COPY 	conf/my.cnf /etc/mysql/my.cnf

WORKDIR /db

EXPOSE  3306

ENTRYPOINT [ "/init.sh" ]
CMD 	[ "mysqld", "--user=root", "--console" ]
