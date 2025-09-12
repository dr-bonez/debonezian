#!/bin/bash

function handle_error() {
  # Get information about the error
  local error_code=$?
  local error_line=$BASH_LINENO
  local error_command=$BASH_COMMAND

  # Log the error details
  echo "Error occurred on line $error_line: $error_command (exit code: $error_code)"

  if [ -f ./chroot/debootstrap/debootstrap.log ]; then
  	cat ./chroot/debootstrap/debootstrap.log;
  fi

  exit $error_code
}

trap handle_error ERR

echo "==== Debonezian Image Build ===="

echo "Building for architecture: $IB_TARGET_ARCH"

base_dir="/root"
prep_results_dir="$base_dir/images-prep"
RESULTS_DIR="$base_dir/results"
echo "Saving results in: $RESULTS_DIR"

IMAGE_BASENAME=debonezian_${IB_TARGET_PLATFORM}

QEMU_ARCH=${IB_TARGET_ARCH}
BOOTLOADERS=grub-efi,syslinux
if [ "$QEMU_ARCH" = 'amd64' ]; then
	QEMU_ARCH=x86_64
elif [ "$QEMU_ARCH" = 'arm64' ]; then
	QEMU_ARCH=aarch64
	BOOTLOADERS=grub-efi
fi

mkdir -p $prep_results_dir

cd $prep_results_dir

NON_FREE=
if [[ "${IB_TARGET_PLATFORM}" =~ -nonfree$ ]] || [ "${IB_TARGET_PLATFORM}" = "raspberrypi" ]; then
	NON_FREE=1
fi
IMAGE_TYPE=iso

ARCHIVE_AREAS="main contrib"
if [ "$NON_FREE" = 1 ]; then
	if [ "$IB_SUITE" = "bullseye" ]; then
		ARCHIVE_AREAS="$ARCHIVE_AREAS non-free"
	else
		ARCHIVE_AREAS="$ARCHIVE_AREAS non-free-firmware"
	fi
fi

cat > /etc/wgetrc << EOF
retry_connrefused = on
tries = 100
EOF
lb config \
	--iso-application "debonezian ${IB_TARGET_ARCH}" \
	--iso-volume "debonezian ${IB_TARGET_ARCH}" \
	--iso-preparer "DR-BONEZ; HTTPS://DRBONEZ.DEV" \
	--iso-publisher "DR-BONEZ; HTTPS://DRBONEZ.DEV" \
	--backports true \
	--bootappend-live "boot=live noautologin" \
	--bootloaders $BOOTLOADERS \
	--mirror-bootstrap "https://deb.debian.org/debian/" \
	--mirror-chroot "https://deb.debian.org/debian/" \
	--mirror-chroot-security "https://security.debian.org/debian-security" \
	-d ${IB_SUITE} \
	-a ${IB_TARGET_ARCH} \
	--bootstrap-qemu-arch ${IB_TARGET_ARCH} \
	--bootstrap-qemu-static /usr/bin/qemu-${QEMU_ARCH}-static \
	--archive-areas "${ARCHIVE_AREAS}" \
	${PLATFORM_CONFIG_EXTRAS[@]}

# Overlays

mkdir -p config/includes.chroot/etc
echo debonezian > config/includes.chroot/etc/hostname
cat > config/includes.chroot/etc/hosts << EOT
127.0.0.1       localhost debonezian
::1             localhost debonezian ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOT

# Bootloaders

rm -rf config/bootloaders
cp -r /usr/share/live/build/bootloaders config/bootloaders

cat > config/bootloaders/syslinux/syslinux.cfg << EOF
include menu.cfg
default vesamenu.c32
prompt 0
timeout 50
EOF

cat > config/bootloaders/isolinux/isolinux.cfg << EOF
include menu.cfg
default vesamenu.c32
prompt 0
timeout 50
EOF

#rm config/bootloaders/syslinux_common/splash.svg
#cp $base_dir/splash.png config/bootloaders/syslinux_common/splash.png
#cp $base_dir/splash.png config/bootloaders/isolinux/splash.png
#cp $base_dir/splash.png config/bootloaders/grub-pc/splash.png

sed -i -e '2i set timeout=5' config/bootloaders/grub-pc/config.cfg

# Archives

mkdir -p config/archives

# Dependencies

## Base dependencies
cat << EOF > config/package-lists/debonezian.list.chroot
$IB_INCLUDE b3sum bash-completion bmon btrfs-progs ca-certificates cryptsetup curl dnsutils dosfstools e2fsprogs ecryptfs-utils exfatprogs htop iotop iptables iw jq lm-sensors lshw lvm2 lxc magic-wormhole man-db ncdu net-tools network-manager nfs-common nvme-cli openssh-server psmisc qemu-user-static rsync smartmontools socat sqlite3 squashfs-tools squashfs-tools-ng sudo systemd systemd-resolved systemd-sysv systemd-timesyncd util-linux vim wireguard-tools wireless-tools
EOF

## Firmware
# if [ "$NON_FREE" = 1 ]; then
# 	 echo 'firmware-misc-nonfree' > config/package-lists/nonfree.list.chroot
# fi
echo 'grub-efi grub2-common' > config/package-lists/bootloader.list.chroot
if [ "${IB_TARGET_ARCH}" = "amd64" ] || [ "${IB_TARGET_ARCH}" = "i386" ]; then
	echo 'grub-pc-bin' >> config/package-lists/bootloader.list.chroot
fi

if [ "${IB_TARGET_ARCH}" = "riscv64" ]; then
	tee 0500-compress-vmlinux.hook.binary > config/hooks/normal/0500-compress-vmlinux.hook.chroot <<- 'EOF'
	#!/bin/bash
	
	set -e
	
	LINUX_VERSION="6.12.33+deb13-riscv64"
	
	cat "/boot/vmlinux-$LINUX_VERSION" | gzip > "/boot/vmlinuz-$LINUX_VERSION"
	
	if [ ! -f "/boot/vmlinuz-$LINUX_VERSION" ]; then
	    echo "Error: vmlinuz creation failed" >&2
	    exit 1
	fi
	EOF
fi

cat > config/hooks/normal/9000-setup.hook.chroot << EOF
#!/bin/bash

set -e

useradd --shell /bin/bash -m drbonez
echo drbonez:drbonez | chpasswd
usermod -aG sudo drbonez

echo "#" > /etc/network/interfaces
cat << EOF2 > /etc/NetworkManager/NetworkManager.conf
[main]
plugins=ifupdown,keyfile
dns=systemd-resolved

[ifupdown]
managed=true
EOF2

systemctl enable systemd-resolved.service
systemctl enable ssh.service
systemctl disable wpa_supplicant.service
systemctl mask systemd-networkd-wait-online.service # currently use NetworkManager-wait-online.service

EOF

SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(date '+%s')}"

lb build

mkdir -p "$RESULTS_DIR/$IB_TARGET_PLATFORM"
cp *.iso "$RESULTS_DIR/$IB_TARGET_PLATFORM"