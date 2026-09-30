SUMMARY = "MiTAC Signing Keys"
DESCRIPTION = "MiTAC signing keys for image signature verification."

LICENSE = "CLOSED"

inherit allarch

UNPACKDIR = "${S}"

SRC_URI = " \
    file://keys \
    "

MITAC_KEY_DIR = "${sysconfdir}/activationdata/MiTAC"

do_patch[noexec] = "1"
do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d "${D}${MITAC_KEY_DIR}"

    key_found=0
    for key in "${S}"/keys/*; do
        [ -f "$key" ] || continue
        key_found=1
        install -m 0644 "$key" "${D}${MITAC_KEY_DIR}/"
    done

    if [ "$key_found" -eq 0 ]; then
        bbfatal "No MiTAC signing keys found in ${S}/keys"
    fi
}
