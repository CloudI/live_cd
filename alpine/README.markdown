[Alpine Linux](https://alpinelinux.org/) CloudI LiveCD
======================================================

DIRECTIONS
----------

Setup the Alpine Linux [installation](https://www.alpinelinux.org/downloads/) (based on [custom ISO wiki page](https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage), as `root`):

0. `apk update`
1. `apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot syslinux xorriso squashfs-tools mtools dosfstools grub-efi`
2. `adduser build -G abuild`
3. `passwd build`
4. `echo "permit nopass build" > /etc/doas.d/build.conf`
5. `su build`
6. `cd ~`
7. `abuild-keygen -i -a`
8. `git clone git://git.alpinelinux.org/aports`
9. `git clone https://github.com/CloudI/live_cd.git`
10. `cp live_cd/alpine/*.sh aports/scripts`
11. `mkdir iso`
12. `cd aports/scripts`
13. `./iso.sh x86_64 cloudi` (or) `./iso.sh x86 cloudi`
   (the images are put into the `~/iso` directory)

