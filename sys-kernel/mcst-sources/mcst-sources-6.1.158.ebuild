# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 OpenE2K
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="190"

inherit kernel-2
detect_version
detect_arch

MCST_PV="1.9"
MY_P=linux-${PV}
EXTRAVERSION="-mcst-${MCST_PV}"
KV_FULL="${OKV}${EXTRAVERSION}"
S="${WORKDIR}/linux-${KV_FULL}"
KV="${KV_FULL}"

DESCRIPTION="Full sources including the MCST patchset for the ${KV_MAJOR}.${KV_MINOR} kernel tree"
HOMEPAGE="https://github.com/OpenE2K/linux"
SRC_URI="https://github.com/OpenE2K/linux/archive/refs/tags/v${PV}.tar.gz -> ${MY_P}.tar.gz"
KEYWORDS="~e2k"
IUSE="experimental"

src_unpack() {
	default
	mv "${WORKDIR}/${MY_P}" "${S}" || die
	unpack_set_extraversion
	unpack_fix_install_path
}

pkg_postinst() {
	kernel-2_pkg_postinst
	einfo "For more info on this patchset, and how to report problems, see:"
	einfo "${HOMEPAGE}"
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
