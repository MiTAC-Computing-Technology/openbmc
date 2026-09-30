FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = "\
    file://rsyslog.conf \
    file://rsyslog.logrotate \
    file://rotate-event-logs.service \
    file://rotate-event-logs.sh \
    file://rsyslog-override.conf \
    "

FILES:${PN} += "${systemd_system_unitdir}/rsyslog.service.d/rsyslog-override.conf"

PACKAGECONFIG:append = " imjournal"

do_install:append() {
    sed -i \
        -e '/^Wants=network.target network-online.target$/d' \
        -e '/^After=network.target network-online.target$/d' \
        ${D}${systemd_system_unitdir}/rsyslog.service

    install -m 0644 ${UNPACKDIR}/rotate-event-logs.service ${D}${systemd_system_unitdir}
    install -d ${D}${systemd_system_unitdir}/rsyslog.service.d
    install -m 0644 ${UNPACKDIR}/rsyslog-override.conf \
                    ${D}${systemd_system_unitdir}/rsyslog.service.d/rsyslog-override.conf
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/rotate-event-logs.sh ${D}/${bindir}/rotate-event-logs.sh
    rm -f ${D}${sysconfdir}/rsyslog.d/imjournal.conf
}

SYSTEMD_SERVICE:${PN} += " rotate-event-logs.service"
