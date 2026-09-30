FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0001-Add-redfish-bmc-boot-reason-event-logging.patch \
    "
