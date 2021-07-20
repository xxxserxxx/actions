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
targets=${@-"darwin/amd64 darwin/arm64 linux/amd64 linux/386 linux/arm64 linux/arm7 linux/arm6 linux/arm5 windows/amd64 windows/386 freebsd/amd64 freebsd/386"}

pushd $GITHUB_WORKSPACE
export VERSION=${GITHUB_REF##*/}
[[ -z $VERSION ]] && VERSION=$(git describe --tags)
popd

echo "----> Setting up Go repository"
mkdir -p $release_path
mkdir -p $root_path
cp -a $GITHUB_WORKSPACE/* $root_path/
cd $root_path

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
  local CC=gcc
  local CXX=g++
  export CGO_ENABLED CC CXX
  case $GOOS in
    "darwin")
        local MACOSX_DEPLOYMENT_TARGET=10.10.0
        export MACOSX_DEPLOYMENT_TARGET
        if [[ $GOARCH == "arm64" ]]; then
          CC=arm64-apple-darwin20-cc
          CXX=arm64-apple-darwin20-c++
        else
          CC=o64-clang 
          CXX=o64-clang++ 
        fi
      ;;
    "windows")
        if [[ $GOARCH == "386" ]]; then
          CC=i686-w64-mingw32-gcc
          CXX=i686-w64-mingw32-g++
        else
          CC=x86_64-w64-mingw32-gcc 
          CXX=x86_64-w64-mingw32-g++ 
        fi
      ;;
    "linux")
      case $GOARCH in
        "arm")
          CC=arm-linux-gnueabihf-gcc
          CXX=arm-linux-gnueabihf-g++
          ;;
        "arm64")
          CC=aarch64-linux-gnu-gcc
          CXX=aarch64-linux-gnu-g++
          ;;
        "mips64el")
          CC=mips64el-linux-gnuabi64-gcc
          CXX=mips64el-linux-gnuabi64-g++
          ;;
        *)
          CC=gcc
          CXX=g++
          ;;
      esac
      ;;
    "freebsd")
      CC=x86_64-pc-freebsd9-gcc
      CXX=x86_64-pc-freebsd9-g++
      ;;
    *)
      echo "UNKNOWN OS $GOOS"
      exit 1
      ;;
  esac
  if [[ $GOOS == "linux" && $GOARCH == "amd64" ]]; then
    local pie="--buildmode=pie"
  fi
  local asset="${repo_name}_${VERSION}_${GOOS}_${archo}"
  local output="${release_path}/${asset}"

  echo -n "----> Building project for: $GOOS / $GOARCH"
  [[ -n $PIE ]] && echo -n " PIE"
  [[ $CGO_ENABLED -eq 1 ]] && echo -n " CGO"
  echo ""
  BUILDDATE=`date +%Y%m%dT%H%M%S`
  echo "----> ENVIRONMENT"
  go build -ldflags="-X main.Version=${VERSION} -X main.BuildDate=${BUILDDATE} -s -w" $pie -o $output $SRCPATH

  # upx will figure out whether it can compress the executable or not. We don't care if it works or not;
  # it's a nice-to-have
  upx -qqq $output

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
