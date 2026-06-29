FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PACKAGECONFIG:append = " dynamic-sensors entity-manager-decorators arm-sbmr "

SRC_URI:append = " \
    file://0001-Use-MiOBMC-s-naming-convention-to-preset-EntityID-an.patch \
    file://0002-Skip-malformed-IPMI-Decorators-to-improve-the-robust.patch \
    file://0003-Fix-SDR-count-error.patch \
    file://0004-Remove-ChannelAccess-synchronization-methods.patch \
    file://0005-Avoid-VLAN-set-when-VLAN-off.patch \
    file://0006-Reject-set-IP-source-to-unspecified.patch \
    file://0007-Remove-entIns-assignment-inlet-temp-sensors.patch \
"
