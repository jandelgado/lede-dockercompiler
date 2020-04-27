# Dockerized LEDE/OpenWrt compile environment

[![Build Status](https://travis-ci.org/jandelgado/lede-dockercompiler.svg?branch=master)](https://travis-ci.org/jandelgado/lede-dockercompiler)

A docker image to compile LEDE/OpenWrt images from source.


<!-- vim-markdown-toc GitLab -->

* [Quickstart](#quickstart)
* [Build and run docker image](#build-and-run-docker-image)
* [Using the image](#using-the-image)
    * [Basic usage](#basic-usage)
    * [Compile an individual package](#compile-an-individual-package)
    * [Adding a new package](#adding-a-new-package)
        * [Build the OpenWrt SDK](#build-the-openwrt-sdk)
        * [Create package structure (in-tree version)](#create-package-structure-in-tree-version)
        * [Create package structure (custom feed version)](#create-package-structure-custom-feed-version)
    * [Working with patches](#working-with-patches)
        * [Change an existing patch](#change-an-existing-patch)
* [Author and Copyright](#author-and-copyright)

<!-- vim-markdown-toc -->

Note: Look [here](https://github.com/jandelgado/lede-dockerbuilder) for a
version which uses the LEDE/OpenWrt imager builder, which uses pre-compiled
packages to build the actual image.

## Quickstart

You can directly start the image builder from the docker hub:

```
$ mkdir -p workdir
$ docker run --rm -e GOSU_UID="$(id -ur)" -e GOSU_GID="$(id -g)" \
             -v $(cd workdir; pwd):/workdir:z \
             -ti --rm docker.io/jandelgado/openwrt-imagecompiler:latest bash
```

This will take you to a bash shell with an OpenWrt build environment. Local
directory `workdir` will be mounted to `/workdir` in the container. See below
for how to use the image.

## Build and run docker image

Use the `builder.sh` to build and run the docker image:

```
Dockerized OpenWRT compile environment.

Usage: ./builder.sh COMMAND [OPTIONS] 
  COMMAND is one of:
    build-docker-image    - build docker image
    run CMD -- [ARGS...]  - run given command in docker container
    shell                 - start shell in docker container

  OPTIONS:
    -o WORK_DIR           - working directory (default /home/paco/src/container-pi/lede-dockercompiler/workdir)
    --rootfs-overlay DIR  - rootfs overlay directory
    --skip-sudo           - call docker directly, without sudo
    --docker-opts OPTS    - additional options to pass to docker. Can be specified
                            multiple times.

Environment:
  IMAGE_TAG               - Tag to be used for docker image. 
                            (default: jandelgado/openwrt-imagecompiler)

Example:
  ./builder.sh shell
  ./builder.sh run -- sh -c "cd lede && make menuconfig defconfig world"
  ./builder.sh run --docker-opts "-v/tmp:/mytemp" -- bash
```

First build the docker image with `./builder.sh build-docker-image`,
then put your source files in the `workdir/` directory and start the acutal
container with the OpenWrt build environment with `./builder.sh shell`.

The last command will open a shell in the docker container with local the
`workdir/` mounted to the directory `/workdir` in the container. Since
workdir is externally mounted, it's contents will survive container restarts.

## Using the image

Some tipps on using the OpenWrt SDK.

### Basic usage

Start a container as described above.  This will take you straight into a shell
in the container, with the local `workdir` directory mounted as a volume to
`/workdir` inside the container. On success, you'll see a prompt like
`builder@567cbabfb36b:/workdir$`.

Now execute the following commands in the container to prepare the OpenWrt
source (see [this page for more
details](https://lede-project.org/docs/guide-developer/quickstart-build-images)):

```bash
git clone https://github.com/openwrt/openwrt lede && cd lede
./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make menuconfig
make
```

The resulting images can be found in `workdir/lede/bin/target` (on the host),
or in `/workdir/lede/bin/target` in the container.

### Compile an individual package

```bash
$ make packages/network/utils/tcpdump/{clean,compile}
```

Add `V=s` for enhanced verbosity.

### Adding a new package

This describes how to add a new OpenWrt package. We use the
[udptunnel](http://www.cs.columbia.edu/~lennox/udptunnel/) tool as an
example.

See also

* https://openwrt.org/docs/guide-developer/packages
* https://github.com/openwrt/packages/blob/master/CONTRIBUTING.md
* https://openwrt.org/docs/guide-developer/build-system/use-buildsystem

#### Build the OpenWrt SDK

First we need to build the OpenWrt SDK:

```bash
$ make tools/install
$ make toolchain/install
```

#### Create package structure (in-tree version)

We need to create a directory in a suitable place under the `package/`
directory and create at least a [Makefile as described
here.](https://openwrt.org/docs/guide-developer/packages). We will place our
package in `package/network/util/udptunnel`.

```
udptunnel
├── Makefile
└── patches
    ├── 001-multicast.patch
    └── 002-main_code_fix.patch
```

Build the package with

```
$ make packages/network/utils/tcpdump/{clean,compile}
```

#### Create package structure (custom feed version)

This time the we place the package in a custom feed, outside the OpenWrt root.
We put our package to `/workdir/myfeed/net/udptunnel` (container path).

The custom feed needs to be added to `feeds.conf.default`:

```
src-link myfeed /workdir/myfeed
```

Install the feed with 

```
$ ./scripts/feed update myfeed && ./scripts/feed install -a myfeed`
```

Now run `make menuconfig` and activate the custom feed under `[*] Image
configuration` -> `[*] Separate feed repositories` -> `<*> enable feed myfeed`.

The package should now be available within the `Network` category (because we
chose `Network` as category in the Makefile). Compile the package manually with 

```bash
$ make package/udptunnel/{clean,compile}
```

See [OpenWrt Hello,
world!](https://openwrt.org/docs/guide-developer/helloworld/start) for an
in-depth description.

### Working with patches

(Adapted from https://openwrt.org/docs/guide-developer/patches)

To make the package compile as properly, we need to patch it. OpenWrt uses the
[quilt](https://en.wikipedia.org/wiki/Quilt_(software) quilt tool for patch
management.

From the root of your OpenWrt tree, execute:

```bash
$ make package/network/util/udptunnel/{clean,prepare} V=s QUILT=1
```

Then cd into the prepared source directory with
```
$ cd build_dir/target-*/udptunnel-*
```

First we have to apply existing patches (in case your are working on an
exisiting OpenWrt package which already contains patches):

```bash
$ quilt push -a
```

Then start the first patch:

```bash
$ quilt new 010-main_code_fix.patch
Patch patches/010-main_code_fix.patch is now on top
```

Now edit the sources using `quilt edit`, in our case we will edit the file
`host2ip.c`:

```bash
$ quilt edit host2ip.c
File host2ip.c added to patch patches/010-main_code_fix.patch
```

The `quilt` command will automatically start an editor for you, according your
[~/.quiltc file](https://openwrt.org/docs/guide-developer/build-system/use-patches-with-buildsystem#prepare_quilt_configuration).

Check the changes with `quilt diff` and `quilt files`. If everything is ok,
we can update the patch file, `010-main_code_fix.patch`:

```bash
$ quilt refresh
```

Change back to root of your OpenWrt tree and update the package with the
patch:

```bash
$ (cd ../../.. && make package/network/utils/udptunnel/update V=s)
make[1]: Entering directory '/workdir/lede'
make[2]: Entering directory '/workdir/lede/package/network/utils/udptunnel'
if [ -s "/workdir/lede/build_dir/target-mipsel_24kc_musl/udptunnel-full/udptunnel-1.1/patches/series" ]; then (cd "/workdir/lede/build_dir/target-mipsel_24kc_musl/udptunnel-full/udptunnel-1.1"; if quilt --quiltrc=- next >/dev/null 2>&1; then quilt --quiltrc=- push -a; else quilt --quiltrc=- top >/dev/null 2>&1; fi ); fi
touch "/workdir/lede/build_dir/target-mipsel_24kc_musl/udptunnel-full/udptunnel-1.1/.quilt_checked"
mkdir -p ./patches
rm -f ./patches/* 2>/dev/null >/dev/null
'/workdir/lede/build_dir/target-mipsel_24kc_musl/udptunnel-full/udptunnel-1.1/patches/010-main_code_fix.patch' -> './patches/010-main_code_fix.patch'
make[2]: Leaving directory '/workdir/lede/package/network/utils/udptunnel'
time: package/network/utils/udptunnel/full/update#0.07#0.04#0.12
make[1]: Leaving directory '/workdir/lede'
```

As you can see, the patch `010-main_code_fix.patch` was applied.

Now the patched package can be built:

```bash
$ (cd ../../.. && make package/network/utils/udptunnel/{clean,compile} V=s)
```

Depending on your architecture, the resulting `ipk` package can be found under
`bin/packages/<architecture>/base`, e.g.
`./bin/packages/mipsel_24kc/base/udptunnel_1.1-1_mipsel_24kc.ipk`.


#### Change an existing patch

The workflow to change an exisiting patch is similar to the above described
workflow:

```bash
# start in root of your OpenWrt source tree
$ make package/network/utils/udptunnel/{clean,compile} V=s
$ cd build_dir/target-*/udptunnel-*
$ quilt series
001-multicast.patch
002-main_code_fix.patch
$ quilt push 002-main_code_fix.patch
$ quilt edit udptunnel.c
$ quilt diff
$ quilt refresh
$ ( cd ../../.. && make package/network/utils/udptunnel/update V=s )  # apply patches
$ ( cd ../../.. && make package/network/utils/udptunnel/{clean,compile} V=s )
```

## Author and Copyright

(C) Copyright 2019-2020 Jan Delgado <jdelgado[at]gmx.net>

