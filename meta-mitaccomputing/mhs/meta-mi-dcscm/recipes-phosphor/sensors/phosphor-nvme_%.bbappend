FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS:${PN}:append = " bash"

SRC_URI:append = " \
    file://com.mitac.Hardware.Chassis.Model.E7142/ \
    file://com.mitac.Hardware.Chassis.Model.R520G6/ \
    file://com.mitac.Hardware.Chassis.Model.S8051/ \
    file://com.mitac.Hardware.Chassis.Model.C810Z5/ \
    "

do_install:append() {
    for profile_name in ${PLATFORM_PROFILES}; do
        install -d ${D}${datadir}/${PN}/${profile_name}
        install -m 0644 ${UNPACKDIR}/${profile_name}/nvme_config.json ${D}${datadir}/${PN}/${profile_name}/
    done
}
