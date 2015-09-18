# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: ba2ec73f2b120043e1fe0cd9dbd5cc0df5a2049e $

EAPI=5
PYTHON_COMPAT=( python2_7 )
DISTUTILS_OPTIONAL=1
WANT_AUTOMAKE="none"
MY_P="${P/_/-}"
GENTOO_DEPEND_ON_PERL="no"

inherit autotools bash-completion-r1 db-use depend.apache distutils-r1 elisp-common flag-o-matic java-pkg-opt-2 libtool multilib perl-module eutils toolchain-funcs

DESCRIPTION="Advanced version control system"
HOMEPAGE="http://subversion.apache.org/"
SRC_URI="mirror://apache/${PN}/${MY_P}.tar.bz2"
S="${WORKDIR}/${MY_P}"

LICENSE="Subversion GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm ~arm64 hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="apache2 berkdb clang ctypes-python debug doc +dso extras gnome-keyring java kde nls perl python ruby sasl test vim-syntax +webdav-neon webdav-serf"

COMMON_DEPEND=">=dev-db/sqlite-3.6.18[threadsafe(+)]
	>=dev-libs/apr-1.3:1
	>=dev-libs/apr-util-1.3:1
	dev-libs/expat
	sys-libs/zlib
	berkdb? ( >=sys-libs/db-4.0.14 )
	ctypes-python? ( ${PYTHON_DEPS} )
	gnome-keyring? ( dev-libs/glib:2 sys-apps/dbus gnome-base/libgnome-keyring )
	kde? ( sys-apps/dbus dev-qt/qtcore:4 dev-qt/qtdbus:4 dev-qt/qtgui:4 >=kde-base/kdelibs-4:4 )
	perl? ( dev-lang/perl:= )
	python? ( ${PYTHON_DEPS} )
	ruby? ( >=dev-lang/ruby-1.8.2:1.8
		dev-ruby/rubygems[ruby_targets_ruby18] )
	sasl? ( dev-libs/cyrus-sasl )
	webdav-neon? ( >=net-libs/neon-0.28 )
	webdav-serf? ( >=net-libs/serf-0.3.0 )"
RDEPEND="${COMMON_DEPEND}
	apache2? ( www-servers/apache[apache2_modules_dav] )
	java? ( >=virtual/jre-1.5 )
	kde? ( kde-apps/kwalletd:4 )
	nls? ( virtual/libintl )
	perl? ( dev-perl/URI )"
# Note: ctypesgen doesn't need PYTHON_USEDEP, it's used once
DEPEND="${COMMON_DEPEND}
	test? ( ${PYTHON_DEPS} )
	!!<sys-apps/sandbox-1.6
	ctypes-python? ( dev-python/ctypesgen )
	doc? ( app-doc/doxygen )
	gnome-keyring? ( virtual/pkgconfig )
	java? ( >=virtual/jdk-1.5 )
	kde? ( virtual/pkgconfig )
	nls? ( sys-devel/gettext )
	webdav-neon? ( virtual/pkgconfig )"

REQUIRED_USE="
	ctypes-python? ( ${PYTHON_REQUIRED_USE} )
	python? ( ${PYTHON_REQUIRED_USE} )
	test? ( ${PYTHON_REQUIRED_USE} )"

want_apache

