FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON:append= " \
    -Dhttp-body-limit=264 \
    -Dredfish-dump-log=enabled \
    -Dredfish-host-logger=enabled \
    "

SRC_URI:append = " \
    file://override.conf \
    "

# Service override (Linux-6.12 VM) + staged OpenBMC registry for consumers.
FILES:${PN} += " \
    ${systemd_system_unitdir}/bmcweb.service.d/override.conf \
    ${datadir}/bmcweb/registries \
    "

do_install:append() {
    install -d ${D}${systemd_system_unitdir}/bmcweb.service.d
    install -m 0644 ${UNPACKDIR}/override.conf \
            ${D}${systemd_system_unitdir}/bmcweb.service.d/override.conf

    install -d ${D}${datadir}/bmcweb/registries

    # Remove this installation after SNMP merge corresponding fix
    # Stage OpenBMC message registry for consumers (e.g. redfish-snmp-bridge).
    install -m 0644 ${S}/redfish-core/include/registries/openbmc.json \
            ${D}${datadir}/bmcweb/registries/openbmc.json

    if [ -e "${S}/redfish-core/include/registries/fault_registries.csv" ]; then
        # Stage DMTF & OpenBMC fault message registry for consumers (e.g. redfish-snmp-bridge).
        install -m 0644 ${S}/redfish-core/include/registries/fault_registries.csv \
            ${D}${datadir}/bmcweb/registries/fault_registries.csv
    fi
}
