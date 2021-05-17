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
build seafile and thus cannot enjoy the latest version. Don't worry, it will work anyway. The procedure is described [below](#Low-RAM).*

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

2. Copy that file or rename it to `.env` (That's the file the `docker-compose.yml` is looking for).
  ```bash
cp .env.example .env
```

3. Note the instructions and hints inside the `.env` and adapt everything to your needs (The least thing you probably want to do is change the server name). Afterwards, save the file.

### :warning: !!Notice!! :warning:

Previously, the configuration for this project was done in the `docker-compose.yml`. Using the `.env`-file, the configuration gets much easier and you wont have to update variables in two places. If you want to switch to the new method, you are likely some commits behind the master branch. In that case, just rename your `docker-compose.yml` to say `configuration.old`. Afterwards, `git pull` and update the repo to the latest commit. Then you just follow the instructions to do the [configuration](#Configuration), incorporating your old config from `configuration.old` into `.env`.

### Build Method

You can either compile the whole seafile server yourself, using `BUILD_METHOD=build` in your `.env` file, or pull a precompiled version from the official Github repo. Note that building seafile may take ~1h (~30 min. needed for compilation of lxml). However, can can in theory enjoy the latest version of seafile, even if there is no official ARM-version now. Also, the resulting docker image will be only about ~300 MB in size, because we can use alpine as a base image.

If you want to avoid waiting that long, you can also use `BUILD_METHOD=pull` (see also [below](#Low-RAM)). In that case, a precompiled seafile server will be downloaded from the official Github repo ([Seafile on Raspberry Pi](https://github.com/haiwen/seafile-rpi)) and you don't need to compile seafile on your hardware. This will not take as long, also you don't need as much RAM. The resulting docker image will be ~1 GB in size.

:warning: **Notice**: If you have your project up and running with either build or pull method, you can't switch to the other one, unless you know what you are doing! At the very least, you would have to back up your data, then rename your `seafile/haiwen` folder to say `seafile/haiwen-old/` and after the switch, move your old config (`seafile/haiwen-old/ccnet`, `seafile/haiwen-old/conf`, etc.) back to the new `seafile/haiwen` folder. Also, you would have to create a `seafile/haiwen/seafile-server-latest` symlink to `seafile/haiwen/seafile-server` yourself.

### Using a different MySQL database

The idea behind this project is to have Seafile set up as simple as possible. Therefore, the most straightforward option is taken here, which is to ship the application database with Seafile and run it in another container alongside seafile.

However, if you already have a mysql database in place, it may make more sense to use that instance for seafile.

In that case,

1. comment out or delete the `db`-section inside the `docker-compose.yml`.
  ```yaml
  services:
      ...
  #    db:
  #        restart: always
  #        build:
  #            context: db
  #            args:
  #              - MYSQL_VERSION=${MYSQL_VERSION}
  #        image: jojo243/mysql:${MYSQL_VERSION}
  #        container_name: seafile_db
  #        volumes:
  #          - ./db/data:/db/mysql
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

Make sure you adapted everything inside the `.env` following the instructions above (See [Configuration](#Configuration)). Now build the whole thing (this can take up to an hour):

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

You will have to rely on the [official seafile builds for Raspberry Pi](https://github.com/haiwen/seafile-rpi).
Just set the `BUILD_METHOD` inside your `.env`-file to `pull`.

```bash
~~BUILD_METHOD=build~~
BUILD_METHOD=pull
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

- `Page unavailable / server hiccup`

    This means seahub has thrown some exception. Look it up inside `seafile/haiwen/logs/seahub.log`.
    Also, set Djangos `DEBUG = True` inside `seahub-settings.py`.

- `Error: Seahub failed to start.`

    This is some gunicorn error. Try setting `daemon = False` in `conf/gunicorn.conf` to get more info.

