FROM 		arm64v8/buildpack-deps:stretch

ARG		GITHUB=https://www.github.com/
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
ARG		LIBSEARPC_VERSION=3.0
ARG		LIBSEARPC_TAG=v${LIBSEARPC_VERSION}-latest
ARG		SERVER_VERSION
ARG		SERVER_TAG=v${SERVER_VERSION}-server

WORKDIR		${PREFIX_PATH}

# alpine: apk add --no-cache --update libevent-dev libcurl
RUN 		apt-get update && apt-get -y install \
			# libevent-dev \
			# libglib2.0-dev \
			uuid-dev \
			intltool \
			# libsqlite3-dev \
			# default-libmysqlclient-dev \
			libarchive-dev \
			# libtool \
			libjansson-dev \
			valac \
			libfuse-dev \
			re2c \
			flex \
			python-pip \
			python-setuptools \
			cmake \
			# git \
			libonig-dev \
			libssl1.0-dev \
            		# libjpeg-dev \
			# zlib1g-dev \
			build-essential && \
		mkdir -p dev && \
		apt-get clean && \
		rm -rf /var/lib/apt/lists/* && \
		find /var/cache/apt/ -type f -exec rm -v {} \;

# libevhtp
RUN 		cd dev && \
			git clone ${LIBEVHTP_URL} && \
			cd libevhtp && \
			cmake -DEVHTP_DISABLE_SSL=ON -DEVHTP_BUILD_SHARED=OFF . && \
			make && \
			make install && \
			ldconfig

ADD		https://raw.githubusercontent.com/haiwen/seahub/${SERVER_TAG}/requirements.txt requirements.txt
# seahub thirdpart
RUN		mkdir -p dev/seahub_thirdpart && \
		cd dev/seahub_thirdpart && \
		mv ../../requirements.txt . && \
		echo "flup" | tee -a requirements.txt && \
		echo "gunicorn==19.8.1" | tee -a requirements.txt && \
		pip install --install-option="--prefix=$PREFIX_PATH/dev/seahub_thirdpart" -r requirements.txt

# For whatever reason, the ac_init call of seafile, ccnet, etc. happens which "6.0.1" (1.2.2 for libsearpc),
# thus every corresponding entry in configure.ac must be found and replaced with ${*PACKAGE*_VERSION}.
# `sed -i` does this.
# libsearpc
RUN		cd dev && \
 		git clone ${LIBSEARPC_URL} && \
		cd libsearpc && \
		git reset --hard ${LIBSEARPC_TAG} && \
		sed -i "s/1.2.2/${LIBSEARPC_VERSION}/g" configure.ac && \
		./autogen.sh && \
		./configure && \
		make dist

# ccnet
RUN		cd dev && \
		git clone ${CCNET_SERVER_URL} && \
		cd ccnet-server && \
		git reset --hard ${SERVER_TAG} && \
		sed -i "s/6.0.1/${SERVER_VERSION}/g" configure.ac && \
		./autogen.sh && \
		./configure && \
		make dist

# seafile-server
RUN		cd dev && \
		git clone ${SEAFILE_SERVER_URL} && \
		cd seafile-server && \
		git reset --hard ${SERVER_TAG} && \
		sed -i "s/6.0.1/${SERVER_VERSION}/g" configure.ac && \
		./autogen.sh && \
		./configure && \
		make dist

# seahub
ENV		PATH=${PATH}:${PREFIX_PATH}/dev/seahub_thirdpart/bin
ENV		PYTHONPATH=${PREFIX_PATH}/dev/seahub_thirdpart/bin
RUN		cd dev && \
		git clone ${SEAHUB_URL} && \
		cd seahub && \
		git reset --hard ${SERVER_TAG} && \
		./tools/gen-tarball.py --version=${SERVER_VERSION} --branch=HEAD

# seaobj
RUN		cd dev && \
		git clone ${SEAFOBJ_URL} && \
		cd seafobj && \
		git reset --hard ${SERVER_TAG} && \
		make dist

# seafdav
RUN		cd dev && \
		git clone ${SEAFDAV_URL} && \
		cd seafdav && \
		git reset --hard ${SERVER_TAG} && \
		make

# For whatever reason, the ac_init call of seafile, ccnet, etc. happens which "6.0.1" (1.2.2 for libsearpc),
# thus every corresponding entry in configure.ac must be found and replaced with ${*PACKAGE*_VERSION}.
# `sed -i` does this.
RUN  		sed -i "s/--enable-ldap//g" dev/seafile-server/scripts/build/build-server.py && \
			mkdir seafile-sources && \
			cp dev/libsearpc/libsearpc-${LIBSEARPC_VERSION}.tar.gz seafile-sources && \
			cp dev/ccnet-server/ccnet-${SERVER_VERSION}.tar.gz seafile-sources && \
			cp dev/seafile-server/seafile-${SERVER_VERSION}.tar.gz seafile-sources && \
			cp dev/seahub/seahub-${SERVER_VERSION}.tar.gz seafile-sources/seahub-${SERVER_VERSION}.tar.gz && \
			cp dev/seafobj/seafobj.tar.gz seafile-sources && \
			cp dev/seafdav/seafdav.tar.gz seafile-sources && \
			mkdir seafile-server-pkgs && \
			dev/seafile-server/scripts/build/build-server.py \
				--version=${SERVER_VERSION} \
				--libsearpc_version=${LIBSEARPC_VERSION} \
				--ccnet_version=${SERVER_VERSION} \
				--seafile_version=${SERVER_VERSION} \
				--thirdpartdir=${PREFIX_PATH}/dev/seahub_thirdpart/lib/python2.7/site-packages/ \
				--srcdir=${PREFIX_PATH}/seafile-sources \
				--outputdir=${PREFIX_PATH}/seafile-server-pkgs \
				--yes

# Clean Up
RUN		rm -r dev seafile-sources

#--------------------------------------------------
# Just extract the previously produced archive here. Use alpine as it provides busybox/tar.
FROM	        alpine:edge

COPY		--from=0 /usr/src/seafile-server-pkgs/* /usr/src/

RUN         	busybox tar -xzf /usr/src/seafile-server_*.tar.gz -C /usr/src/ && \
               		rm /usr/src/seafile-server_*.tar.gz && \
                	mv /usr/src/seafile-server* /usr/src/seafile-server

# Include this volume in containers/seafile/build/<tarballdir> so it becomes available to the host.
VOLUME      	/haiwen

CMD         	["cp", "-r", "/usr/src/seafile-server", "haiwen/"]
