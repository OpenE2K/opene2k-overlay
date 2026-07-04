# Copyright 2026 OpenE2K
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit lcc-target

DESCRIPTION="crossdev driver wrappers for the MCST lcc cross-compiler"
HOMEPAGE="https://dev.mcst.ru"

S="${WORKDIR}"
LICENSE="GPL-3+"
SLOT="$(ver_cut 1-2)"
KEYWORDS="~amd64"
REQUIRED_USE="^^ ( ${LCC_TARGET_IUSE} )"

RDEPEND="$(lcc-target_cross_bin_dep)"

src_install() {
	local target isa sdkbin

	target=$(lcc-target_selected)
	isa=$(lcc-target_isa "${target}")
	sdkbin="/opt/mcst/lcc-${PV}.e2k-${isa}.linux-6.1/bin"

	install_driver() {
		local name=${1}
		local binary=${2}

		sed "s|@LCC@|${EPREFIX}${sdkbin}/${binary}|g" \
			"${FILESDIR}"/lcc-cross-wrapper.sh.in > "${T}/${name}" || die

		exeinto /usr/bin
		newexe "${T}/${name}" "e2k-mcst-linux-gnu-${name}"
	}

	install_driver gcc      lcc
	install_driver cc       lcc
	install_driver lcc      lcc
	install_driver g++      l++
	install_driver c++      l++
	install_driver l++      l++
	install_driver gfortran lfortran
	install_driver lfortran lfortran
	dosym "${sdkbin}/cpp" "/usr/bin/e2k-mcst-linux-gnu-cpp"
}
