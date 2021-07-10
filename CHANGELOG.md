# Changelog for lede-dockercompiler

## 1.1.0 - [2020-05-15]

* add `pyhton3-distutils` package needed by OpenWrt master
* replace `go-su` by `exec chroot --userspec ...`

## 1.0.0 - [2020-04-16]

* changelog and versioning started
* new optional argument `--docker-opts` 
* ditch travis-ci, use github actions due to travis reliability problems
* added simple example script which is executed in the build container


