[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity)

# Seafile Docker ARM64

## About

This is a set of scripts and Dockerfiles for setting up [Seafile](https://www.seafile.com/en/home/) in docker.

The Seafile Maintainers provide a dockerized setup themselves (https://github.com/haiwen/seafile-docker), but that one is not compatible with ARM devices.

## Overview

![](components-overview.png)

We use three main docker images to separate the different components from each other.
- **nginx** acts as a reverse proxy for the main seafile server w/ seahub.
- **seafile** is the main application, built and packaged using the procedure described [in the official manual](https://manual.seafile.com/build_seafile/rpi.html).

   *Note:* Building and packaging is done seperately, inside the **build** image.
- **mysql** is the application database.

## Prerequisites

### Hardware Prerequisites

- CPU with **ARMv8 64-bit** architecture (e.g. SBCs listed below)
- **\>= 1 GB of RAM**, *Recommended*: ~= 4 GB of RAM (needed for compilation of lxml)
- *Recommended*: >= **30 GB of disk space** per user

**Note**: *If your Hardware doesn't have enough RAM, you won't be able to
build seafile and thus cannot enjoy the latest version. Don't worry, it will work anyway. The procdure is described [below](#Low-RAM).*

Specifically, this setup has been tested on:

- [Raspberry Pi 3 Model B+](https://www.raspberrypi.org/products/raspberry-pi-3-model-b-plus/)
- [Rock64](https://www.pine64.org/devices/single-board-computers/rock64/)

### Software Prerequisites

- An OS with working Docker (e.g. Raspbian, Ubuntu)
- [Docker](https://docs.docker.com/install/linux/docker-ce/debian/)
- [docker-compose](https://docs.docker.com/compose/install/)
- make

It's heavily recommended to add your user to the `docker` group,
otherwise you will have to put `sudo` in front of every docker command.

```bash
sudo usermod -aG docker $USER
```

Log out and back in again for the change to take effect.

## Getting Started

First of all, make sure you meet the [Requirements](#Prerequisites). Then fork or clone this repo:

```bash
git clone https://github.com/jojo243/seafile-docker-arm64.git
cd seafile-docker-arm64
```

## Configuration

1. Take a look at the `.env.example`. Most of the configuration
is done there.

2. Copy that file or rename it to `.env`. The `docker-compose.yml` looks for that file.
  ```bash
cp .env.example .env
```

3. Note the instructions and hints inside the `.env` and adapt everything to your needs (The least thing you probably want to do is change the server name). Afterwards, save the file.

### Using a different MySQL database

The idea behind this project is to have Seafile set up as simple as possible. Therefore, the most straightforward option is taken here, which is to ship the application database with Seafile and run it in a container.

However, if you already have a mysql database in place, it may make more sense to use that instance for seafile.

In that case,

1. comment out or delete the `db`-section inside the `docker-compose.yml`.
  ```yaml
  services:
      ...
  #    db:
  #        build:
  #            context: db
  #        restart: always
  #        image: jojo243/mysql
  #        container_name: seafile_db
  #        volumes:
  #          - ./db/data:/var/lib/mysql
  #        env_file: .env
      ...
  ```
2. Also comment out or delete the `depends_on` field from the seafile section:
  ```yaml
  services:
    ...
    seafile:
        build:
            context: seafile
        restart: always
        ...
        # depends_on:
        #    - db
  ```
3. Configure `MYSQL_HOST`/`MYSQL_PORT`/`MYSQL_USER`/`MYSQL_PASSWORD`/`MYSQL_ROOT_PASSWORD` in the `.env`-file to reflect the location of the MySQL database.

    **Note**: The `MYSQL_HOST` must be accessible *from within the seafile docker container*. That means, if you specify `localhost` here, the database won't be accessible and an error will be thrown during the installation process. Specify either the IP address of the host or make sure the database is accessible from within the container otherwise. E.g., if the database is running inside another docker container, create a `docker network` and add both the `seafile`-container and the mysql container to that.

### SSL Configuration

To enable SSL (https:\/\/SERVER_NAME:PORT)

1. Set `SSL` to 1.
2. Create a folder named `ssl`.

    ```bash
    mkdir -p ssl
    ```
3. Copy your SSL Certs (`fullchain.pem` and `privkey.pem`) as well as a
DH params file (`dhparams.pem`) into that directory.
If you don't have such files, follow the instructions
[here](https://certbot.eff.org/lets-encrypt/) (SSL Certs) and
[here](https://weakdh.org/sysadmin.html) (DH params). The following command
should do the trick for the last one:

    ```bash
    openssl dhparam 2048 > ssl/dhparam.pem
    ```

4. Make sure your user owns the SLL folder:

    ```bash
    sudo chown -R $USER ssl
    ```

## Building

Make sure you adapted everything inside the `.env` following the instructions above (See [Configuration](#Configuration)). Now build the whole thing (this may take a while):

```bash
make 1
```

Run the first startup in foreground so you can see what's going on.

```bash
make up
```

Wait for the startup procedure to complete
(it may take a while when first starting seafile).
You will see something like this:

```txt
seafile_seafile | Starting seahub at port 8000 ...
seafile_seafile |
seafile_seafile |
seafile_seafile |
seafile_seafile | ----------------------------------------
seafile_seafile | Successfully created seafile admin
seafile_seafile | ----------------------------------------
seafile_seafile |
seafile_seafile |
seafile_seafile |
seafile_seafile |
seafile_seafile | Seahub is started
```

Everything is now set up.
Now, stop the first run be typing `Ctrl+C` and start seafile in background.

```bash
make
```

You can access the seahub webinterface at http(s):\/\/SERVER_NAME:PORT.
Log in with your ADMIN_EMAIL and ADMIN_PASSWORD.
After that, change your ADMIN_PASSWORD via webinterface.

## Running

Start Seafile in background.

```bash
make
```

You can now access the seahub webinterface at http(s):\/\/SERVER_NAME:PORT.
Seafile will start up automatically, you wont need start it everytime you boot up your system.

## Stopping

```bash
make down
```

## Low RAM

You will have to rely on the [official seafile builds for Raspberry Pi](https://github.com/haiwen/seafile-rpi). Just grab the latest release, uncompress it and place it inside `build/src`:

```bash
SERVER_VERSION=6.3.4
wget https://github.com/haiwen/seafile-rpi/releases/download/v${SERVER_VERSION}/seafile-server_${SERVER_VERSION}_stable_pi.tar.gz
tar -xzf seafile-server_*.tar.gz
rm seafile-server_*.tar.gz
mv seafile-server* build/src/seafile-server
```

Additionally, you will have to comment out the whole `baseimage` target inside `docker-compose.yml`:

```yaml
services:
#    baseimage:
#        build:
#            context: build
#            args:
#              - "SERVER_VERSION=7.0.0"
#        image: jojo243/seafile-base
#        container_name: seafile_base
#        volumes:
#            - ./build/src:/haiwen
    seafile:
        build:
            ...
        ...
```

## Troubleshooting

- `Error 502: Bad Gateway.`

    Most likely, seahub is not started.

    ```
    docker-compose exec seafile bash -c "cd seafile-server-latest && ./seahub.sh start"
    ```

    Secondly, try restarting the application:

    ```
    make down
    make
    ```
