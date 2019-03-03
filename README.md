# Dockerized LEDE/OpenWRT compile environment

A docker image to compile LEDE/OpenWRT images from source.

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
container with the OpenWRT build environment with `./builder.sh shell`.

The last command will open a shell in the docker container with local the 
`workdir/` mounted to the directory `/workdir` in the container. Since 
workdir is externally mounted, it's contents will survive container restarts.

## Example build session

Create the docker image and start a container as described above.  This will
take you straight into a shell in the container, with the local `workdir`
directory mounted as a volume to `/workdir` inside the container. On success,
you'll see a prompt like `builder@567cbabfb36b:/workdir$`.  

Now execute the following commands in the container to prepare the OpenWRT
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
$ make packages/network/utils/tcpdump/install
```

Add `V=s` for enhanced verbosity.

## Adding a new package

In this chapter I am going to create a package for the 
[udptunnel](http://www.cs.columbia.edu/~lennox/udptunnel/) tool.

See also

* https://openwrt.org/docs/guide-developer/packages
* https://github.com/openwrt/packages/blob/master/CONTRIBUTING.md

### Build the OpenWRT SDK

First we need to build the OpenWRT SDK:

```bash
$ make tools/install
$ make toolchain/install
```

### Create package structure

We need to create a directory in a suitable place under the `package/` directory 
and create at least a [Makefile as described here.](https://openwrt.org/docs/guide-developer/packages). We will place our package in `package/network/util/udptunnel`.

### Working with patches

(Adapted from https://openwrt.org/docs/guide-developer/patches)

To make the package compile as properly, we need to patch it. OpenWRT uses the
[quilt](https://en.wikipedia.org/wiki/Quilt_(software) quilt tool for patch
management.

From the root of your OpenWRT tree, execute:

```bash
$ make package/network/util/udptunnel/{clean,prepare} V=s QUILT=1
```

Then cd into the prepared source directory with 
```
$ cd build_dir/target-*/udptunnel-*
```

First we have to apply existing patches (in case your are working on an
exisiting OpenWRT package which already contains patches):

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

Change back to root of your OpenWRT tree and update the package with the 
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


### Change an existing patch

The workflow to change an exisiting patch is similar to the above described
workflow:

```bash
# start in root of your OpenWRT source tree
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

## Author

Jan Delgado <jdelgado[at]gmx.net>

