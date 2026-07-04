EAPI=8

inherit lcc-target unpacker

DESCRIPTION="MCST lcc compiler binary"
HOMEPAGE="https://dev.mcst.ru"

lcc-target_native_src_uri lcc vd9u3

S="${WORKDIR}"
LICENSE="MCST"
SLOT="0"
KEYWORDS="~e2k"
REQUIRED_USE="^^ ( ${LCC_TARGET_IUSE} )"

# for now, use prebuilt version of compiler runtime
RDEPEND="~sys-devel/lcc-libs-bin-${PV}"

src_unpack() {
	unpack_deb ${A}
}

src_install() {
	# home dir name follows the target (e2k-4c-linux, e2k-8c-linux, ...)
	local home=( opt/mcst/lcc-home/${PV}/e2k-*-linux )
	home=${home[0]}
	[[ -d ${home} ]] || die "lcc-home target dir not found"

	einstalldocs opt/mcst/doc/lcc
	doman opt/mcst/man/man1/{lcc.1,ldis.1}

	exeinto /opt/mcst/bin
	doexe opt/mcst/bin/{cpp,l++,lcc,ldis,lfortran}

	exeinto "/${home}/bin"
	doexe "${home}"/bin/{ecc,ecc64,ecc128,ecf_opt,ecf_opt64,ecf_opt128,eprof,ldis,ldis64,libffe.so}

	insinto "/${home}/"
	doins -r "${home}"/{include,lib32,lib64,lib128,mod}

	# symlinks to /opt/mcst/bin
	insinto /usr/bin
	doins usr/bin/{c++,cc,cpp,g++,gcc,gfortran}

	# compatibility symlinks
	for i in cc ++ fortran; do
		dosym -r /opt/mcst/bin/l$i /usr/bin/l$i
		dosym -r /opt/mcst/bin/l$i /usr/bin/${CHOST}-g$i
		dosym -r /opt/mcst/bin/l$i /usr/bin/${CHOST}-l$i
	done
}
