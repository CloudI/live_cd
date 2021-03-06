[Alpine Linux](https://alpinelinux.org/) CloudI LiveCD
======================================================

DIRECTIONS
----------

Setup the Alpine Linux [installation](https://www.alpinelinux.org/downloads/) (based on [custom ISO wiki page](https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage), as `root`):

0. `apk update`
1. `apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot syslinux xorriso squashfs-tools mtools dosfstools grub-efi sudo`
2. `adduser build -G abuild`
3. `passwd build`
4. `addgroup sudo` (modify `/etc/sudoers` to allow sudo group)
5. `adduser build sudo`
6. `su build`
7. `cd ~`
8. `abuild-keygen -i -a`
9. `git clone git://git.alpinelinux.org/aports`
10. `git clone https://github.com/CloudI/live_cd.git`
11. `cp live_cd/alpine/*.sh aports/scripts`
12. `mkdir iso`
13. `cd aports/scripts`
14. `./iso.sh x86_64 cloudi` (or) `./iso.sh x86 cloudi`
   (the images are put into the `~/iso` directory)

