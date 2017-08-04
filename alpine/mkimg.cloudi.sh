
profile_cloudi() {
	profile_standard
	title="CloudI LiveCD"
	desc="CloudI AlpineLinux LiveCD"
	hostname="cloudi"
	rootfs_size="335544320" # 256MB + 64MB
	kernel_cmdline="nomodeset console=tty0 console=ttyS0,19200 rootflags=\"size=$rootfs_size\""
	syslinux_serial="0 19200"
	kernel_addons=""
	apks="$apks cloudi"
	apkovl="genapkovl-cloudi.sh"
}

