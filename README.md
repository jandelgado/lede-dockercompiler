# Dockerized LEDE/OpenWRT compile environment
A simple docker image to compile LEDE/OpenWRT images from source.

## Usage
First build the docker image:
```
$ ./build.sh build-docker-image 
```

Then put your source files in the `workdir/` directory and start the container:
```
$ ./build.sh shell
```

The second command will open a shell in the docker container with the 
`workdir/` mounted to the directory `/workdir` inside the container. Since 
workdir is externally mounted, it's contents will survive container restarts.

## Author
Jan Delgado <jdelgado[at]gmx.net>

