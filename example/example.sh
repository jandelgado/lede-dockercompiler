#!/bin/bash
#
# This script is run in the container and demonstrates a typical OpenWrt 
# build session. Currently it is called from the ci.
#
# usage: example.sh CONFIG-FILE
#   where CONFIG-FILE is an OpenWrt .config file

set -eou pipefail

[ ! -d openwrt ] &&  git clone --depth 1 --branch v19.07.2 https://github.com/openwrt/openwrt

ln -sf "$1" openwrt/.config
cd openwrt

./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make 

