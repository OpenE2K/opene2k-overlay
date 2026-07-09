# Copyright 2026 OpenE2K
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Catalyst arch definition and qemu interpreter for building e2k stages"
HOMEPAGE="https://github.com/OpenE2K/opene2k-overlay"
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~e2k"
IUSE="qemu"

RDEPEND="
	dev-util/catalyst
	qemu? ( app-emulation/qemu-e2k[static-user] )
"

src_install() {
	insinto /usr/share/catalyst/arch
	doins "${FILESDIR}"/e2k.toml

	insinto /usr/share/catalyst/spec/e2k
	doins "${FILESDIR}"/*.spec.example

	insinto /usr/share/catalyst/confdir
	doins -r "${FILESDIR}"/confdir/e2k-v3
	doins -r "${FILESDIR}"/confdir/e2k-e4c
	doins -r "${FILESDIR}"/confdir/e2k-e8c2
}
