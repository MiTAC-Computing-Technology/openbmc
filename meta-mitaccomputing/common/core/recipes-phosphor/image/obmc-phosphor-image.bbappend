inherit ${@bb.utils.contains('MACHINE_FEATURES', 'mitac-sign', 'mitac-sign', '', d)}

# SDK obmc-phosphor-image.bbappend installs packagegroup-aspeed-obmc-{apps,inband},
# but packagegroup-aspeed-obmc also PROVIDES virtual/obmc-*-mgmt and is skipped when
# mitac.inc sets PREFERRED_PROVIDER_* = packagegroup-mitac-apps.
IMAGE_INSTALL:remove = " \
    packagegroup-aspeed-obmc-apps \
    packagegroup-aspeed-obmc-inband \
    "

# SDK EVB extras (fio/python, perf, mtdtest, usb-gadget, …) are pulled in because
# mitac-layer globs the SDK root. 64MB AST2600 ROFS is 38MB; those packages push
# squashfs over FLASH_RWFS_OFFSET. AST2700 (128MB) keeps them.
IMAGE_INSTALL:remove:aspeed-g6 = " \
    packagegroup-oss-apps \
    packagegroup-oss-libs \
    packagegroup-oss-intel-pmci \
    packagegroup-aspeed-apps \
    packagegroup-aspeed-crypto \
    packagegroup-aspeed-ssif \
    packagegroup-aspeed-mtdtest \
    packagegroup-aspeed-usbtools \
    packagegroup-aspeed-ktools \
    "
EXTRA_IMAGE_FEATURES:remove:aspeed-g6 = "nfs-client"
