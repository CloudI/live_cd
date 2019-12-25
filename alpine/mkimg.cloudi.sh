
profile_cloudi() {
	profile_standard
	title="CloudI LiveCD"
	desc="CloudI AlpineLinux LiveCD"
	hostname="cloudi"
	rootfs_size="765460480" # 329.2 MB (used) + 400.8 MB (free) = 730 MB
	kernel_cmdline="nomodeset console=tty0 console=ttyS0,19200 rootflags=size=$rootfs_size"
	initfs_cmdline="modules=loop,squashfs,sd-mod,usb-storage"
	syslinux_serial="0 19200"
	kernel_addons=""
	# debug information
	#kernel_cmdline="$kernel_cmdline debug"
	#initfs_cmdline="$initfs_cmdline debug_init=yes"
	apkovl="genapkovl-cloudi.sh"
	apks="$apks cloudi"
	# add programming languages supported on all architecturs
	apks="$apks go nodejs openjdk8 perl php7 python3 ruby"
	# add programming languages supported on some architectures
	case "$ARCH" in
	x86_64)
		apks="$apks ghc cabal"
		apks="$apks ocaml"
		;;
	x86)
		;;
	*)
		exit 1
		;;
	esac
}

