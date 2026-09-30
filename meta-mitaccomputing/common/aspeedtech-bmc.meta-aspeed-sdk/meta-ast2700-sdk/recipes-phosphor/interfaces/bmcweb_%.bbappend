FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Dual-node/ast2750 VM patch targets upstream bmcweb layout; MiTAC NDA bmcweb
# (dev-MiOBMC) does not have features/kvm/kvm_websocket.hpp at the expected path.
# SRC_URI:append = " file://0004-bmcweb-support-ast2750-dual-nodes.patch"
