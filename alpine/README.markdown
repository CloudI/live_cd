[Alpine Linux](https://alpinelinux.org/) CloudI LiveCD
======================================================

DIRECTIONS
----------

Setup the Alpine Linux [installation](https://www.alpinelinux.org/downloads/) (based on [custom ISO wiki page](https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage), as `root`):
0. `apk update`
1. `apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot syslinux xorriso`
   (if UEFI, add "`mtools dosfstools grub-efi`")
2. `adduser build -G abuild`
3. `passwd build`
4. `addgroup sudo` (modify `/etc/sudoers` to allow sudo group)
5. `adduser build sudo`
6. `su build`
7. `cd ~`
8. `abuild-keygen -i -a`
9. `git clone git://git.alpinelinux.org/aports`
10. `mkdir ~/iso`
11. `./iso.sh x86_64 cloudi` (or) `./iso.sh x86 cloudi`
   (the images are put into the `~/iso` directory)