pkg_setup() {
	if use berkdb; then
		local apu_bdb_version="$(${EPREFIX}/usr/bin/apu-1-config --includes \
			| grep -Eoe '-I${EPREFIX}/usr/include/db[[:digit:]]\.[[:digit:]]' \
			| sed 's:.*b::')"
		einfo
		if [[ -z "${SVN_BDB_VERSION}" ]]; then
			if [[ -n "${apu_bdb_version}" ]]; then
				SVN_BDB_VERSION="${apu_bdb_version}"
				einfo "Matching db version to apr-util"
			else
				SVN_BDB_VERSION="$(db_ver_to_slot "$(db_findver sys-libs/db 2>/dev/null)")"
				einfo "SVN_BDB_VERSION variable isn't set. You can set it to enforce using of specific version of Berkeley DB."
			fi
		fi
		einfo "Using: Berkeley DB ${SVN_BDB_VERSION}"
		einfo

		if [[ -n "${apu_bdb_version}" && "${SVN_BDB_VERSION}" != "${apu_bdb_version}" ]]; then
			eerror "APR-Util is linked against Berkeley DB ${apu_bdb_version}, but you are trying"
			eerror "to build Subversion with support for Berkeley DB ${SVN_BDB_VERSION}."
			eerror "Rebuild dev-libs/apr-util or set SVN_BDB_VERSION=\"${apu_bdb_version}\"."
			eerror "Aborting to avoid possible run-time crashes."
			die "Berkeley DB version mismatch"
		fi
	fi

	depend.apache_pkg_setup

	java-pkg-opt-2_pkg_setup

	if ! use webdav-neon && ! use webdav-serf; then
		ewarn "WebDAV support is disabled. You need WebDAV to"
		ewarn "access repositories through the HTTP protocol."
		ewarn "Consider enabling one of the following USE-flags:"
		ewarn "  webdav-neon webdav-serf"
		echo -ne "\a"
	fi

	if use debug; then
		append-cppflags -DSVN_DEBUG -DAP_DEBUG
	fi

	# Allow for custom repository locations.
	SVN_REPOS_LOC="${SVN_REPOS_LOC:-${EPREFIX}/var/svn}"
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.5.4-interix.patch \
		"${FILESDIR}"/${PN}-1.5.6-aix-dso.patch \
		"${FILESDIR}"/${PN}-1.6.3-hpux-dso.patch \
		"${FILESDIR}"/${PN}-fix-parallel-build-support-for-perl-bindings.patch
	epatch_user

	fperms +x build/transform_libtool_scripts.sh

	sed -i \
		-e "s/\(BUILD_RULES=.*\) bdb-test\(.*\)/\1\2/g" \
		-e "s/\(BUILD_RULES=.*\) test\(.*\)/\1\2/g" configure.ac

	# this bites us in particular on Solaris
	sed -i -e '1c\#!/usr/bin/env sh' build/transform_libtool_scripts.sh || \
		die "/bin/sh is not POSIX shell!"

	tc-export CC CXX

	eautoconf
	elibtoolize

	sed -e 's/\(libsvn_swig_py\)-\(1\.la\)/\1-$(EPYTHON)-\2/g' \
		-i build-outputs.mk || die "sed failed"

	if use python; then
		# XXX: make python_copy_sources accept path
		S=${S}/subversion/bindings/swig/python python_copy_sources
		rm -r "${S}"/subversion/bindings/swig/python || die
	fi
}

