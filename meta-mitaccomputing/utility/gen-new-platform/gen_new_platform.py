#!/usr/bin/env python3

import os
import re
import shutil
import sys


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
META_MITACCOMPUTING_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
REPO_DIR = os.path.dirname(META_MITACCOMPUTING_DIR)
LOG_FILE = os.path.join(SCRIPT_DIR, "gen_new_platform.log")
LOG_ENTRIES = []


def format_log_path(path):
    return os.path.relpath(path, REPO_DIR)


def add_log_entry(action, path):
    entry = f"{action}: {format_log_path(path)}"
    if entry not in LOG_ENTRIES:
        LOG_ENTRIES.append(entry)


def add_rename_log_entry(old_path, new_path):
    entry = (
        f"Renamed: {format_log_path(old_path)} -> "
        f"{format_log_path(new_path)}"
    )
    if entry not in LOG_ENTRIES:
        LOG_ENTRIES.append(entry)


def write_log_file():
    with open(LOG_FILE, "w", encoding="utf-8") as log_file:
        if not LOG_ENTRIES:
            log_file.write("No files or directories were added or modified.\n")
            return

        for entry in LOG_ENTRIES:
            log_file.write(f"{entry}\n")


def add_added_tree_log_entries(base_dir):
    add_log_entry("Added directory", base_dir)

    for root, dirs, files in os.walk(base_dir):
        for dir_name in dirs:
            add_log_entry("Added directory", os.path.join(root, dir_name))
        for file_name in files:
            add_log_entry("Added file", os.path.join(root, file_name))


def get_layer_dir(machine_conf_file):
    return os.path.abspath(
        os.path.join(os.path.dirname(machine_conf_file), "..", "..")
    )


def find_machine_conf_files(base_dir):
    machine_conf_files = {}
    excluded_common_dir = os.path.join(base_dir, "common")

    for root, dirs, _files in os.walk(base_dir):
        dirs[:] = [
            dir_name
            for dir_name in dirs
            if os.path.join(root, dir_name) != excluded_common_dir
        ]

        for dir_name in dirs:
            if "machine" not in dir_name:
                continue

            machine_dir = os.path.join(root, dir_name)
            for file_name in sorted(os.listdir(machine_dir)):
                file_path = os.path.join(machine_dir, file_name)
                if os.path.isfile(file_path) and file_name.endswith(".conf"):
                    machine_conf_files[os.path.splitext(file_name)[0]] = file_path

    return machine_conf_files


def select_machine_conf(machine_conf_names):
    print("Machine conf:")
    for machine_conf_name in machine_conf_names:
        print(f" {machine_conf_name}")

    while True:
        selected = input("Select: ")
        if selected in machine_conf_names:
            return selected


def parse_reference_platforms(machine_conf_file):
    reference_platforms = []
    in_platform_profiles = False

    with open(machine_conf_file, "r", encoding="utf-8") as conf_file:
        for line in conf_file:
            stripped_line = line.strip()

            if not in_platform_profiles:
                if not stripped_line.startswith("PLATFORM_PROFILES"):
                    continue

                in_platform_profiles = True
                stripped_line = stripped_line.split('"', 1)[1]

            if '"' in stripped_line:
                stripped_line = stripped_line.split('"', 1)[0]
                in_platform_profiles = False

            stripped_line = stripped_line.replace("\\", "").strip()
            if stripped_line:
                reference_platforms.append(stripped_line.split(".")[-1])

            if not in_platform_profiles:
                break

    return reference_platforms


def select_reference_platform(reference_platforms):
    print()
    print("Reference Platform:")
    for reference_platform in reference_platforms:
        print(f" {reference_platform}")

    while True:
        selected = input("Select: ")
        if selected in reference_platforms:
            return selected


def input_new_platform(reference_platforms):
    print()
    print("New Platform:")

    while True:
        new_platform = input("Select: ").strip()
        if not new_platform:
            continue
        if new_platform not in reference_platforms:
            return new_platform


