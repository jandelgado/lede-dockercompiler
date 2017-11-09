# Dockerized LEDE/OpenWRT compile environment

A simple docker image to compile LEDE/OpenWRT images from source.

Look [here](https://github.com/jandelgado/lede-dockerbuilder) for a simpler 
version which uses the LEDE/OpenWRT imager builder, which uses pre-compiled 
packages to build the actual image.

## Usage

```
Dockerized LEDE/OpenWRT compile environment.

Usage: $1 COMMAND [OPTIONS] 
  COMMAND is one of:
    build-docker-image- build docker image
    shell             - start shell in docker container

  OPTIONS:
  -o WORK_DIR         - working directory 
  --skip-sudo         - call docker directly, without sudo

Example:
  ./builder.sh shell
```

First build the docker image with `./builder.sh build-docker-image`, 
then put your source files in the `workdir/` directory and start the acutal
container with the LEDE build environment with `./builder.sh shell`.

The last command will open a shell in the docker container with local the 
`workdir/` mounted to the directory `/workdir` in the container. Since 
workdir is externally mounted, it's contents will survive container restarts.

## Example build session

Create the the docker image and start a container as described above.  This
will take you straight into a shell in the container, with the local `workdir`
directory mounted as a volume to `/workdir`. On success, you'll see a prompt
like `builder@567cbabfb36b:/workdir$`.  Now execute the following commands to
build LEDE from source (see [this page for more
details](https://lede-project.org/docs/guide-developer/quickstart-build-images)):

```
git clone https://git.lede-project.org/source.git lede && cd lede
./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make menuconfig
make
```

The resulting images can be found in `workdir/lede/bin/target`.

## Author
Jan Delgado <jdelgado[at]gmx.net>