src_configure() {
	local myconf="" linkopts="" rubyopts=""

	if use python || use perl || use ruby; then
		myconf+=" --with-swig"
	else
		myconf+=" --without-swig"
	fi

	if use java; then
		myconf+=" --without-junit"
	fi

	if use kde || use nls; then
		myconf+=" --enable-nls"
	else
		myconf+=" --disable-nls"
	fi

	case ${CHOST} in
		*-aix*)
			# avoid recording immediate path to sharedlibs into executables
			append-ldflags -Wl,-bnoipath
		;;
		*-darwin*)
			# Configure says that local-library-preloading doesn't work on
			# Darwin...
			myconf+=" --disable-local-library-preloading"
		;;
		*-interix*)
			# loader crashes on the LD_PRELOADs...
			myconf+=" --disable-local-library-preloading"
		;;
		*-solaris*)
			# need -lintl to link
			use nls && append-libs intl
			# this breaks installation, on x64 echo replacement is 32-bits
			myconf+=" --disable-local-library-preloading"
		;;
		*-mint*)
			myconf+=" --enable-all-static --disable-local-library-preloading"
		;;
		*)
			# inject LD_PRELOAD entries for easy in-tree development
			myconf+=" --enable-local-library-preloading"
		;;
	esac

	#workaround for bug 387057
	has_version =dev-vcs/subversion-1.6* && myconf+=" --disable-disallowing-of-undefined-references"

	#version 1.7.7 again tries to link against the older installed version and fails, when trying to
	#compile for x86 on amd64, so workaround this issue again
	#check newer versions, if this is still/again needed
	myconf+=" --disable-disallowing-of-undefined-references"

	# for build-time scripts
	if use ctypes-python || use python || use test; then
		python_export_best
	fi

	if use clang; then
		if type -pf python >/dev/null 2>&1; then
			linkopts="$( python -B "${S}"/build/get-py-info.py --link )"
			linkopts="ac_cv_python_link=\"${CC} $( echo "$link" | cut -d' ' -f 2- )\""
		fi
	fi

	#force ruby-1.8 for bug 399105
	if use ruby; then
		rubyopts="ac_cv_path_RUBY=\"${EPREFIX}\"/usr/bin/ruby18 ac_cv_path_RDOC=\"${EPREFIX}\"/usr/bin/rdoc18"
	fi

	tc-export CC CXX
	
	#allow overriding Python include directory
	eval \
	ac_cv_python_compile="${CC} " \
	ac_cv_python_includes='-I\$\(PYTHON_INCLUDEDIR\)' \
	${linkopts} \
	${rubyopts} \
	econf --libdir="${EPREFIX}/usr/$(get_libdir)" \
		$(use_with apache2 apxs "${APXS}") \
		$(use_with berkdb berkeley-db "db.h:${EPREFIX}/usr/include/db${SVN_BDB_VERSION}::db-${SVN_BDB_VERSION}") \
		$(use_with ctypes-python ctypesgen "${EPREFIX}/usr") \
		$(use_enable dso runtime-module-search) \
		$(use_with gnome-keyring) \
		$(use_enable java javahl) \
		$(use_with java jdk "${JAVA_HOME}") \
		$(use_with kde kwallet) \
		$(use_with sasl) \
		$(use_with webdav-neon neon) \
		$(use_with webdav-serf serf "${EPREFIX}/usr") \
		${myconf} \
		--with-apr="${EPREFIX}/usr/bin/apr-1-config" \
		--with-apr-util="${EPREFIX}/usr/bin/apu-1-config" \
		--disable-experimental-libtool \
		--without-jikes \
		--disable-mod-activation \
		--disable-neon-version-check \
		--disable-static
}

src_compile() {
	emake local-all

	if use ctypes-python; then
		# pre-generate .py files
		use ctypes-python && emake ctypes-python

		pushd subversion/bindings/ctypes-python >/dev/null || die
		distutils-r1_src_compile
		popd >/dev/null || die
	fi

	if use python; then
		swig_py_compile() {
			local p=subversion/bindings/swig/python
			rm -f ${p} || die
			ln -s "${BUILD_DIR}" ${p} || die

			python_export PYTHON_INCLUDEDIR
			emake swig-py \
				swig_pydir="$(python_get_sitedir)/libsvn" \
				swig_pydir_extra="$(python_get_sitedir)/svn"
		}

		# this will give us proper BUILD_DIR for symlinking
		BUILD_DIR=python \
		python_foreach_impl swig_py_compile
	fi

	if use perl; then
		emake swig-pl
	fi

	if use ruby; then
		emake swig-rb
	fi

	if use java; then
		emake -j1 JAVAC_FLAGS="$(java-pkg_javac-args) -encoding iso8859-1" javahl
	fi

	if use extras; then
		emake tools
	fi

	if use doc; then
		doxygen doc/doxygen.conf || die "Building of Subversion HTML documentation failed"

		if use java; then
			emake doc-javahl
		fi
	fi
}

src_test() {
	default

	if use ctypes-python; then
		python_test() {
			"${PYTHON}" subversion/bindings/ctypes-python/test/run_all.py \
				|| die "ctypes-python tests fail with ${EPYTHON}"
		}

		distutils-r1_src_test
	fi

	if use python; then
		swig_py_test() {
			pushd "${BUILD_DIR}" >/dev/null || die
			"${PYTHON}" tests/run_all.py || die "swig-py tests fail with ${EPYTHON}"
			popd >/dev/null || die
		}

		BUILD_DIR=subversion/bindings/swig/python \
		python_foreach_impl swig_py_test
	fi
}