def confirm_new_platform(new_platform):
    print()

    while True:
        confirmation = input(f"Generate {new_platform} Platform (yes/no): ")
        if confirmation == "yes":
            return
        if confirmation == "no":
            sys.exit(0)


def add_kernel_devicetree(machine_conf_file, new_platform):
    new_devicetree = (
        f'KERNEL_DEVICETREE += "aspeed/${{KMACHINE}}-bmc-mitac-'
        f'{new_platform.lower()}.dtb"\n'
    )

    with open(machine_conf_file, "r", encoding="utf-8") as conf_file:
        lines = conf_file.readlines()

    if new_devicetree in lines:
        return

    last_kernel_devicetree_index = None
    for index, line in enumerate(lines):
        if line.strip().startswith("KERNEL_DEVICETREE"):
            last_kernel_devicetree_index = index

    if last_kernel_devicetree_index is None:
        raise RuntimeError(f"KERNEL_DEVICETREE not found in {machine_conf_file}")

    lines.insert(last_kernel_devicetree_index + 1, new_devicetree)

    with open(machine_conf_file, "w", encoding="utf-8") as conf_file:
        conf_file.writelines(lines)
    add_log_entry("Modified file", machine_conf_file)


def add_platform_profile(machine_conf_file, new_platform):
    new_profile = f"\tcom.mitac.Hardware.Chassis.Model.{new_platform} \\\n"

    with open(machine_conf_file, "r", encoding="utf-8") as conf_file:
        lines = conf_file.readlines()

    if new_profile in lines:
        return

    in_platform_profiles = False
    platform_profiles_end_index = None

    for index, line in enumerate(lines):
        stripped_line = line.strip()

        if not in_platform_profiles:
            if not stripped_line.startswith("PLATFORM_PROFILES"):
                continue
            in_platform_profiles = True
            if '"' in stripped_line.split('"', 1)[1]:
                platform_profiles_end_index = index
                break
            continue

        if '"' in stripped_line:
            platform_profiles_end_index = index
            break

    if platform_profiles_end_index is None:
        raise RuntimeError(f"PLATFORM_PROFILES not found in {machine_conf_file}")

    lines.insert(platform_profiles_end_index, new_profile)

    with open(machine_conf_file, "w", encoding="utf-8") as conf_file:
        conf_file.writelines(lines)
    add_log_entry("Modified file", machine_conf_file)


def add_new_platform_kernel_devicetree(
    machine_conf_file, reference_platform, new_platform
):
    layer_dir = get_layer_dir(machine_conf_file)
    linux_aspeed_dir = os.path.join(
        layer_dir, "recipes-kernel", "linux", "linux-aspeed"
    )
    reference_platform_lower = reference_platform.lower()
    new_platform_lower = new_platform.lower()
    reference_dts_name = f"aspeed-bmc-mitac-{reference_platform_lower}.dts"
    new_dts_name = f"aspeed-bmc-mitac-{new_platform_lower}.dts"
    reference_dts_file = os.path.join(linux_aspeed_dir, reference_dts_name)
    new_dts_file = os.path.join(linux_aspeed_dir, new_dts_name)

    if not os.path.isfile(reference_dts_file):
        print(
            "Warning: Unable to find "
            f"{reference_dts_name} for reference. Please manually add "
            f"{new_dts_name}."
        )
        return

    dts_file_action = "Modified file" if os.path.exists(new_dts_file) else "Added file"
    shutil.copyfile(reference_dts_file, new_dts_file)
    add_log_entry(dts_file_action, new_dts_file)
    update_devicetree_model(new_dts_file, new_platform)


def update_devicetree_model(dts_file, new_platform):
    with open(dts_file, "r", encoding="utf-8") as devicetree_file:
        lines = devicetree_file.readlines()

    for index, line in enumerate(lines):
        stripped_line = line.lstrip()
        if not stripped_line.startswith("model ="):
            continue

        indent = line[: len(line) - len(stripped_line)]
        lines[index] = f'{indent}model = "MiTAC {new_platform}";\n'
        break
    else:
        print(
            f"Warning: Unable to find model in {dts_file}. "
            "Please manually check and update."
        )
        return

    with open(dts_file, "w", encoding="utf-8") as devicetree_file:
        devicetree_file.writelines(lines)
    add_log_entry("Modified file", dts_file)


