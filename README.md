
Various [Gentoo Linux](http://www.gentoo.org/) ebuilds, to provide out-of-tree packages and miscellaneous fixes.

# Raspberry Pi tools and utilities

* dev-python/raspberrypi-gpio
    * RPi.GPIO ebuild
* media-libs/raspberrypi-userland
    * Replace non-functional Raspian init script with OpenRC equivalent, and update PID location
* sys-apps/raspberrypi-utilities-armv6
    * Some Raspberry Pi userland tools are closed-source, and so not available in media-libs/raspberrypi-userland.  There (armv6 only, currently) utilities are installed by this package
* sys-boot/raspberrypi-firmware
    * Raspberry Pi VideoCore firmware, Device Tree overlays, Kernel image, and kernel modules from a `smart-live-rebuild`-compatible ebuild
* sys-boot/raspberrypi-mkimage
    * Add latest signing tools to enable Device Tree support in self-built kernels
* sys-kernel/raspberrypi-sources
    * Raspberry Pi latest kernel sources, from a `smart-live-rebuild`-compatible ebuild
* www-apps/rpi-monitor
    * Raspberry Pi monitoring web-interface from [rpi-experiences.blogspot.fr](http://rpi-experiences.blogspot.fr/)

# Fixes for compiling prefix packages under Mac OS using LLVM/clang

Some packages will fail with `illegal instruction: 4` if compiled with certain compiler-optimisations enabled.  Indeed, the `-ftrapv` flag will cause `clang` to intenionally insert `ud2` (Undefined Instruction) op-codes where integer overflows could occur, and this catches-out a significant number of packages, causing them to crash with `SIGILL` - illegal instruction.  To work around this on a per-package basis where `-ftrapv` has not been used during compilation, perform the following steps:

```
mkdir ${EPREFIX}/etc/portage/env

cat > ${EPREFIX}/etc/portage/env/debug <<EOF

# Assuming that clang is now default...

#CC="${EPREFIX}/usr/bin/clang"
#CXX="${EPREFIX}/usr/bin/clang++"

CFLAGS="-arch x86_64 -march=x86-64"
CFLAGS="${CFLAGS} -fcolor-diagnostics -O0 -g -pipe"
CFLAGS="${CFLAGS} -Wno-implicit-function-declaration"

CXXFLAGS="${CFLAGS}"
#CXXFLAGS="${CXXFLAGS} -stdlib=libstdc++"

#LDFLAGS="${LDFLAGS} -stdlib=libstdc++"

MAKEOPTS="-j1"

#PKGDIR="${PORTDIR}/packages/clang"

# vi: set syntax=conf:
EOF

cat >> ${EPREFIX}/etc/portage/package.env <<EOF
~sys-devel/binutils-apple-6.1 debug
EOF
```

... correcting for `CFLAGS` as appropriate in `${EPREFIX}/etc/portage/env/debug`.

A similar configuration file could be added for all packages which fail to compile with clang and require gcc.  An (unfortunately incomplete) list of these packages consists of:

```
~dev-vcs/subversion-1.7.19
~sys-devel/binutils-config-3-r03.1
~sys-devel/gcc-apple-4.2.1_p5666
~sys-libs/db-5.2.42
```

(subversion presents an issue - it cannot be compiled with clang, but if `USE="perl"` then the same compiler must be used to build subversion as was used to build perl)

... with a slightly larger set of builds failing if `FEATURES="strict"` or `FEATURES="stricter"`, or if `MAKEOPTS` is not set to "`-j1`".

* app-arch/lz4
    * Ensure that appropriate `PREFIX` directory is available to build system
* app-arch/unzip
    * Remove `cc` hard-coding
* app-crypt/pinentry
    * Add `-Wno-implicit-function-declaration` to work around ncurses-related failures, if supported by the compiler
* app-shells/bash
    * Include `<signal.h>` in relevant places to avoid `-Wimplicit-function-declaration` errors
* dev-lang/python
    * If `configure` is not removed after applying the prefix libffi patch, `@LIBFFI_LIB@` is never expanded to the correct value even after `autoconf` has completed
* dev-libs/apr
    * Support F_FULLFSYNC on Darwin
* dev-libs/gmp
    * Add patch to prevent `invalid reassignment of non-absolute variable 'L0m4_tmp'` error
* dev-libs/jemalloc
    * Correct library version used when calling `install_name_tool`
* dev-libs/libksba
    * Override `-Wall` CFLAG by adding clang `#pragma`s to problematic code
* dev-libs/liblinear
    * Update Makefile to build correctly on Darwin
* dev-libs/libxslt
    * Fix for 'double prefix' QA error introduced in 1.1.28-r2
* dev-libs/openssl
    * Add `-Wno-error=unused-command-line-argument` to clang to prevent aborting with an `error` due to `-Wa,--noexecstack`, and fix util/domd to treat clang like gcc
* dev-libs/udis86
    * Add `${EPREFIX}` to `docdir` configure option
* dev-python/backports-ssl-match-hostname
    * Change `${ED}` to `${D}` to prevent double-prefix path usage QA error
* dev-vcs/cvs
    * Allow CVS to build and tests to run on Darwin
* dev-vcs/subversion
    * Correct detection of compiler by `get-py-info.py` and ensure appropriate compiler is used
* sys-apps/baselayout-prefix
    * Add missing `run_applets` prototype
* sys-apps/darwin-miscutils
    * Add missing `md.c` prototypes and `#include`s
* sys-apps/gptfdisk
    * Allow `gdisk` to build on Darwin (there's a separate `Makefile` for this platform which doesn't use `libuuid`) and ensure appropriate compiler is used
* sys-apps/help2man
    * Ensure that `usr/lib/help2man/bindtextdomain.dylib` is correctly built and named
* sys-apps/texinfo
    * Add missing `#include`
* sys-devel/binutils-apple
    * Build to current Mac OS version and fix missing Libc header
* sys-devel/gdb
    * Fixes for building with clang, building on Yosemite, and building with Python support
* sys-devel/gcc-apple
    * Fixes for building with clang and building on Yosemite
* sys-devel/llvm
    * Additional fixes for Darwin
* sys-libs/db
    * Prevent clang builtins error due to `__atomic_compare_exchange` function
* sys-libs/gdbm
    * Ensure that all functions are defined before being called
* sys-libs/readline
    * Ensure that `<sys/ioctl.h>` header is included on Darwin

# iOS7 and iOS 8 -compatible ebuilds

* app-pda/ipheth-pair
    * Tether an Apple iOS device to provide a network-link
* app-pda/libimobiledevice
    * git live ebuild for updated libimobiledevice tools
* app-pda/libplist
    * git live ebuild for updated plist library
* app-pda/libusbmuxd
    * git live ebuild for split libusbmuxd/usbmuxd library
* app-pda/usbmuxd
    * git live ebuild for usbmuxd binaries

# PHP 7.x compatible ebuilds
* dev-php/pecl-memcache
    * '`--php_targets_php7-0`' must currently be added to `/etc/portage/profile/use.mask`

# nftables ebuilds

* net-libs/libnftnl
    * Updated library version required by latest net-firewall/nftables
* net-firewall/iptables-nftables
    * git live ebuild for nftables' iptables compatibility libraries
* ~~net-firewall/nftables~~
    * ~~git live ebuild for nftables `nft` binary~~ (obsolete due to in-tree nftables build)
* app-emulation/docker
    * Allow net-firewall/iptables-nftables as an alternative to net-firewall/iptables
* sys-apps/iproute2
    * Allow net-firewall/iptables-nftables as an alternative to net-firewall/iptables

# Out-of-tree ebuilds

* app-admin/openrc-restart-crashed
    * Check for services with status 'crashed', and optionally restart specified services
* app-emulation/wa-linux-agent
* dev-perl/CPANPLUS
* dev-perl/CPANPLUS-Dist-Gentoo
* dev-perl/Email-Outlook-Message
* dev-perl/Locale-Hebrew
* dev-perl/IO-Interface
* dev-perl/IO-Socket-Multicast
* dev-perl/Mojolicious
* dev-perl/Mojo-Server-FastCGI
* dev-perl/Net-Interface
* dev-perl/Net-MAC-Vendor
* dev-perl/Net-SDP
* dev-perl/Net-Subnet
* dev-perl/Net-Twitter-Lite
* dev-perl/POE-Component-Client-Ping
* dev-perl/Proc-PID-File
* dev-php/PEAR-Crypt_GPG
    * To replace the bundled libraries which are supplied with mail-client/roundcube-1.0.0
* dev-python/noxspellserver
* dev-ruby/CFPropertyList
* dev-ruby/cora
* dev-ruby/geocoder
* dev-ruby/guard
* dev-ruby/guard-rspec
* dev-ruby/pry
* dev-ruby/rake
* mail-client/roundcube
    * Roundcube 1.0.0 and Roundcube 1.0.1 have been released, but are not yet in-tree...
* ~~net-analyzer/netdata~~
    * ~~netdata is now in-tree~~
* net-libs/libhtp
    * Add more recent libhtp-0.5.21 release, to prevent net-analyzer/suricata-3.1 from complaining about libhtp being too old
* net-libs/libupnp
    * Add more recent libupnp-1.6.20 and forked libupnp-1.8.0 releases, both with [mjg59](https://twitter.com/mjg59/status/755062671418929152)'s [POST](http://seclists.org/oss-sec/2016/q3/118) patch applied
* net-mail/davmail-bin
    * Java Microsoft Exchange <-> IMAP connector
* net-misc/minissdpd
    * Temporarily retain old build, which doesn't require `USE="old-output"` for sys-apps/net-tools
* sys-apps/tmpfs
    * Mirror segments of a filesystem to a memory-based backing store
* sys-auth/opie
    * OPIE One-time password system
* sys-auth/pam_mobile_otp
    * PAM component of mOTP
* sys-auth/yubipam
    * PAM authentication module for YubiKey hardware
* www-apps/heatmiser
    * Data acquisition and web-interface for Heatmiser Wifi Thermostats
* www-apps/nabaztaglives
    * Nabaztag Lives server software, re-factored into a webapp
* www-apps/opennab
    * OpenNAB Nabaztag server software
* www-apps/siriproxy
    * Web interface for 'Three Little Pigs' fork of SiriProxy
* ~~www-misc/observium~~
    * ~~Observium is an autodiscovering SNMP based network monitoring platform~~ Observium have removed public repo access, do not make versioned sources available, and aren't updating the current version string previously maintained at http://www.observium.org/stable.php - there no longer appears to be any sane way to package this application (... although it never worked correctly if using any web server other than Apache in any case)
* www-servers/3dm2
    * 3ware 3DM2 RAID controller web interface for 3w-xxxx, 3w-9xxx and 3w-sas controllers

# Modified ebuilds

* app-crypt/gnupg
    * Fix clang compilation errors
* app-emulation/lxc
    * Don't require an upgrade to Python 3.x unless building against Python
* app-misc/ca-certificates
    * Don't install files for creating .deb archives to `/usr/share/doc/${PF}/examples/`
* app-misc/colordiff
    * Install example configuration file to `/usr/share/doc/${PF}/` rather than `/etc/`
* dev-libs/libcgroup
    * Improve output with `USE="DEBUG"`
* mail-filter/opendkim
    * Prevent the unqualified need for 'RequireSafeKeys' on Gentoo due to GID=0 standard system users
* mail-filter/spampd
    * Fix `status` reporting, revise installed documentation, add optional systemd service support
* media-libs/opengl-apple
    * Check for missing files before installing the Apple X11/Xquartz compatibility symlinks
* media-sound/teamspeak-server-bin
    * A more FHS/Gentoo-like installation structure
* net-analyzer/munin
    * Re-factor munin to operate as a webapp, and remove configuration from `/etc`
* net-analyzer/netdata
    * With modifications to upstream ebuild and init script
* net-analyzer/suricata
    * Minor ebuild fixes, automatically fetch latest rules on build
* net-dialup/ppp
    * Incorporate patches to allow interface discovery (rather than assuming the `eth0` is the primary interface -the appropriate interface with a prefix of `eth`, `em`, `ef`, or `eg` will be auto-discovered), and to enable the use of Baby Jumbo Frames whereby the host interface is given an MTU of 1508 so that the PPPoE link can retain a full 1500-byte MTU
* net-firewall/ebtables
    * Update to latest git commit, which adds compatibility kernel headers more recent than v3.16
    * Allow `--among-src-file` and `--among-dst-file` options to accept files containing multiple lines, for ease of maintenance
    * Fix some crazy inconsistencies in output which were breaking `ebtables-save` and `ebtables-restore`
    * Set appropriate maximum buffer sizes to prevent `ebtables-restore` from segfaulting when loading more than 2kbytes of data from a single statement
    * Add Debian patch to correct the use of `RETURN` as a module target
* net-libs/neon
    * Patch trivial typo which prevents `writev` from being defined
* net-misc/dhcp
    * Enhance chroot support in init script
* net-misc/tor
    * Prevent GCC infinite loop, rather than simply warning about it
* net-misc/usbip
    * Prevent build failure due to harmless warning
* net-misc/wget
    * Filter `-funsafe-math-optimizations`, which prevents wget from building on ARM
* net-nds/openldap
    * If /etc/init.d/tmpfiles.setup isn't active, /var/run/openldap is never created yet the ebuild still attempts to set permissions upon it...
* sys-apps/busybox
    * Updates to make mdev more functional - see [here](http://blog.stuart.shelton.me/archives/891)...
* ~~sys-apps/gentoo-functions~~
    * ~~Deploy files to the correct locations on prefix installations~~
    * Fixed in sys-apps/gentoo-functions/sys-apps/gentoo-functions-0.9 v1.2
* sys-apps/gentoo-functions
    * Fix inclusion when unbound variable checking is enabled
* sys-apps/portage
    * Prevent `ebuild ... digest` from aborting if the owner of the category directory differs from that of the package directory
* sys-apps/usbutils
    * Revert changes which make usbutils dependent on udev
* sys-power/apcupsd
    * Incorporate patch to allow apcupsd to be bulit against recent SNMP headers;
    * Correct SNMP patch failure of version 3.14.12, make exposed configuration options more flexible;
    * Provide more flexibility with finer-grained USE flags
* sys-power/iasl
    * Fix paths in ebuild and make build documentation optional
* x11-drivers/nvidia-drivers
    * Only start nVidia System Management Interface if valid for the host system

# Fixes for ebuilds using `/run`
(... rather than `/var/run`)

Included as `install-qa-check.d/95run-directory` is the repo `metadata` directory is an additional QA check which reports an error if files deployed to `/etc/init.d` or `/etc/conf.d` contain references to `/run`.

* app-admin/eselect-php
* app-admin/syslog-ng
* app-admin/ulogd
* app-misc/screen
* dev-libs/cyrus-sasl
* mail-filter/spamassassin
* net-analyzer/darkstat
* net-analyzer/iptraf-ng
* net-analyzer/ntop
* net-analyzer/rrdtool
* net-analyzer/vnstat
* ~~net-analyzer/wireshark~~
* net-analyzer/zabbix
* net-dialup/freeradius
* net-dns/bind
* net-firewall/conntrack-tools
* net-fs/samba
* net-misc/dhcpcd
* net-misc/memcached
* net-misc/minidlna
* net-misc/openntpd
* net-misc/rsyncd
* net-p2p/bitcoind
* sys-apps/haveged
* sys-apps/kmod
* sys-apps/lm_sensors
* sys-apps/smartmontools
* sys-apps/util-linux
* sys-libs/pam
* sys-power/acpid
* www-servers/lighttpd

# Fixes to allow `/var/state` to be used in place of `/var/lib`

* dev-lang/php
* dev-php/PEAR-PEAR
* media-libs/libpvx

# Fixes for MIPS n32 and x86_64 x32 ABIs

Included is a modified `eclass/multilib.eclass` that no longer overrides any amd64 `LIBDIR_*` environment variables, which may now usefully be set in `/etc/portage/make.conf`.  For this to work universally, you may need to edit `/etc/portage/repos.conf` and add:

```
[DEFAULT]
eclass-overrides = srcshelton
```

... to ensure that main-repo ebuilds benefit from the change.  The `LIBDIR` variables, and their default values, are:

```
LIBDIR_amd64="lib64"
LIBDIR_x32="libx32"
LIBDIR_x86="lib"
SYMLINK_LIB="yes"
```

... noting that `SYMLINK_LIB` defaults to `"no"` (e.g. do not try to symlink `/lib` and `/usr/lib` to the library directory which the ABI actually uses) for x32 profiles, and that these variables only affect multilib systems.

* app-admin/monit
    * Add required `--with-ssl-lib-dir` option
* app-crypt/mit-krb5
    * Ensure that AES assembly is built for x32 rather than amd64
* app-antivirus/clamav
    * Don't use (64-bit) assembly if `__ILP32__` is defined
* dev-db/libdbi-drivers
    * Add required `--with-dbi-libdir` option
* dev-lang/ruby
    * Avoid inline assembly with x32 ABI
* dev-util/cmake
    * Add (x)32 library paths in addition to 64-bit variants
* media-libs/flac
    * Avoid link failures due to 32 bit downgrade with x32 ABI
* media-libs/graphviz
    * Ensure that correct lib directory is searched
* net-analyzer/arp-sk
    * Look for libnet in the appropriate "libdir" rather than `lib`
* net-dns/bind-tools
    * Correct many instances of hard-coded references to `lib`
* net-misc/miniupnpd
    * Prevent use of `sysctl` syscall (which specifically errors on x32, but is deprecated for all ABIs)
* net-misc/openssh
    * Add experimental `libseccomp` patch, and on x32 either use this or fallback to `rlimit` sandbox.  Without one of these changes, `sshd` is non-functional on x32
* sys-apps/baselayout
    * Don't error-out if using `lib32` for x32 libraries
* sys-apps/cpuid
    * Don't use 64-bit assembly if `__ILP32__` is defined
* sys-devel/binutils
    * Allow `LIBDIR_*` variables to override hard-coded default directory locations
* sys-devel/gcc
    * Allow `LIBDIR_*` variables to override hard-coded default directory locations
* sys-libs/glibc
    * Allow `LIBDIR_*` variables to override hard-coded default directory locations (for x86 only)

# Fixes for `udev` and to allow separate `/usr`
(... and/or operation without a `/run` directory)

* net-wireless/bluez
    * Make 'udev' an optional dependency, controlled by `USE="udev"`
* sys-apps/coreutils
    * Add `uniq` to the list of binaries moved to `/bin`, as some init scripts (such as `device-mapper`) rely on it being present during early-boot
* sys-apps/gawk
    * Install to `/bin` rather than `/usr/bin`, for init scripts which invoke `awk`
* sys-apps/openrc
    * Add optional `USE="varrun"` flag to allow 'run' directory to remain as '/var/run'
* sys-fs/cryptsetup
    * Make 'udev' an optional dependency, controlled by `USE="udev"`
* sys-fs/fuse
    * Avoid installing udev rules unless `USE="udev"` is specified
* sys-fs/lvm2
    * Make 'udev' an optional dependency, controlled by `USE="udev"`
* sys-fs/mdadm
    * Restore previous boot-time functionality, add support for module-loading from `/etc/mdadm/mdmod.conf`
* net-misc/netifrc
    * Avoid installing udev rules unless `USE="udev"` is specified
* sys-libs/libeudev
    * Provide `libudev` only without (e)udev daemon, for builds which require only the library component of udev
* sys-process/procps
    * Maintain compatibility with releases prior to 3.3.11 by keeping `sysctl` in `/sbin`
* virtual/libudev
    * Allow sys-libs/libeudev to satisfy `virtual/libudev` dependency

