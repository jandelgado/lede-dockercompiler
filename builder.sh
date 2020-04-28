#!/bin/bash
# Docker based LEDE/OpenWRT build environment
# (c) 2019-2020 Jan Delgado
set -euo pipefail

# base Tag to use for docker image
DEF_IMAGE_TAG=jandelgado/openwrt-imagecompiler
IMAGE_TAG=${IMAGE_TAG:-$DEF_IMAGE_TAG}
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
WORK_DIR=$SCRIPT_DIR/workdir

function usage {
    cat<<EOT
Dockerized OpenWRT compile environment.

Usage: $1 COMMAND [OPTIONS] 
  COMMAND is one of:
    build-docker-image    - build docker image
    run CMD -- [ARGS...]  - run given command in docker container
    shell                 - start shell in docker container

  OPTIONS:
    -o WORK_DIR           - working directory (default $WORK_DIR)
    --docker-opts OPTS    - additional options to pass to docker run
                            (can occur multiple times)
    --rootfs-overlay DIR  - rootfs overlay directory
    --skip-sudo           - call docker directly, without sudo

Environment:
  IMAGE_TAG               - Tag to be used for docker image. 
                            (default: $DEF_IMAGE_TAG)

Example:
  ./builder.sh shell
  ./builder.sh shell --docker-opts "-v=/tmp:/host-tmp"
  ./builder.sh run -- sh -c "cd lede && make menuconfig defconfig world"
 
EOT
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
    [ ! -t 0 ] && docker_term_opts="-i"
    local rootfs_volume=()
    if [ -n "${ROOTFS_OVERLAY+x}" ]; then
        local rootfs
        rootfs="$(abspath "$ROOTFS_OVERLAY")"
        rootfs_volume=(-v "$rootfs":/rootfs-overlay:z)
    fi
    # shellcheck disable=SC2068
	$SUDO docker run \
			--rm \
			-e GOSU_UID="$(id -ur)" -e GOSU_GID="$(id -g)" \
            -v "$(abspath "$WORK_DIR")":/workdir:z \
            "${rootfs_volume[@]}" \
			$docker_term_opts \
            --rm \
            ${DOCKER_OPTS[@]} \
            "$IMAGE_TAG" \
            "$@"
}

function fail {
    echo "ERROR: $*" >&2
    exit 1
}

if [ $# -lt 1 ]; then
    usage "$0"
    exit 0
fi

COMMAND=$1; shift
SUDO=sudo
DOCKER_OPTS=()

# parse cli args, can override config file params
while [[ $# -ge 1 ]]; do
    key="$1"
    case $key in
        -o) WORK_DIR="$2"; shift ;;
        --rootfs-overlay) ROOTFS_OVERLAY="$2"; shift ;;
        --skip-sudo) SUDO="" ;;
        --docker-opts) DOCKER_OPTS+=("$2"); shift ;;
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
     *) usage "$0"; exit 0 ;;
esac

