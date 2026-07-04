# OpenE2K Gentoo overlay

This overlay adds Elbrus 2000 architecture support on top of the existing Gentoo upstream repository.

To make it work, new profile and keyword are added.
* Through magic of symlinks, `e2k` profile is based on upstream Gentoo profiles.
* Keyword `e2k` is only added to the packages that are specifically patched to support Elbrus.
* As changes of getting this upstreamed are very slim due to proprietary compilers, packages that can be built as-is, are enabled through `amd64` keyword, so we don't have to patch every ebuild from the upstream.
	* ~~It's temporarily on my machine /etc/portage, but could be added in profile, if profiles support `.accept_keywords`.~~ `package.accept_keywords` is landed into profile.
* The only patch is required for Gentoo portage tree is adding e2k to supported arches in `eclass/toolchain-funcs.eclass`:
```diff
diff --git a/eclass/toolchain-funcs.eclass b/eclass/toolchain-funcs.eclass
index 89da26b86..8f65033c1 100644
--- a/eclass/toolchain-funcs.eclass
+++ b/eclass/toolchain-funcs.eclass
@@ -783,6 +783,7 @@ tc-ninja_magic_to_arch() {
 		bfin*)		_tc_echo_kernel_alias blackfin bfin;;
 		c6x*)		echo c6x;;
 		cris*)		echo cris;;
+		e2k*)		echo e2k;;
 		frv*)		echo frv;;
 		hexagon*)	echo hexagon;;
 		hppa*)		_tc_echo_kernel_alias parisc hppa;;
diff --git a/eclass/multilib.eclass b/eclass/multilib.eclass
index 15c44e0..defdfdb 100644
--- a/eclass/multilib.eclass
+++ b/eclass/multilib.eclass
@@ -470,6 +470,31 @@ multilib_env() {
 			: "${MULTILIB_ABIS=sparc64 sparc32}"
 			: "${DEFAULT_ABI=sparc64}"
 		;;
+		e2k*)
+			# e2k differs by pointer size, not CHOST, so the ABI CFLAGS carry it
+			export CFLAGS_ptr64="-mptr64"
+			export LDFLAGS_ptr64="-m elf64_e2k"
+			export LIBDIR_ptr64="lib64"
+
+			export CFLAGS_ptr32="-mptr32"
+			export LDFLAGS_ptr32="-m elf32_e2k"
+			export LIBDIR_ptr32="lib"
+
+			export CFLAGS_ptr128="-mptr128"
+			export LDFLAGS_ptr128="-m elf64_e2k_pm"
+			export LIBDIR_ptr128="lib128"
+
+			export CHOST_ptr64=${CTARGET}
+			export CTARGET_ptr64=${CTARGET}
+
+			export CHOST_ptr32=${CTARGET}
+			export CTARGET_ptr32=${CTARGET}
+
+			export CHOST_ptr128=${CTARGET}
+			export CTARGET_ptr128=${CTARGET}
+			: "${MULTILIB_ABIS=ptr64 ptr32 ptr128}"
+			: "${DEFAULT_ABI=ptr64}"
+		;;
 		*)
 			: "${MULTILIB_ABIS=default}"
 			: "${DEFAULT_ABI=default}"
```

### Cross-compiling env

It might be useful to keep /usr/e2k-mcst-linux-gnu, for distcc or building stage from scratch. For that:

1. Build the cross root, crossdev at stage0 will build cross binutils:

   ```sh
   crossdev --stage0 -A "ptr64 ptr32 ptr128" --target e2k-mcst-linux-gnu
   ```

2. Emerge `sys-devel/lcc-cross-wrappers` with single `LCC_TARGET`, it will pull `sys-devel/lcc-cross-bin` with the matching flag.

3. Build the toolchain sysroot:

   ```sh
   emerge cross-e2k-mcst-linux-gnu/linux-headers cross-e2k-mcst-linux-gnu/glibc
   ```

4. Crossdev makes a lot of assumptions, so we need to edit `/usr/e2k-mcst-linux-gnu/etc/portage/`:

   - add `opene2k` (priority 100) to `repos.conf`
   - point `make.profile` at `/var/db/repos/opene2k/profiles/default/linux/e2k/23.0`
   - `make.conf`: change default `-O2` to `-O3` in `CFLAGS`/`CXXFLAGS`, set `LCC_TARGET`.
   - `package.license`: `lcc` is, unfortunately, a proprietary compiler, so allow `MCST` license.
   - crossdev makes split-usr for some reason, so turn it into merged-usr.

5. Build the userland:

   ```sh
   e2k-mcst-linux-gnu-emerge @system
   ```

### Acknowledgments

Thanks to MCST and ALT Linux Team for their efforts and publishing patches for Elbrus support, as OpenE2K is based around ~90% of their work. Thanks to Gentoo team for creating such flexible distribution and package manager.

### Current state

Supported profiles:
- [x] default/linux/e2k/23.0
- [ ] default/linux/e2k/23.0/systemd

Supported CPUs (defined as ABI in the profile):
- [x] Elbrus 4C
- [ ] Elbrus 8CB

Supported ABIs:
- [ ] ptr32
- [x] ptr64
- [ ] ptr128

TODO:
- [ ] Fill out missing parts above. :)
- [ ] Get rid of hardcoded stuff
	- [x] Add copyrights to ebuilds.
	- [x] Move `e2k` keyword to `~e2k`, as it's obviously not tested.
	- [x] Remove all other keywords, so `e2k` specific packages won't get accidentally pulled on supported by upstream system.
- [ ] Build parts of lcc-libs that have source code published:
	- [ ] compiler-rt
	- [ ] libatomic
	- [ ] libgcc
	- [ ] libquadmath
	- [ ] libstdc++
- [ ] Build and publish stage3
- [ ] Moar e2k packages:
	- [ ] Add MCST and Unipro LLVM ports as separate packages
	- [ ] Add MCST Rust port
	- [ ] Add rtc (x86 binary translator) package, maybe neatly integrate as crossdev, etc...
- [x] Cross compiling support

## Example `make.conf`

```bash
# LCC_TARGET picks which MCST native lcc build to install (a USE_EXPAND flag).
# Set exactly one:
# - an ISA baseline (e2k_v3/e2k_v4/e2k_v5/e2k_v6) is forward COMPATIBLE - its
#   binaries run on that ISA and every newer Elbrus CPU. Use it for a portable
#   stage3, e.g. e2k_v3 works on any v3+ machine and can be recompiled later.
#   For that setup also avoid -mcpu/-march/-mtune flags.
# - a model name (e4c/e1c/e8c/e8c2/e16c/e2c3) will produce faster binaries
#   but forward INCOMPATIBLE - binaries refuse to run on other CPUs, even of the
#   same ISA version (e1c bins will not run on e8c, even though both are e2k_v4)
LCC_TARGET="e2k_v3"

# OpenE2K stage3 is built for e2k_v3 by default, which you are supposed to
# recompile for your native ISA.
COMMON_FLAGS="-O3 -pipe"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

MAKEOPTS="-j17 -l17"
VIDEO_CARDS="radeonsi amdgpu"
```
