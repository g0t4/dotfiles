#!/usr/bin/env python3
"""Connect/disconnect the AirPods Pro #2 via IOBluetooth (macOS only).

The bluetooth device is looked up by partial name match (via `system_profiler`)
so the MAC address doesn't need to be hardcoded and the script stays portable
across Macs. macOS auto-selects a freshly-connected bluetooth output device as
the default and reverts the default when it disconnects, so this just toggles
the bluetooth link. Requires the macOS-only dependency pyobjc-framework-IOBluetooth.

Usage: airpods.py connect|disconnect [name]

`name` is a partial device-name match (first match is used); defaults to
"AirPods Pro #2".
"""

import subprocess
import sys
import time

import IOBluetooth

# partial name match against the paired-device list
AIRPODS_NAME = "AirPods Pro #2"
CONNECT_WAIT_SECONDS = 5.0
# `system_profiler` section headers (not device names)
_SECTION_HEADERS = {"Bluetooth", "Bluetooth Controller", "Connected", "Not Connected"}


def system_bluetooth_text() -> str:
    """Return the full `system_profiler SPBluetoothDataType` output."""
    result = subprocess.run(
        ["system_profiler", "SPBluetoothDataType"], capture_output=True, text=True
    )
    return result.stdout


def find_address_by_name(name_substring: str) -> str | None:
    """Return the bluetooth address of the paired device whose name contains
    `name_substring`, or None if no paired device matches."""
    text = system_bluetooth_text()
    # device blocks look like: <name>: ... Address: AA:BB:CC:DD:EE:FF
    # track the current device name, binding each Address line to the device it
    # belongs to (section headers are excluded so they can't steal an address).
    current_name = None
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.endswith(":") and not stripped.startswith("Address"):
            name = stripped[:-1]
            current_name = None if name in _SECTION_HEADERS else name
        elif stripped.startswith("Address:") and current_name:
            address = stripped.split(":", 1)[1].strip()
            if name_substring in current_name:
                return address
    return None


def find_device(name_substring: str = AIRPODS_NAME) -> IOBluetooth.IOBluetoothDevice:
    """Return the IOBluetoothDevice for the first bluetooth device whose name
    contains `name_substring`."""
    address = find_address_by_name(name_substring)
    if address is None:
        raise RuntimeError(f"no paired bluetooth device matching {name_substring!r}")
    device = IOBluetooth.IOBluetoothDevice.deviceWithAddressString_(address)
    if device is None:
        raise RuntimeError(f"no IOBluetooth device for {address}")
    return device


def connect(name_substring: str = AIRPODS_NAME) -> int:
    """Open the bluetooth connection and wait for it to establish."""
    device = find_device(name_substring)
    if device.isConnected():
        print("already connected")
        return 0
    io_return = device.openConnection()
    if io_return != 0:
        print(f"openConnection failed (IOReturn {io_return})")
        return 1
    deadline = time.monotonic() + CONNECT_WAIT_SECONDS
    while time.monotonic() < deadline:
        time.sleep(0.5)
        if device.isConnected():
            print("connected")
            return 0
    print("timed out waiting to connect")
    return 1


def disconnect(name_substring: str = AIRPODS_NAME) -> int:
    """Close the bluetooth connection and wait for it to drop."""
    device = find_device(name_substring)
    if not device.isConnected():
        print("already disconnected")
        return 0
    io_return = device.closeConnection()
    if io_return != 0:
        print(f"closeConnection failed (IOReturn {io_return})")
        return 1
    deadline = time.monotonic() + CONNECT_WAIT_SECONDS
    while time.monotonic() < deadline:
        time.sleep(0.5)
        if not device.isConnected():
            print("disconnected")
            return 0
    print("timed out waiting to disconnect")
    return 1


def main(argv: list[str]) -> int:
    """Dispatch to the requested subcommand."""
    command = argv[1] if len(argv) > 1 else "connect"
    name_substring = argv[2] if len(argv) > 2 else AIRPODS_NAME
    if command == "connect":
        return connect(name_substring)
    if command == "disconnect":
        return disconnect(name_substring)
    print(f"unknown command: {command}")
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
