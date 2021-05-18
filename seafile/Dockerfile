ARG             BUILD_METHOD

#--------------------------------------------------
FROM            arm64v8/python:3.7-alpine as build

ARG             GITHUB=https://github.com/
ARG             REPO=haiwen
ARG             BASEURL=${GITHUB}${REPO}/

# Github URLs
ARG             LIBEVHTP_URL=${BASEURL}libevhtp.git
ARG             LIBSEARPC_URL=${BASEURL}libsearpc.git
ARG             CCNET_SERVER_URL=${BASEURL}ccnet-server.git
ARG             SEAFILE_SERVER_URL=${BASEURL}seafile-server.git
ARG             SEAHUB_URL=${BASEURL}seahub.git
ARG             SEAFOBJ_URL=${BASEURL}seafobj.git
ARG             SEAFDAV_URL=${BASEURL}seafdav.git

ARG             PREFIX_PATH=/usr/src
ARG             PKG_CONFIG_PATH=${PREFIX_PATH}/dev/seafile-server/lib:$PKG_CONFIG_PATH
ARG             PKG_CONFIG_PATH=${PREFIX_PATH}/dev/libsearpc:$PKG_CONFIG_PATH
ARG             PKG_CONFIG_PATH=${PREFIX_PATH}/dev/ccnet-server:$PKG_CONFIG_PATH

# Tags & Versions
ARG             LIBSEARPC_VERSION=3.2
ARG             LIBSEARPC_TAG=v${LIBSEARPC_VERSION}-latest
ARG             SERVER_VERSION
ARG             SERVER_TAG=v${SERVER_VERSION}-server

WORKDIR         ${PREFIX_PATH}

COPY            requirements.txt .

ENV             PATH=${PATH}:${PREFIX_PATH}/dev/seahub_thirdpart/bin
ENV             PYTHONPATH=${PREFIX_PATH}/dev/seahub_thirdpart/bin

RUN             mkdir -p dev/seahub_thirdpart seafile-sources seafile-server-pkgs && \
                    apk add --no-cache --virtual build-deps \
                        autoconf \
                        automake \
                        bash \
                        bsd-compat-headers \
                        build-base \
                        cmake \
                        fuse-dev \
                        git \
                        gzip \
                        intltool \
                        jansson-dev \
                        libarchive-dev \
                        libjpeg-turbo-dev \
                        libtool \
                        libxml2-dev \
                        libxslt-dev \
                        mariadb \
                        mariadb-dev \
                        oniguruma-dev \
                        openssl-dev \
                        sqlite-dev \
                        zlib-dev \
                    && \
                    cd dev && \
# clone repos
                    git clone ${LIBEVHTP_URL} && \
                    git clone ${LIBSEARPC_URL} && \
                    git clone ${CCNET_SERVER_URL} && \
                    git clone ${SEAFILE_SERVER_URL} && \
                    git clone ${SEAHUB_URL} && \
                    git clone ${SEAFOBJ_URL} && \
                    git clone ${SEAFDAV_URL} && \
# libevhtp
                    cd libevhtp && \
                    apk add --no-cache libevent-dev && \
                    cmake -DEVHTP_DISABLE_SSL=ON -DEVHTP_BUILD_SHARED=OFF . && \
                    make && make install && ldconfig /usr/local/lib && \
                    apk del libevent-dev && \