def add_new_platform_src_uri_appends(
    machine_conf_file, reference_platform, new_platform
):
    layer_dir = get_layer_dir(machine_conf_file)
    reference_profile = f"com.mitac.Hardware.Chassis.Model.{reference_platform}"
    new_profile = f"com.mitac.Hardware.Chassis.Model.{new_platform}"
    matched_recipe_files = []

    for root, _dirs, files in os.walk(layer_dir):
        for file_name in files:
            if not (file_name.endswith(".bbappend") or file_name.endswith(".bb")):
                continue

            recipe_file = os.path.join(root, file_name)
            if add_new_platform_to_src_uri_append(
                recipe_file, reference_profile, new_profile
            ):
                matched_recipe_files.append(recipe_file)

    return matched_recipe_files


def add_new_platform_to_src_uri_append(recipe_file, reference_profile, new_profile):
    platform_profile_prefix = "com.mitac.Hardware.Chassis.Model."

    with open(recipe_file, "r", encoding="utf-8") as src_file:
        lines = src_file.readlines()

    updated_lines = []
    index = 0
    changed = False
    matched = False

    while index < len(lines):
        line = lines[index]
        stripped_line = line.strip()

        if not stripped_line.startswith("SRC_URI:append"):
            updated_lines.append(line)
            index += 1
            continue

        block_lines = [line]
        index += 1
        if '"' not in stripped_line:
            block_done = True
        elif '"' in stripped_line.split('"', 1)[1]:
            block_done = True
        else:
            block_done = False

        while index < len(lines) and not block_done:
            block_line = lines[index]
            block_lines.append(block_line)
            index += 1
            if '"' in block_line:
                block_done = True

        block_matched = any(reference_profile in block_line for block_line in block_lines)
        if block_matched:
            matched = True

        if block_matched and not any(
            new_profile in block_line for block_line in block_lines
        ):
            updated_block_lines = []
            last_profile_index = None

            for block_index, block_line in enumerate(block_lines):
                if platform_profile_prefix in block_line:
                    last_profile_index = block_index

            for block_index, block_line in enumerate(block_lines):
                updated_block_lines.append(block_line)
                if block_index == last_profile_index:
                    updated_block_lines.append(
                        re.sub(
                            rf"{re.escape(platform_profile_prefix)}[^/\\\"'\s]+",
                            new_profile,
                            block_line,
                            count=1,
                        )
                    )
                    changed = True
            block_lines = updated_block_lines

        updated_lines.extend(block_lines)

    if changed:
        with open(recipe_file, "w", encoding="utf-8") as src_file:
            src_file.writelines(updated_lines)
        add_log_entry("Modified file", recipe_file)

    return matched


def add_new_platform_config_dirs(recipe_files, reference_platform, new_platform):
    reference_profile = f"com.mitac.Hardware.Chassis.Model.{reference_platform}"
    new_profile = f"com.mitac.Hardware.Chassis.Model.{new_platform}"

    for recipe_file in recipe_files:
        recipe_dir = os.path.dirname(recipe_file)
        reference_dirs = []

        for root, dirs, _files in os.walk(recipe_dir):
            for dir_name in dirs:
                if dir_name == reference_profile:
                    reference_dirs.append(os.path.join(root, dir_name))

        if not reference_dirs:
            print(
                f"Warning: Unable to find {reference_profile} under "
                f"{recipe_dir}. Please manually add {new_profile}."
            )
            continue

        for reference_dir in reference_dirs:
            new_platform_dir = os.path.join(os.path.dirname(reference_dir), new_profile)
            if os.path.exists(new_platform_dir):
                continue
            shutil.copytree(reference_dir, new_platform_dir)
            rename_platform_paths(
                new_platform_dir, reference_platform, new_platform
            )
            add_added_tree_log_entries(new_platform_dir)
            replace_platform_in_files(
                new_platform_dir, reference_platform, new_platform
            )


