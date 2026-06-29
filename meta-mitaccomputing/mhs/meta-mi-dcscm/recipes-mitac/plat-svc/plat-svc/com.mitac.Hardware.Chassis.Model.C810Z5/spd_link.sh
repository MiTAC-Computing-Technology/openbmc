#ls -d /sys/bus/i3c/devices/i3c-3/3-3c000000100/i3c-*/*-3c*
#/sys/bus/i3c/devices/i3c-3/3-3c000000100/i3c-6/6-3c000000000
I3C_DEV_PREFIX="/dev/bus/i3c/"

mapping_table=(
        "SPD_CPU0_DIMM_A0"
        "SPD_CPU0_DIMM_A1"
        "SPD_CPU0_DIMM_B0"
        "SPD_CPU0_DIMM_B1"
        "SPD_CPU0_DIMM_C0"
        "SPD_CPU0_DIMM_C1"
        "SPD_CPU0_DIMM_D0"
        "SPD_CPU0_DIMM_D1"
        "SPD_CPU0_DIMM_E0"
        "SPD_CPU0_DIMM_E1"
        "SPD_CPU0_DIMM_F0"
        "SPD_CPU0_DIMM_F1"
        "SPD_CPU0_DIMM_G0"
        "SPD_CPU0_DIMM_G1"
        "SPD_CPU0_DIMM_H0"
        "SPD_CPU0_DIMM_H1"
        "SPD_CPU1_DIMM_A0"
        "SPD_CPU1_DIMM_A1"
        "SPD_CPU1_DIMM_B0"
        "SPD_CPU1_DIMM_B1"
        "SPD_CPU1_DIMM_C0"
        "SPD_CPU1_DIMM_C1"
        "SPD_CPU1_DIMM_D0"
        "SPD_CPU1_DIMM_D1"
        "SPD_CPU1_DIMM_E0"
        "SPD_CPU1_DIMM_E1"
        "SPD_CPU1_DIMM_F0"
        "SPD_CPU1_DIMM_F1"
        "SPD_CPU1_DIMM_G0"
        "SPD_CPU1_DIMM_G1"
        "SPD_CPU1_DIMM_H0"
        "SPD_CPU1_DIMM_H1"
)

pmic_mapping_table=(
        "PMIC_CPU0_DIMM_A0"
        "PMIC_CPU0_DIMM_A1"
        "PMIC_CPU0_DIMM_B0"
        "PMIC_CPU0_DIMM_B1"
        "PMIC_CPU0_DIMM_C0"
        "PMIC_CPU0_DIMM_C1"
        "PMIC_CPU0_DIMM_D0"
        "PMIC_CPU0_DIMM_D1"
        "PMIC_CPU0_DIMM_E0"
        "PMIC_CPU0_DIMM_E1"
        "PMIC_CPU0_DIMM_F0"
        "PMIC_CPU0_DIMM_F1"
        "PMIC_CPU0_DIMM_G0"
        "PMIC_CPU0_DIMM_G1"
        "PMIC_CPU0_DIMM_H0"
        "PMIC_CPU0_DIMM_H1"
        "PMIC_CPU1_DIMM_A0"
        "PMIC_CPU1_DIMM_A1"
        "PMIC_CPU1_DIMM_B0"
        "PMIC_CPU1_DIMM_B1"
        "PMIC_CPU1_DIMM_C0"
        "PMIC_CPU1_DIMM_C1"
        "PMIC_CPU1_DIMM_D0"
        "PMIC_CPU1_DIMM_D1"
        "PMIC_CPU1_DIMM_E0"
        "PMIC_CPU1_DIMM_E1"
        "PMIC_CPU1_DIMM_F0"
        "PMIC_CPU1_DIMM_F1"
        "PMIC_CPU1_DIMM_G0"
        "PMIC_CPU1_DIMM_G1"
        "PMIC_CPU1_DIMM_H0"
        "PMIC_CPU1_DIMM_H1"
)

mapfile array < <(ls -d /sys/bus/i3c/devices/i3c-3/3-3c000000100/i3c-*/*-3c0*)
for i in "${!array[@]}"
do
        #spd_dev=array[i]
        spd_dev="${array[i]##*/}"
        echo ${mapping_table[$i]}
        pseudo_dev_name=${mapping_table[$i]}
        if [ ! -z "$pseudo_dev_name" ]; then
                ln -s $I3C_DEV_PREFIX/$spd_dev $I3C_DEV_PREFIX/$pseudo_dev_name
        else
                echo "Mapping not available for ${spd_dev}"
        fi
done

mapfile array < <(ls -d /sys/bus/i3c/devices/i3c-3/3-3c000000100/i3c-*/*-204*)
for i in "${!array[@]}"
do
        pmic_dev="${array[i]##*/}"
        echo ${pmic_mapping_table[$i]}
        pseudo_dev_name=${pmic_mapping_table[$i]}
        if [ ! -z "$pseudo_dev_name" ]; then
                ln -s $I3C_DEV_PREFIX/$pmic_dev $I3C_DEV_PREFIX/$pseudo_dev_name
        else
                echo "Mapping not available for ${pmic_dev}"
        fi
done


