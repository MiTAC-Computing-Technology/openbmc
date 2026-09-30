inherit image_types_phosphor

do_copy_signing_pubkey[noexec] = "1"
do_copy_signing_pubkey[depends] = ""

# Generate the MiTAC firmware manifest without KeyType and HashType.
# Keep this function in sync with image_types_phosphor.bbclass.
python do_generate_phosphor_manifest() {
    purpose = d.getVar('VERSION_PURPOSE', True)
    version = do_get_version(d)
    build_id = do_get_buildID(d)
    target_machine = d.getVar('MACHINE', True)
    extended_version = do_get_extended_version(d)
    compatible_names = d.getVar('OBMC_COMPATIBLE_NAMES', True)
    with open('MANIFEST', 'w') as fd:
        fd.write('purpose={}\n'.format(purpose))
        fd.write('version={}\n'.format(version.strip('"')))
        fd.write('BuildId={}\n'.format(build_id.strip('"')))
        if extended_version:
            fd.write('ExtendedVersion={}\n'.format(extended_version))
        if compatible_names:
            for name in compatible_names.split():
                fd.write('CompatibleName={}\n'.format(name))
        fd.write('MachineName={}\n'.format(target_machine))
}

do_generate_phosphor_manifest[depends] = " \
    os-release:do_populate_sysroot \
"

# Package the static MTD image and manifest into an all-in-one tar archive.
do_generate_static_alltar() {
    ln -sf ${S}/MANIFEST MANIFEST
    ln -sf ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.static.mtd image-bmc

    tar -h -cvf ${IMGDEPLOYDIR}/${IMAGE_NAME}.static.mtd.all.tar \
        image-bmc MANIFEST

    cd ${IMGDEPLOYDIR}

    ln -sf ${IMAGE_NAME}.static.mtd.all.tar \
        ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.static.mtd.all.tar

    # Maintain non-standard legacy link.
    ln -sf ${IMAGE_NAME}.static.mtd.all.tar \
        ${IMGDEPLOYDIR}/${MACHINE}-${DATETIME}.all.tar

}

do_generate_static_alltar[depends] = ""

# Package the static image components and MiTAC manifest without signing files.
do_generate_static_tar() {
    ln -sf ${S}/MANIFEST MANIFEST
    make_image_links ${OVERLAY_BASETYPE} ${IMAGE_BASETYPE}
    make_tar_of_images static.mtd MANIFEST

    # Maintain non-standard legacy link.
    cd ${IMGDEPLOYDIR}
    ln -sf ${IMAGE_NAME}.static.mtd.tar ${IMGDEPLOYDIR}/${MACHINE}-${DATETIME}.tar
}

do_generate_static_tar[depends] = " \
    ${PN}:do_image_${@d.getVar('IMAGE_BASETYPE', True).replace('-', '_')} \
    virtual/kernel:do_deploy \
    u-boot:do_deploy \
"
