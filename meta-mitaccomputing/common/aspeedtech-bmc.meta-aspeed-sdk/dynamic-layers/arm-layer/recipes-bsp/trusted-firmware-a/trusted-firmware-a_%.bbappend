FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Older meta-arm installs to /firmware and does not define FIRMWARE_DIR.
# Newer meta-arm (firmware.bbclass) sets FIRMWARE_DIR to /firmware/${PN}.
FIRMWARE_DIR ?= "/firmware"

FILES:${PN} += " \
    ${FIRMWARE_DIR}/*.map \
    ${FIRMWARE_DIR}/*.dump \
"

do_install:append() {
    for atfbin in ${TFA_INSTALL_TARGET}; do
        if [ -f ${BUILD_DIR}/$atfbin/$atfbin.map ]; then
            echo "Install $atfbin.map"
            install -m 0644 ${BUILD_DIR}/$atfbin/$atfbin.map \
                ${D}${FIRMWARE_DIR}/$atfbin-${TFA_PLATFORM}.map
            ln -sf $atfbin-${TFA_PLATFORM}.map ${D}${FIRMWARE_DIR}/$atfbin.map
        fi
        if [ -f ${BUILD_DIR}/$atfbin/$atfbin.dump ]; then
            echo "Install $atfbin.dump"
            install -m 0644 ${BUILD_DIR}/$atfbin/$atfbin.dump \
                ${D}${FIRMWARE_DIR}/$atfbin-${TFA_PLATFORM}.dump
            ln -sf $atfbin-${TFA_PLATFORM}.dump ${D}${FIRMWARE_DIR}/$atfbin.dump
        fi
    done
}

# Aspeed image/manifest tooling expects ${DEPLOY_DIR_IMAGE}/trusted-firmware-a/bl31.bin.
# Older meta-arm deploys to the image root; match the subdirectory layout here.
do_deploy() {
    install -d ${DEPLOYDIR}/${PN}
    cp -rf ${D}${FIRMWARE_DIR}/* ${DEPLOYDIR}/${PN}/
}
