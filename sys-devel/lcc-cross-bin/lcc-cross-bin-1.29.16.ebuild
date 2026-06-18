# Copyright 2026 OpenE2K
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="MCST lcc cross-compiler binary"
HOMEPAGE="https://dev.mcst.ru"
LICENSE="MCST"
SLOT="0"
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

# most of deps are for binutils and gdb builds, in the future we could build them ourselves
RDEPEND="
	app-arch/xz-utils
	app-arch/zstd
	dev-libs/boehm-gc
	dev-libs/xxhash
	dev-scheme/guile:3.0
	sys-libs/ncurses:0/6
"

src_install() {
	local flag isa
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
		esac

		dodir /opt/mcst
		# preserve modes/symlinks but not the tarball's foreign uid/gid
		cp -a --no-preserve=ownership "${S}/opt/mcst/lcc-${PV}.e2k-${isa}.linux-6.1" "${ED}"/opt/mcst/ || die
	done
}
