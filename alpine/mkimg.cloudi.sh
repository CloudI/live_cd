
profile_cloudi() {
	profile_standard
	title="CloudI LiveCD"
	desc="CloudI AlpineLinux LiveCD"
	hostname="cloudi"
	rootfs_size="765460480" # 382 MB (used) + 348 MB (free) = 730 MB
	kernel_cmdline="nomodeset console=tty0 console=ttyS0,19200 rootflags=\"size=$rootfs_size\""
	syslinux_serial="0 19200"
	kernel_addons=""
	apkovl="genapkovl-cloudi.sh"
	apks="$apks cloudi"
	# add programming languages supported on all architecturs
	apks="$apks go nodejs openjdk8 perl php7 python3 ruby"
	# add programming languages supported on some architectures
	case "$ARCH" in
	x86_64 | armhf)
		apks="$apks ghc cabal"
		;;
	esac
	case "$ARCH" in
	x86 | armhf | s390x)
		;;
	*)
		apks="$apks ocaml"
		;;
	esac
}

