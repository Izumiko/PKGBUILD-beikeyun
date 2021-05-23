#!/bin/sh

if [ -e /.need_resize ]; then 
echo "d
n
p
1
32768
-0
w" | fdisk /dev/mmcblk0 && resize2fs /dev/mmcblk0p1 && echo "resize done, please reboot" || echo "resize failed!"
	rm -f /.need_resize
/usr/bin/pacman-key --init && /usr/bin/pacman-key --populate archlinuxarm
fi
