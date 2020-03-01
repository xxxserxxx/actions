#!/bin/bash

pkgver=$1

set -x

# Verify the PKGBUILD
r=$(namcap PKGBUILD)
if [[ $r != "" ]]; then
    echo $r
    exit 1
fi

arch=$(uname -m)
for f in *${arch}.pkg.tar.xz; do
    # Verify the built package
    #r=$(namcap $f)
    #if [[ $r != "" ]]; then
    #    echo $r
    #    exit 1
    #fi

    # Install the package
    sudo pacman -U --noconfirm $f
    [[ $? -ne 0 ]] && exit 1

    # Test that the program runs
    vers=`gotop -V`
    [[ $? -ne 0 ]] && exit 1

    # Test that the right version was installed
    [[ $vers != $pkgver ]] && exit 1

    # Uninstall the package
    pkn=$(echo $f | sed "s/\(^.*\)-${pkgver}.*/\1/")
    sudo pacman -R --noconfirm $pkn
    [[ $? -ne 0 ]] && exit 1
done

set +x
