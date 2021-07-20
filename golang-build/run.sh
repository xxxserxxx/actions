#!/bin/sh
#
# For building locally (e.g., on a laptop)
#
# USAGE: $0 REPO SRCPATH INPUT_ARGS [GITREF]
#
# cd ~/workspace
# git daemon --port=8880 --verbose --export-all --reuseaddr --base-path=.
# bash run.sh git://localhost:8880/gotop ./cmd/gotop "darwin/arm64/1" refs/remotes/origin/master
#
# That last is because git is, well, git, and nothing in git can be straightforward.

if [[ $# -lt 2 ]]; then
    echo "USAGE: $0 <repo> <srcpath> [input_args] [version]"
    echo
    echo "Example:"
    echo "   $0 https://github.com/xxxserxxx/gotop ./cmd/gotop \"linux/amd64\""
    echo "or to build head entirely locally"
    echo "   # cd to project"
    echo "   git daemon --port=8880 --verbose --export-all --reuseaddr --base-path=."
    echo "   # and then here, run"
    echo "   $0 git://localhost:8880/gotop ./cmd/gotop darwin/arm64/1 refs/remotes/origin/master"
    exit 1
fi

export REPO=$1
export SRCPATH=$2

if [[ $# -lt 3 ]]; then
  export INPUT_ARGS="darwin/arm64/1 darwin/amd64/1 linux/amd64 linux/386 linux/arm64 linux/arm7 linux/arm6 linux/arm5 windows/amd64 windows/386 freebsd/amd64 freebsd/386"
else
  export INPUT_ARGS="$3"
fi

if [[ $# -eq 4 ]];then
    export GITHUB_REF=$4
fi

export COMPRESS_FILES=true

echo "################################################################################"
echo "Make container"
if [[ `podman images | grep builder` != "" ]]; then
    # Check that the builder image is up-to-date
    entr=`date -r entrypoint.sh`
    dock=`date -r Dockerfile`
    imag=`podman inspect builder | jq -r '.[0].Created'`

    imag_ts=`date -d "$imag" +%s`
    dock_ts=`date -d "$dock" +%s`
    entr_ts=`date -d "$entr" +%s`

    if [[ $imag_ts -lt $entr_ts || $imag_ts -lt $dock_ts ]]
    then
        podman rmi builder
    fi
fi
if [[ `podman images | grep builder` == "" ]]; then
    podman build -t builder .
    [[ $? -ne 0 ]] && exit 1
fi

rm -rf work
mkdir work
export WORKDIR=`pwd`/work

echo "################################################################################"
echo "Checkout"
export PROJECT=${REPO##*/}
export GITHUB_REPOSITORY=$PROJECT/$PROJECT
mkdir -p $WORKDIR/$PROJECT/$PROJECT
pushd $WORKDIR/$PROJECT/$PROJECT
git init 
git remote add origin $REPO
git config --local gc.auto 0
git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
git submodule foreach --recursive git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader && git config --local --unset-all http.https://github.com/.extraheader || :
git -c protocol.version=2 fetch --tags --prune --progress --no-recurse-submodules --depth=1 origin
[[ -z $GITHUB_REF ]] && export GITHUB_REF=$(git show-ref | tail -1 | cut -d ' ' -f 2)
git checkout --progress --force $GITHUB_REF
popd

echo "################################################################################"
echo "BUILD"
export GITHUB_WORKSPACE=/github/workspace
/usr/bin/podman run \
   --name build_$$ \
   --workdir /github/workspace \
   --rm \
   -e COMPRESS_FILES \
   -e INPUT_ARGS \
   -e GITHUB_REF \
   -e GITHUB_REPOSITORY \
   -e GITHUB_WORKSPACE \
   -e SRCPATH \
   -v "$WORKDIR/$PROJECT/$PROJECT":"$GITHUB_WORKSPACE" \
   builder \
   "$INPUT_ARGS"

echo To update the image or entrypoint.sh file, you must remove the builder image:
echo
echo podman rmi builder
