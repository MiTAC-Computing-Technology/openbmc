FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS:${PN}:append = " bash"
RDEPENDS:${PN}:append = " mitac-common-functions"

SRC_URI:append = " \
    file://com.mitac.Hardware.Chassis.Model.E7142 \
    file://com.mitac.Hardware.Chassis.Model.R520G6 \
    file://com.mitac.Hardware.Chassis.Model.C810Z5 \
    "

do_install:append() {
    for profile_name in ${PLATFORM_PROFILES}; do
        install -d ${D}${libexecdir}/${PN}/${profile_name}
        install -m 0644 ${UNPACKDIR}/${profile_name}/mainboard-init-functions ${D}${libexecdir}/${PN}/${profile_name}/
        install -m 0644 ${UNPACKDIR}/${profile_name}/thermal-mgmt-init-functions ${D}${libexecdir}/${PN}/${profile_name}/
        install -m 0644 ${UNPACKDIR}/${profile_name}/mainboard_env.sh ${D}${libexecdir}/${PN}/${profile_name}/
        install -m 0644 ${UNPACKDIR}/${profile_name}/spd_link.sh ${D}${libexecdir}/${PN}/${profile_name}/
        install -m 0644 ${UNPACKDIR}/${profile_name}/MRD*.json ${D}${libexecdir}/${PN}/${profile_name}/
    done
}
