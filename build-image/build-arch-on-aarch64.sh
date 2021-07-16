#!/bin/bash
# requirements: sudo jq sfdisk parted bsdtar

# run following command to init pacman keyring:
# pacman-key --init
# pacman-key --populate archlinuxarm

[ "$EUID" != "0" ] && echo "please run as root" && exit 1

rootfs_mount_point="./arch_rootfs"

tmpdir="tmp"
output="output"

origin="latest"
target="beikeyun-$(date +%Y-%m-%d)"

rootsize=1600
ROOTOFFSET=32768

func_generate() {
	local rootfs=$1
	local img_new=${2:-archlinux.img}
	mkdir -p ${output}

	[ ! -f "$rootfs" ] && echo "archlinux rootfs file not found!" && return 1

	# create ext4 rootfs img
	mkdir -p ${tmpdir}
	echo "create rootfs, size: ${rootsize}M"
	fallocate -l ${rootsize}M ${output}/${img_new}
	parted -s ${output}/${img_new} -- mktable gpt
	parted -s ${output}/${img_new} -- mkpart rootfs ext4 ${ROOTOFFSET}s -1
	devname=`losetup -P -f --show ${output}/${img_new}`
	mkfs.ext4 -q -m 2 ${devname}p1

	# mount rootfs
	mkdir -p $rootfs_mount_point
	mount -o loop ${devname}p1 $rootfs_mount_point

	# extract archlinux rootfs
	echo "extract archlinux rootfs($rootfs) to $rootfs_mount_point"
	bsdtar -xpf $rootfs -C $rootfs_mount_point

	# chroot to archlinux rootfs
	cp -r ${tmpdir}/pkgs $rootfs_mount_point/root/
	cp ./tools/archlinux/init.sh $rootfs_mount_point/init.sh
	echo "chroot to archlinux rootfs"
	mount -t proc /proc $rootfs_mount_point/proc/
	mount -o bind /sys $rootfs_mount_point/sys/
	mount -o bind /dev $rootfs_mount_point/dev/
	LANG=C LC_ALL=C chroot $rootfs_mount_point /init.sh

	rm -f $rootfs_mount_point/init.sh

	# add resize script
	echo "add resize mmc script"
	cp ./tools/archlinux/resizemmc.service $rootfs_mount_point/lib/systemd/system/
	cp ./tools/archlinux/resizemmc.sh $rootfs_mount_point/sbin/
	mkdir -p $rootfs_mount_point/etc/systemd/system/basic.target.wants
	ln -sf /lib/systemd/system/resizemmc.service $rootfs_mount_point/etc/systemd/system/basic.target.wants/resizemmc.service
	touch $rootfs_mount_point/.need_resize

	#prepare uboot files
	cp $rootfs_mount_point/boot/uboot.* ${tmpdir}/uboot.img
	cp $rootfs_mount_point/boot/trust.* ${tmpdir}/trust.img
	cp $rootfs_mount_point/boot/idbloader.* ${tmpdir}/idbloader.img
	cp $rootfs_mount_point/boot/u-boot.itb ${tmpdir}/

	# generate img
	umount -R $rootfs_mount_point
	echo "Generating release image"
	if [[ -f ${tmpdir}/u-boot.itb ]]; then
		dd if=${tmpdir}/idbloader.img of=${output}/${img_new} seek=64 conv=notrunc status=none > /dev/null 2>&1
		dd if=${tmpdir}/u-boot.itb of=${output}/${img_new} seek=16384 conv=notrunc status=none > /dev/null 2>&1
	else
		if [[ -f ${tmpdir}/uboot.img ]]; then
			dd if=${tmpdir}/idbloader.img of=${output}/${img_new} seek=64 conv=notrunc status=none > /dev/null 2>&1
			dd if=${tmpdir}/uboot.img of=${output}/${img_new} seek=16384 conv=notrunc status=none > /dev/null 2>&1
			dd if=${tmpdir}/trust.img of=${output}/${img_new} seek=24576 conv=notrunc status=none > /dev/null 2>&1
		else
			echo "Unsupported u-boot processing configuration!"
			exit 1
		fi
	fi
	sync
	losetup -d ${devname}
}

func_release() {
	local rootfs=$1
	local linuxpkg=$2
	local firmwarepkg=$3
	local ubootpkg=$4

	[ ! -f "$linuxpkg" ] && echo "Linux package not found!" && return 1
	[ ! -f "$firmwarepkg" ] && echo "Firmware package not found!" && return 1
	[ ! -f "$ubootpkg" ] && echo "U-Boot package not found!" && return 1
	
	rm -rf ${tmpdir}
	mkdir -p ${tmpdir}/pkgs
	cp $linuxpkg ${tmpdir}/pkgs/
	cp $firmwarepkg ${tmpdir}/pkgs/
	cp $ubootpkg ${tmpdir}/pkgs/

	echo "archlinux rootfs: $rootfs"
	echo "Linux package file: $linuxpkg"
	echo "Firmware package file: $firmwarepkg"
	echo "U-Boot package file: $ubootpkg"

	imgname_new="`basename $rootfs | sed "s/${origin}/${target}/" | sed 's/.tar.gz$/.img/'`"

	func_generate $rootfs $imgname_new
	echo "new image file: $imgname_new"

	xz -f -T0 -v ${output}/${imgname_new}
	#rm -rf ${tmpdir}
}

chmod 755 ./tools/archlinux/*.sh

case "$1" in
generate)
	func_generate "$2" "$3"
	;;
release)
	func_release "$2" "$3" "$4" "$5"
	;;
*)
	echo "Usage: $0 { generate [rootfs] [img_new] | release [rootfs] [linuxpkg] [firmwarepkg] [ubootpkg] }"
	exit 1
	;;
esac
