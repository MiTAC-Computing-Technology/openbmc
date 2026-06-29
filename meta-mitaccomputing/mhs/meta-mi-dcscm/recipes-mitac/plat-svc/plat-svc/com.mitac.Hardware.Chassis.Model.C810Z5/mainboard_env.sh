#!/bin/bash

FRU_DEVICE="/sys/bus/i2c/devices/14-0050/eeprom"
HOST_COUNT=1
MAC_ADDRESS_BASE="0x40"
PLATFORM_COMPACT_NAME="com.mitac.Hardware.Chassis.Model.C810Z5"

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

action_keep_minimum_cooling () {
        mapfile array < <(ls /sys/bus/i2c/devices/11-002?/hwmon/*/pwm?)
        for i in "${array[@]}"
        do
                echo $i
                sh -c "echo '10'>$i"
        done
}

action_set_crt_to_host () {
        echo "Switch ownership of VGA/DP output to host."
        echo 0 >/sys/bus/platform/drivers/aspeed_gfx/1e6e6000.display/dac_mux
}

action_power_transition_off () {
        echo "action_power_transition_off"
        # action_keep_minimum_cooling
        # Found that there are timing issue from reset and may not turned off screen.
        # The workaround is to move action_set_crt_to_host to action_power_status_off.
        # action_set_crt_to_host
}

action_power_transition_on () {
        echo "action_power_transition_on"
}

action_power_status_off () {
        action_set_crt_to_host
}
