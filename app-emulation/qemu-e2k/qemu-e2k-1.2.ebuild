# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
PYTHON_REQ_USE="ensurepip(-),ncurses,readline"

inherit toolchain-funcs python-r1 udev readme.gentoo-r1 pax-utils xdg-utils

COMMIT="1d7a291c46dc89aa14741776c234a4194a1c9637"
MY_P="qemu-${COMMIT}"
SRC_URI="https://git.openelbrus.ru/mcst/qemu/-/archive/${COMMIT}/${MY_P}.tar.bz2"

# the gitlab archive ships the meson wrap files but not the subproject sources.
# fetch the pinned revisions (identical to upstream qemu) and drop them into
# subprojects/, otherwise qemu refuses to build a "non-GIT" tree.
declare -A SUBPROJECTS=(
	[keycodemapdb]="f5772a62ec52591ff6870b7e8ef32482371f22c6"
	[berkeley-softfloat-3]="b64af41c3276f97f0e181920400ee056b9c88037"
	[berkeley-testfloat-3]="e7af9751d9f9fd3b47911f51a5cfd08af256a9ab"
)
for proj in "${!SUBPROJECTS[@]}"; do
	SRC_URI+=" https://gitlab.com/qemu-project/${proj}/-/archive/${SUBPROJECTS[${proj}]}/${proj}-${SUBPROJECTS[${proj}]}.tar.bz2"
done
unset proj

S="${WORKDIR}/${MY_P}"
KEYWORDS="~amd64"

DESCRIPTION="QEMU + Kernel-based Virtual Machine userland tools"
HOMEPAGE="https://www.qemu.org https://www.linux-kvm.org"

LICENSE="GPL-2 LGPL-2 BSD-2"
SLOT="0"

IUSE="debug nls plugins selinux static-user systemtap valgrind xattr"

IUSE_USER_TARGETS="
	e2k
"

use_user_targets=$(printf ' +qemu_user_targets_%s' ${IUSE_USER_TARGETS})
IUSE+=" ${use_user_targets}"

# Block USE flag configurations known to not work.
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	static-user? ( !plugins )
	plugins? ( !static-user )
"

# Dependencies required for qemu tools (qemu-nbd, qemu-img, qemu-io, ...)
# and user/softmmu targets (qemu-*, qemu-system-*).
#
# Yep, you need both libcap and libcap-ng since virtfs only uses libcap.
#
# The attr lib isn't always linked in (although the USE flag is always
# respected).  This is because qemu supports using the C library's API
# when available rather than always using the external library.
ALL_DEPEND="
	dev-libs/glib:2[static-libs(+)]
	virtual/zlib:=[static-libs(+)]
	systemtap? ( dev-debug/systemtap )
	xattr? ( sys-apps/attr[static-libs(+)] )
"

