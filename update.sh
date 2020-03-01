#!/bin/bash
# Updates the version and checksums of a gotop release

pkgver=$1

for d in aur aur-bin; do
    pushd $d

    # Build the packages
    ../make.sh $pkgver
    ex=$?
    if [[ $ex -ne 0 ]]; then
        popd
        echo FAILED $d
        exit $ex
    fi

    # Test the packages
    ../test.sh $pkgver
    if [[ $ex -ne 0 ]]; then
        popd
        echo FAILED $d
        exit $ex
    fi
done

popd

exit 0
