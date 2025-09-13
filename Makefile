.SECONDEXPANSION:
.SECONDARY:

ARCHES := aarch64 x86_64 riscv64
PLATFORMS := $(ARCHES) $(addsuffix -nonfree,$(ARCHES))
ARM_ALIASES := arm64 arm
AMD_ALIASES := amd64 x86
RISCV_ALIASES := riscv
ALIASES := $(ARM_ALIASES) $(AMD_ALIASES) $(RISCV_ALIASES)

.PHONY: all $(PLATFORMS) $(ALIASES) $(addsuffix -nonfree,$(ALIASES)) $(addsuffix /ingredients,$(PLATFORMS))

HOST_ARCH := $(shell uname -m)

host-arch: $(HOST_ARCH)

$(ARM_ALIASES): aarch64
$(AMD_ALIASES): x86_64
$(RISCV_ALIASES): riscv64
$(addsuffix -nonfree,$(ARM_ALIASES)): aarch64-nonfree
$(addsuffix -nonfree,$(AMD_ALIASES)): x86_64-nonfree
$(addsuffix -nonfree,$(RISCV_ALIASES)): riscv64-nonfree

define ingredients_src
  TARGET := $(1)
  $$(call uses_arch,$$(TARGET))
  ifeq ($$(patsubst %-nonfree,%,$1),riscv64)
    LINUX_VERSION := 6.16
  endif
  INGREDIENTS := ./image-recipe/run-local-build.sh ./image-recipe/build.sh image-recipe/Dockerfile $$(TARGET)/ingredients
  ifneq ($$(LINUX_VERSION),)
    INGREDIENTS := $$(INGREDIENTS) image-recipe/lb-overlays/$$(TARGET)/config/packages.chroot/linux-image-$$(LINUX_VERSION)-$$(TARGET).deb
  endif
endef
define ingredients
  $(eval $(call ingredients_src,$(1)))
  $(INGREDIENTS)
endef

$(addsuffix /ingredients,$(PLATFORMS)):

$(PLATFORMS): %: results/%.iso

results/%.iso: $$(call ingredients,$$*)
	./image-recipe/run-local-build.sh $*

define cross_compile_src
  ifneq ($(HOST_ARCH),$(1))
    CROSS_COMPILE := $(1)-linux-gnu-
  endif
endef
define cross_compile
  $(eval $(call cross_compile_src,$(1)))
  $(CROSS_COMPILE)
endef

define linux_arch_src
  LINUX_ARCH := $(1)
  ifeq ($(1),riscv64)
    LINUX_ARCH := riscv
  else ifeq ($(1),x86_64)
    LINUX_ARCH := x86
  else ifeq ($(1),aarch64)
    LINUX_ARCH := arm64
  endif
endef
define linux_arch
  $(eval $(call linux_arch_src,$(1)))
  $(LINUX_ARCH)
endef

define MAKE_LINUX

build_dir/linux-%:
	mkdir -p tmp
	rm -rf tmp/linux-$$*
	curl -fsSL https://github.com/torvalds/linux/archive/refs/tags/v$$*.tar.gz | tar -xzf- -C build_dir
	rm -rf build_dir/linux-$$*
	mv tmp/linux-$$* build_dir/linux-$$*

image-recipe/lb-overlays/$(1)/config/packages.chroot/linux-image-%-$(1).deb: build_dir/linux-%
	rm -rf build_dir/*.deb build_dir/*.buildinfo build_dir/*.changes
	cd build_dir/linux-$$* && ARCH=$$(strip $$(call linux_arch,$(1))) CROSS_COMPILE=$$(strip $$(call cross_compile,$(1))) make defconfig
	cd build_dir/linux-$$* && ARCH=$$(strip $$(call linux_arch,$(1))) CROSS_COMPILE=$$(strip $$(call cross_compile,$(1))) nice make bindeb-pkg
	mkdir -p image-recipe/lb-overlays/$(1)/config/packages.chroot
	cp build_dir/linux-headers-*.deb image-recipe/lb-overlays/$(1)/config/packages.chroot/linux-headers-$$*-$(1).deb
	cp build_dir/linux-libc-*.deb image-recipe/lb-overlays/$(1)/config/packages.chroot/linux-libc-$$*-$(1).deb
	cp build_dir/linux-image-*.deb image-recipe/lb-overlays/$(1)/config/packages.chroot/linux-image-$$*-$(1).deb

endef
$(foreach arch,$(ARCHES),$(eval $(call MAKE_LINUX,$(arch))))