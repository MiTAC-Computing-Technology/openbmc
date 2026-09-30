SUMMARY = "OpenBMC for MiTAC - Applications"
PR = "r1"

inherit packagegroup

PROVIDES = "${PACKAGES}"
PACKAGES = " \
        ${PN}-chassis \
        ${PN}-flash \
        ${PN}-system \
        ${PN}-fans \
        "

PROVIDES += "virtual/obmc-chassis-mgmt"
PROVIDES += "virtual/obmc-flash-mgmt"
PROVIDES += "virtual/obmc-system-mgmt"
PROVIDES += "virtual/obmc-fan-mgmt"

RPROVIDES:${PN}-chassis += "virtual-obmc-chassis-mgmt"
RPROVIDES:${PN}-flash += "virtual-obmc-flash-mgmt"
RPROVIDES:${PN}-system += "virtual-obmc-system-mgmt"
RPROVIDES:${PN}-fans += "virtual-obmc-fan-mgmt"

SUMMARY:${PN}-chassis = "MiTAC Chassis"
RDEPENDS:${PN}-chassis = " \
        x86-power-control \
        "

SUMMARY:${PN}-flash = "MiTAC Flash"
RDEPENDS:${PN}-flash = " \
        phosphor-software-manager \
        mitac-software-manager \
        "
RDEPENDS:${PN}-flash:append:mitac-sign = " \
        mitac-signing-keys \
        "

SUMMARY:${PN}-system = "MiTAC System"
RDEPENDS:${PN}-system = " \
        dbus-sensors \
        phosphor-hostlogger \
        phosphor-sel-logger \
        ipmitool \
        intel-ipmi-oem \
        phosphor-post-code-manager \
        phosphor-host-postd \
        phosphor-watchdog \
        "

SUMMARY:${PN}-fans = "Mitac Fans"
RDEPENDS:${PN}-fans = " \
	phosphor-pid-control \
        "
