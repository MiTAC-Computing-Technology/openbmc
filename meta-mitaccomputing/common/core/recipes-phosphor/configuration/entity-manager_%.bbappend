FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit obmc-phosphor-systemd systemd

RDEPENDS:${PN}:append = " bash"

SRC_URI:append = " \
    file://0002-Support-MUXDEV-and-MUXCH-so-that-configuration-file-.patch \
    file://0003-Recreate-mux-channels-when-deviceIsCreated-return-po.patch \
    file://0004-Adjusted-getBusFRUs-to-avoid-MUX-channels-setting-be.patch \
    file://0005-Changed-the-default-16Bits-detect-mode-from-MODE_1-t.patch \
    file://0006-Fixed-the-issue-that-isDevice16BitMode2-is-unable-to.patch \
    file://0007-Change-the-namespace-of-replace_all-to-fix-build-iss.patch \
    file://0008-Fixed-the-issue-of-invalid-config-when-type-of-I2CMu.patch \
    file://0009-Support-the-association-of-cooling-and-cooledby-for-.patch \
    file://0010-Add-support-for-4KB-0x1000-FRU-header-offset.patch \
    file://1001-Updated-legacy.json-to-support-MuxIdleMode-and-MuxCh.patch \
    file://1002-Updated-legacy.json-to-support-sensors-used-by-MiOBM.patch \
    file://1003-Extended-to-support-the-device-type-of-Fan.patch \
    "
