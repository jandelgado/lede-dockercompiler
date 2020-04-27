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
    build-docker-image    - build docker image
    run CMD -- [ARGS...]  - run given command in docker container
    shell                 - start shell in docker container

  OPTIONS:
    -o WORK_DIR           - working directory (default $WORK_DIR)
    --rootfs-overlay DIR  - rootfs overlay directory
    --skip-sudo           - call docker directly, without sudo
    --docker-opts OPTS    - additional options to pass to docker. Can be specified
                            multiple times.

Environment:
  IMAGE_TAG               - Tag to be used for docker image. 
                            (default: $DEF_IMAGE_TAG)

Example:
  ./builder.sh shell
  ./builder.sh run -- sh -c "cd lede && make menuconfig defconfig world"
  ./builder.sh run --docker-opts "-v/tmp:/mytemp" -- bash
 
EOT
    exit 0
}

# return given file path as absolute path. path to file must exist.
function abspath {
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

# build container 
function build_docker_image {
    echo "building docker image $IMAGE_TAG ..."
	$SUDO docker build -t "$IMAGE_TAG" docker
}

function run_cmd_in_container {
    local docker_term_opts="-ti"
    local rootfs
    local rootfs_vol
    if [ -n "$ROOTFS_OVERLAY" ]; then
        rootfs="$(abspath "$ROOTFS_OVERLAY")"
        rootfs_vol=(-v "$rootfs":/rootfs-overlay:z)
    else
        rootfs_vol=()
    fi
    # shellcheck disable=SC2086
	$SUDO docker run \
			--rm \
			-e GOSU_UID="$(id -ur)" -e GOSU_GID="$(id -g)" \
            -v "$(abspath "$WORK_DIR")":/workdir:z \
            "${rootfs_vol[@]}" \
			$docker_term_opts \
            --rm \
            $DOCKER_OPTS \
            "$IMAGE_TAG" \
            "$@"
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
DOCKER_OPTS=

# parse cli args, can override config file params
while [[ $# -ge 1 ]]; do
    key="$1"
    case $key in
        -o) WORK_DIR="$2"; shift ;;
        --rootfs-overlay) ROOTFS_OVERLAY="$2"; shift ;;
        --skip-sudo) SUDO="" ;;
        --docker-opts) DOCKER_OPTS="$DOCKER_OPTS $2"; shift ;;
        --) shift; break ;;
        *) fail "invalid option: $key";;
    esac
    shift
done

[ ! -d "$WORK_DIR" ] && fail "output-dir: no such directory $WORK_DIR"
[ -n  "${ROOTFS_OVERLAY+x}" ] && [ ! -d "$ROOTFS_OVERLAY" ] && fail "roofs-overlay: no such directory $ROOTFS_OVERLAY"

case $COMMAND in
     build-docker-image) 
         build_docker_image  ;;
     run)
         run_cmd_in_container "$@" ;;
     shell) 
         run_cmd_in_container bash ;;
     *) usage_and_exit "$0" ;;
esac

