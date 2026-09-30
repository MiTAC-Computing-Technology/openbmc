FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
FILESEXTRAPATHS:prepend := "${THISDIR}/shared:"
ENV_CONFIG_FILE = "fw_env.config"

SRC_URI:append = "\
    file://fw_env.config \
    "

SRC_URI:append:aspeed-g6 = "\
    file://0001-Added-defconfig-for-BEOC-Capri-and-Mi-DCSCM-projects.patch \
    "
