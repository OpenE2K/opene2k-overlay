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
	- [ ] Add copyrights to ebuilds.
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
	- [ ] Add rtc (x86 binary translator) package, maybe neatly integrate as multilib, etc...
- [ ] Cross compiling support
