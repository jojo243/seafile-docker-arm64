FROM        arm64v8/python:2-slim-stretch

ARG         BUILD_DEPS='build-essential libmariadbclient-dev'

RUN         mkdir data haiwen && \
                apt-get update && \
                apt-get install -y --no-install-recommends \
			            libmariadbclient18 \
                        locales \
			            libtiff5 \
                        libjpeg62-turbo \
                        procps \
                        ffmpeg && \
		        apt-get install -y --no-install-recommends \
			             $BUILD_DEPS && \
                pip install MySQL-python && \
		        apt-get purge --autoremove -y $BUILD_DEPS && \
                groupadd seafile && useradd -g seafile seafile && \
                rm -rf /var/lib/apt/lists/* && \
                apt-get clean && \
                find /var/cache/apt/ -type f -exec rm -v {} \;

COPY        init/init.sh .

WORKDIR     /haiwen/

EXPOSE      8000
EXPOSE      8082

ENTRYPOINT  ["/bin/bash", "/init.sh"]
CMD         ["tail", "-f", "/dev/null"]
