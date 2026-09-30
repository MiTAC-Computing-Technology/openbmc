LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
RDEPENDS:${PN}:append = " bash"

DEPENDS:append = " \
    boost \
    nlohmann-json \
    phosphor-dbus-interfaces \
    phosphor-logging \
    sdbusplus \
    i2c-tools \
    "

inherit pkgconfig systemd obmc-phosphor-systemd

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"


SRC_URI = " \
	file://ep-mgr.hpp \
	file://mctp.hpp \
	file://ep-mgr.cpp \
	file://mctp-netlink.hpp \
	file://mctp-netlink.cpp \
    file://mmpvcd.cpp \
    file://mctp-packet.hpp \
    file://mctp-packet.cpp \
    file://mctp-endpoint-base.hpp \
    file://mctp-endpoint-base.cpp \
	file://mctp-driver.hpp \
	file://mctp-driver.cpp \
	file://mctp-driver-mgr.hpp \
	file://mctp-driver-mgr.cpp \
	file://power-state-monitor.hpp \
	file://power-state-monitor.cpp \
	file://mmpvcd_intel_platforms.json \
	file://mitac-mctp-engine-intel.service \
	file://mmpvcd_amd_platforms.json \
	file://mitac-mctp-engine-amd.service \
    "

SYSTEMD_SERVICE:${PN}:append = " \
    mitac-mctp-engine-intel.service \
    mitac-mctp-engine-amd.service \
    "

SYSTEMD_AUTO_ENABLE:${PN} = "disable"
SONAME = "libmmpvc.so.0"


do_compile() {
    ${CXX} ${CFLAGS} ${LDFLAGS} \
        ep-mgr.cpp \
        -std=c++23 \
		-I./ \
        -c \
        -fPIC \
        -o ep-mgr.o
    
	${CXX} ${CFLAGS} ${LDFLAGS} \
        mctp-packet.cpp \
        -std=c++23 \
		-I./ \
        -c \
        -fPIC \
        -o mctp-packet.o

    ${CXX} ${CFLAGS} ${LDFLAGS} \
        mctp-endpoint-base.cpp \
        -std=c++23 \
		-I./ \
        -c \
        -fPIC \
        -o mctp-endpoint-base.o

    ${CXX} ${CFLAGS} ${LDFLAGS} \
        mctp-netlink.cpp \
        -std=c++23 \
		-I./ \
        -c \
        -fPIC \
        -o mctp-netlink.o

    ${CXX} ${CFLAGS} ${LDFLAGS} \
        mctp-driver-mgr.cpp \
        -std=c++23 \
		-I./ \
        -c \
        -fPIC \
        -o mctp-driver-mgr.o

    ${CXX} ${CFLAGS} ${LDFLAGS} \
        mctp-driver.cpp \
        -std=c++23 \
		-I./ \
        -c \
        -fPIC \
        -o mctp-driver.o

    ${CXX} ${CFLAGS} ${LDFLAGS} \
        power-state-monitor.cpp \
        -std=c++23 \
		-I./ \
        -c \
        -fPIC \
        -o power-state-monitor.o

    ${CXX} ${CFLAGS} ${LDFLAGS} \
        -Wl,-soname,${SONAME} \
        -std=c++23 \
		-I./ \
        -shared -o libmmpvc.so.${PV} \
                    ep-mgr.o \
                    mctp-netlink.o \
                    mctp-driver.o \
                    mctp-packet.o \
					mctp-endpoint-base.o \
                    mctp-driver-mgr.o \
                    power-state-monitor.o

    ln -sf libmmpvc.so.${PV} libmmpvc.so

    ${CXX} ${CFLAGS} ${LDFLAGS} \
        mmpvcd.cpp \
        -pthread \
        -lphosphor_logging \
        -lboost_thread-mt \
		-I./ \
        -std=c++23 \
        -L. \
        -Wl,-rpath=${libdir}/${PN} \
        -lmmpvc \
        -o mctp-ep-mgr

}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/mctp-ep-mgr ${D}${bindir}

	install -d ${D}${includedir}
	install -m 0755 ${UNPACKDIR}/mctp.hpp ${D}${includedir}/
	install -m 0755 ${UNPACKDIR}/mctp-packet.hpp ${D}${includedir}/
	install -m 0755 ${UNPACKDIR}/mctp-driver.hpp ${D}${includedir}/
	install -m 0755 ${UNPACKDIR}/mctp-endpoint-base.hpp ${D}${includedir}/

    install -m 0755 -d ${D}/${libdir}/${PN}
    oe_soinstall ${UNPACKDIR}/libmmpvc.so.${PV} ${D}/${libdir}/${PN}
    install -m 0755 ${UNPACKDIR}/libmmpvc.* ${D}/${libdir}/${PN}
    install -m 0755 ${UNPACKDIR}/mmpvcd_intel_platforms.json ${D}/${libdir}/${PN}
    install -m 0755 ${UNPACKDIR}/mmpvcd_amd_platforms.json ${D}/${libdir}/${PN}
}

# skip dev-so in order for the unversioned so file to be packaged as well
FILES_SOLIBSDEV = ""
INSANE_SKIP:${PN} += "dev-so"
FILES:${PN} += "${libdir}/${PN}/libmmpvc.* "
