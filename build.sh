#!/bin/bash

cd `dirname $0`
chown -R alarm:alarm linux-aarch64-beikeyun-p1 linux-firmware-armbian linux-uboot-beikeyun-p1

echo "Building Linux image...  "
cd linux-aarch64-beikeyun-p1
runuser -u alarm updpkgsums
runuser -u alarm -- makepkg -Ccf
mv *.tar.xz ../
cd ..
echo -e "done.\n\n"

echo "Building Linux Firmware...  "
cd linux-firmware-armbian
runuser -u alarm -- makepkg -Ccf
mv *.tar.xz ../
cd ..
echo -e "done.\n\n"

echo "Building U-Boot...  "
cd linux-uboot-beikeyun-p1
runuser -u alarm -- makepkg -Ccf
mv *.tar.xz ../
cd ..
echo -e "done.\n\n"
