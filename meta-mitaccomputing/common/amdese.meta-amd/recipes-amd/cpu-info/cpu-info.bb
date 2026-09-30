SUMMARY = "AMD CPU Info module"
DESCRIPTION = "CPU Info module creates the processor inventory D-BUS object \
path and updates the Cpu interface properties by reading the CPU values of \
the SOC from the esmi OOB library API's"
LICENSE = "CLOSED"
FILESEXTRAPATHS:prepend := "${THISDIR}:"
inherit meson pkgconfig systemd
SRC_URI = "git://git@github.com/AMDESE/bmc-cpuinfo.git;branch=integ_sp7;protocol=ssh"
SRCREV = "41929cf639f84703f682a9af84d1b28218908003"

SRC_URI += "file://0001-cpu-info-porting-to-MiTAC-platforms-and-fix-build-er.patch \
            file://0002-cpu-info-use-PRIx64-for-uint64_t-PPIN-sprintf.patch \
            "

S = "${WORKDIR}/git"
DEPENDS += " \
    amd-apml \
    i2c-tools \
    libgpiod \
    phosphor-dbus-interfaces \
    phosphor-logging \
    sdbusplus \
    "
do_configure:prepend() {
    install -d ${STAGING_DIR_HOST}${includedir}/linux
    install -m 0755 ${STAGING_KERNEL_DIR}/include/uapi/linux/amd-apml.h ${STAGING_DIR_HOST}${includedir}/linux/amd-apml.h
}

SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.Inventory.Item.Cpu_info.service"
