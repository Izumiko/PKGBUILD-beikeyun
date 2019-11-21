#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/bin

source="https://apt.armbian.com/"
#source="https://mirrors.tuna.tsinghua.edu.cn/armbian/"
pkglist="${source}dists/buster/main/binary-arm64/Packages"

need_commit=0

vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return -1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 1
        fi
    done
    return 0
}

check_linux_image () {
debver=$(cat Packages |grep "Package: linux-image-legacy-rockchip64" -A 10|grep Filename|cut -f2 -d'_'|sort -r|head -n 1
)
debfile=$(cat Packages |grep "Package: linux-image-legacy-rockchip64" -A 10|grep ${debver}|cut -f2 -d' '|tail -n 1)
kerver=$(echo ${debfile}|cut -d' ' -f4|cut -d'-' -f2)
pkgver=$(grep _debver linux-aarch64-beikeyun-p1/PKGBUILD | cut -f2 -d'=' | head -n 1)

vercomp $pkgver $debver
if [ $? -gt 0 ]; then
  echo 'Linux kernel update available'
  sed \
    -e "s|_debver=.*|_debver=${debver}|" \
    -e "s|_kv=.*|_kv=${kerver}|" \
    -e "s|pkgrel=.*|pkgrel=1|" \
    -i "linux-aarch64-beikeyun-p1/PKGBUILD"
  pushd linux-aarch64-beikeyun-p1
  updpkgsums
  #makepkg -f
  popd
  need_commit=1
fi

}
check_uboot () {
debver=$(cat Packages |grep "Package: linux-u-boot-rock64-legacy" -A 10|grep Version|cut -f2 -d' '|sort -r|head -n 1)
pkgver=$(grep _debver linux-uboot-beikeyun-p1/PKGBUILD | cut -f2 -d'=' | head -n 1)

vercomp $pkgver $debver
if [ $? -gt 0 ]; then
  echo 'U-boot update available'
  sed \
    -e "s|_debver=.*|_debver=${debver}|" \
    -e "s|pkgrel=.*|pkgrel=1|" \
    -i "linux-uboot-beikeyun-p1/PKGBUILD"
  pushd linux-uboot-beikeyun-p1
  updpkgsums
  #makepkg -f
  popd
  need_commit=1
fi
}

check_firmware () {
debver=$(cat Packages |grep "Package: armbian-firmware" -A 10|grep Version|cut -f2 -d' '|sort -r|head -n 1)
pkgver=$(grep _debver linux-firmware-armbian/PKGBUILD | cut -f2 -d'=' | head -n 1)

vercomp $pkgver $debver
if [ $? -gt 0 ]; then
  echo 'Firmware update available'
  sed \
    -e "s|_debver=.*|_debver=${debver}|" \
    -e "s|pkgrel=.*|pkgrel=1|" \
    -i "linux-firmware-armbian/PKGBUILD"
  pushd linux-firmware-armbian
  updpkgsums
  #makepkg -f
  popd
  need_commit=1
fi
}

wget -O Packages $pkglist

check_linux_image
check_uboot
check_firmware

rm Packages

if [ $need_commit -eq 1 ]; then 
  git commit -am "Update."
  git push
fi
 
