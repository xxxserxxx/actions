#!/bin/bash
#
# REQUIRED: $VERSION must be exported
# OPTIONAL: $_tests may be defined. BNF-ish is: command '=' expected-result
#           Both command and expected-result should be URL encoded.
#
# $0 "gotop%20-V=$VERSION ls%20-1%20|%20wc%20-l=9"

export _tests=${@-""}

# Helper to unencode tests
function urldecode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

# Runs tests defined in the $_tests variable.
function runTests() {
    for test in $_tests; do
        local t=$(echo "$test" | cut -d '=' -f 1)
        local e=$(echo "$test" | cut -d '=' -f 2)
        local command=$(urldecode "$t")
        local expected=$(urldecode "$e")
        local got=$(eval "$command")
        if [[ $got != $expected ]]; then
            echo "'$command' expected '$expected', got '$got'"
            exit 1
        fi
    done
}

# Installs each package in the directory, executes any defined tests, and
# uninstalls the package
#
# Call from within a directory containing packages
function testPackages() {
    arch=$(uname -m)
    for f in *${arch}.pkg.tar.xz; do
        # Install the package
        pkn=$(echo $f | sed "s/\(^.*\)-${VERSION}.*/\1/")

        sudo pacman -U --noconfirm $f
        [[ $? -ne 0 ]] && exit 1

        # Test that the program runs
        runTests
        if [[ $res -ne 0 ]]; then
            sudo pacman -R --noconfirm $pkn
            exit 1
        fi

        # Uninstall the package
        sudo pacman -R --noconfirm $pkn
        [[ $? -ne 0 ]] && exit 1
    done
}

# Update and build the packages.
# Call from the directory containing the PKGBUILD
function buildPackages() {
    sed -i "s/^pkgver=.*/pkgver=$VERSION/; /^sha256sums/d; /^md5sums/d" PKGBUILD

    makepkg -g >> PKGBUILD
    [[ $? -ne 0 ]] && exit 1

    makepkg --printsrcinfo > .SRCINFO
    [[ $? -ne 0 ]] && exit 1

    makepkg -f
}


# Main loop; enters aur and aur-bin, and in each:
# 1. Builds the packages
# 2. Tests the packages
# 3. Publishes the packages
function update() {
    for d in aur aur-bin; do
        pushd $d

        # Build the packages
        buildPackages
        ex=$?
        if [[ $ex -ne 0 ]]; then
            popd
            echo FAILED $d
            exit $ex
        fi

        # Test the packages
        testPackages
        if [[ $ex -ne 0 ]]; then
            popd
            echo FAILED $d
            exit $ex
        fi
        popd

        aurpublish log $d
    done
}

set -x

# Fix makepkg to allow RUNNING AS ROOT in containers.  For christ's sake.
sed -i '/\n/!N;/\n.*\n/!N;/\n.*\n.*catastrophic damage/{$d;N;N;d};P;D' /usr/bin/makepkg
update

exit 0
