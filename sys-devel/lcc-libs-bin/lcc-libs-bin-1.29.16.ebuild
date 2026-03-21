EAPI=8

inherit unpacker

DESCRIPTION="MCST lcc compiler runtime binary"
HOMEPAGE="https://dev.mcst.ru"
SRC_URI="https://setwd.ws/sp/${PV%.*}/${PV}/native/${CPU_MODEL}/lcc-libs_${PV}-vd9u45_e2k-${CPU_MODEL:1}.deb"
LICENSE="MCST"
S="${WORKDIR}"
SLOT="0"
KEYWORDS="~e2k"

src_prepare() {
	[ -z "${CPU_MODEL}" ] && "set CPU_MODEL variable in make.conf!"

	default
}

src_unpack() {
	unpack_deb ${A}
}

src_install() {
	# if only there was a simpler way to do this
	# LOL

	insinto /usr
	insopts -m755
	doins -r usr/lib{32,64,128}
}
