# PACKAGECONFIG:append = " log-threshold log-pulse send-to-logger"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PACKAGECONFIG:append = "log-threshold sel-delete log-watchdog log-host log-alarm "

SRC_URI:append = "\
    file://0001-Support-SensorThresholdFatalHigh-and-SensorThreshold.patch \
    "
