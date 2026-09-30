FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
FILESEXTRAPATHS:prepend := "${THISDIR}/shared:"

# AST2600 (aspeed-g6) Mitac board support
SRC_URI:append:aspeed-g6 = "\
    file://ast2600-beoc.dts \
    file://ast2600-capri.dts \
    file://ast2600-s8050.dts \
    file://ast2600-mi-dcscm.dts \
    file://ast2600-mic-amd-instinct.dts \
    "

SRC_URI:append:aspeed-g6 = "\
    file://0001-Added-defconfig-for-BEOC-Capri-and-Mi-DCSCM-projects.patch \
    file://0001-Added-base-board-init-file-for-AST2600.patch \
    file://0003-Added-default-CFG_EXTRA_ENV_SETTINGS-for-evb_ast2600.patch \
    file://0004-Added-defconfig-for-mitac-platforms-using-AST2600.patch \
    file://0005-Update-CFG_EXTRA_ENV_SETTINGS-to-follow-current-layo.patch \
    file://0006-Update-ENV_OFFSET-and-ENV_SECT_SIZE-to-fit-current-f.patch \
    "

# AST2700 (aspeed-g7) Mitac board support
SRC_URI:append:aspeed-g7 = "\
    file://0002-Added-base-board-init-file-for-AST2700.patch \
    "

do_configure:append:aspeed-g6(){
    cp ${UNPACKDIR}/ast2600-beoc.dts ${S}/arch/arm/dts/
    cp ${UNPACKDIR}/ast2600-capri.dts ${S}/arch/arm/dts/
    cp ${UNPACKDIR}/ast2600-s8050.dts ${S}/arch/arm/dts/
    cp ${UNPACKDIR}/ast2600-mi-dcscm.dts ${S}/arch/arm/dts/
    cp ${UNPACKDIR}/ast2600-mic-amd-instinct.dts ${S}/arch/arm/dts/

    # Build mainboard device tree.
    # TODO: This is convenient way.
    sed -i '1i dtb-$(CONFIG_ARCH_ASPEED) += ast2600-beoc.dtb' ${S}/arch/arm/dts/Makefile
    sed -i '1i dtb-$(CONFIG_ARCH_ASPEED) += ast2600-capri.dtb' ${S}/arch/arm/dts/Makefile
    sed -i '1i dtb-$(CONFIG_ARCH_ASPEED) += ast2600-s8050.dtb' ${S}/arch/arm/dts/Makefile
    sed -i '1i dtb-$(CONFIG_ARCH_ASPEED) += ast2600-mi-dcscm.dtb' ${S}/arch/arm/dts/Makefile
    sed -i '1i dtb-$(CONFIG_ARCH_ASPEED) += ast2600-mic-amd-instinct.dtb' ${S}/arch/arm/dts/Makefile
}
