#!/bin/sh -e

ARCH="$1"
PROFILE="$2"
if [ -z "$ARCH" -o -z "$PROFILE" ]; then
    echo "usage: $0 x86|x86_64 profile"
    exit 1
fi

URL="http://dl-cdn.alpinelinux.org/alpine/edge"
#URL="http://nl.alpinelinux.org/alpine/edge"

sh ~/aports/scripts/mkimage.sh --outdir ~/iso --repository "${URL}/main" --extra-repository "${URL}/community" --extra-repository "${URL}/testing" --tag edge --arch "$ARCH" --profile "$PROFILE"

