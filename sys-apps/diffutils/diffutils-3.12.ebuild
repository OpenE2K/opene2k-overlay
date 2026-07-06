# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/diffutils.asc
inherit branding toolchain-funcs verify-sig

DESCRIPTION="Tools to make diffs and compare files"
HOMEPAGE="https://www.gnu.org/software/diffutils/"

if [[ ${PV} == *_p* ]] ; then
	# Subscribe to the 'platform-testers' ML to find these.
	# Useful to test on our especially more niche arches and report issues upstream.
	MY_COMMIT="11-7e53"
	MY_P=${PN}-$(ver_cut 1-2).${MY_COMMIT}
	SRC_URI="https://meyering.net/diff/${MY_P}.tar.xz"
	SRC_URI+=" verify-sig? ( https://meyering.net/diff/${MY_P}.tar.xz.sig )"
	S="${WORKDIR}"/${MY_P}
else
	SRC_URI="mirror://gnu/${PN}/${P}.tar.xz"
	SRC_URI+=" verify-sig? ( mirror://gnu/${PN}/${P}.tar.xz.sig )"
	KEYWORDS="~e2k"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="nls"

BDEPEND="
	nls? ( sys-devel/gettext )
	verify-sig? ( sec-keys/openpgp-keys-diffutils )
"
RDEPEND="
	nls? ( app-i18n/gnulib-l10n )
"

src_prepare() {
	default

	# stack-direction.m4 self-detects natively; only cross needs the e2k patch.
	if tc-is-cross-compiler; then
		eapply "${FILESDIR}"/${P}-e2k-stack-direction.patch
	fi
}

src_configure() {
	# Disable automagic dependency over libsigsegv; see bug #312351.
	export ac_cv_libsigsegv=no

	# required for >=glibc-2.26, bug #653914
	use elibc_glibc && export gl_cv_func_getopt_gnu=yes

	local myeconfargs=(
		# Interferes with F_S (sets F_S=2)
		--disable-gcc-warnings
		$(use_enable nls)
	)
	econf "${myeconfargs[@]}"
}
