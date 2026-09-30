#!/bin/bash

FRU_DEVICE="/sys/bus/i2c/devices/1-0050/eeprom"
HOST_COUNT=1
MAC_ADDRESS_BASE="0x2040"
PLATFORM_COMPACT_NAME="com.mitac.Hardware.Chassis.Model.S8056"

# Detect AMD RAS service name
# We support two versions of amd-ras:
# 1. NDA version: Depends on private amd-apml, using templated service "com.amd.RAS@.service"
# 2. Public version: Depends on esmi_oob_library, using static service "com.amd.RAS.service"
if systemctl list-unit-files | grep -q "com.amd.RAS@.service"; then
    # New version found, use instance 0
    RAS_SVC="com.amd.RAS@0.service"
else
    # Legacy version, use standard service name
    RAS_SVC="com.amd.RAS.service"
fi
echo "Using service: $RAS_SVC"

get_mac_addr_from_fru()
{
    echo "Get MAC Address [$1] from FRU".
    if [ -e $FRU_DEVICE ]; then
        local ETH_INTF_INDEX=$1
        local MAC_ADDRESS_OFFSET=$((MAC_ADDRESS_BASE + ETH_INTF_INDEX * 6))
        local MAC_ADDRESS=`fru-simple-read  -i $FRU_DEVICE -o $MAC_ADDRESS_OFFSET`
        echo "Identified MAC Address: $MAC_ADDRESS".
        eval "$2=$MAC_ADDRESS"
        return $?
    else
        local MAC_ADDRESS="FF:FF:FF:FF:FF:FF"
        echo "Can't find the FRU Device. Please double check the configuration of FRU EEROM in Kernel DTS. ($FRU_DEVICE)"
        echo "Here will return $MAC_ADDRESS to force using random EEPROM."
        eval "$2=$MAC_ADDRESS"
        return -1
    fi
}

exec_before_power_control () {
        echo "before_exec"
}

exec_after_power_control () {
        echo "after_exec"
}

action_power_transition_off () {
	echo "Detected host power off, stop $RAS_SVC"
	systemctl stop $RAS_SVC
}

action_power_transition_on () {
	echo "Detected host power on, start $RAS_SVC"
	systemctl start $RAS_SVC
}