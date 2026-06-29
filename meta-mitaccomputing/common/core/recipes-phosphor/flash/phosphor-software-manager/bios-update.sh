#!/bin/bash
# MiTAC 2024/10/11

set -e

POWER_CMD="/usr/bin/ipmitool power"
IMAGE_DIR=$1
IMAGE_FILE=$IMAGE_DIR/bios.bin
GPIO=`gpiofind spi-mux-bios`

IPMB_OBJ="xyz.openbmc_project.Ipmi.Channel.Ipmb"
IPMB_PATH="/xyz/openbmc_project/Ipmi/Channel/Ipmb"
IPMB_INTF="org.openbmc.Ipmb"
IPMB_CALL="sendRequest yyyyay"
ME_CMD_RECOVER="1 0x2e 0 0xdf 4 0x57 0x01 0x00 0x01"
ME_CMD_RESET="1 6 0 0x2 0"
SPI_DEV="spi1.0"
SPI_PATH="/sys/bus/spi/drivers/spi-nor"

remove_resource()
{
    echo "Remove resource in $IMAGE_DIR"
    rm -rf $IMAGE_FILE
}

set_gpio_to_bmc()
{
    echo "switch bios GPIO to bmc"
    gpioset $GPIO=1
    return 0
}

set_gpio_to_pch()
{
    echo "switch bios GPIO to pch"
    gpioset $GPIO=0
    return 0
}

echo "Bios upgrade started at $(date)"

#Power off host server.
echo "Power off host server"
$POWER_CMD off
sleep 15
if [ "$($POWER_CMD status)" != "Chassis Power is off" ];
then
    echo "Host server didn't power off"
    echo "Bios upgrade failed"
    exit -1
fi
echo "Host server powered off"

#Set ME to recovery mode
echo "Set ME to recovery mode"
# shellcheck disable=SC2086
#busctl call "$IPMB_OBJ" "$IPMB_PATH" "$IPMB_INTF" $IPMB_CALL $ME_CMD_RECOVER
#sleep 5

#Flip GPIO to access SPI flash used by host.
echo "Set GPIO $GPIO to access SPI flash from BMC used by host"
set_gpio_to_bmc

#Bind spi driver to access flash
echo "bind aspeed-smc spi driver"
if [ ! -d "$SPI_PATH/$SPI_DEV" ]; then
    echo "$SPI_DEV Not Found. Try to bind."
    echo $SPI_DEV>$SPI_PATH/bind
    if [ ! -d "$SPI_PATH/$SPI_DEV" ]; then
        echo $SPI_DEV>$SPI_PATH/bind Failed.
        remove_resource
        exit -1
    fi
fi
sleep 1
#Flashcp image to device.
if [ -e "$IMAGE_FILE" ];
then
    if [ -d "$IMAGE_FILE" ];
    then
        echo "Append bios.bin to path."
        IMAGE_FILE=${IMAGE_FILE}bios.bin
        if [ ! -e "$IMAGE_FILE" ];
        then
             echo "$IMAGE_FILE not found."
             remove_resource
             exit -1
        fi
    fi

    echo "Bios image is $IMAGE_FILE"
    MTD_DEV=`ls $SPI_PATH/$SPI_DEV/mtd/ -1 | grep -E -i -w "^(mtd.*[^ro]$)"` 
    for d in "${MTD_DEV[@]}" ; do
         echo "Flashing bios image to $d..."
         if flashcp -v "$IMAGE_FILE" /dev/$d; then
             echo "bios updated successfully..."
             remove_resource
         else
             echo "bios update failed..."
             remove_resource
             exit -1
         fi
         break
    done
else
    echo "Bios image $IMAGE_FILE doesn't exist"
    remove_resource
    exit -1
fi

#TODO: Intentionally setup MUX before unbind.
#      This is the workaround to unknown host booting issue.
#Flip GPIO back for host to access SPI flash
echo "Set GPIO $GPIO back for host to access SPI flash"
set_gpio_to_pch
sleep 2

#Unbind spi driver
sleep 2
echo "Unbind aspeed-smc spi driver"
echo -n $SPI_DEV > $SPI_PATH/unbind
sleep 2

#Reset ME to boot from new bios
echo "Reset ME to boot from new bios"
# shellcheck disable=SC2086
#busctl call "$IPMB_OBJ" "$IPMB_PATH" "$IPMB_INTF" $IPMB_CALL $ME_CMD_RESET
#sleep 10

#Power on server
echo "Power on server"
$POWER_CMD on
sleep 5

# Retry to power on once again if server didn't powered on
if [ "$($POWER_CMD status)" != "Chassis Power is on" ];
then
    sleep 5
    echo "Powering on server again"
    $POWER_CMD on
fi
