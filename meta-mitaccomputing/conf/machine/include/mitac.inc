require conf/machine/include/mitac-linux.inc
require conf/machine/include/miobmc-flash-size.inc

######################
# Feature Management #
######################

MACHINE_FEATURES:append = "\
        obmc-bmc-state-mgmt \
        obmc-chassis-state-mgmt \
        obmc-host-ipmi \
        obmc-host-state-mgmt \
        obmc-phosphor-chassis-mgmt \
        obmc-phosphor-fan-mgmt \
        obmc-phosphor-flash-mgmt \
        "

DISTRO_FEATURES:append = " ldap"

####################
# Machine Features #
####################

# OBMC Phosphor
IMAGE_INSTALL:append = "phosphor-led-sysfs elfutils phosphor-inventory-manager biosconfig-manager phosphor-dbus-monitor "
# Mitac Common
IMAGE_INSTALL:append = "mitac-common-functions plat-svc id-button early-vga mitac-dcm-telemetry infineon-vr-util "
IMAGE_INSTALL:append = "mitac-mctp-pcie-vdm-core mitac-mctp-pcie-vdm-drivers "
# MCTP
IMAGE_INSTALL:append = "mctp libmctp i3c-tools libnvme "
# The use of pmci-launcher and mctpd are legacy approach and is going to be replaced by mctp.
IMAGE_INSTALL:append = " ${@bb.utils.contains("DISTRO_FEATURES", "intel-legacy-mctp-pcie", " pmci-launcher mctpd libmctp-intel-test ", "", d)}"
# Networking
IMAGE_INSTALL:append = "ifenslave usb-network "
IMAGE_INSTALL:append = "${@bb.utils.contains('MACHINE_FEATURES', 'bonding',\
                        ' update-bond-mac ', '', d)}"
# AMD Common
IMAGE_INSTALL:append = " ${@bb.utils.contains("DISTRO_FEATURES", "amd-common", "packagegroup-amd-common ", "", d)}"

EXTRA_IMAGE_FEATURES:append = " allow-root-login "


#################
# DEBUG Modules #
#################

IMAGE_INSTALL:append = " ${@bb.utils.contains("DISTRO_FEATURES", "debug-env", "gdb ", "", d)}"
# The workaround for projects without enough free space.
IMAGE_INSTALL:remove = " ${@bb.utils.contains("DISTRO_FEATURES", "debug-env", "elfutils early-vga mitac-dcm-telemetry infineon-vr-util i3c-tools libnvme ", "", d)}"

###############
# NDA Modules #
###############
# Be noted that the "common" may just contain dummy recipe to provide notification at the first attempt of build.

# Broadcom SAS
IMAGE_INSTALL:append = "libbrcm-storelib7 brcm-vdm-storelib7-gadget "

# SMBPBI
IMAGE_INSTALL:append = "smbpbi-gpu-manager "

####################
# Optional Modules #
####################

# MiOBMC Extra Tools: Contains optional tools useful for debugging or operation purpose
IMAGE_INSTALL:append = " ${@bb.utils.contains("DISTRO_FEATURES", "miobmc-extra-tools", " nvme-cli pldm ", "", d)}"



# TODO: 
# To support com/intel/Control/OCOTShutdownPolicy header from phosphor-dbus-interfaces to build intel-ipmi-oem but this function is not adapted by MiOBMC.
# However we possibly could remove the function related to OCOTShutdownPolicy from intel-ipmi-oem.
OBMC_ORG_YAML_SUBDIRS += " com/intel"

SERIAL_CONSOLES = "115200;ttyS4"

VIRTUAL-RUNTIME_obmc-inventory-manager = "entity-manager"
PREFERRED_PROVIDER_virtual/obmc-inventory-data = "entity-manager"

VIRTUAL-RUNTIME_obmc-host-state-manager ?= "x86-power-control"
VIRTUAL-RUNTIME_obmc-chassis-state-manager ?= "x86-power-control"

PREFERRED_PROVIDER_virtual/obmc-chassis-mgmt = "packagegroup-mitac-apps"
PREFERRED_PROVIDER_virtual/obmc-flash-mgmt = "packagegroup-mitac-apps"
PREFERRED_PROVIDER_virtual/obmc-host-ipmi-hw ?= "phosphor-ipmi-kcs"
PREFERRED_PROVIDER_virtual/obmc-system-mgmt = "packagegroup-mitac-apps"
PREFERRED_PROVIDER_virtual/obmc-fan-mgmt = "packagegroup-mitac-apps"
