FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

CONFIGFILE = "ast2700-dcscm.json"

SRC_URI:append = " file://${CONFIGFILE}"
SRC_URI:append = " file://blacklist.json"

do_install:append() {
     # Drop stock board JSON only; keep configurations/schemas (entity-manager
     # requires schemas/global.json at runtime).
     rm -f ${D}${datadir}/entity-manager/configurations/*.json
     install -d ${D}${datadir}/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/${CONFIGFILE} ${D}${datadir}/entity-manager/configurations/
}
