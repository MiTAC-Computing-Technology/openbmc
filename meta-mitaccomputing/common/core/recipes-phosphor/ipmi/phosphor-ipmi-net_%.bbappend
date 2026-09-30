RMCPP_IFACE = "${@bb.utils.contains("MACHINE_FEATURES", "bonding", "bond0", "${DEFAULT_RMCPP_IFACE}", d)}"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0001-impv-Adjust-invalid-login-logging.patch \
    file://0002-Set-ipmi-net-restart-limit.patch \
"

SYSTEMD_SERVICE:${PN}:append = "\
    ${PN}@eth0.service \
    ${PN}@eth0.socket \
    "

SYSTEMD_SERVICE:${PN}:append = "\
    ${PN}@eth1.service \
    ${PN}@eth1.socket \
    "
