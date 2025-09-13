.SECONDEXPANSION:

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

define uses_arch



endef

define ingredients_src
  TARGET := $(1)
  $$(call uses_arch,$$(TARGET))
  ifeq ($$(patsubst %-nonfree,%,$1),riscv64)
    LINUX_VERSION := 6.16
  endif
  INGREDIENTS := ./image-recipe/run-local-build.sh ./image-recipe/build.sh image-recipe/Dockerfile $$(TARGET)/ingredients
  ifneq ($$(LINUX_VERSION),)
    INGREDIENTS := $$(INGREDIENTS) image-recipe/lb-overlays/$1/config/packages.chroot/linux-image-$$(LINUX_VERSION)-custom.deb
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

define MAKE_LINUX
image-recipe/lb-overlays/$(1)/config/packages.chroot/linux-image-%-custom.deb:
	mkdir -p tmp
	curl -fsSL https://github.com/torvalds/linux/archive/refs/tags/v$$*.tar.gz | tar -xzf- -C tmp
	ARCH=$(1) CROSS_COMPILE=$$(strip $$(call cross_compile,$(1))) (cd tmp/linux-$$* && make defconfig && nice make bindeb-pkg)
endef
$(foreach arch,$(ARCHES),$(eval $(call MAKE_LINUX,$(arch))))