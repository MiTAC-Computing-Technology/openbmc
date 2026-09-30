FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG:remove = " ipmbsensor"
PACKAGECONFIG:append = " nvmesensor"
PACKAGECONFIG:append = " leakdetector"

SRC_URI:append = " \
    file://0001-Support-using-MuxChannel-modifier.patch \
    file://1001-Updated-PSUSensorMain-to-support-sensors-and-the-nam.patch \
    file://1002-Customized-IntelCPUSensor-to-follow-MiOBMC-naming-co.patch \
    file://1003-Customized-Fan-PresenceGpio-to-follow-MiOBMC-sensor-.patch \
    file://1004-Fixed-incorrect-health-status-from-OperationalStatus.patch \
    file://1005-Fixed-psusensor-for-label-specific-PowerStates-configu.patch \
    file://1006-Added-to-support-NCT7904-RAA229620-and-RAA229621-for.patch \
    file://1007-Make-GPIOInterface-able-to-support-polling-mechanism.patch \
    file://1008-Support-GPIO-based-LeakDetector.patch \
    file://1009-Prevent-leakdetector-service-crashes-when-failing-to-get-GPIO-pin-value.patch \
    file://1010-Do-not-recreate-sensors-when-ADC-and-PSU-sensor-thresholds-change.patch \
    file://1011-fan-support-redundancy-events-for-I2C-fans.patch \
    file://1012-Fix-continuous-read-failed-logs-for-some-psu-sensors-after-BMC-boot.patch \
    "
