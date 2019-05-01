# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit autotools

DESCRIPTION="Open Source Deep Packet Inspection Software Toolkit"
HOMEPAGE="http://www.ntop.org/"
SRC_URI="https://github.com/ntop/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="dev-libs/json-c
	net-libs/libpcap"
RDEPEND="${DEPEND}"

PATCHES=(
    "${FILESDIR}"/${PN}-2.8-gentoo.patch
)

src_prepare() {
	default

	# Let's not sink to this level of craziness...
	./autogen.sh --libdir=/lib64 --pkgconfigdir=/share/pkgconfig

	# ... but instead try to sort it out ourselves:
	#NDPI_MAJOR="${PV%.*}"
	#NDPI_MINOR="${PV#*.}"
	#NDPI_PATCH="0"
	#[[ "${PVR}" == *-r* ]] && NDPI_PATCH="${PVR#*-r}"
	#NDPI_VERSION_SHORT="${NDPI_MAJOR}.${NDPI_MINOR}.${NDPI_PATCH}"

	#ebegin "Generating configure.ac ..."
	#sed -e "s/@NDPI_MAJOR@/${NDPI_MAJOR}/g" \
		#-e "s/@NDPI_MINOR@/${NDPI_MINOR}/g" \
		#-e "s/@NDPI_PATCH@/${NDPI_PATCH}/g" \
		#-e "s/@NDPI_VERSION_SHORT@/${NDPI_VERSION_SHORT}/g" \
		#configure.seed > configure.ac ||
	#eend ${?}  "Version substitution failed: ${?}" || die

	#local myeconfargs=(
		#--libdir=/lib64
	#)

	#eautoreconf
}
