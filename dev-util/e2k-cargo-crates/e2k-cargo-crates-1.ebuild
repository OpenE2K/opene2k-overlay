# Copyright 2026 OpenE2K
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="e2k forks of Rust crates, for cargo-overrides"
HOMEPAGE="https://github.com/helce"

LICENSE="|| ( Apache-2.0 MIT )"
SLOT="0"
KEYWORDS="~e2k"

E2K_CARGO_CRATES=(
	# crate|version|repourl|gitref|subpath
	"linux-raw-sys|0.12.1|https://github.com/helce/linux-raw-sys|v0.12.1|."
	"rustix|1.1.4|https://github.com/helce/rustix|v1.1.4|."
	"libc|0.2.185|https://github.com/helce/libc|0.2.185|."
	"nix|0.31.2|https://github.com/helce/nix|v0.31.2|."
	"ring|0.17.14|https://github.com/helce/ring|0.17.14|."
	"target-lexicon|0.13.5|https://github.com/helce/target-lexicon|v0.13.5|."
	"cc|1.2.60|https://github.com/helce/cc-rs|cc-v1.2.60|."
	"find-msvc-tools|0.1.9|https://github.com/helce/cc-rs|find-msvc-tools-v0.1.9|find-msvc-tools"
	"psm|0.1.30|https://github.com/helce/stacker|psm-0.1.30|psm"
	"stacker|0.1.23|https://github.com/helce/stacker|stacker-0.1.23|."
)

EGIT_CLONE_TYPE="shallow"
S="${WORKDIR}"

src_unpack() {
	local entry crate ver url ref sub
	for entry in "${E2K_CARGO_CRATES[@]}"; do
		IFS='|' read -r crate ver url ref sub <<<"${entry}"
		local EGIT_REPO_URI="${url}"
		local EGIT_COMMIT="${ref}"
		local EGIT_CHECKOUT_DIR="${WORKDIR}/${crate}/${ver}"
		git-r3_src_unpack
	done
}

src_install() {
	local base=/usr/src/e2k-cargo-crates entry crate ver url ref sub path key
	dodir "${base}"
	echo "# e2k-cargo" > "${ED}${base}/patch.toml" || die
	for entry in "${E2K_CARGO_CRATES[@]}"; do
		IFS='|' read -r crate ver url ref sub <<<"${entry}"
		dodir "${base}/${crate}"
		cp -r "${WORKDIR}/${crate}/${ver}" "${ED}${base}/${crate}/" || die
		path="${base}/${crate}/${ver}"
		[[ ${sub} == . ]] || path+="/${sub}"
		key="${crate//[-.]/_}_${ver//./_}"
		echo "${key} = { package = \"${crate}\", path = \"${path}\" }" >> "${ED}${base}/patch.toml" || die
	done
}
