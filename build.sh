#!/bin/bash

pkgver=$1

set -x

sed -i "s/^pkgver=.*/pkgver=$pkgver/; /^sha256sums/d; /^md5sums/d" PKGBUILD

makepkg -g >> PKGBUILD
[[ $? -ne 0 ]] && exit 1

makepkg --printsrcinfo > .SRCINFO
[[ $? -ne 0 ]] && exit 1

makepkg -f

set +x
