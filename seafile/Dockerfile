#syntax=docker/dockerfile:1.2
ARG             BUILD_METHOD

#--------------------------------------------------
FROM            arm64v8/python:3.7-alpine as build-stage-0

ARG             GITHUB=https://github.com/
ARG             REPO=haiwen
ARG             BASEURL=${GITHUB}${REPO}/

ARG             PREFIX_PATH=/usr/src

# Tags & Versions
ARG             LIBSEARPC_VERSION=3.2
ARG             LIBSEARPC_TAG=v${LIBSEARPC_VERSION}-latest
ARG             SERVER_VERSION
ARG             SERVER_TAG=v${SERVER_VERSION}-server

ARG             PKG_CONFIG_PATH=${PREFIX_PATH}/seafile-server/lib:$PKG_CONFIG_PATH
ARG             PKG_CONFIG_PATH=${PREFIX_PATH}/libsearpc:$PKG_CONFIG_PATH
ARG             PKG_CONFIG_PATH=${PREFIX_PATH}/ccnet-server:$PKG_CONFIG_PATH

WORKDIR         ${PREFIX_PATH}

ENV             PATH=${PATH}:${PREFIX_PATH}/seahub-thirdpart/bin
ENV             PYTHONPATH=${PREFIX_PATH}/seahub-thirdpart/bin

RUN             --mount=type=cache,target=/var/cache/apk/ \
                    apk add --virtual build-deps \
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
                        zlib-dev

# -------
FROM            build-stage-0 as build-stage-1

RUN             --mount=type=cache,target=/var/cache/apk/ \
                    apk add --virtual build-deps-python \
                        glib-dev \
                        libevent-dev \
                        vala

# -------
FROM            build-stage-0 as seahub-thirdpart

RUN             --mount=target=./build,source=build \
                --mount=type=cache,target=/root/.cache/pip \
                    pip3 install --target=seahub-thirdpart -r build/requirements.txt

# -------
FROM            build-stage-0 as libevhtp

RUN             git clone ${BASEURL}libevhtp.git && cd libevhtp && \
                    apk add --no-cache libevent-dev && \
                    cmake -DEVHTP_DISABLE_SSL=ON -DEVHTP_BUILD_SHARED=OFF . && \
                    make && make install && ldconfig /usr/local/lib && \
                    apk del libevent-dev

# -------
FROM            build-stage-1 as libsearpc

RUN             git clone ${BASEURL}libsearpc.git && cd libsearpc && \
                    git reset --hard ${LIBSEARPC_TAG} && \
                    sed -i "s/3.1.0/${LIBSEARPC_VERSION}/g" configure.ac && \
                    ./autogen.sh && ./configure && make dist

# -------
FROM            libsearpc as ccnet

RUN             git clone ${BASEURL}ccnet-server.git && cd ccnet-server && \
                    git reset --hard ${SERVER_TAG} && \
                    sed -i "s/6.0.1/${SERVER_VERSION}/g" configure.ac && \
                    sed -i "s/mysqlclient/mariadb/g" configure.ac && \
                    ./autogen.sh && ./configure && make dist

# -------
FROM            ccnet as seafile-server

RUN             git clone ${BASEURL}seafile-server.git && cd seafile-server && \
                    git reset --hard ${SERVER_TAG} && \
                    sed -i "s/6.0.1/${SERVER_VERSION}/g" configure.ac && \
                    sed -i "s/mysqlclient/mariadb/g" configure.ac && \
                    ./autogen.sh && ./configure && make dist

# -------
FROM            seahub-thirdpart as seahub

RUN             git clone ${BASEURL}seahub.git && cd seahub && \
                    git reset --hard ${SERVER_TAG} && \
                    python3 tools/gen-tarball.py --version=${SERVER_VERSION} --branch=HEAD

# -------
FROM            build-stage-0 as seafobj

RUN             git clone ${BASEURL}seafobj.git && cd seafobj && \
                    git reset --hard ${SERVER_TAG} && make dist

# -------
FROM            build-stage-0 as seafdav

RUN             git clone ${BASEURL}seafdav.git && cd seafdav && \
                    git reset --hard ${SERVER_TAG} && make

# -------
FROM            libevhtp as build

WORKDIR         ${PREFIX_PATH}

COPY            --from=libsearpc ${PREFIX_PATH}/libsearpc/libsearpc-${LIBSEARPC_VERSION}.tar.gz seafile-sources/
COPY            --from=ccnet ${PREFIX_PATH}/ccnet-server/ccnet-${SERVER_VERSION}.tar.gz seafile-sources/
COPY            --from=seafile-server ${PREFIX_PATH}/seafile-server/seafile-${SERVER_VERSION}.tar.gz seafile-sources/
COPY            --from=seafile-server ${PREFIX_PATH}/seafile-server/scripts/build/build-server.py build-server.py
COPY            --from=seahub ${PREFIX_PATH}/seahub/seahub-${SERVER_VERSION}.tar.gz seafile-sources/
COPY            --from=seahub-thirdpart ${PREFIX_PATH}/seahub-thirdpart seahub-thirdpart/
COPY            --from=seafobj ${PREFIX_PATH}/seafobj/seafobj.tar.gz seafile-sources/
COPY            --from=seafdav ${PREFIX_PATH}/seafdav/seafdav.tar.gz seafile-sources/

RUN             mkdir seafile-server-pkgs && \
                    ls -la seafile-sources && \
                    ls -la seahub-thirdpart && \
                    apk add --no-cache --virtual build-deps-server \
                        glib-dev \
                        libevent-dev \
                    && \
                    sed -i "s/--enable-ldap//g" build-server.py && \
                    python3 build-server.py \
                        --version=${SERVER_VERSION} \
                        --libsearpc_version=${LIBSEARPC_VERSION} \
                        --ccnet_version=${SERVER_VERSION} \
                        --seafile_version=${SERVER_VERSION} \
                        --thirdpartdir=${PREFIX_PATH}/seahub-thirdpart/ \
                        --srcdir=${PREFIX_PATH}/seafile-sources \
                        --outputdir=${PREFIX_PATH}/seafile-server-pkgs \
                        --yes && \
# Clean Up
                    mv seafile-server-pkgs/* . && \
                    tar xzf seafile-server_*.tar.gz && \
                    rm -r seafile-server-pkgs seafile-server_*.tar.gz && \
                    mv seafile-server* seafile-server && \
                    apk del build-deps-server && \
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
