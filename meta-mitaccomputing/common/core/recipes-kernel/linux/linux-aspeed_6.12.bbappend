FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}-${PV}:"

# Patches rebased onto linux-aspeed v00.07.04 (SRCREV 17a8ccbd).
# Dropped vs earlier series:
# - 0007 casting fix: upstream already casts & uses EDAF; file moved to espi/
# - 0008 AUXILIARY_BUS: already select'd by RESET_ASPEED; also forced via mitac_2700.cfg
SRC_URI:append = "\
    file://0003-To-improve-accustic-PWM-will-set-to-the-maximum-stat.patch \
    file://0004-Support-peci-legacy-device-in-device-t.patch \
    file://0005-Migrate-NCT7363-HWMON-driver-from-Linux-6.6.13.patch \
    file://0006-Fixed-dac_mux-issue-when-using-display-port-and-AST2.patch \
    file://0009-Add-AMD-APML-driver.patch \
    file://0011-Optional-Beautify-dump-of-packet-data.patch \
    file://0013-Implement-cache-for-LTC2497-driver-to-avoid-timeout-.patch \
    file://0012-Downgrade-MCTP-driver-and-waiting-for-new-driver-eva.patch \
    file://0014-Added-to-support-TUSB4041-usb-hub.patch \
    file://0015-Extend-IS168137-driver-to-support-Renesas-RAA229620-.patch \
    file://0016-Added-MFD-driver-to-suppport-CPLDs-on-G4826Z5-for-ve.patch \
    file://0017-Update-Kconfig-and-Makefile-to-support-the-configura.patch \
    file://0018-cpld-cpu-presence-driver.patch \
    file://0019-hwmon-mic-cpld-4826-fix-tach-mapping-and-RPM-convers.patch \
    "

do_patch:append() {
    for DTB in ${KERNEL_DEVICETREE}; do
        DT=`/bin/basename $DTB .dtb`
        if [ -r "${UNPACKDIR}/${DT}.dts" ]; then
            cp ${UNPACKDIR}/${DT}.dts \
                ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/${KMACHINE}/
        fi
    done
}
