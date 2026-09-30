SUMMARY = "Bridge Warning/Critical Redfish events to SNMP traps"
DESCRIPTION = "Follows the systemd journal for REDFISH_MESSAGE_ID and emits \
OBMCErrorNotification SNMP traps for OpenBMC registry MessageSeverity \
Warning/Critical. Uses phosphor-snmp sendTrap directly. \
Severity lookup loads /usr/share/bmcweb/registries/openbmc.json at runtime."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://redfish-snmp-bridge.cpp;beginline=1;endline=15;md5=c1614992e8c9c50b80e71c42d750e154"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += " \
    nlohmann-json \
    net-snmp \
    phosphor-dbus-interfaces \
    phosphor-logging \
    phosphor-snmp \
    sdbusplus \
    systemd \
    "

RDEPENDS:${PN} += " \
    bmcweb \
    phosphor-logging \
    phosphor-snmp \
    "

inherit pkgconfig obmc-phosphor-systemd

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"
B = "${S}"

SRC_URI = " \
    file://redfish-snmp-bridge.cpp \
    file://redfish-snmp-bridge.service \
    "

SYSTEMD_SERVICE:${PN} = "redfish-snmp-bridge.service"

do_compile() {
    ${CXX} ${CXXFLAGS} ${LDFLAGS} \
        redfish-snmp-bridge.cpp \
        -std=c++23 -Wall -Wextra \
        $(pkg-config --cflags --libs phosphor-snmp phosphor-logging phosphor-dbus-interfaces sdbusplus libsystemd) \
        -o redfish-snmp-bridge
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/redfish-snmp-bridge ${D}${bindir}/redfish-snmp-bridge
}
