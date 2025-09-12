ARCHES := aarch64 x86_64 riscv64
PLATFORMS := $(ARCHES) $(addsuffix -nonfree,$(ARCHES))
ARM_ALIASES := arm64 arm
AMD_ALIASES := amd64 x86
RISCV_ALIASES := riscv
ALIASES := $(ARM_ALIASES) $(AMD_ALIASES) $(RISCV_ALIASES)

CMD_ARCH_GOAL := $(filter $(ARCHES) $(ALIASES) $(addsuffix -nonfree,$(ARCHES) $(ALIASES)), $(MAKECMDGOALS))
ifeq ($(CMD_ARCH_GOAL),)
  PLATFORM := $(shell uname -m)
else
  PLATFORM := $(firstword $(CMD_ARCH_GOAL))
endif

IB_PLATFORM := $(patsubst %-nonfree, %, $(PLATFORM))
ifeq ($(ARCH), $(PLATFORM))
  NONFREE := ""
else
  NONFREE := "-nonfree"
endif
IB_PLATFORM := $(patsubst $(ARM_ALIASES),aarch64,$(IB_PLATFORM))
IB_PLATFORM := $(patsubst $(AMD_ALIASES),x86_64,$(IB_PLATFORM))
IB_PLATFORM := $(patsubst $(RISCV_ALIASES),riscv64,$(IB_PLATFORM))
IB_PLATFORM := "$(IB_PLATFORM)$(NONFREE)"

.PHONY: all x86_64 riscv64 $(PLATFORM)

all: $(PLATFORM)

$(ARM_ALIASES): aarch64
$(AMD_ALIASES): x86_64
$(RISCV_ALIASES): riscv64
$(addsuffix -nonfree,$(ARM_ALIASES)): aarch64-nonfree
$(addsuffix -nonfree,$(AMD_ALIASES)): x86_64-nonfree
$(addsuffix -nonfree,$(RISCV_ALIASES)): riscv64-nonfree

$(PLATFORMS): %.iso
