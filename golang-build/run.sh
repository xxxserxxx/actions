#!/bin/sh
#
# USAGE: $0 REPO SRCPATH INPUT_ARGS

if [[ $# -lt 3 ]]; then
    echo "USAGE: $0 <repo> <srcpath> <input_args>"
    echo
    echo "Example:"
    echo "   $0 https://github.com/xxxserxxx/gotop ./cmd/gotop \"linux/amd64\""
    exit 1
fi

export REPO=$1
export SRCPATH=$2
export INPUT_ARGS=$3
export COMPRESS_FILES=true

echo "################################################################################"
echo "Make container"
if [[ `docker images | grep builder` == "" ]]; then 
    docker build -t builder .
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
git -c protocol.version=2 fetch --no-tags --prune --progress --no-recurse-submodules --depth=1 origin
export GITHUB_REF=$(git show-ref | tail -1 | cut -d ' ' -f 2)
git checkout --progress --force $GITHUB_REF
popd

echo "################################################################################"
echo "BUILD"
export GITHUB_WORKSPACE=/github/workspace
/usr/bin/docker run \
   --name build_$$ \
   --workdir /github/workspace \
   --rm \
   -e COMPRESS_FILES \
   -e INPUT_ARGS \
   -e GITHUB_REF \
   -e GITHUB_REPOSITORY \
   -e GITHUB_WORKSPACE \
   -e SRCPATH \
   -v "$WORKDIR/$PROJECT/$PROJECT":"/github/workspace" \
   builder \
   $INPUT_ARGS

echo To update the docker or entrypoint.sh file, you must remove the builder image:
echo
echo docker rmi builder
