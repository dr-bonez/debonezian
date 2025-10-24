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

dockerfile_hash=$(sha256sum image-recipe/Dockerfile | head -c 7)

docker_img_name="debonezian_build:${SUITE}-${dockerfile_hash}"

if [ -z "$(docker images -q "${docker_img_name}")" ]; then
	docker build --build-arg=SUITE=${SUITE} -t "${docker_img_name}" ./image-recipe
fi

docker run $USE_TTY --rm --privileged -v "$(pwd)/image-recipe:/root/image-recipe" -v "$(pwd)/results:/root/results" \
	-e IB_TARGET_PLATFORM="$PLATFORM" -e IB_TARGET_ARCH="$ARCH" -e IB_SUITE="$SUITE" -e IB_UID="$UID" -e IB_INCLUDE -e IB_LINUX_VERSION="6.16.3+deb13" \
	"${docker_img_name}" /root/image-recipe/build.sh