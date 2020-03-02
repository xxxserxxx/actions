#!/bin/bash
#
# $0 "gotop%20-V=$VERSION ls%20-1%20|%20wc%20-l=9"

export VERSION=${GITHUB_REF##*/}

export _tests=${@-""}

./update.sh $VERSION
