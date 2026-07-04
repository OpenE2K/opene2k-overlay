# Copyright 2026 OpenE2K
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit lcc-target

DESCRIPTION="MCST lcc cross-compiler binary"
HOMEPAGE="https://dev.mcst.ru"

lcc-target_cross_src_uri

S="${WORKDIR}"
LICENSE="MCST"
SLOT="$(ver_cut 1-2)"
KEYWORDS="~amd64"
IUSE+=" bundled-gdb"
REQUIRED_USE="|| ( ${LCC_TARGET_IUSE} )"

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
	local target isa sdk btdir f tool

	for target in $(lcc-target_selected); do
		isa=$(lcc-target_isa "${target}")
		sdk="lcc-${PV}.e2k-${isa}.linux-6.1"

		dodir /opt/mcst
		# preserve modes/symlinks but not the tarball's foreign uid/gid
		cp -a --no-preserve=ownership "${S}/opt/mcst/${sdk}" "${ED}"/opt/mcst/ || die

		# Replace the bundled binutils with symlinks to our own cross binutils
		# (e2k-mcst-linux-gnu-*); lcc reaches them via $SDK/binutils relative to
		# itself. bin.toolchain/e2k-linux-* already point into binutils/bin.
		btdir="${ED}/opt/mcst/${sdk}/binutils"
		for f in "${btdir}"/bin/e2k-linux-*; do
			tool=${f##*/e2k-linux-}
			ln -sf "${EPREFIX}/usr/bin/e2k-mcst-linux-gnu-${tool}" "${f}" || die
		done
		for f in "${btdir}"/e2k-linux/bin/*; do
			tool=${f##*/}
			ln -sf "${EPREFIX}/usr/bin/e2k-mcst-linux-gnu-${tool}" "${f}" || die
		done

		# drop the bundled gdb unless kept; cross-*/gdb (RDEPEND) is used
		# instead and nothing reaches into $SDK/gdb, so no symlinks needed
		if ! use bundled-gdb; then
			rm -r "${ED}/opt/mcst/${sdk}/gdb" || die
		fi
	done
}
