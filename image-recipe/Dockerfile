ARG SUITE=trixie

FROM debian:${SUITE}

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -yq \
    live-build \
    procps \
    binfmt-support \
    xorriso \
    isolinux \
    ca-certificates \
    curl \
    wget \
    gpg \
    fdisk \
    dosfstools \
    e2fsprogs \
    squashfs-tools \
    rsync \
    b3sum \
    dpkg-dev

RUN apt-get install -yq \
    ninja-build \
    libglib2.0-dev \
    libpixman-1-dev \
    python3-pip \
    python3-venv && \
    wget https://download.qemu.org/qemu-10.1.1.tar.xz && \
    unxz qemu-10.1.1.tar.xz && \
    tar -xf qemu-10.1.1.tar && \
    cd qemu-10.1.1 && \
    mkdir build && \
    cd build && \
    ../configure --target-list=x86_64-linux-user,aarch64-linux-user,riscv64-linux-user --prefix=/usr --static --enable-linux-user && \
    nice make -j && \
    make install && \
    update-binfmts --enable && \
    apt-get remove --purge -yq \
    ninja-build \
    libglib2.0-dev \
    libpixman-1-dev \
    python3-pip \
    python3-venv

COPY binary_grub-efi.patch /root/binary_grub-efi.patch
RUN patch /usr/lib/live/build/binary_grub-efi < /root/binary_grub-efi.patch && rm /root/binary_grub-efi.patch

RUN echo 'retry_connrefused = on' > /etc/wgetrc && \
    echo 'tries = 100' >> /etc/wgetrc

WORKDIR /root
