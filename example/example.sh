#!/bin/bash
#
# This script is run in the container and demonstrates a typical OpenWrt 
# build session. Currently it is called from the ci.
#
# usage: example.sh CONFIG-FILE
#   where CONFIG-FILE is an OpenWrt .config file
#
# Environment variables:
# OPENWRT_VERSION - Version to check out, defaults to v19.07.7

set -eou pipefail

OPENWRT_VERSION=${OPENWRT_VERSION:-v19.07.7}

if [ ! -d openwrt ]; then
    git clone --depth 1 --branch "$OPENWRT_VERSION" https://github.com/openwrt/openwrt
fi

cp "$1" openwrt/.config
cd openwrt
git pull

./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make 

