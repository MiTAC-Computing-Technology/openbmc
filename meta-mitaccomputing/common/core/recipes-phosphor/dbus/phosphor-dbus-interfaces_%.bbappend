FILESEXTRAPATHS:prepend := "${THISDIR}/phosphor-dbus-interfaces:"

S = "${WORKDIR}/git"

SRC_URI += "file://0001-com.amd-AMD-OEM-RAS-configuration-interface-added.patch \
            file://0001-Update-dbus-interface-definitions-to-support-MCTP-PC.patch \
            file://0002-Add-crashdump-interface.patch \
            file://0003-add-Cpu-VendorId-property.patch \
            file://0004-Update-GPIOLeakDetector.interface.yaml.patch \
            file://0005-Update-LeakDetector-interface.patch \
            file://0006-Patch-Add-ReKey-and-ReNew-features.patch \
            file://0007-State-Add-BMC-reboot-causes.patch \
            file://0008-Software-Update-add-StartUpdateOptions.patch \
            file://0009-Software-Version-add-CPLD-version-purposes.patch \
            "

EXTRA_OEMESON += "-Ddata_com_amd=true"

do_configure:prepend() {
  cd ${S}/gen && ./regenerate-meson
}
