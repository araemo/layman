# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit git-r3 mount-boot

DESCRIPTION="Raspberry PI boot loader and firmware"
HOMEPAGE="https://github.com/raspberrypi/firmware"
SRC_URI=""

LICENSE="GPL-2 raspberrypi-videocore-bin"
SLOT="0"
KEYWORDS="arm -*"
IUSE="+rpi1 +rpi2"

DEPEND=""
RDEPEND=""

EGIT_REPO_URI="https://github.com/raspberrypi/firmware"
EGIT_CLONE_TYPE="shallow" # The current repo is ~4GB in size, but contains only
						  # ~200MB of data - the rest is (literally) history :(

RESTRICT="binchecks strip"
#QA_PREBUILT=""


pkg_setup() {
	local state boot="${RASPBERRYPI_BOOT:-/boot}"

	einfo "Checking mount-points ..."

	[[ "${boot}" == "${boot// }" ]] || die "Invalid value '${boot}' for control variable 'RASPBERRYPI_BOOT'"

	if [[ -z "${RASPBERRYPI_BOOT:-}" ]]; then
		ewarn "This ebuild assumes that your FAT32 firmware/boot partition is"
		ewarn "mounted on '${boot}'."
		ewarn
		ewarn "If this is not the case, please cancel this install *NOW* and"
		ewarn "re-install having set the RASPBERRYPI_BOOT environment variable"
		ewarn "in /etc/portage/make.conf"
		sleep 5
	else
		einfo "Using '${boot}' as boot-partition mount-point"
	fi

	if [[ "${MERGE_TYPE}" != "buildonly" ]]; then
		if ! [[ -d "${boot}" ]]; then
			eerror "Directory '${boot}' does not exist"
			eerror
			die "Please set the RASPBERRYPI_BOOT environment variable in /etc/portage/make.conf"
		fi

		#state="$( cut -d' ' -f 2-4 /proc/mounts 2>/dev/null | grep -E "^${boot} (u?msdos|v?fat) " | grep -Eo '[ ,]r[ow](,|$)' | sed 's/[ ,]//g' )"
		#case "${state}" in
		#	rw)
		#		:
		#		;;
		#	ro)
		#		die "Filesystem '${boot}' is currently mounted read-only - installation cannot proceed"
		#		;;
		#	*)
		#		die "Cannot determine mount-state of boot filesystem '${boot}' - is this partition mounted?"
		#		;;
		#esac
	fi
}

src_install() {
	local f boot="${RASPBERRYPI_BOOT:-/boot}" ver

	dodir "${boot}"
	dodir "${boot}"/kernel
	dodir "${boot}"/overlays
	dodir /lib/modules

	# Install firmware ...
	insinto "${boot}"
	for f in boot/*.dtb boot/*.bin boot/*.dat boot/*.elf; do
		[[ -e "${f}" ]] && doins "${f}"
	done

	# Install kernel(s) ...
	insinto "${boot}"/kernel
	for f in boot/*.img; do
		case "${f}" in
			boot/kernel.img)
				use rpi1 && doins "${f}" ;;
			boot/kernel7.img)
				use rpi2 && doins "${f}" ;;
			*)
				[[ -e "${f}" ]] && doins "${f}" ;;
		esac
	done

	# Install Device Tree overlays ...
	insinto "${boot}"/overlays
	doins boot/overlays/*.dtb

	newdoc boot/overlays/README device-tree-overlays.txt

	# Install kernel modules ...
	insinto /lib/modules
	for f in modules/*; do
		case "${f}" in
			*-v7+)
				[[ -z "${ver}" ]] && ver="$( basename "${f}" | sed 's/-v7+$//' )"
				use rpi2 && doins -r "${f}" ;;
			*-v[0-9]*+)
				# For future architectures ...
				[[ -z "${ver}" ]] && ver="$( basename "${f}" | sed 's/-v[0-9]\++$//' )"
				doins -r "${f}" ;;
			*+)
				[[ -z "${ver}" ]] && ver="$( basename "${f}" | sed 's/+$//' )"
				use rpi1 && doins -r "${f}" ;;
			*)
				if [[ -e "${f}" ]]; then
					[[ -z "${ver}" ]] && ver="$( basename "${f}" )"
					doins -r "${f}"
				fi
				;;
		esac
	done

	insinto /boot
	newins "${FILESDIR}"/${PN}-config.txt config.txt
	#newins "${FILESDIR}"/${PN}-cmdline.txt cmdline.txt

	# There's little or no standardisation in regards to where System.map
	# should live, and the only two common locations seem to be /boot and /
	if [[ -n "${ver}" ]]; then
		use rpi2 && newins extra/System7.map "System.map-${ver}-v7+"
		use rpi1 && newins extra/System.map "System.map-${ver}+"
		einfo "You should create a symlink from /System.map to /boot/System.map"
		einfo "and from /boot/System.map to System.map-${ver}+ or System.map-${ver}-v7+,"
		einfo "as appropriate."
	fi

	newenvd "${FILESDIR}"/${PN}-envd 90${PN}
}

pkg_preinst() {
	if [[ "${MERGE_TYPE}" != "buildonly" ]]; then
		if [[ -z "${REPLACING_VERSIONS}" ]]; then
			local msg=""
			#if [[ -e "${D}"/boot/cmdline.txt -a -e /boot/cmdline.txt ]] ; then
			#	msg+="/boot/cmdline.txt "
			#fi
			if [ [-e "${D}"/boot/config.txt -a -e /boot/config.txt ]] ; then
				msg+="/boot/config.txt "
			fi
			if [ -n "${msg}" ] ; then
				msg="This package installs following files: ${msg}"
				msg="${msg} Please backup and remove your local verions prior to installation"
				msg="${msg} and merge your changes afterwards."
				msg="${msg} Further updates will be CONFIG_PROTECTed."
				die "${msg}"
			fi
		fi
	fi

	mount-boot_pkg_preinst
}

pkg_postinst() {
	mount-boot_pkg_postinst

	einfo "Please customise your Raspberry Pi configuration by editing /boot/config.txt"
}