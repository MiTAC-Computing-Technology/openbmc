FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit obmc-phosphor-systemd systemd

SRC_URI:append= "\
    file://mitac_nvme_intel_p4500_p5500.json \
    file://mitac_nvme_intel_p_series.json \
    file://mitac_nvme_kioxia_generic.json \
    file://mitac_nvme_micron_generic.json \
    file://mitac_nvme_phison_generic.json \
    file://mitac_nvme_samsung_generic.json \
    file://mitac_nvme_solidigm_generic.json \
    "

RDEPENDS:${PN}:append = " bash"

do_install:append() {
    install -m 0644 -D ${UNPACKDIR}/mitac_nvme_intel_p4500_p5500.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_nvme_intel_p_series.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_nvme_kioxia_generic.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_nvme_micron_generic.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_nvme_phison_generic.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_nvme_samsung_generic.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_nvme_solidigm_generic.json ${D}${datadir}/${PN}/configurations/

    # Some configuration required to be removed to avoid contention.
    rm -f ${D}${datadir}/${PN}/configurations/micron*.json
    rm -f ${D}${datadir}/${PN}/configurations/nvme_*.json
}
