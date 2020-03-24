#!/bin/bash
#
# This script is run in the container and demonstrates a typical OpenWrt 
# build session. Currently it is called from the ci.
#

set -eou pipefail

[ ! -d openwrt ] &&  git clone --depth 1 --branch v19.07.2 https://github.com/openwrt/openwrt

cp config openwrt/.config
cd openwrt

./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make 

