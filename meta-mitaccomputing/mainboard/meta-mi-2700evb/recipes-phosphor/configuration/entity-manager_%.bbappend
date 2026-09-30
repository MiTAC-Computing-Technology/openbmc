FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit obmc-phosphor-systemd systemd

RDEPENDS:${PN}:append = " bash"

SRC_URI:append = " \
    file://com.mitac.Hardware.Chassis.Model.Template/ \
    "

do_install:append() {
    # SDK bbappend used to rm -rf configurations/ (wiping schemas/). It now only
    # removes *.json; still restore schemas defensively so EM can open
    # configurations/schemas/global.json.
    install -d ${D}${datadir}/${PN}/configurations/schemas
    install -m 0644 ${S}/schemas/*.json \
        ${D}${datadir}/${PN}/configurations/schemas/

    # Drop Aspeed reference board (ast2700-evb, Probe: TRUE) pulled by
    # meta-ast2700-sdk. Keep Mitac platform-profile JSON only.
    rm -f ${D}${datadir}/${PN}/configurations/ast2700-evb.json

    for profile_name in ${PLATFORM_PROFILES}; do
        RESOURCE_DIR=${UNPACKDIR}/${profile_name}
        if [ "$(ls -A $RESOURCE_DIR)" ]; then
            install -m 0644 ${RESOURCE_DIR}/*.json ${D}${datadir}/${PN}/configurations/
        else
            echo "WARNING: ${RESOURCE_DIR} is Empty"
        fi
    done
}
