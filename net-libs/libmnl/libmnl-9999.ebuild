# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-libs/libmnl/libmnl-1.0.3-r1.ebuild,v 1.14 2015/05/05 15:30:19 vapier Exp $

EAPI=4

inherit autotools eutils git-2 toolchain-funcs

DESCRIPTION="Minimalistic netlink library"
HOMEPAGE="http://netfilter.org/projects/libmnl"
EGIT_REPO_URI="git://git.netfilter.org/${PN}.git"
EGIT_MASTER="master"

LICENSE="LGPL-2.1"
SLOT="0"
#KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ppc ppc64 s390 sh sparc x86 ~amd64-linux"
KEYWORDS=""
IUSE="examples static-libs"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf $(use_enable static-libs static)
}

src_install() {
	default
	gen_usr_ldscript -a mnl
	prune_libtool_files

	if use examples; then
		find examples/ -name 'Makefile*' -delete
		dodoc -r examples/
		docompress -x /usr/share/doc/${PF}/examples
	fi
}