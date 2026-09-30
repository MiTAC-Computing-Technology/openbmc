FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://bios-update.sh \
    file://pre-phosphor-software-manage.sh \
    file://phosphor-software-manage.conf \
    file://0001-Workaround-the-system-hang-issue-after-BIOS-update.patch \
    file://0002-Enable-bios-firmware-udpate-using-flashcp-utility.patch \
    file://0003-Temporarily-use-Other-to-identify-the-host-image-in-.patch \
    file://0004-Added-to-support-VersionPurpose-Host-when-signed-bui.patch \
    file://0005-Use-the-factory-reset-whitelist-option-instead-of-factory-reset.patch \
    file://0006-Add-redfish-event-log.patch \
    file://0007-Only-one-firmware-update-task-shall-be-allowed-at-a-time.patch \
    file://0008-Clean-uploaded-BIOS-activation.patch \
    file://0009-Add-MiTAC-image-signature-verification.patch \
    file://0010-Preserve-bmc-firmware-update-reboot-reason.patch \
    file://0011-Add-MiTAC-firmware-downgrade-verification.patch \
    file://0012-Support-per-update-firmware-apply-options.patch \
    file://0013-Avoid-GCC-14-LTO-stringop-overflow-on-path-concat.patch \
    file://insert-mitac-meson-flag.py \
    file://0014-cpld-port-latest-multi-device-updater-implementation.patch \
    file://0015-common-publish-initial-software-state-and-D-Bus-interfaces.patch \
    file://0016-cpld-improve-firmware-update-safety-and-diagnostics.patch \
    "

# AST2600 applies this recipe's patches before the SDK aspeed-verify hunk;
# AST2700 applies them after. The START_UPDATE_DBUS_INTEFACE block is the
# same on both, so insert WANT_MITAC_SIGNATURE_VERIFY after quilt.
# do_patch is a Python task; use a postfunc instead of do_patch:append.
do_patch[postfuncs] += "insert_mitac_meson_flag"
insert_mitac_meson_flag() {
    python3 ${UNPACKDIR}/insert-mitac-meson-flag.py ${S}/bmc/meson.build
}

# Temporarily remove BIOS PLDM update support until needed.
# PACKAGECONFIG:append = " bios-software-update"
PACKAGECONFIG:append = " flash_bios"
PACKAGECONFIG:append = " i2cvr-software-update"
PACKAGECONFIG:append = " cpld-software-update"

PACKAGECONFIG[cpld-software-update] = "-Dcpld-software-update=enabled, -Dcpld-software-update=disabled, libpldm libgpiod i2c-tools"

PACKAGECONFIG[verify_mitac_signature] = "-Dverify-mitac-signature=enabled, -Dverify-mitac-signature=disabled"
PACKAGECONFIG:append:mitac-sign = " verify_mitac_signature"

EXTRA_OEMESON:append = " -Dactive-bmc-max-allowed=2"

RDEPENDS:${PN}:append = " bash"

FILES:${PN}-version += "${systemd_system_unitdir}/xyz.openbmc_project.Software.Manager.service.d/phosphor-software-manage.conf"

do_install:append() {
    install -d ${D}/${sbindir}
    install -m 0755 ${UNPACKDIR}/bios-update.sh ${D}/${sbindir}/
    install -m 0755 ${UNPACKDIR}/pre-phosphor-software-manage.sh ${D}/${sbindir}/

    install -d ${D}${systemd_system_unitdir}/xyz.openbmc_project.Software.Manager.service.d
    install -m 0644 ${UNPACKDIR}/phosphor-software-manage.conf \
            ${D}${systemd_system_unitdir}/xyz.openbmc_project.Software.Manager.service.d/
}
