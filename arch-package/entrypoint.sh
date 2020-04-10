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

    # FIXME makepkg shouldn't be run as root. Patched to make it work, but it still generates fake errors. Find a better way.
    makepkg --printsrcinfo > .SRCINFO
    [[ $? -ne 0 ]] && exit 1
}


# Main loop; enters aur and aur-bin, and in each:
# 1. Builds the packages
# 2. Tests the packages
# 3. Publishes the packages
function update() {
    pushd aur
    # Build the packages
    buildPackages
    makepkg -f
    [[ $? -ne 0 ]] && exit 1
    # Test the packages
    testPackages
    git clean -f -d
    rm -rf src
    popd

    pushd aur-bin
    # Build the packages
    buildPackages
    git clean -f -d
    popd

    aurpublish log aur aur-bin
}

set -x

# Fix makepkg to allow RUNNING AS ROOT in containers.  For christ's sake.
sed -i '/catastrophic damage/{n;d}' /usr/bin/makepkg
update

git clean -fd
rm -rf aur/src

exit 0
