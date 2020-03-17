#!/bin/bash

# FIXME: allow building plugins

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

function compile() {
  local target=$1
  local GOOS="$(echo $target | cut -d '/' -f1)"
  local GOARCH="$(echo $target | cut -d '/' -f2)"
  export GOOS GOARCH
  local pie=""
  local archo=$GOARCH
  local cgo="$(echo $target | cut -d '/' -f3)"
  if [[ $GOARCH == arm[567] ]]; then
    local GOARM=$(echo $GOARCH | tr -d '[:alpha:]')
    local GOARCH=arm
	export GOARM GOARCH
  fi
  if [[ $cgo == "" ]]; then
    local CGO_ENABLED=0
  else
    local CGO_ENABLED=1
  fi
  export CGO_ENABLED
  if [[ $GOOS == "darwin" ]]; then
    local MACOSX_DEPLOYMENT_TARGET=10.10.0 
    local CC=o64-clang 
    local CXX=o64-clang++ 
	export MACOSX_DEPLOYMENT_TARGET CC CXX
  fi
  if [[ $GOOS == "linux" && $GOARCH == "amd64" ]]; then
    local pie="--buildmode=pie"
  fi
  local asset="${repo_name}_${VERSION}_${GOOS}_${archo}"
  local output="${release_path}/${asset}"

  echo "----> Building project for: $target"
  go build $pie -o $output $SRCPATH

  if [[ -n "$COMPRESS_FILES" ]]; then
    if [[ -n "$SRCPATH" ]]; then 
      local exe="${release_path}/$(basename $SRCPATH)"
    else
      local exe="${release_path}/${repo_name}"
    fi
    mv "$output" "${exe}"
    if [[ $GOOS == "windows" ]]; then
      mv "${exe}" "${exe}.exe"
      exe="${exe}.exe"
      zip -j "$output.zip" "${exe}" > /dev/null
    else
      tar -czf "$output.tgz" -C "${release_path}" $(basename "${exe}")
    fi
    rm $exe
  fi
}

for target in $targets; do
  compile $target
done

echo "----> Build is complete. List of files in ${release_path}/:"
cd $release_path
ls -al
