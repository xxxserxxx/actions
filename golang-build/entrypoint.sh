#!/bin/bash

set -e

if [[ -z "$GITHUB_WORKSPACE" ]]; then
  echo "Set the GITHUB_WORKSPACE env variable."
  exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
  echo "Set the GITHUB_REPOSITORY env variable."
  exit 1
fi

root_path="/go/src/github.com/$GITHUB_REPOSITORY"
release_path="$GITHUB_WORKSPACE/.release"
repo_name="$(echo $GITHUB_REPOSITORY | cut -d '/' -f2)"
targets=${@-"darwin/amd64 darwin/386 linux/amd64 linux/386 linux/arm64 linux/arm7 linux/arm6 linux/arm5 windows/amd64 windows/386 freebsd/amd64 freebsd/386"}

echo "----> Setting up Go repository"
mkdir -p $release_path
mkdir -p $root_path
cp -a $GITHUB_WORKSPACE/* $root_path/
cd $root_path

export VERSION=${GITHUB_REF##*/}

for target in $targets; do
  export GOOS="$(echo $target | cut -d '/' -f1)"
  export GOARCH="$(echo $target | cut -d '/' -f2)"
  pie=""
  archo=$GOARCH
  cgo="$(echo $target | cut -d '/' -f3)"
  if [[ $GOARCH == arm[567] ]]; then
    export GOARM=$(echo $GOARCH | tr -d '[:alpha:]')
    export GOARCH=arm
  fi
  if [[ $cgo == "" ]]; then
    export CGO_ENABLED=0
  else
    export CGO_ENABLED=1
  fi
  if [[ $GOOS == "darwin" ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.10.0 
    export CC=o64-clang 
    export CXX=o64-clang++ 
  fi
  if [[ $GOOS == "linux" ]]; then
    export pie="--buildmode=pie"
  fi
  asset="${repo_name}_${VERSION}_${GOOS}_${archo}"
  output="${release_path}/${asset}"

  echo "----> Building project for: $target"
  go build $pie -o $output $SRCPATH

  if [[ -n "$COMPRESS_FILES" ]]; then
    if [[ $GOOS == "windows" ]]; then
      zip -j $output.zip $output > /dev/null
    else
      tar -czf $output.tgz -C "${release_path}" "${asset}"
    fi
    rm $output
  fi
  unset GOOS GOARCH GOARM CGO_ENABLED
done

echo "----> Build is complete. List of files in ${release_path}/:"
cd $release_path
ls -al
