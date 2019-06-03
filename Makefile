MAKEFLAGS += --silent

CLEANDIRS=mysql/data seafile/haiwen seafile/seafile build/src

default: daemon

.PHONY: 1 2 3 4 5 6 build up daemon start down stop clean backup backup-ssl restore

#1.BUILD
1: build

build:
	docker-compose build


#2.START
2: up

up:
	docker-compose up

daemon:
	docker-compose up -d

start:
	docker-compose start

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
			rm -rf $$dir; \
		fi; \
	done
