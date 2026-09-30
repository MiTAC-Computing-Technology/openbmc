FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit obmc-phosphor-systemd systemd

SRC_URI:append= "\
    file://mitac_ocpnic_nvidia_connectx7-ocp3p0.json \
    file://mitac_ocpnic_broadcom_BCM9.json \
    "

RDEPENDS:${PN}:append = " bash"

do_install:append() {
    install -m 0644 -D ${UNPACKDIR}/mitac_ocpnic_*.json ${D}${datadir}/${PN}/configurations/

    # Some configuration required to be removed to avoid contention.
    rm -f ${D}${datadir}/${PN}/configurations/cx7_ocp.json
}
