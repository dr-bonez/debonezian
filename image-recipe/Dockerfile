ARG SUITE=trixie

FROM debian:${SUITE}

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -yq \
    live-build \
    procps \
    systemd \
    binfmt-support \
    qemu-utils \
    qemu-user-static \
    qemu-system-x86 \
    qemu-system-aarch64 \
    qemu-system-riscv64 \
    xorriso \
    isolinux \
    ca-certificates \
    curl \
    gpg \
    fdisk \
    dosfstools \
    e2fsprogs \
    squashfs-tools \
    rsync \
    b3sum

WORKDIR /root