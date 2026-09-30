FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://com.mitac.Hardware.Chassis.Model.E7142/ \
    file://com.mitac.Hardware.Chassis.Model.R520G6/ \
    file://com.mitac.Hardware.Chassis.Model.S8051/ \
    file://com.mitac.Hardware.Chassis.Model.C810Z5/ \
    "

do_install:append() {
    install -m 0644 ${UNPACKDIR}/bios_attrs.json ${D}/usr/share/pldm/bios/bios_attrs.json
    for profile_name in ${PLATFORM_PROFILES}; do
        install -d ${D}/usr/share/pldm/pdr/${profile_name}
        install -d ${D}/usr/share/pldm/bios/${profile_name}
        install -m 0644 ${UNPACKDIR}/${profile_name}/bios_attrs.json ${D}/usr/share/pldm/bios/${profile_name}/bios_attrs.json
    done
}
