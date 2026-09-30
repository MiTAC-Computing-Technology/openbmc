SUMMARY = "Synchronize BMC time (source) to the UBB satellite BMC over Redfish"
DESCRIPTION = "Pushes the BMC clock to the UBB satellite Redfish (192.168.31.1) \
at boot (After=time-sync.target) and periodically via a systemd timer."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit allarch systemd

RDEPENDS:${PN} += "bash curl"

SRC_URI += " \
    file://ubb-timesync.sh \
    file://ubb-timesync.service \
    file://ubb-timesync.timer \
    "

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} += "ubb-timesync.service ubb-timesync.timer"

do_install() {
    install -d ${D}${libexecdir}/${PN}
    install -m 0755 ${UNPACKDIR}/ubb-timesync.sh ${D}${libexecdir}/${PN}/ubb-timesync.sh

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${UNPACKDIR}/ubb-timesync.service ${D}${systemd_unitdir}/system
    install -m 0644 ${UNPACKDIR}/ubb-timesync.timer ${D}${systemd_unitdir}/system
}