# seahub thirdpart
                    cd ../seahub_thirdpart && \
                    mv ../../requirements.txt . && \
                    pip3 install --user -r requirements.txt && \
                    mv ~/.local/* . && \
# For whatever reason, the ac_init call of seafile, ccnet, etc. happens which "6.0.1" (3.1.0 for libsearpc), 
# thus every corresponding entry in configure.ac must be found and replaced with ${*PACKAGE*_VERSION}.
# `sed -i` does this.
# libsearpc
                    cd ../libsearpc && \
                    apk add --no-cache --virtual build-deps-python \
                        glib-dev \
                        libevent-dev \
                        vala && \
                    git reset --hard ${LIBSEARPC_TAG} && \
                    sed -i "s/3.1.0/${LIBSEARPC_VERSION}/g" configure.ac && \
                    ./autogen.sh && ./configure && make dist && \
                    mv libsearpc-${LIBSEARPC_VERSION}.tar.gz ../../seafile-sources && \
# ccnet
                    cd ../ccnet-server && \
                    git reset --hard ${SERVER_TAG} && \
                    sed -i "s/6.0.1/${SERVER_VERSION}/g" configure.ac && \
                    sed -i "s/mysqlclient/mariadb/g" configure.ac && \
                    ./autogen.sh && ./configure && make dist && \
                    mv ccnet-${SERVER_VERSION}.tar.gz ../../seafile-sources && \
# seafile-server
                    cd ../seafile-server && \
                    git reset --hard ${SERVER_TAG} && \
                    sed -i "s/6.0.1/${SERVER_VERSION}/g" configure.ac && \
                    sed -i "s/mysqlclient/mariadb/g" configure.ac && \
                    ./autogen.sh && ./configure && make dist && \
                    mv seafile-${SERVER_VERSION}.tar.gz ../../seafile-sources && \
                    apk del build-deps-python && \
# seahub
                    cd ../seahub && git reset --hard ${SERVER_TAG} && \
                    python3 tools/gen-tarball.py --version=${SERVER_VERSION} --branch=HEAD && \
                    mv seahub-${SERVER_VERSION}.tar.gz ../../seafile-sources/ && \
# seaobj
                    cd ../seafobj && git reset --hard ${SERVER_TAG} && make dist && \
                    mv seafobj.tar.gz ../../seafile-sources && \
# seafdav
                    cd ../seafdav && git reset --hard ${SERVER_TAG} && make && \
                    mv seafdav.tar.gz ../../seafile-sources && \
# build server
                    cd ../.. && \
                    apk add --no-cache --virtual build-deps-server \
                        glib-dev \
                        libevent-dev \
                    && \
                    sed -i "s/--enable-ldap//g" dev/seafile-server/scripts/build/build-server.py && \
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
                    mv seafile-server-pkgs/* . && \
                    tar xzf seafile-server_*.tar.gz && \
                    rm -r dev seafile-sources seafile-server-pkgs seafile-server_*.tar.gz /root/.cache/ root/.local && \
                    mv seafile-server* seafile-server && \
                    apk del build-deps build-deps-server && \
                    cd /usr && find . -regex '^.*\(__pycache__\|\.py[co]\)$' -delete

#--------------------------------------------------
FROM                arm64v8/python:3.7-alpine as pull

ARG                 SERVER_VERSION

WORKDIR             /usr/src/

ADD                 https://github.com/haiwen/seafile-rpi/releases/download/v${SERVER_VERSION}/seafile-server-${SERVER_VERSION}-buster-arm64.tar.gz .

RUN                 tar xzf seafile-server-*.tar.gz && \
                        rm seafile-server-*.tar.gz && \
                        mv seafile-server* seafile-server

#--------------------------------------------------
FROM                arm64v8/python:3.7-alpine as prodbase-build
FROM                arm64v8/python:3.7-buster as prodbase-pull
FROM                ${BUILD_METHOD} as merger

#--------------------------------------------------
FROM                prodbase-${BUILD_METHOD} as prod

ARG                 BUILD_METHOD

COPY	            --from=merger /usr/src/seafile-server /usr/src/seafile-server

RUN                 mkdir -p /data && \
                        if [ "${BUILD_METHOD}" = "build" ]; then \
                            apk add --no-cache --virtual build-deps \
                                build-base \
                                mariadb-dev && \
                            apk add --no-cache \
                                bash \
                                mariadb-client \
                                tiff \
                                libjpeg-turbo \
                                ffmpeg && \
	                        pip3 install PyMySQL && \
	                        apk del build-deps && \
	                        adduser -D -H -g 'seafile' seafile; \
                        elif [ "${BUILD_METHOD}" = "pull" ]; then \
                            pip3 install python3-ldap && \
                            adduser --disabled-password --no-create-home --gecos 'seafile' seafile; \
                        fi

COPY                init/init.sh .

WORKDIR             /haiwen/

EXPOSE              8000
EXPOSE              8082

VOLUME              [ "/data/" ]
VOLUME              [ "/haiwen/" ]

ENV                 PYTHONPATH=/haiwen/seafile-server-latest/seahub/thirdpart/:/haiwen/seafile-server-latest/seafile/lib/python3.7/site-packages/

ENTRYPOINT          [ "/init.sh" ]
CMD                 [ "tail", "-f", "/dev/null" ]
