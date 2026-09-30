# OpenBMC 2.18.0 / poky 5.2.1 (walnascar) has no linux-yocto-fitimage recipe
# and no kernel-fit-extra-artifacts class; stay on the in-kernel FIT flow.
#
# Require this include *before* aspeed-sdk.inc / ast2700-sdk.inc so hard
# assignments and :aarch64 overrides pre-empt the SDK's weak ?= defaults.
# An override-specific ?= from the SDK would otherwise beat a plain assignment
# at expansion time on aarch64 (AST2700).

KERNEL_IMAGETYPE = "fitImage"
KERNEL_IMAGETYPE:aarch64 = "fitImage"
KERNEL_IMAGETYPES = "fitImage vmlinux"
KERNEL_IMAGETYPES:aarch64 = "fitImage vmlinux"
KERNEL_CLASSES = "kernel-fitimage"

# Drop the SDK WKS dependency on the missing linux-yocto-fitimage recipe.
WKS_FILE_DEPENDS:remove = "linux-yocto-fitimage"

# This meta-arm deploys bl31.bin to DEPLOY_DIR_IMAGE root, not a per-recipe subdir.
UBOOT_FIT_ARM_TRUSTED_FIRMWARE_IMAGE = "${DEPLOY_DIR_IMAGE}/${TFA_BUILD_TARGET}.bin"

# A2 Caliptra flash needs QEMU 11+ (ast2700a2-evb + vbootrom). Poky ships 9.2
# (ast2700-a0 only); prefer the Aspeed SDK qemu_11.0.1 recipes.
PREFERRED_VERSION_qemu ?= "11.0.1"
PREFERRED_VERSION_qemu-native ?= "11.0.1"
PREFERRED_VERSION_qemu-system-native ?= "11.0.1"
PREFERRED_VERSION_nativesdk-qemu ?= "11.0.1"

# QB_MACHINE must be set in the machine conf *after* ast2700-sdk.inc (that
# file hard-assigns QB_MACHINE = "-machine ast2700-evb").
