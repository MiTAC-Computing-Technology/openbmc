# OpenBMC 2.18.0 / walnascar: no linux-yocto-fitimage recipe. FIT is built by
# kernel-fitimage via virtual/kernel; drop the SDK's extra deploy dependency.
# mi-dcscm-2700 pulls this recipe via EXTRA_IMAGEDEPENDS.
# Note: BitBake does not support :remove on task varflags.
python() {
    deps = d.getVarFlag("do_deploy", "depends") or ""
    filtered = " ".join(
        x for x in deps.split() if x != "linux-yocto-fitimage:do_deploy"
    )
    d.setVarFlag("do_deploy", "depends", filtered)
}
