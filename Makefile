MAKEFLAGS += --silent

CLEANDIRS=db/data seafile/haiwen seafile/seafile

default: daemon

.PHONY: 1 2 3 4 5 6 build up daemon start down stop clean upgrade backup backup-ssl restore

export DOCKER_BUILDKIT=1

#1.BUILD
1: build

build:
	docker-compose --env-file .env build

#2.START
2: up

up:
	docker-compose up

daemon:
	docker-compose up -d

start:
	docker-compose start

#21.UPGRADE
21: upgrade

upgrade:
	docker-compose run seafile upgrade
	docker-compose down

#3.STOP
3: down

down:
	docker-compose down

stop:
	docker-compose stop

#4.CLEAN
4: clean

clean:
	make down
	for dir in $(CLEANDIRS); do \
		if [ -d $$dir ]; then \
			sudo rm -rf $$dir; \
		fi; \
	done
