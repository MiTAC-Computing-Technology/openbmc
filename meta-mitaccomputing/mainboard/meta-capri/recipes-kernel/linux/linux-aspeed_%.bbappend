FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
  file://aspeed-bmc-mitac-base.dts \
  file://aspeed-bmc-mitac-capri_v2.dts \
  "

do_patch:append() {
  for DTB in ${KERNEL_DEVICETREE}; do
      DT=`/bin/basename $DTB .dtb`
      if [ -r "${WORKDIR}/${DT}.dts" ]; then
          cp ${WORKDIR}/${DT}.dts \
              ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/${KMACHINE}/
      fi
  done

}
