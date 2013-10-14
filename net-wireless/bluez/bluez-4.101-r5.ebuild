# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/bluez/bluez-4.101-r5.ebuild,v 1.9 2013/06/30 15:27:08 jlec Exp $

EAPI=5
PYTHON_COMPAT=( python{2_6,2_7} )
inherit eutils multilib python-single-r1 systemd user

DESCRIPTION="Bluetooth Tools and System Daemons for Linux"
HOMEPAGE="http://www.bluez.org/"
SRC_URI="mirror://kernel/linux/bluetooth/${P}.tar.xz"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 arm hppa ppc ppc64 x86"
IUSE="alsa +consolekit cups debug gstreamer pcmcia readline selinux test-programs +udev usb"

REQUIRED_USE="test-programs? ( ${PYTHON_REQUIRED_USE} )"

CDEPEND=">=dev-libs/glib-2.28:2
	>=sys-apps/dbus-1.6:=
	>=sys-apps/hwids-20121202.2
	udev? ( >=virtual/udev-171 )
	alsa? (
		media-libs/alsa-lib:=[alsa_pcm_plugins_extplug(+),alsa_pcm_plugins_ioplug(+)]
		media-libs/libsndfile:=
	)
	cups? ( net-print/cups:= )
	gstreamer? (
		>=media-libs/gstreamer-0.10:0.10
		>=media-libs/gst-plugins-base-0.10:0.10
	)
	readline? ( sys-libs/readline:= )
	selinux? ( sec-policy/selinux-bluetooth )
	usb? ( virtual/libusb:0 )
"
DEPEND="${CDEPEND}
	sys-devel/flex
	virtual/pkgconfig
	test-programs? ( >=dev-libs/check-0.9.6 )
"
RDEPEND="${CDEPEND}
	consolekit? ( || ( sys-auth/consolekit sys-apps/systemd ) )
	test-programs? (
		>=dev-python/dbus-python-1
		dev-python/pygobject:2
		dev-python/pygobject:3
		${PYTHON_DEPS}
	)
"

DOCS=( AUTHORS ChangeLog README )

pkg_setup() {
	use consolekit || enewgroup plugdev
	use test-programs && python-single-r1_pkg_setup
}

src_prepare() {
	# Revert upstream change causing bug #431624, the problem was
	# reported to upstream but they didn't look into it. Could be solved
	# in bluez-5... stop the revert in that version to test then.
	epatch -R "${FILESDIR}"/${P}-mgmt-update.patch

	epatch "${FILESDIR}"/${P}-network{1,2,3,4}.patch

	# Use static group "plugdev" if there is no ConsoleKit (or systemd logind)
	use consolekit || epatch "${FILESDIR}"/bluez-plugdev.patch

	if use cups; then
		sed -i \
			-e "s:cupsdir = \$(libdir)/cups:cupsdir = `cups-config --serverbin`:" \
			Makefile.{in,tools} || die
	fi
}

src_configure() {
	export ac_cv_header_readline_readline_h=$(usex readline)

	# Missing flags: --enable-{sap,hidd,pand,dund,dbusoob,gatt}
	# Keep this in ./configure --help order!
	econf \
		--localstatedir=/var \
		--enable-network \
		--enable-serial \
		--enable-input \
		--enable-audio \
		--enable-service \
		--enable-health \
		--enable-pnat \
		$(use_enable gstreamer) \
		$(use_enable alsa) \
		$(use_enable usb) \
		--enable-tools \
		--enable-bccmd \
		$(use_enable pcmcia) \
		--enable-hid2hci \
		--enable-dfutool \
		$(use_enable cups) \
		$(use_enable test-programs test) \
		--enable-datafiles \
		$(use_enable debug) \
		--enable-maemo6 \
		--enable-wiimote \
		--disable-hal \
		--with-ouifile=/usr/share/misc/oui.txt \
		--with-systemdunitdir="$(systemd_get_unitdir)"
}

src_install() {
	default

	if use test-programs; then
		pushd test >/dev/null
		dobin simple-agent simple-service monitor-bluetooth
		newbin list-devices list-bluetooth-devices
		rm test-textfile.{c,o} || die #356529
		local b
		for b in hsmicro hsplay test-*; do
			newbin "${b}" bluez-"${b}"
		done
		insinto /usr/share/doc/${PF}/test-services
		doins service-*
		python_fix_shebang "${ED}"
		popd >/dev/null
	fi

	insinto /etc/bluetooth
	local d
	for d in input audio network serial; do
		doins ${d}/${d}.conf
	done

	newinitd "${FILESDIR}"/bluetooth-init.d-r2 bluetooth
	newinitd "${FILESDIR}"/rfcomm-init.d rfcomm
	newconfd "${FILESDIR}"/rfcomm-conf.d rfcomm

	prune_libtool_files --modules
}

pkg_postinst() {
	use udev && udevadm control --reload-rules

	has_version net-dialup/ppp || elog "To use dial up networking you must install net-dialup/ppp."

	if use consolekit; then
		elog "If you want to use rfcomm as a normal user, you need to add the user"
		elog "to the uucp group."
	else
		elog "Since you have the consolekit use flag disabled, you will only be able to run"
		elog "bluetooth clients as root. If you want to be able to run bluetooth clients as"
		elog "a regular user, you need to enable the consolekit use flag for this package or"
		elog "to add the user to the plugdev group."
	fi

	if [ "$(rc-config list default | grep bluetooth)" = "" ]; then
		elog "You will need to add bluetooth service to default runlevel"
		elog "for getting your devices detected. For that please run:"
		elog "'rc-update add bluetooth default'"
	fi
}
