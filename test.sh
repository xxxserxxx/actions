#!/bin/bash

pkgver=$1

set -x

# Verify the PKGBUILD
namcap PKGBUILD
[[ $? -ne 0 ]] && exit 1

for f in *.gz; do
    # Verify the built package
    namcap $f
    [[ $? -ne 0 ]] && exit 1

    # Install the package
    pacman -U $f
    [[ $? -ne 0 ]] && exit 1

    # Test that the program runs
    vers=`gotop -V`
    [[ $? -ne 0 ]] && exit 1

    # Test that the right version was installed
    [[ $vers -ne $pkgver ]] && exit 1

    # Uninstall the package
    pacman -R $f
    [[ $? -ne 0 ]] && exit 1
done

set +x
