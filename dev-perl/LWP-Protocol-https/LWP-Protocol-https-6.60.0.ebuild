# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: a15d59e2fa0d9b6cba0d1dcca5d58f99670ee29a $

EAPI=5

MODULE_AUTHOR=MSCHILLI
MODULE_VERSION=6.06
inherit perl-module prefix

DESCRIPTION="Provide https support for LWP::UserAgent"
SRC_URI+=" https://dev.gentoo.org/~tove/distfiles/${CATEGORY}/${PN}/${PN}_ca-cert-r1.patch.gz"

SLOT="0"
IUSE=""
KEYWORDS="alpha amd64 arm ~arm64 hppa ia64 ~m68k ~mips ppc ppc64 ~s390 ~sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"

RDEPEND="
	app-misc/ca-certificates
	>=dev-perl/libwww-perl-6.20.0
	>=dev-perl/Net-HTTP-6
	>=dev-perl/IO-Socket-SSL-1.540.0
"
DEPEND="${RDEPEND}
	virtual/perl-ExtUtils-MakeMaker
"

PATCHES=(
	"${FILESDIR}"/${PN}-6.60.0-CVE-2014-3230.patch
	#"${FILESDIR}"/${PN}-6.60.0-etcsslcerts.patch
)

src_prepare() {
	default

	epatch "$( prefixify_ro "${FILESDIR}"/${PN}-6.60.0-etcsslcerts.patch )"
}

SRC_TEST=online