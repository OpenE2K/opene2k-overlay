# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit multilib-minimal

DESCRIPTION="Audio codec to connect bluetooth HQ audio devices as headphones or loudspeakers"
HOMEPAGE="https://git.kernel.org/?p=bluetooth/sbc.git"
SRC_URI="https://www.kernel.org/pub/linux/bluetooth/${P}.tar.xz"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~e2k"
IUSE="static-libs"

# --enable-tester is building src/sbctester but the tarball is missing required
# .wav file to execute it
RESTRICT="test"

BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}/${PN}-1.5-ifdef-builtin.patch"
	"${FILESDIR}/${PN}-2.1-arm-c23.patch"
)

src_prepare() {
	default
	# lcc doesn't understand -fgcse-after-reload (the rest of the opt flags are fine)
	sed -i -e 's/-fgcse-after-reload//' Makefile.am Makefile.in || die
}

multilib_src_configure() {
	ECONF_SOURCE=${S} \
	econf \
		$(use_enable static-libs static) \
		--disable-tester
}

multilib_src_install_all() {
	einstalldocs
	find "${D}" -name '*.la' -delete || die
}
