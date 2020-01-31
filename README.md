# PKGBUILD-beikeyun

## PKGBUILD scripts for archlinuxarm of beikeyun P1

### Build instruction:

0. Install base-devel: 
```shell
# pacman -S base-devel
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