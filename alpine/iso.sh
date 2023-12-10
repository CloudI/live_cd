#!/bin/sh -e

ARCH="$1"
PROFILE="$2"
if [ -z "$ARCH" -o -z "$PROFILE" ]; then
    echo "usage: $0 x86|x86_64 profile"
    exit 1
fi

TAG="v3.19"
#TAG="edge"

URL="http://dl-cdn.alpinelinux.org/alpine/${TAG}"

sh ~/aports/scripts/mkimage.sh --outdir ~/iso --repository "${URL}/main" --repository "${URL}/community" --tag "${TAG}" --arch "${ARCH}" --profile "${PROFILE}"

