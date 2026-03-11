EAPI=8

inherit unpacker

DESCRIPTION="MCST lcc compiler runtime binary"
HOMEPAGE="https://dev.mcst.ru"
SRC_URI="https://setwd.ws/sp/${PV%.*}/${PV}/native/${ABI}/lcc-libs_${PV}-vd9u45_e2k-4c.deb"
LICENSE="MCST"
S="${WORKDIR}"
SLOT="0"
KEYWORDS="~e2k"

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
