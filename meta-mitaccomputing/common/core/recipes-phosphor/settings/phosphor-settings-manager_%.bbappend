FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
	file://NMISource.override.yml \
	file://sol-default.override.yml \
	file://powerOnHours.override.yml \
	file://chassis-capabilities.override.yml \
	"