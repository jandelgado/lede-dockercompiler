#!/bin/bash
# Docker based LEDE/OpenWRT build environment
# (c) 2019 Jan Delgado
set -e

# base Tag to use for docker image
DEF_IMAGE_TAG=jandelgado/openwrt-imagecompiler
IMAGE_TAG=${IMAGE_TAG:-$DEF_IMAGE_TAG}
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
WORK_DIR=$SCRIPT_DIR/workdir

function usage_and_exit {
    cat<<EOT
Dockerized OpenWRT compile environment.

Usage: $1 COMMAND [OPTIONS] 
  COMMAND is one of:
    build-docker-image- build docker image
    shell             - start shell in docker container

  OPTIONS:
    -o WORK_DIR       - working directory (default $WORK_DIR)
    --skip-sudo       - call docker directly, without sudo

Environment:
  IMAGE_TAG           - Tag to be used for docker image. 
                        (default: $DEF_IMAGE_TAG)

Example:
  ./builder.sh shell
EOT
    exit 0
}

# build container 
function build_docker_image {
    echo "building docker image $IMAGE_TAG ..."
	$SUDO docker build -t "$IMAGE_TAG" docker
}

function run_cmd_in_container {
	$SUDO docker run \
			--rm \
			-e GOSU_UID="$(id -ur)" -e GOSU_GID="$(id -g)" \
            -v "$(cd "$WORK_DIR"; pwd)":/workdir:z \
			-ti --rm "$IMAGE_TAG" "$@"
}

# run a shell in the container, useful for debugging.
function run_shell {
    run_cmd_in_container bash
}

# print message and exit
function fail {
    echo "ERROR: $*" >&2
    exit 1
}

if [ $# -lt 1 ]; then
    usage_and_exit "$0"
fi

COMMAND=$1; shift
SUDO=sudo

# parse cli args, can override config file params
while [[ $# -ge 1 ]]; do
    key="$1"
    case $key in
        -o) WORK_DIR="$2"; shift ;;
        --skip-sudo) SUDO="" ;;
        *) fail "invalid option: $key";;
    esac
    shift
done

[ ! -d "$WORK_DIR" ] && fail "output-dir: no such directory $WORK_DIR"

case $COMMAND in
     build-docker-image) 
         build_docker_image  ;;
     shell) 
         run_shell ;;
     *) usage_and_exit "$0"
esac

