#!/bin/bash

# Setting fieldmode to true means that if signature verification fails, 
# the firmware update will not continue.
if [ "$(fw_printenv -n fieldmode)" != "true" ]; then
    fw_setenv fieldmode true
fi
