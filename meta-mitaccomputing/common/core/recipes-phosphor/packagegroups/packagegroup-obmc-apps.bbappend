RDEPENDS:${PN}-extras:append = " \
    phosphor-image-signing \
    phosphor-virtual-sensor \
    phosphor-misc-usb-ctrl \
    phosphor-gpio-monitor-monitor \
    phosphor-gpio-monitor-presence \
    phosphor-hostlogger \
    phosphor-sel-logger \
    phosphor-logging \
    phosphor-post-code-manager \
    phosphor-host-postd \
    phosphor-software-manager \
    obmc-phosphor-buttons-signals \
    obmc-phosphor-buttons-handler \
    util-linux-logger \
    smbios-mdr \
    phosphor-ipmi-blobs \
    phosphor-snmp \
    redfish-snmp-bridge \
    net-snmp \
    iptables \
    curl \
    "

# AMD-only packages (cpu-info, amd-apml, amd-ras, powercap-monitor, …) live in
# packagegroup-amd-common, installed when DISTRO_FEATURES includes amd-common
# (see mitac.inc).


RDEPENDS:${PN}-inventory:append = "\
    dbus-sensors \
    entity-manager \
    "

RDEPENDS:${PN}-extras:remove = " phosphor-hwmon"
VIRTUAL-RUNTIME_obmc-sensors-hwmon ?= " dbus-sensors"
