FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0001-Fixed-user-enabled-state-is-abnormal-when-renaming.patch \
    file://0002-Add-support-for-correct-lock-status-in-manual-unlock.patch \
    file://0003-Update-boost-process-includes-for-Boost-1.88.patch \
    "
