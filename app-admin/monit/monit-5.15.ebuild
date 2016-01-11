# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: c3245a4294cb4845ba74eca1a403c24950e253a4 $

EAPI="5"
inherit pam systemd

DESCRIPTION="a utility for monitoring and managing daemons or similar programs running on a Unix system"
HOMEPAGE="http://mmonit.com/monit/"
SRC_URI="http://mmonit.com/monit/dist/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 ppc ~ppc64 x86 ~amd64-linux"
IUSE="pam ssl systemd"

RDEPEND="ssl? ( dev-libs/openssl:0= )"
DEPEND="${RDEPEND}
	sys-devel/flex
	sys-devel/bison
	pam? ( virtual/pam )"

src_prepare() {
	sed -i -e '/^INSTALL_PROG/s/-s//' Makefile.in || die "sed failed in Makefile.in"
}

src_configure() {
	econf $(use_with ssl) $(use_with pam) --enable-optimized
}

src_install() {
	default

	dodoc README*
	dohtml -r doc/*

	insinto /etc; insopts -m600; doins monitrc
	newinitd "${FILESDIR}"/monit.initd-5.0-r1 monit
	use systemd && systemd_dounit "${FILESDIR}"/${PN}.service

	use pam && newpamd "${FILESDIR}"/${PN}.pamd ${PN}
}

pkg_postinst() {
	elog "Sample configurations are available at:"
	elog "http://mmonit.com/monit/documentation/"
}