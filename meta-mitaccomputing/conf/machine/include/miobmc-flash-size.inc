# This file contains the configuration for flash layout for 
# 1. Visit below files and evaluate the risk before you change this file.
#    meta-mitaccomputing/common/core/recipes-kernel/linux/linux-aspeed/MiObmc-flash-layout-64.dtsi
#    meta-mitaccomputing/common/core/recipes-kernel/linux/linux-aspeed/README.md

FLASH_ROFS_OFFSET:flash-65536 ?= "10240"
FLASH_RWFS_OFFSET:flash-65536 ?= "55296"
