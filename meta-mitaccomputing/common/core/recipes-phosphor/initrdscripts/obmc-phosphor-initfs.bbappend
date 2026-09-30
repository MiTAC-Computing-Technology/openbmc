FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://factory_reset_whitelist \
    "

do_install:append() {
        # verify white list entries
        # each entry should have no '//', '/./', '/../' or trailing '/', '/.', '/..'
        while read -r f
        do
                if test $(realpath -L -m ${UNPACKDIR}$f) != ${UNPACKDIR}$f
                then
                        bberror "Bad whitelist entry ${f}."
                fi
        done < ${UNPACKDIR}/factory_reset_whitelist
        install -m 0644 ${UNPACKDIR}/factory_reset_whitelist ${D}/factory_reset_whitelist
}

FILES:${PN}:append = " \
    factory_reset_whitelist \
    "

