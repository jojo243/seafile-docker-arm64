#--------------------------------------------------
FROM 		arm64v8/python:3.7-alpine as build

ARG		GITHUB=https://github.com/
ARG		REPO=haiwen
ARG		BASEURL=${GITHUB}${REPO}/

# Github URLs
ARG		LIBEVHTP_URL=${BASEURL}libevhtp.git
ARG		LIBSEARPC_URL=${BASEURL}libsearpc.git
ARG		CCNET_SERVER_URL=${BASEURL}ccnet-server.git
ARG		SEAFILE_SERVER_URL=${BASEURL}seafile-server.git
ARG		SEAHUB_URL=${BASEURL}seahub.git
ARG		SEAFOBJ_URL=${BASEURL}seafobj.git
ARG		SEAFDAV_URL=${BASEURL}seafdav.git

ARG		PREFIX_PATH=/usr/src
ARG		PKG_CONFIG_PATH=${PREFIX_PATH}/dev/seafile-server/lib:$PKG_CONFIG_PATH
ARG		PKG_CONFIG_PATH=${PREFIX_PATH}/dev/libsearpc:$PKG_CONFIG_PATH
ARG		PKG_CONFIG_PATH=${PREFIX_PATH}/dev/ccnet-server:$PKG_CONFIG_PATH

# Tags & Versions
ARG		LIBSEARPC_VERSION=3.2
ARG		LIBSEARPC_TAG=v${LIBSEARPC_VERSION}-latest
ARG		SERVER_VERSION
ARG		SERVER_TAG=v${SERVER_VERSION}-server

WORKDIR		${PREFIX_PATH}

COPY		requirements.txt .

ENV		PATH=${PATH}:${PREFIX_PATH}/dev/seahub_thirdpart/bin
ENV		PYTHONPATH=${PREFIX_PATH}/dev/seahub_thirdpart/bin

RUN		mkdir -p dev/seahub_thirdpart && \
			mkdir seafile-sources && \
			mkdir seafile-server-pkgs && \
			cd dev && \
			apk add --no-cache git && \
			git clone ${LIBEVHTP_URL} && \
			git clone ${LIBSEARPC_URL} && \
			git clone ${CCNET_SERVER_URL} && \
			git clone ${SEAFILE_SERVER_URL} && \
			git clone ${SEAHUB_URL} && \
			git clone ${SEAFOBJ_URL} && \
			git clone ${SEAFDAV_URL} && \
			cd libsearpc && git reset --hard ${LIBSEARPC_TAG} && cd .. && \
			cd ccnet-server && git reset --hard ${SERVER_TAG} && cd .. && \
			cd seafile-server && git reset --hard ${SERVER_TAG} && cd .. && \
			cd seahub && git reset --hard ${SERVER_TAG} && cd .. && \
			cd seafobj && git reset --hard ${SERVER_TAG} && cd .. && \
			cd seafdav && git reset --hard ${SERVER_TAG} && cd .. && \
			apk add --no-cache --virtual build-deps \
				autoconf \
				automake \
				bash \
				build-base \
				cmake \
				gzip \
				libtool \
				jansson-dev \
				libarchive-dev \
				bsd-compat-headers \
				sqlite-dev \
				mariadb \
				mariadb-dev \
				oniguruma-dev \
				fuse-dev \
				openssl-dev \
			&& \
			apk add --no-cache \
				libevent-dev \ 
			&& \
# libevhtp
			cd libevhtp && \
			cmake -DEVHTP_DISABLE_SSL=ON -DEVHTP_BUILD_SHARED=OFF . && \
			make && make install && ldconfig /usr/local/lib && \
			apk del libevent-dev && \
