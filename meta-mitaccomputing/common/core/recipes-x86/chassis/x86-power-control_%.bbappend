FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append = "\
    file://0001-Changed-to-use-the-configuration-indicated-by-mitac-.patch \
    file://0002-Activate-Fan-Control-during-S5-Power-State.patch \
    file://0003-Fixed-incorrect-power-status-issue-for-AC-power-cycl.patch \
    file://0004-Fix-the-BMC-cannot-control-power-when-pass-through-f.patch \
    file://0005-Fixed-the-issue-that-system-is-unable-to-powered-off.patch \
    file://0006-Register-BootProgress-interface-and-property.patch \
    file://0007-1.-Refact-powr_control-using-the-lib-from-phosphor-d.patch \
    file://0008-Correct-GPIO-pass-through-restoration-point.patch \
    file://0009-Fix-ipmitool-power-on-failed.patch \
    file://0010-Fix-power-button-long-pressed-issue.patch \
    file://0011-impv-Add-event-log-for-system-reset.patch \
    file://0012-Fix-OperatingSystemState-for-OS-boot-progress.patch \
    file://0013-Disable-pass-through-only-for-control-GPIOs.patch \
    file://power-control.sh \
    file://power-config-host0.json \
    "

RDEPENDS:${PN}:append = " bash"

do_install:append() {
    install -d ${D}${libexecdir}/${PN}/
    install -m 0644 ${UNPACKDIR}/power-control.sh ${D}${libexecdir}/${PN}/

    install -d ${D}${datadir}/${PN}/default/
    install -m 0644 ${UNPACKDIR}/power-config-host0.json ${D}${datadir}/${PN}/default
}