# See bug #913084 for pip dep
BDEPEND="
	${PYTHON_DEPS}
	dev-python/distlib[${PYTHON_USEDEP}]
	dev-lang/perl
	>=dev-build/meson-0.63.0
	app-alternatives/ninja
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
"
CDEPEND="
	${ALL_DEPEND//\[static-libs(+)]}
"
DEPEND="
	${CDEPEND}
	kernel_linux? ( >=sys-kernel/linux-headers-2.6.35 )
	static-user? ( ${ALL_DEPEND} )
	valgrind? ( dev-debug/valgrind )
"
RDEPEND="
	${CDEPEND}
	selinux? (
		sec-policy/selinux-qemu
		sys-libs/libselinux
	)
"

QA_WX_LOAD="
	usr/bin/qemu-e2k
"

DOC_CONTENTS="If you want to register binfmt handlers for qemu-e2k user targets:
For openrc:
	# rc-update add qemu-e2k-binfmt
For systemd:
	# ln -s /usr/share/qemu-e2k/binfmt.d/qemu-e2k.conf /etc/binfmt.d/qemu-e2k.conf"

src_unpack() {
	default

	local proj
	cd "${WORKDIR}" || die
	for proj in "${!SUBPROJECTS[@]}"; do
		mv "${proj}-${SUBPROJECTS[${proj}]}" "${S}/subprojects/${proj}" || die
	done
	cd "${S}" || die
	meson subprojects packagefiles --apply || die
}

src_prepare() {
	default

	# Use correct toolchain to fix cross-compiling
	tc-export AR AS LD NM OBJCOPY PKG_CONFIG RANLIB STRINGS
	export WINDRES=${CHOST}-windres

	# Workaround for bug #938302
	if use systemtap && has_version "dev-debug/systemtap[-dtrace-symlink(+)]" ; then
		cat >> "${S}"/configs/meson/linux.txt <<-EOF || die
		[binaries]
		dtrace='stap-dtrace'
		EOF
	fi

	# Verbose builds
	MAKEOPTS+=" V=1"
}

##
# configures qemu based on the build directory and the build type
# we are using.
#
qemu_src_configure() {
	debug-print-function ${FUNCNAME} "$@"

	local buildtype=$1
	local builddir="${S}/${buildtype}-build"

	mkdir "${builddir}" || die

	local conf_opts=(
		--prefix=/usr
		--sysconfdir=/etc
		--bindir=/usr/bin
		--libdir=/usr/$(get_libdir)
		--datadir=/usr/share
		--docdir=/usr/share/doc/${PF}/html
		--mandir=/usr/share/man
		--localstatedir=/var
		--disable-bsd-user
		--disable-containers # bug #732972
		--disable-guest-agent
		--disable-strip
		--disable-download
		--python="${PYTHON}"

		# bug #746752: TCG interpreter has a few limitations:
		# - it does not support FPU
		# - it's generally slower on non-self-modifying code
		# It's advantage is support for host architectures
		# where native codegeneration is not implemented.
		# Gentoo has qemu keyworded only on targets with
		# native code generation available. Avoid the interpreter.
		--disable-tcg-interpreter

		--disable-werror
		# We support gnutls/nettle for crypto operations.  It is possible
		# to use gcrypt when gnutls/nettle are disabled (but not when they
		# are enabled), but it's not really worth the hassle.  Disable it
		# all the time to avoid automatically detecting it. #568856
		--disable-gcrypt
		--cc="$(tc-getCC)"
		--cxx="$(tc-getCXX)"
		--objcc="$(tc-getCC)"
		--host-cc="$(tc-getBUILD_CC)"

		$(use_enable debug debug-info)
		$(use_enable debug debug-tcg)
		$(use_enable nls gettext)
		$(use_enable plugins)
		$(use_enable selinux)
		$(use_enable xattr attr)
		$(use_enable valgrind)
	)

	conf_opts+=(
		--disable-brlapi
		--disable-linux-aio
		--disable-bzip2
		--disable-capstone
		--disable-curl
		--disable-docs
		--disable-fdt
		--disable-fuse
		--disable-glusterfs
		--disable-gnutls
		--disable-nettle
		--disable-gtk
		--disable-rdma
		--disable-libiscsi
		--disable-linux-io-uring
		--disable-vnc-jpeg
		--disable-kvm
		--disable-libkeyutils
		--disable-lzo
		--disable-mpath
		--disable-curses
		--disable-libnfs
		--disable-numa
		--disable-opengl
		--disable-auth-pam
		--disable-passt
		--disable-png
		--disable-rbd
		--disable-vnc-sasl
		--disable-sdl
		--disable-seccomp
		--disable-slirp
		--disable-smartcard
		--disable-snappy
		--disable-spice
		--disable-libssh
		--disable-libudev
		--disable-libusb
		--disable-usb-redir
		--disable-vde
		--disable-vhost-net
		--disable-virglrenderer
		--disable-vnc
		--disable-vte
		--disable-xen
		--disable-xen-pci-passthrough
		# use prebuilt keymaps, bug #759604
		--disable-xkbcommon
		--disable-zstd
	)

	case ${buildtype} in
	user)
		conf_opts+=(
			--enable-linux-user
			--disable-system
			--disable-tools
			--disable-cap-ng
			--disable-seccomp
		)
		local static_flag="static-user"
		;;
	esac

	local targets="${buildtype}_targets"
	[[ -n ${targets} ]] && conf_opts+=( --target-list="${!targets}" )

	# Add support for SystemTap
	use systemtap && conf_opts+=( --enable-trace-backends="dtrace" )

	# We always want to attempt to build with PIE support as it results
	# in a more secure binary. But it doesn't work with static or if
	# the current GCC doesn't have PIE support.
	if [[ ${static_flag} != "none" ]] && use ${static_flag}; then
		conf_opts+=( --static --disable-pie )
	else
		tc-enables-pie && conf_opts+=( --enable-pie )
	fi

	# Meson will not use a cross-file unless cross_prefix is set.
	tc-is-cross-compiler && conf_opts+=( --cross-prefix="${CHOST}-" )

	# Plumb through equivalent of EXTRA_ECONF to allow experiments
	# like bug #747928.
	conf_opts+=( ${EXTRA_CONF_QEMU} )

	echo "../configure ${conf_opts[*]}"
	cd "${builddir}"
	../configure "${conf_opts[@]}" || die "configure failed"
}

src_configure() {
	local target

	python_setup

	user_targets=

	for target in ${IUSE_USER_TARGETS} ; do
		if use "qemu_user_targets_${target}"; then
			user_targets+=",${target}-linux-user"
		fi
	done

	user_targets=${user_targets#,}

	[[ -n ${user_targets}    ]] && qemu_src_configure "user"
}

src_compile() {
	if [[ -n ${user_targets} ]]; then
		cd "${S}/user-build" || die
		default
	fi
}

src_install() {
	if [[ -n ${user_targets} ]]; then
		cd "${S}/user-build"
		emake DESTDIR="${ED}" install

		# drop the system-emulation blobs, firmware, etc
		rm -r "${ED}/usr/share/qemu" || die

		# install binfmt handler init script for user targets.
		newinitd "${FILESDIR}"/qemu-e2k-binfmt.initd qemu-e2k-binfmt

		# install binfmt/qemu-e2k.conf.
		insinto "/usr/share/qemu-e2k/binfmt.d"
		doins "${FILESDIR}"/qemu-e2k.conf
	fi

	cd "${S}" || die
	dodoc MAINTAINERS

	DISABLE_AUTOFORMATTING=true
	readme.gentoo_create_doc
}

pkg_postinst() {
	xdg_icon_cache_update

	DISABLE_AUTOFORMATTING=true
	readme.gentoo_print_elog
}

pkg_postrm() {
	xdg_icon_cache_update
	udev_reload
}
