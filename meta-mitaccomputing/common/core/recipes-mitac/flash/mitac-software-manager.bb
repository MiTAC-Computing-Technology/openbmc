SUMMARY = "MiTAC Software Manager"
DESCRIPTION = "MiTAC software update manager that forwards update images to the matching OpenBMC software updater."

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git@micgitlab1-ssh.mic.com.tw:1022/beoc/solution-enabling/openbmc/mitac-software-manager.git;branch=main;protocol=ssh"
SRCREV = "0923bbb0fd7fabccff9c8373b62df0e2449be6a0"

S = "${WORKDIR}/git"

DEPENDS += "sdbusplus phosphor-logging phosphor-dbus-interfaces sdeventplus systemd libpldm"

inherit meson pkgconfig systemd

SYSTEMD_SERVICE:${PN} = "com.mitaccomputing.Software.Manager.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"
