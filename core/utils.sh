#!/usr/bin/env bash

chroot_copy_config() {
    cd configs/$1
    rsync -av --backup --suffix=.bak . /
    cd -
}
