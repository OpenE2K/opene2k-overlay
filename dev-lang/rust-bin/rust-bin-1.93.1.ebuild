# Copyright 2026 OpenE2K
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rust-target

DESCRIPTION="MCST prebuilt Rust toolchain for Elbrus (e8c2)"
HOMEPAGE="https://dev.mcst.ru/rust/"

SRC_URI="
	https://dev.mcst.ru/rust/2026-03-05/rust-${PV}-e2k8c2-unknown-linux-gnu.tar.xz
	rust-src? ( https://dev.mcst.ru/rust/2026-03-05/rust-src-${PV}.tar.xz )
"

KEYWORDS="~e2k"
# e8c2 gets its own model-tuned build for now
REQUIRED_USE="^^ ( lcc_target_e8c2 )"
