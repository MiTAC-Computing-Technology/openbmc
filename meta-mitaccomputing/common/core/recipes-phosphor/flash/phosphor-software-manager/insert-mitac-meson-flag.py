#!/usr/bin/env python3
"""Insert WANT_MITAC_SIGNATURE_VERIFY after the START_UPDATE meson flag.

The START_UPDATE_DBUS_INTEFACE block is identical on AST2600 (stock) and
AST2700 (after the SDK ASPEED_VERIFY line). Quilt hunks cannot share both
predecessors, so this edit is applied after do_patch.
"""

from pathlib import Path
import sys

NEEDLE = """conf.set(
    'START_UPDATE_DBUS_INTEFACE',
    get_option('software-update-dbus-interface').allowed(),
)
"""

INSERT = """conf.set(
    'START_UPDATE_DBUS_INTEFACE',
    get_option('software-update-dbus-interface').allowed(),
)
conf.set(
    'WANT_MITAC_SIGNATURE_VERIFY',
    get_option('verify-mitac-signature').enabled(),
)
"""


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: insert-mitac-meson-flag.py <bmc/meson.build>", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    text = path.read_text()
    if "WANT_MITAC_SIGNATURE_VERIFY" in text:
        return 0
    if NEEDLE not in text:
        print(
            f"{path}: START_UPDATE_DBUS_INTEFACE block not found",
            file=sys.stderr,
        )
        return 1
    path.write_text(text.replace(NEEDLE, INSERT, 1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
