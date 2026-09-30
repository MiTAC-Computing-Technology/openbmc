MITAC_SIGN_ENABLE ?= "0"

MACHINE_FEATURES:append = "${@oe.utils.conditional('MITAC_SIGN_ENABLE', '1', ' mitac-sign', '', d)}"
MACHINEOVERRIDES .= "${@oe.utils.conditional('MITAC_SIGN_ENABLE', '1', ':mitac-sign', '', d)}"
