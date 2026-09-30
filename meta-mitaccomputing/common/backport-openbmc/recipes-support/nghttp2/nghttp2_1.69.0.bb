SUMMARY = "HTTP/2 C Library and tools"
HOMEPAGE = "https://nghttp2.org/"
SECTION = "libs"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING;md5=764abdf30b2eadd37ce47dcbce0ea1ec"

SRC_URI = "${GITHUB_BASE_URI}/download/v${PV}/nghttp2-${PV}.tar.xz"
SRC_URI[sha256sum] = "1fb324b6ec2c56f6bde0658f4139ffd8209fa9e77ce98fd7a5f63af8d0e508ad"

inherit cmake manpages python3native github-releases
PACKAGECONFIG[manpages] = ""

# examples are never installed, and don't need to be built in the
# first place
EXTRA_OECMAKE = "-DENABLE_EXAMPLES=OFF -DENABLE_APP=OFF -DENABLE_HPACK_TOOLS=OFF -DENABLE_PYTHON_BINDINGS=OFF"

PACKAGES =+ "lib${BPN} ${PN}-proxy "

RDEPENDS:${PN} = "${PN}-proxy (>= ${PV})"
RDEPENDS:${PN}:class-native = ""
RDEPENDS:${PN}-proxy = "openssl python3-core python3-io python3-shell"

ALLOW_EMPTY:${PN} = "1"
FILES:${PN} = ""
FILES:lib${BPN} = "${libdir}/*${SOLIBS}"
FILES:${PN}-proxy = "${bindir}/nghttpx ${datadir}/${BPN}/fetch-ocsp-response"

BBCLASSEXTEND = "native nativesdk"
