FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PACKAGECONFIG:append = " smbios-ipmi-blob "

SRC_URI:append = "\
    file://0001-Added-to-support-SMBIOS-Versions-up-to-3.7.patch \
    file://0002-apply-processor-naming-convention.patch \
    "
