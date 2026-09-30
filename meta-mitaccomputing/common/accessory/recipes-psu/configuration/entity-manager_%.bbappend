FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit obmc-phosphor-systemd systemd

SRC_URI:append= "\
    file://mitac_psu_acbel.json \
    file://mitac_psu_compuware.json \
    file://mitac_psu_generic.json \
    file://mitac_psu_delta_0_KLQD54.json \
    file://mitac_psu_delta_0_TDPS-5200BB.json \
    file://mitac_psu_delta_9_default.json \
    file://mitac_psu_murata-ps.json \
    file://mitac_pdb_m1638t76pdb.json \
    "

RDEPENDS:${PN}:append = " bash"

do_install:append() {
    install -m 0644 -D ${UNPACKDIR}/mitac_psu_acbel.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_psu_compuware.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_psu_generic.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_psu_delta_0_KLQD54.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_psu_delta_0_TDPS-5200BB.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_psu_delta_9_default.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_psu_murata-ps.json ${D}${datadir}/${PN}/configurations/
    install -m 0644 -D ${UNPACKDIR}/mitac_pdb_m1638t76pdb.json ${D}${datadir}/${PN}/configurations/
}