src_install() {
	emake -j1 DESTDIR="${D}" local-install

	if use ctypes-python; then
		pushd subversion/bindings/ctypes-python >/dev/null || die
		distutils-r1_src_install
		popd >/dev/null || die
	fi

	if use python; then
		swig_py_install() {
			local p=subversion/bindings/swig/python
			rm -f ${p} || die
			ln -s "${BUILD_DIR}" ${p} || die

			emake \
				DESTDIR="${D}" \
				swig_pydir="$(python_get_sitedir)/libsvn" \
				swig_pydir_extra="$(python_get_sitedir)/svn" \
				install-swig-py
		}

		BUILD_DIR=python \
		python_foreach_impl swig_py_install
	fi

	if use perl; then
		emake DESTDIR="${D}" INSTALLDIRS="vendor" install-swig-pl
		perl_delete_localpod
		find "${ED}" "(" -name .packlist -o -name "*.bs" ")" -delete
	fi

	if use ruby; then
		emake DESTDIR="${D}" install-swig-rb
	fi

	if use java; then
		emake DESTDIR="${D}" install-javahl
		java-pkg_regso "${ED}"usr/$(get_libdir)/libsvnjavahl*$(get_libname)
		java-pkg_dojar "${ED}"usr/$(get_libdir)/svn-javahl/svn-javahl.jar
		rm -fr "${ED}"usr/$(get_libdir)/svn-javahl/*.jar
	fi

	# Install Apache module configuration.
	if use apache2; then
		keepdir "${APACHE_MODULES_CONFDIR}"
		insinto "${APACHE_MODULES_CONFDIR}"
		doins "${FILESDIR}/47_mod_dav_svn.conf"
	fi

	# Install Bash Completion, bug 43179.
	newbashcomp tools/client-side/bash_completion subversion
	rm -f tools/client-side/bash_completion

	# Install hot backup script, bug 54304.
	newbin tools/backup/hot-backup.py svn-hot-backup
	rm -fr tools/backup

	# Install svnserve init-script and xinet.d snippet, bug 43245.
	newinitd "${FILESDIR}"/svnserve.initd2 svnserve
	newconfd "${FILESDIR}"/svnserve.confd svnserve
	insinto /etc/xinetd.d
	newins "${FILESDIR}"/svnserve.xinetd svnserve

	#adjust default user and group with disabled apache2 USE flag, bug 381385
	use apache2 || sed -e "s\USER:-apache\USER:-svn\g" \
			-e "s\GROUP:-apache\GROUP:-svnusers\g" \
			-i "${ED}"etc/init.d/svnserve || die
	use apache2 || sed -e "0,/apache/s//svn/" \
			-e "s:apache:svnusers:" \
			-i "${ED}"etc/xinetd.d/svnserve || die

	# Install documentation.
	dodoc CHANGES COMMITTERS README
	dodoc tools/xslt/svnindex.{css,xsl}
	rm -fr tools/xslt

	# Install extra files.
	if use extras; then
		cat << EOF > 80subversion-extras
PATH="${EPREFIX}/usr/$(get_libdir)/subversion/bin"
ROOTPATH="${EPREFIX}/usr/$(get_libdir)/subversion/bin"
EOF
		doenvd 80subversion-extras

		emake DESTDIR="${D}" toolsdir="/usr/$(get_libdir)/subversion/bin" install-tools || die "Installation of tools failed"

		find tools "(" -name "*.bat" -o -name "*.in" -o -name ".libs" ")" -print0 | xargs -0 rm -fr
		rm -fr tools/client-side/svnmucc
		rm -fr tools/server-side/{svn-populate-node-origins-index,svnauthz-validate}*
		rm -fr tools/{buildbot,dev,diff,po}

		insinto /usr/share/${PN}
		find tools -name '*.py' -exec sed -i -e '1s:python:&2:' {} + || die
		doins -r tools
	fi

	if use doc; then
		dohtml -r doc/doxygen/html/*

		if use java; then
			java-pkg_dojavadoc doc/javadoc
		fi
	fi

	find "${ED}" '(' -name '*.la' ')' -print0 | xargs -0 rm -f

	cd "${ED}"usr/share/locale
	for i in * ; do
		[[ $i == *$LINGUAS* ]] || { rm -r $i || die ; }
	done
}

pkg_preinst() {
	# Compare versions of Berkeley DB, bug 122877.
	if use berkdb && [[ -f "${EROOT}usr/bin/svn" ]]; then
		OLD_BDB_VERSION="$(scanelf -nq "${EROOT}usr/$(get_libdir)/libsvn_subr-1$(get_libname 0)" | grep -Eo "libdb-[[:digit:]]+\.[[:digit:]]+" | sed -e "s/libdb-\(.*\)/\1/")"
		NEW_BDB_VERSION="$(scanelf -nq "${ED}usr/$(get_libdir)/libsvn_subr-1$(get_libname 0)" | grep -Eo "libdb-[[:digit:]]+\.[[:digit:]]+" | sed -e "s/libdb-\(.*\)/\1/")"
		if [[ "${OLD_BDB_VERSION}" != "${NEW_BDB_VERSION}" ]]; then
			CHANGED_BDB_VERSION="1"
		fi
	fi
}

pkg_postinst() {
	if [[ -n "${CHANGED_BDB_VERSION}" ]]; then
		ewarn "You upgraded from an older version of Berkeley DB and may experience"
		ewarn "problems with your repository. Run the following commands as root to fix it:"
		ewarn "    db4_recover -h ${SVN_REPOS_LOC}/repos"
		ewarn "    chown -Rf apache:apache ${SVN_REPOS_LOC}/repos"
	fi

	ewarn "If you run subversion as a daemon, you will need to restart it to avoid module mismatches."
}

pkg_config() {
	# Remember: Don't use ${EROOT}${SVN_REPOS_LOC} since ${SVN_REPOS_LOC}
	# already has EPREFIX in it
	einfo "Initializing the database in ${SVN_REPOS_LOC}..."
	if [[ -e "${SVN_REPOS_LOC}/repos" ]]; then
		echo "A Subversion repository already exists and I will not overwrite it."
		echo "Delete \"${SVN_REPOS_LOC}/repos\" first if you're sure you want to have a clean version."
	else
		mkdir -p "${SVN_REPOS_LOC}/conf"

		einfo "Populating repository directory..."
		# Create initial repository.
		"${EROOT}usr/bin/svnadmin" create "${SVN_REPOS_LOC}/repos"

		einfo "Setting repository permissions..."
		SVNSERVE_USER="$(. "${EROOT}etc/conf.d/svnserve"; echo "${SVNSERVE_USER}")"
		SVNSERVE_GROUP="$(. "${EROOT}etc/conf.d/svnserve"; echo "${SVNSERVE_GROUP}")"
		if use apache2; then
			[[ -z "${SVNSERVE_USER}" ]] && SVNSERVE_USER="apache"
			[[ -z "${SVNSERVE_GROUP}" ]] && SVNSERVE_GROUP="apache"
		else
			[[ -z "${SVNSERVE_USER}" ]] && SVNSERVE_USER="svn"
			[[ -z "${SVNSERVE_GROUP}" ]] && SVNSERVE_GROUP="svnusers"
		fi
		chmod -Rf go-rwx "${SVN_REPOS_LOC}/conf"
		chmod -Rf o-rwx "${SVN_REPOS_LOC}/repos"
		echo "Please create \"${SVNSERVE_GROUP}\" group if it does not exist yet."
		echo "Afterwards please create \"${SVNSERVE_USER}\" user with homedir \"${SVN_REPOS_LOC}\""
		echo "and as part of the \"${SVNSERVE_GROUP}\" group if it does not exist yet."
		echo "Finally, execute \"chown -Rf ${SVNSERVE_USER}:${SVNSERVE_GROUP} ${SVN_REPOS_LOC}/repos\""
		echo "to finish the configuration."
	fi
}