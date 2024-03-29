
profile_cloudi() {
	profile_standard
	title="CloudI LiveCD"
	desc="CloudI AlpineLinux LiveCD"
	hostname="cloudi"
	rootfs_size="2147483648" # 598.5 MB (used) + 1449.5 MB (free) = 2048 MB
	kernel_cmdline="nomodeset console=tty0 console=ttyS0,19200 rootflags=size=$rootfs_size"
	syslinux_serial="0 19200"
	kernel_addons=""
	initfs_cmdline="modules=loop,squashfs,sd-mod,usb-storage"
	apkovl="genapkovl-cloudi.sh"
	apks="$apks cloudi"
	# add programming languages supported on all architecturs
	case "$ARCH" in
	x86_64)
			apks="$apks openjdk17-jre"
			;;
	x86)
			;;
	*)
			exit 1
			;;
	esac
	apks="$apks go nodejs ocaml perl php python3 ruby"
	# debug information
	#kernel_cmdline="$kernel_cmdline debug"
	#initfs_cmdline="$initfs_cmdline debug_init=yes" # output?
	# normal information
	initfs_cmdline="$initfs_cmdline quiet"
}

