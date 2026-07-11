# Copyright 2026 OpenE2K
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rust-target

DESCRIPTION="MCST prebuilt Rust toolchain for Elbrus (ISA builds)"
HOMEPAGE="https://setwd.ws/rust/"

rust-target_isa_src_uri https://setwd.ws/rust/2025-06-16
SRC_URI+=" rust-src? ( https://setwd.ws/rust/2025-06-16/rust-src-${PV}.tar.xz )"

KEYWORDS="~e2k"
REQUIRED_USE="$(rust-target_isa_required_use)"
