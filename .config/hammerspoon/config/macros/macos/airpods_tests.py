"""Tests for the IOBluetooth AirPods helper (macOS only)."""

import pytest

airpods = pytest.importorskip("airpods")


# realistic system_profiler SPBluetoothDataType snippet, AirPods under "Connected"
SAMPLE_BT = """Bluetooth:
    Bluetooth Controller:
        Address: 11:22:33:44:55:66
    Connected:
        Wes’s AirPods Pro #2:
            Address: AA:BB:CC:DD:EE:FF
    Not Connected:
        AirPods Max:
            Address: 12:34:56:78:9A:BC
"""


def test_find_address_by_name(monkeypatch):
    monkeypatch.setattr(airpods, "system_bluetooth_text", lambda: SAMPLE_BT)
    assert airpods.find_address_by_name("AirPods Pro #2") == "AA:BB:CC:DD:EE:FF"


def test_find_address_by_name_partial_match(monkeypatch):
    monkeypatch.setattr(airpods, "system_bluetooth_text", lambda: SAMPLE_BT)
    assert airpods.find_address_by_name("AirPods Pro") == "AA:BB:CC:DD:EE:FF"


def test_find_address_by_name_unknown_returns_none(monkeypatch):
    monkeypatch.setattr(airpods, "system_bluetooth_text", lambda: SAMPLE_BT)
    assert airpods.find_address_by_name("Bogus Device") is None


def test_find_address_by_name_first_match(monkeypatch):
    # two devices contain "AirPods Pro"; the first in the output wins
    both = SAMPLE_BT.replace(
        "        Wes’s AirPods Pro #2:",
        "        Wes’s AirPods Pro:\n            Address: DE:AD:BE:EF:00:01\n        Wes’s AirPods Pro #2:",
    )
    monkeypatch.setattr(airpods, "system_bluetooth_text", lambda: both)
    assert airpods.find_address_by_name("AirPods Pro") == "DE:AD:BE:EF:00:01"


def test_main_passes_name_to_connect(monkeypatch):
    received = []
    monkeypatch.setattr(airpods, "connect", lambda name: received.append(name) or 0)
    assert airpods.main(["airpods.py", "connect", "Bose"]) == 0
    assert received == ["Bose"]


def test_main_defaults_name_to_airpods(monkeypatch):
    received = []
    monkeypatch.setattr(airpods, "connect", lambda name: received.append(name) or 0)
    assert airpods.main(["airpods.py", "connect"]) == 0
    assert received == ["AirPods Pro #2"]


def test_main_defaults_to_connect(monkeypatch):
    monkeypatch.setattr(airpods, "connect", lambda _name: 0)
    assert airpods.main(["airpods.py"]) == 0


def test_main_dispatches_connect(monkeypatch):
    monkeypatch.setattr(airpods, "connect", lambda _name: 0)
    assert airpods.main(["airpods.py", "connect"]) == 0


def test_main_dispatches_disconnect(monkeypatch):
    monkeypatch.setattr(airpods, "disconnect", lambda _name: 0)
    assert airpods.main(["airpods.py", "disconnect"]) == 0


def test_main_unknown_command(monkeypatch):
    assert airpods.main(["airpods.py", "bogus"]) == 2


def test_connect_already_connected(monkeypatch):
    class FakeDevice:
        def isConnected(self):
            return True

    monkeypatch.setattr(airpods, "find_device", lambda _name: FakeDevice())
    assert airpods.connect() == 0


def test_connect_times_out(monkeypatch):
    class FakeDevice:
        def isConnected(self):
            return False

        def openConnection(self):
            return 0

    monkeypatch.setattr(airpods, "find_device", lambda _name: FakeDevice())
    monkeypatch.setattr(airpods.time, "sleep", lambda _seconds: None)
    monkeypatch.setattr(airpods.time, "monotonic", lambda: 0)
    monkeypatch.setattr(airpods, "CONNECT_WAIT_SECONDS", 0.0)
    assert airpods.connect() == 1


def test_disconnect_already_disconnected(monkeypatch):
    class FakeDevice:
        def isConnected(self):
            return False

    monkeypatch.setattr(airpods, "find_device", lambda _name: FakeDevice())
    assert airpods.disconnect() == 0
