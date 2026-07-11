# Copyright 2026 OpenE2K
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: rust-target.eclass
# @MAINTAINER:
# Alibek Omarov
# @SUPPORTED_EAPIS: 8
# @BLURB: install MCST prebuilt rust-bin toolchains, keyed on LCC_TARGET
# @DESCRIPTION:
# shared logic for dev-lang/rust-bin

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI} unsupported" ;;
esac

inherit lcc-target

LICENSE="|| ( MIT Apache-2.0 )"
SLOT="${PV}"
IUSE+=" +clippy +doc +rustfmt rust-analyzer rust-src"

RDEPEND+="
	>=app-eselect/eselect-rust-20190311
	dev-libs/openssl-compat:1.1.1
"

# prebuilt binaries, stripping them may break rustc
RESTRICT="strip"
QA_PREBUILT="opt/${P}/.*"

# @FUNCTION: rust-target_triple
# @DESCRIPTION:
# Due to how rust binaries are uploaded and named, convert LCC_TARGET
# to currently available builds. e8c2 is special because there is now e8c2 tuned build
rust-target_triple() {
	local flag isa
	flag=$(lcc-target_selected)
	[[ ${flag} == e8c2 ]] && { echo "e2k8c2-unknown-linux-gnu"; return; }
	isa=$(lcc-target_isa "${flag}") || return 1
	echo "e2k${isa%%.*}-unknown-linux-gnu"
}

# @FUNCTION: rust-target_isa_src_uri
# @USAGE: <baseurl>
# @DESCRIPTION:
# generate SRC_URI
rust-target_isa_src_uri() {
	local baseurl=${1}
	local entry flag dir suffix isa

	for entry in "${LCC_TARGET_MAP[@]}"; do
		IFS=: read -r flag dir suffix isa <<<"${entry}"
		[[ ${flag} == e8c2 ]] && continue
		SRC_URI+="
			lcc_target_${flag}? (
				${baseurl}/rust-${PV}-e2k${isa%%.*}-unknown-linux-gnu.tar.xz
			)
		"
	done
}

# @FUNCTION: rust-target_isa_required_use
# @DESCRIPTION:
# we can have slightly more newer rust but only on e8c2 for now
rust-target_isa_required_use() {
	local entry flag out=""
	for entry in "${LCC_TARGET_MAP[@]}"; do
		flag=${entry%%:*}
		[[ ${flag} == e8c2 ]] && continue
		out+=" lcc_target_${flag}"
	done
	echo "^^ (${out} )"
}

rust-target_src_unpack() {
	default_src_unpack
	mv "${WORKDIR}/rust-${PV}-$(rust-target_triple)" "${S}" || die
}

rust-target_src_install() {
	cd "${S}" || die

	local std components
	std=$(grep '^rust-std' ./components) || die "rust-std not found in components"
	components="rustc,cargo,${std}"
	use doc && components+=",rust-docs"
	use clippy && components+=",clippy-preview"
	use rustfmt && components+=",rustfmt-preview"
	if use rust-analyzer; then
		local analysis
		analysis=$(grep '^rust-analysis' ./components) || die "rust-analysis not found in components"
		components+=",rust-analyzer-preview,${analysis}"
	fi
	if use rust-src; then
		mv "${WORKDIR}/rust-src-${PV}/rust-src" "${S}" || die
		echo rust-src >> ./components || die
		components+=",rust-src"
	fi

	./install.sh \
		--components="${components}" \
		--disable-verify \
		--disable-ldconfig \
		--prefix="${ED}/opt/${P}" \
		--mandir="${ED}/opt/${P}/man" || die

	docompress /opt/${P}/man/

	# eselect-rust picks the active toolchain by these version-tagged names
	local symlinks=( cargo rustc rustdoc rust-gdb rust-gdbgui rust-lldb )
	use clippy && symlinks+=( clippy-driver cargo-clippy )
	use rustfmt && symlinks+=( rustfmt cargo-fmt )
	use rust-analyzer && symlinks+=( rust-analyzer )

	local i ver_i
	for i in "${symlinks[@]}"; do
		ver_i="${i}-bin-${SLOT}"
		ln "${ED}/opt/${P}/bin/${i}" "${ED}/opt/${P}/bin/${ver_i}" || die
		dosym -r "/opt/${P}/bin/${ver_i}" "/usr/bin/${ver_i}"
	done

	dosym -r "/opt/${P}/lib" "/usr/lib/rust/lib-bin-${SLOT}"
	dosym -r "/opt/${P}/man" "/usr/lib/rust/man-bin-${SLOT}"
	dosym -r "/opt/${P}/lib/rustlib" "/usr/lib/rustlib-bin-${SLOT}"
	dosym -r "/opt/${P}/share/doc/rust" "/usr/share/doc/${P}"

	cat <<-_EOF_ > "${T}/50${P}"
		MANPATH="${EPREFIX}/usr/lib/rust/man-bin-${SLOT}"
	_EOF_
	doenvd "${T}/50${P}"

	# eselect-rust prepends EROOT to these paths
	cat <<-_EOF_ > "${T}/provider-${PN}-${SLOT}"
	/usr/bin/cargo
	/usr/bin/rustdoc
	/usr/bin/rust-gdb
	/usr/bin/rust-gdbgui
	/usr/bin/rust-lldb
	/usr/lib/rustlib
	/usr/lib/rust/lib
	/usr/lib/rust/man
	/usr/share/doc/rust
	_EOF_
	use clippy && printf '%s\n' /usr/bin/clippy-driver /usr/bin/cargo-clippy >> "${T}/provider-${PN}-${SLOT}"
	use rustfmt && printf '%s\n' /usr/bin/rustfmt /usr/bin/cargo-fmt >> "${T}/provider-${PN}-${SLOT}"
	use rust-analyzer && echo /usr/bin/rust-analyzer >> "${T}/provider-${PN}-${SLOT}"

	insinto /etc/env.d/rust
	doins "${T}/provider-${PN}-${SLOT}"
}

rust-target_pkg_postinst() {
	eselect rust update
}

rust-target_pkg_postrm() {
	eselect rust cleanup
}

EXPORT_FUNCTIONS src_unpack src_install pkg_postinst pkg_postrm
