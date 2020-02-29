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
targets=${@-"darwin/amd64 darwin/386 linux/amd64 linux/386 linux/arm64 linux/arm-7 linux/arm-6 linux/arm-5 windows/amd64 windows/386 freebsd/amd64 freebsd/386"}

echo "----> Setting up Go repository"
mkdir -p $release_path
mkdir -p $root_path
cp -a $GITHUB_WORKSPACE/* $root_path/
cd $root_path

export VERSION=`git tag -l --points-at HEAD`
if [[ `echo $VERSION | wc -l` -ne 1 ]]; then
  echo "No (unique) build tag. Using commit."
  VERSION=v0.0.0
  VERSION=${VERSION}-`git show -s --format=%cI HEAD | cut -b -19 |  tr -cd '[:digit:]'`
  VERSION=${VERSION}-`git rev-parse HEAD | cut -b -12`
fi

for target in $targets; do
  os="$(echo $target | cut -d '/' -f1)"
  arch="$(echo $target | cut -d '/' -f2 | cut -d '-' -f1)"
  archo="$arch"
  arm="$(echo $target | cut -d '-' -f2)"
  if [[ $arm == "" ]]; then
    ARM="GOARM=$arm"
    archo="${arch}${arm}"
  fi
  if [[ $os == "darwin" ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.10.0 
    export CC=o64-clang 
    export CXX=o64-clang++ 
  fi
  output="${release_path}/${repo_name}_${os}_${archo}"

  echo "----> Building project for: $target"
  GOOS=$os GOARCH=$arch CGO_ENABLED=1 go build -o $output

  if [[ -n "$COMPRESS_FILES" ]]; then
    if [[ $os == "windows" ]]; then
      zip -j $output.zip $output > /dev/null
    else
      tar -czf $output.tgz $output
    fi
    rm $output
  fi
done

echo "----> Build is complete. List of files at $release_path:"
cd $release_path
ls -al
