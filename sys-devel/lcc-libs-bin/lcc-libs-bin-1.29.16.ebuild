EAPI=8

inherit lcc-target unpacker

DESCRIPTION="MCST lcc compiler runtime binary"
HOMEPAGE="https://dev.mcst.ru"

lcc-target_native_src_uri lcc-libs vd9u45

S="${WORKDIR}"
LICENSE="MCST"
SLOT="0"
KEYWORDS="~e2k"
REQUIRED_USE="^^ ( ${LCC_TARGET_IUSE} )"

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
