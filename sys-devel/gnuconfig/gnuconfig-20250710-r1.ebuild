# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Updated config.sub and config.guess file from GNU"
HOMEPAGE="https://savannah.gnu.org/projects/config"
SRC_URI="https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}.tar.xz"
S="${WORKDIR}"

LICENSE="GPL-3+-with-autoconf-exception"
SLOT="0"
KEYWORDS="~amd64 ~e2k"

PATCHES=( "${FILESDIR}"/gnuconfig-e2k-abis.patch )

src_install() {
	insinto /usr/share/${PN}
	doins config.{sub,guess}
	fperms +x /usr/share/${PN}/config.{sub,guess}
	dodoc ChangeLog
}