# seahub thirdpart
			apk add --no-cache \
				libjpeg-turbo-dev \
				zlib-dev \
			&& \
			cd ../seahub_thirdpart && \
			mv ../../requirements.txt . && \
			pip3 install --user -r requirements.txt && \
			mv ~/.local/* . && \
			apk del libjpeg-turbo-dev zlib-dev && \
# For whatever reason, the ac_init call of seafile, ccnet, etc. happens which "6.0.1" (3.1.0 for libsearpc), 
# thus every corresponding entry in configure.ac must be found and replaced with ${*PACKAGE*_VERSION}.
# `sed -i` does this.
# libsearpc
			apk add --no-cache \
				glib-dev \
			&& \
			cd ../libsearpc && \
			sed -i "s/3.1.0/${LIBSEARPC_VERSION}/g" configure.ac && \
			./autogen.sh && ./configure && make dist && \
			apk del glib-dev && \
# ccnet
			apk add --no-cache \
				libevent-dev \
				vala \
			&& \
			cd ../ccnet-server && \
			sed -i "s/6.0.1/${SERVER_VERSION}/g" configure.ac && \
			sed -i "s/mysqlclient/mariadb/g" configure.ac && \
			./autogen.sh && ./configure && make dist && \
			apk del vala libevent-dev && \
# seafile-server
			apk add --no-cache \
				libevent-dev \
				glib-dev \
				intltool \
				vala \
			&& \
			cd ../seafile-server && \
			sed -i "s/6.0.1/${SERVER_VERSION}/g" configure.ac && \
			sed -i "s/mysqlclient/mariadb/g" configure.ac && \
			./autogen.sh && ./configure && make dist && \
			apk del glib-dev intltool vala libevent-dev && \
# seahub
			cd ../seahub && python3 tools/gen-tarball.py --version=${SERVER_VERSION} --branch=HEAD && \
# seaobj
			cd ../seafobj && make dist && \
# seafdav
			cd ../seafdav && make && cd ../.. && \
			apk add --no-cache \
				glib-dev \
				libevent-dev \ 
			&& \
			sed -i "s/--enable-ldap//g" dev/seafile-server/scripts/build/build-server.py && \
			cp dev/libsearpc/libsearpc-${LIBSEARPC_VERSION}.tar.gz seafile-sources && \
			cp dev/ccnet-server/ccnet-${SERVER_VERSION}.tar.gz seafile-sources && \
			cp dev/seafile-server/seafile-${SERVER_VERSION}.tar.gz seafile-sources && \
			cp dev/seahub/seahub-${SERVER_VERSION}.tar.gz seafile-sources/ && \
			cp dev/seafobj/seafobj.tar.gz seafile-sources && \
			cp dev/seafdav/seafdav.tar.gz seafile-sources && \
			python3 dev/seafile-server/scripts/build/build-server.py \
				--version=${SERVER_VERSION} \
				--libsearpc_version=${LIBSEARPC_VERSION} \
				--ccnet_version=${SERVER_VERSION} \
				--seafile_version=${SERVER_VERSION} \
				--thirdpartdir=${PREFIX_PATH}/dev/seahub_thirdpart/lib/python3.7/site-packages/ \
				--srcdir=${PREFIX_PATH}/seafile-sources \
				--outputdir=${PREFIX_PATH}/seafile-server-pkgs \
				--yes && \
# Clean Up
			rm -r dev seafile-sources && \
			cp /usr/src/seafile-server-pkgs/* /usr/src/ && \
			rm -r seafile-server-pkgs && \
			tar xzf /usr/src/seafile-server_*.tar.gz && \
               		rm /usr/src/seafile-server_*.tar.gz && \
                	mv /usr/src/seafile-server* /usr/src/seafile-server && \
			apk del glib-dev build-deps libevent-dev

#--------------------------------------------------
FROM        arm64v8/python:3.7-alpine as pull

WORKDIR	    /usr/src/seafile-server

ADD         https://github.com/haiwen/seafile-rpi/releases/download/v${SERVER_VERSION}/seafile-server_${SERVER_VERSION}_stable_pi.tar.gz .

RUN	    tar xzf seafile-server_*.tar.gz && \
            rm seafile-server_*.tar.gz && \
            mv seafile-server* seafile-server

#--------------------------------------------------
FROM        arm64v8/python:3.7-alpine as prod

COPY	    --from=${BUILD_METHOD} /usr/src/seafile-server /usr/src/seafile-server

RUN         mkdir -p /data && \
		    apk add --no-cache --virtual build-deps \
			build-base \
			mariadb-dev \
		    && \
                    apk add --no-cache \
			bash \
			mariadb-client \
			tiff \
			libjpeg-turbo \
                        ffmpeg && \
		pip install PyMySQL && \
		apk del build-deps && \
		adduser -D -H -g 'seafile' seafile
 
COPY        init/init.sh .

WORKDIR     /haiwen/

EXPOSE      8000
EXPOSE      8082

VOLUME      [ "/data/" ]
VOLUME      [ "/haiwen/" ]

ENV	    PYTHONPATH=/haiwen/seafile-server-latest/seahub/thirdpart/:/haiwen/seafile-server-latest/seafile/lib/python3.7/site-packages/

ENTRYPOINT  [ "/init.sh" ]
CMD         [ "tail", "-f", "/dev/null" ]
