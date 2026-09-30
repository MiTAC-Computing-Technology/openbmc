# MiTAC signing uses its own keys, so skip installing OpenBMC signing files.
do_install:mitac-sign() {
    :
}

ALLOW_EMPTY:${PN}:mitac-sign = "1"
