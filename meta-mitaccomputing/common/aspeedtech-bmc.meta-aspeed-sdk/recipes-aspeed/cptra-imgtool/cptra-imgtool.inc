SUMMARY = "Generate CPTRA authorization flash image with cptra_imgtool"
HOMEPAGE = "https://github.com/AspeedTech-BMC/cptra_imgtool"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

BRANCH = "master"
SRC_URI = "git://github.com/AspeedTech-BMC/cptra_imgtool;protocol=https;branch=${BRANCH};"

# Tag for v00.01.05
SRCREV = "3c06158958aeac6b8aa537a3da67331e730e4562"

S = "${UNPACKDIR}/git"

DEPENDS += "caliptra-mcu-sw"

inherit cargo

# Using cargo to download packages
CARGO_DISABLE_BITBAKE_VENDORING = "1"

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

do_compile() {
    cd ${S}

    # Prefer dependency versions compatible with OE Rust/Cargo 1.84.
    export CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=fallback

    # OE Rust/Cargo 1.84 cannot parse edition 2024 manifests (stabilized in 1.85).
    # Pin crates that already require edition 2024 / MSRV 1.85 in the lockfile.
    cargo update -p clap_lex --precise 1.0.0
    cargo update -p base64ct --precise 1.7.3
    cargo update -p deranged --precise 0.5.5

    # Build caliptra-auth-manifest-app
    cargo build -p ${CALIPTRA_AUTH_MANIFEST_APP} --release

    # Build cptra_imgtool
    cargo build -p cptra-imgtool --release
    cd -
}

do_install() {
    install -d ${D}${bindir}

    install -m 0755 ${B}/target/release/${CALIPTRA_AUTH_MANIFEST_APP} ${D}${bindir}
    install -m 0755 ${B}/target/release/cptra-imgtool ${D}${bindir}
}

BBCLASSEXTEND = "native nativesdk"
