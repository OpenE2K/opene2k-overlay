# Copyright 2026 OpenE2K
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="MCST lcc cross-compiler binary"
HOMEPAGE="https://dev.mcst.ru"
LICENSE="MCST"
SLOT="$(ver_cut 1-2)"
KEYWORDS="~amd64"
S="${WORKDIR}"
IUSE="e4c e1c e8c e8c2 e16c e2c3 e2kv3 e2kv4 e2kv5 e2kv6"

SRC_URI="
	e4c? ( https://setwd.ws/sp/${PV%.*}/${PV}/cross-sp-${PV}.e2k-v3.4c.linux-6.1_64.tar.xz )
	e1c? ( https://setwd.ws/sp/${PV%.*}/${PV}/cross-sp-${PV}.e2k-v4.1c+.linux-6.1_64.tar.xz )
	e8c? ( https://setwd.ws/sp/${PV%.*}/${PV}/cross-sp-${PV}.e2k-v4.8c.linux-6.1_64.tar.xz )
	e8c2? ( https://setwd.ws/sp/${PV%.*}/${PV}/cross-sp-${PV}.e2k-v5.8c2.linux-6.1_64.tar.xz )
	e16c? ( https://setwd.ws/sp/${PV%.*}/${PV}/cross-sp-${PV}.e2k-v6.16c.linux-6.1_64.tar.xz )
	e2c3? ( https://setwd.ws/sp/${PV%.*}/${PV}/cross-sp-${PV}.e2k-v6.2c3.linux-6.1_64.tar.xz )
	e2kv3? ( https://setwd.ws/sp/${PV%.*}/${PV}/cross-sp-${PV}.e2k-v3.linux-6.1_64.tar.xz )
	e2kv4? ( https://setwd.ws/sp/${PV%.*}/${PV}/cross-sp-${PV}.e2k-v4.linux-6.1_64.tar.xz )
	e2kv5? ( https://setwd.ws/sp/${PV%.*}/${PV}/cross-sp-${PV}.e2k-v5.linux-6.1_64.tar.xz )
	e2kv6? ( https://setwd.ws/sp/${PV%.*}/${PV}/cross-sp-${PV}.e2k-v6.linux-6.1_64.tar.xz )
"

# require at least one target use flag
REQUIRED_USE="|| ( ${IUSE} )"
IUSE+=" bundled-gdb"

RDEPEND="
	cross-e2k-mcst-linux-gnu/binutils
	!bundled-gdb? ( cross-e2k-mcst-linux-gnu/gdb )
	bundled-gdb? (
		app-arch/xz-utils
		app-arch/zstd
		dev-libs/boehm-gc
		dev-libs/xxhash
		dev-scheme/guile:3.0
		sys-libs/ncurses:0/6
	)
"

src_install() {
	local flag isa
	local ntargets=0 single_isa=

	for flag in ${IUSE}; do
		use "${flag}" || continue
		case ${flag} in
			e4c) isa=v3.4c ;;
			e1c) isa=v4.1c+ ;;
			e8c) isa=v4.8c ;;
			e8c2) isa=v5.8c2 ;;
			e16c) isa=v6.16c ;;
			e2c3) isa=v6.2c3 ;;
			e2kv3) isa=v3 ;;
			e2kv4) isa=v4 ;;
			e2kv5) isa=v5 ;;
			e2kv6) isa=v6 ;;
			*) continue ;;
		esac

		# count how many cross compilers are enabled
		# if there is only one, we can install symlinks for compilers
		: $(( ntargets++ ))
		single_isa=${isa}

		dodir /opt/mcst
		# preserve modes/symlinks but not the tarball's foreign uid/gid
		cp -a --no-preserve=ownership "${S}/opt/mcst/lcc-${PV}.e2k-${isa}.linux-6.1" "${ED}"/opt/mcst/ || die

		# Replace the bundled binutils with symlinks to our own cross binutils
		# (e2k-mcst-linux-gnu-*); lcc reaches them via $SDK/binutils relative to
		# itself. bin.toolchain/e2k-linux-* already point into binutils/bin.
		local btdir="${ED}/opt/mcst/lcc-${PV}.e2k-${isa}.linux-6.1/binutils"
		local f tool
		for f in "${btdir}"/bin/e2k-linux-*; do
			tool=${f##*/e2k-linux-}
			ln -sf "${EPREFIX}/usr/bin/e2k-mcst-linux-gnu-${tool}" "${f}" || die
		done
		for f in "${btdir}"/e2k-linux/bin/*; do
			tool=${f##*/}
			ln -sf "${EPREFIX}/usr/bin/e2k-mcst-linux-gnu-${tool}" "${f}" || die
		done

		# do the same for gdb if bundled-gdb flag is not enabled
		if ! use bundled-gdb; then
			for f in "${ED}/opt/mcst/lcc-${PV}.e2k-${isa}.linux-6.1/gdb/bin"/e2k-linux-*; do
				tool=${f##*/e2k-linux-}
				ln -sf "${EPREFIX}/usr/bin/e2k-mcst-linux-gnu-${tool}" "${f}" || die
			done
		fi
	done

	if [[ ${ntargets} -eq 1 ]]; then
		local sdkbin="/opt/mcst/lcc-${PV}.e2k-${single_isa}.linux-6.1/bin"
		local i
		for i in cc ++ fortran; do
			dosym "${sdkbin}/l${i}" "/usr/bin/e2k-mcst-linux-gnu-g${i}"
			dosym "${sdkbin}/l${i}" "/usr/bin/e2k-mcst-linux-gnu-l${i}"
		done
		dosym "${sdkbin}/lcc" "/usr/bin/e2k-mcst-linux-gnu-cc"
		dosym "${sdkbin}/l++" "/usr/bin/e2k-mcst-linux-gnu-c++"
		dosym "${sdkbin}/cpp" "/usr/bin/e2k-mcst-linux-gnu-cpp"
	else
		ewarn "for crossdev setup we need symlinks to the compilers"
		ewarn "but the names are ISA version independent"
		ewarn "select only ONE target to get the symlinks"
		ewarn "or suggest an idea how to handle this better :)"
	fi
}
