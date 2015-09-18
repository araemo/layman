# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: fc4088c8689c94e2b8aea6a56d40aa896b320acc $

EAPI=5
inherit cmake-utils flag-o-matic git-r3

DESCRIPTION="Raspberry Pi userspace tools and libraries"
HOMEPAGE="https://github.com/raspberrypi/userland"
SRC_URI=""

LICENSE="BSD"
SLOT="0"
KEYWORDS="arm -*"
IUSE="examples"

DEPEND=""
RDEPEND=""

EGIT_REPO_URI="https://github.com/raspberrypi/userland"

pkg_setup() {
	append-ldflags $(no-as-needed)
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-gentoo.patch
	epatch "${FILESDIR}"/${P}-pid.patch
}

src_install() {
	cmake-utils_src_install

	dodir /usr/lib/opengl/raspberrypi/lib
	touch "${D}"/usr/lib/opengl/raspberrypi/.gles-only
	mv "${D}"/usr/lib/lib{EGL,GLESv2}* \
		"${D}"/usr/lib/opengl/raspberrypi/lib

	dodir /usr/lib/opengl/raspberrypi/include
	mv "${D}"/usr/include/{EGL,GLES,GLES2,KHR,WF} \
		"${D}"/usr/lib/opengl/raspberrypi/include
	mv "${D}"/usr/include/interface/vcos/pthreads/* \
		"${D}"/usr/include/interface/vcos/
	rmdir "${D}"/usr/include/interface/vcos/pthreads
	mv "${D}"/usr/include/interface/vmcs_host/linux/* \
		"${D}"/usr/include/interface/vmcs_host/
	rmdir "${D}"/usr/include/interface/vmcs_host/linux

	if use examples; then
		dodir /usr/share/doc/${PN}
		mv "${D}"/usr/src/hello_pi "${D}"/usr/share/doc/${PN}/
	fi
	rmdir "${D}"/usr/src

	rm "${D}"/etc/init.d/vcfiled
	newinitd "${FILESDIR}"/${PN}-vcfiled.initd vcfiled
}

pkg_postinst() {
	ewarn "The package ${PN} only includes open-source Raspberry Pi"
	ewarn "utilities, and the sys-apps/raspberrypi-utilities-armv6 package is"
	ewarn "additionally required for certain closed-source components such as"
	ewarn "the VideoCore IV debugging tool 'vcdbg'."
}