def rename_platform_paths(base_dir, reference_platform, new_platform):
    reference_platform_exact = reference_platform
    reference_platform_upper = reference_platform.upper()
    reference_platform_lower = reference_platform.lower()
    new_platform_exact = new_platform
    new_platform_upper = new_platform.upper()
    new_platform_lower = new_platform.lower()

    for root, dirs, files in os.walk(base_dir, topdown=False):
        for file_name in files:
            rename_path_if_needed(
                root,
                file_name,
                reference_platform_exact,
                reference_platform_upper,
                reference_platform_lower,
                new_platform_exact,
                new_platform_upper,
                new_platform_lower,
            )

        for dir_name in dirs:
            rename_path_if_needed(
                root,
                dir_name,
                reference_platform_exact,
                reference_platform_upper,
                reference_platform_lower,
                new_platform_exact,
                new_platform_upper,
                new_platform_lower,
            )


def rename_path_if_needed(
    parent_dir,
    path_name,
    reference_platform_exact,
    reference_platform_upper,
    reference_platform_lower,
    new_platform_exact,
    new_platform_upper,
    new_platform_lower,
):
    new_path_name = path_name.replace(reference_platform_exact, new_platform_exact)
    new_path_name = new_path_name.replace(reference_platform_upper, new_platform_upper)
    new_path_name = new_path_name.replace(reference_platform_lower, new_platform_lower)

    if new_path_name == path_name:
        return

    old_path = os.path.join(parent_dir, path_name)
    new_path = os.path.join(parent_dir, new_path_name)

    if os.path.exists(new_path):
        print(
            f"Warning: Unable to rename {old_path} to {new_path} "
            "because the destination already exists."
        )
        return

    os.rename(old_path, new_path)
    add_rename_log_entry(old_path, new_path)


def replace_platform_in_files(base_dir, reference_platform, new_platform):
    reference_platform_exact = reference_platform.encode("ascii")
    reference_platform_upper = reference_platform.upper().encode("ascii")
    reference_platform_lower = reference_platform.lower().encode("ascii")
    new_platform_exact = new_platform.encode("ascii")
    new_platform_upper = new_platform.upper().encode("ascii")
    new_platform_lower = new_platform.lower().encode("ascii")

    for root, _dirs, files in os.walk(base_dir):
        for file_name in files:
            file_path = os.path.join(root, file_name)

            with open(file_path, "rb") as src_file:
                content = src_file.read()

            updated_content = content.replace(
                reference_platform_exact, new_platform_exact
            )
            updated_content = updated_content.replace(
                reference_platform_upper, new_platform_upper
            )
            updated_content = updated_content.replace(
                reference_platform_lower, new_platform_lower
            )

            if updated_content == content:
                continue

            with open(file_path, "wb") as src_file:
                src_file.write(updated_content)
            add_log_entry("Modified file", file_path)


def main():
    machine_conf_files = find_machine_conf_files(META_MITACCOMPUTING_DIR)
    selected_machine_conf = select_machine_conf(machine_conf_files.keys())
    machine_conf_file = machine_conf_files[selected_machine_conf]
    reference_platforms = parse_reference_platforms(
        machine_conf_file
    )
    reference_platform = select_reference_platform(reference_platforms)
    new_platform = input_new_platform(reference_platforms)
    confirm_new_platform(new_platform)
    add_kernel_devicetree(machine_conf_file, new_platform)
    add_platform_profile(machine_conf_file, new_platform)
    add_new_platform_kernel_devicetree(
        machine_conf_file, reference_platform, new_platform
    )
    matched_recipe_files = add_new_platform_src_uri_appends(
        machine_conf_file, reference_platform, new_platform
    )
    add_new_platform_config_dirs(
        matched_recipe_files, reference_platform, new_platform
    )
    write_log_file()


if __name__ == "__main__":
    main()
