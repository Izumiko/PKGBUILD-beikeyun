# PKGBUILD-beikeyun

## PKGBUILD scripts for archlinuxarm of beikeyun P1

Linux is Rock64's edge version from Armbian.   

DTB file is from flippy.   
Related publishing pages:   
https://www.right.com.cn/forum/thread-4076037-1-1.html

current version is extracted from `dtb-rockchip-5.19.8-flippy-76+.tar.gz`

### Build instruction:

0. Install base-devel: 
```shell
# pacman -S base-devel pacman-contrib
```

1. Build package:
```shell
# su alarm
$ cd <package directory>
$ updpkgsums
$ makepkg -Cf
```

2. Install package:
```shell
# pacman -U <package name>.pkg.tar.xz
```

### Update instruction:

Run step 1 above again, and you will get lastest packages.
