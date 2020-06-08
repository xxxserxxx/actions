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
        $($test)
        if [[ $? -ne 0 ]]; then
            echo "'$test' failed with $?"
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
    local V=${VERSION#v}
    for f in *${arch}.pkg.tar.xz; do
        # Install the package
        pkn=$(echo $f | sed "s/\(^.*\)-${V}.*/\1/")

        pacman -U --noconfirm $f
        [[ $? -ne 0 ]] && exit 1

        # Test that the program runs
        runTests
        if [[ $res -ne 0 ]]; then
            pacman -R --noconfirm $pkn
            exit 1
        fi

        # Uninstall the package
        pacman -R --noconfirm $pkn
        [[ $? -ne 0 ]] && exit 1
    done
}

# Update and build the packages.
# Call from the directory containing the PKGBUILD
function buildPackages() {
    local V=${VERSION#v}
    sed -i "s/^pkgver=.*/pkgver=$V/; /^sha256sums/d; /^md5sums/d" PKGBUILD

    updpkgsums
    [[ $? -ne 0 ]] && exit 1

    curl -s https://hg.sr.ht/\~ser/printsrcinfo/raw/printsrcinfo | bash > .SRCINFO
    [[ $? -ne 0 ]] && exit 1
}


# Main loop; enters gotop and gotop-bin, and in each:
# 1. Builds the packages
# 2. Tests the packages
# 3. Publishes the packages
function update() {
    pushd gotop
    # Build the packages
    buildPackages
    makepkg -f
    [[ $? -ne 0 ]] && exit 1
    # Test the packages
    testPackages
    git clean -f -d
    rm -rf src
    popd

    pushd gotop-bin
    # Build the packages
    buildPackages
    git clean -f -d
    popd

    aurpublish log gotop gotop-bin
}

set -x

# Fix makepkg to allow RUNNING AS ROOT in containers.  For christ's sake.
sed -i '/catastrophic damage/{n;d}' /usr/bin/makepkg
update

git clean -fd
rm -rf gotop/src

exit 0
