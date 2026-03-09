EAPI=8

inherit unpacker

# turn e4c into 4c
CPU=${ABI:1}

DESCRIPTION="MCST lcc compiler binary"
HOMEPAGE="https://dev.mcst.ru"
SRC_URI="https://setwd.ws/sp/${PV%.*}/${PV}/native/${ABI}/lcc_${PV}-vd9u3_e2k-${CPU}.deb"
LICENSE="MCST"
S="${WORKDIR}"
SLOT="0"
KEYWORDS="e2k"

# for now, use prebuilt version of compiler runtime
RDEPEND="=sys-devel/lcc-libs-bin-${PV}"

src_unpack() {
	unpack_deb ${A}
}

src_install() {
	einstalldocs opt/mcst/doc/lcc
	doman opt/mcst/man/man1/{lcc.1,ldis.1}

	exeinto /opt/mcst/bin
	doexe opt/mcst/bin/{cpp,l++,lcc,ldis,lfortran}

	exeinto /opt/mcst/lcc-home/${PV}/e2k-${CPU}-linux/bin
	doexe opt/mcst/lcc-home/${PV}/e2k-${CPU}-linux/bin/{ecc,ecc64,ecc128,ecf_opt,ecf_opt64,ecf_opt128,eprof,ldis,ldis64,libffe.so}

	insinto /opt/mcst/lcc-home/${PV}/e2k-${CPU}-linux/
	doins -r opt/mcst/lcc-home/${PV}/e2k-${CPU}-linux/{include,lib32,lib64,lib128,mod}

	# symlinks to /opt/mcst/bin
	insinto /usr/bin
	doins usr/bin/{c++,cc,cpp,g++,gcc,gfortran}

	# compatibility symlinks
	for i in cc ++ fortran; do
		dosym /opt/mcst/bin/l$i /usr/bin/l$i
		dosym /opt/mcst/bin/l$i /usr/bin/${CHOST}-g$i
		dosym /opt/mcst/bin/l$i /usr/bin/${CHOST}-l$i
	done
}
