# Copyright 2026 OpenE2K
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: lcc-target.eclass
# @MAINTAINER:
# OpenE2K
# @SUPPORTED_EAPIS: 8
# @BLURB: LCC_TARGET USE_EXPAND handling for the MCST lcc packages

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI} unsupported" ;;
esac

# @ECLASS_VARIABLE: LCC_TARGET_MAP
# @INTERNAL
# @DESCRIPTION:
# flag:native-dir:native-cpu-suffix:cross-isa
LCC_TARGET_MAP=(
	e2k_v3:v3:4c:v3
	e2k_v4:v4:8c:v4
	e2k_v5:v5:8c2:v5
	e2k_v6:v6:16c:v6
	e4c:e4c:4c:v3.4c
	e1c:e1c:1c:v4.1c+
	e8c:e8c:8c:v4.8c
	e8c2:e8c2:8c2:v5.8c2
	e16c:e16c:16c:v6.16c
	e2c3:e2c3:2c3:v6.2c3
)

# @ECLASS_VARIABLE: LCC_TARGET_IUSE
# @DESCRIPTION:
# The lcc_target_* USE flags, for REQUIRED_USE.
LCC_TARGET_IUSE=""
for lcc_target_entry in "${LCC_TARGET_MAP[@]}"; do
	LCC_TARGET_IUSE+=" lcc_target_${lcc_target_entry%%:*}"
done
unset lcc_target_entry

IUSE+=" ${LCC_TARGET_IUSE}"

# @FUNCTION: lcc-target_native_src_uri
# @USAGE: <prefix> <build-tag>
# @DESCRIPTION:
# Append SRC_URI for the per-target native .deb archives.
lcc-target_native_src_uri() {
	local prefix=${1}
	local tag=${2}
	local entry flag dir suffix isa base

	for entry in "${LCC_TARGET_MAP[@]}"; do
		IFS=: read -r flag dir suffix isa <<<"${entry}"
		base="${prefix}_${PV}-${tag}"

		SRC_URI+="
			lcc_target_${flag}? (
				https://setwd.ws/sp/${PV%.*}/${PV}/native/${dir}/${base}_e2k-${suffix}.deb
					-> ${base}-${dir}.deb
			)
		"
	done
}

# @FUNCTION: lcc-target_cross_src_uri
# @DESCRIPTION:
# Append SRC_URI for the per-target cross SDK tarballs.
lcc-target_cross_src_uri() {
	local entry flag dir suffix isa

	for entry in "${LCC_TARGET_MAP[@]}"; do
		IFS=: read -r flag dir suffix isa <<<"${entry}"

		SRC_URI+="
			lcc_target_${flag}? (
				https://setwd.ws/sp/${PV%.*}/${PV}/cross-sp-${PV}.e2k-${isa}.linux-6.1_64.tar.xz
			)
		"
	done
}

# @FUNCTION: lcc-target_cross_bin_dep
# @DESCRIPTION:
# Emit the matching lcc-cross-bin[flag] dependency for each target.
lcc-target_cross_bin_dep() {
	local entry flag dir suffix isa

	for entry in "${LCC_TARGET_MAP[@]}"; do
		IFS=: read -r flag dir suffix isa <<<"${entry}"
		echo "lcc_target_${flag}? ( ~sys-devel/lcc-cross-bin-${PV}[lcc_target_${flag}] )"
	done
}

# @FUNCTION: lcc-target_isa
# @USAGE: <flag-value>
# @DESCRIPTION:
# Echo the SDK ISA for a target value.
lcc-target_isa() {
	local wanted=${1}
	local entry flag dir suffix isa

	for entry in "${LCC_TARGET_MAP[@]}"; do
		IFS=: read -r flag dir suffix isa <<<"${entry}"
		if [[ ${flag} == "${wanted}" ]]; then
			echo "${isa}"
			return 0
		fi
	done

	return 1
}

# @FUNCTION: lcc-target_selected
# @DESCRIPTION:
# Echo the value of every enabled target flag.
lcc-target_selected() {
	local entry flag dir suffix isa

	for entry in "${LCC_TARGET_MAP[@]}"; do
		IFS=: read -r flag dir suffix isa <<<"${entry}"
		use "lcc_target_${flag}" && echo "${flag}"
	done
}
