FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0001-Added-the-command-for-smbios_blob_transfer-to-allowl.patch \
    file://0002-Added-dcmi-related-commands-to-allowlist.patch \
    file://0003-Support-IPMI-add-sel-entry-command.patch \
    file://0004-Lift-restrictions-of-MasterWriteRead-and-WriteFru.patch \
    file://0005-Remove-set-sel-time-from-intel-ipmi-oem.patch \
    file://0006-Add-miobmc-firmware-version-regex.patch \
    file://0007-Modify-get-device-sdr-interface-privilage.patch \
    file://0008-Align-SEL-sensor-type-and-event-type-parser.patch \
    "
