#!/bin/bash

pkgver=$1

urldecode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

function runTests() {
    for test in $_tests; do
        local t=$(echo "$test" | cut -d '=' -f 1)
        local e=$(echo "$test" | cut -d '=' -f 2)
        local command=$(urldecode "$t")
        local expected=$(urldecode "$e")
        local got=$(eval "$command")
        if [[ $got != $expected ]]; then
            echo "'$command' expected '$expected', got '$got'"
            return 1
        fi
    done
    return 0
}

set -x

arch=$(uname -m)
for f in *${arch}.pkg.tar.xz; do
    # Install the package
    pkn=$(echo $f | sed "s/\(^.*\)-${pkgver}.*/\1/")

    sudo pacman -U --noconfirm $f
    [[ $? -ne 0 ]] && exit 1

    # Test that the program runs
    res=$(runTests)
    if [[ $res -ne 0 ]]; then
        sudo pacman -R --noconfirm $pkn
        exit 1
    fi

    # Uninstall the package
    sudo pacman -R --noconfirm $pkn
    [[ $? -ne 0 ]] && exit 1
done

set +x
