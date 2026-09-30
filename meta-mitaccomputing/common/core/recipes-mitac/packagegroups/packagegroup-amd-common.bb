SUMMARY = "Package group to support AMD platforms."

inherit packagegroup

RDEPENDS:${PN} = " \
    i2c-tools \
    i3c-tools \
    amd-apml \
    amd-ras \
    cpu-info \
    powercap-monitor \
"
