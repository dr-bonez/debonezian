#!/bin/bash
set -e

cd "$(dirname "${BASH_SOURCE[0]}")"/..

PLATFORM="${PLATFORM:-$1}"
if [ -z "$PLATFORM" ]; then
    PLATFORM="$(uname -m)"
fi
if [ "$PLATFORM" = "x86_64" ] || [ "$PLATFORM" = "x86_64-nonfree" ]; then
	ARCH=amd64
	QEMU_ARCH=x86_64
elif [ "$PLATFORM" = "aarch64" ] || [ "$PLATFORM" = "aarch64-nonfree" ] || [ "$PLATFORM" = "raspberrypi" ]  || [ "$PLATFORM" = "rockchip64" ]; then
	ARCH=arm64
	QEMU_ARCH=aarch64
else
	ARCH="$PLATFORM"
	QEMU_ARCH="$PLATFORM"
fi

SUITE=trixie

USE_TTY=
if tty -s; then
  USE_TTY="-it"
fi

if [ -z "$(docker images -q "debonezian_build:${SUITE}")" ]; then
	docker build -t "debonezian_build:${SUITE}" ./image-recipe
fi

docker run $USE_TTY --rm --privileged -v "$(pwd)/image-recipe:/root/image-recipe" -v "$(pwd)/results:/root/results" \
	-e IB_TARGET_PLATFORM="$PLATFORM" -e IB_TARGET_ARCH="$ARCH" -e IB_SUITE="$SUITE" -e IB_UID="$UID" -e IB_INCLUDE \
	"debonezian_build:${SUITE}" /root/image-recipe/build.sh