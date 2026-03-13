# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_P="${P}-Source"
inherit cmake-multilib

DESCRIPTION="SoX Resampler library"
HOMEPAGE="https://sourceforge.net/p/soxr/wiki/Home/"
SRC_URI="https://downloads.sourceforge.net/soxr/${MY_P}.tar.xz"
S="${WORKDIR}/${MY_P}"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~e2k"
IUSE="examples test"

# CMakeLists.txt builds examples if either test or examples USE flag is enabled.
REQUIRED_USE="test? ( examples )"
RESTRICT="!test? ( test )"

PATCHES=(
	"${FILESDIR}/${PN}-0.1.1-nodoc.patch"
	"${FILESDIR}/${P}-fix-pkgconfig.patch"
	"${FILESDIR}/${P}-cmake4.patch" # bug 951815
)

src_prepare() {
	cmake_src_prepare

	sed -i 's/__x86_64__/__e2k__/' src/pffft.c
	sed -i 's/void __cpuidex.*$/#elif 1\n#include <e2kbuiltin.h>/' src/soxr.c
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_EXAMPLES="$(usex examples)"
		-DBUILD_TESTS="$(usex test)"
	)

	case "${CHOST}" in
		e2k*)
			mycmakeargs+=(
				-DWITH_CR64S=FALSE
			)
		;;
	esac

	if use examples ; then
		mycmakeargs+=(
			-DDOC_INSTALL_DIR="/usr/share/doc/${PF}"
		)
	fi
	cmake-multilib_src_configure
}

src_install() {
	cmake-multilib_src_install
	if use examples ; then
		docompress -x /usr/share/doc/${PF}/examples
	fi
}
