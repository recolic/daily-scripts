#!/usr/bin/env python3
"""Control a Shelly plug over Bluetooth LE RPC.

This script intentionally exposes only 3 commands:
    status | on | off

1. pacman -S python-bleak
2. Set your device MAC in TARGET_MAC below.

----
## Pairing notes

Shelly firmware 2.0+ requires Bluetooth pairing for BLE RPC after initial provisioning.

1. Ensure BLE RPC is enabled on the Shelly device: `BLE.SetConfig` with `{"rpc":{"enable":true}}`.
2. Put the Shelly in BLE pairing mode, for example via HTTP/Wi-Fi:
   `http://SHELLY_IP/rpc/BLE.StartPairing?timeout=120`
3. Run once with `--pair`:

```sh
./shelly_ble_plug.py --pair status
```

After the bond is stored by BlueZ and the Shelly, later `on`/`off` commands should not need `--pair`.

GPT 5.5
"""

from __future__ import annotations

import argparse
import asyncio
import json
import shutil
import struct
import subprocess
import sys
from dataclasses import dataclass
from typing import Any

try:
    from bleak import BleakClient, BleakScanner
    from bleak.backends.device import BLEDevice
    from bleak.exc import BleakError
except ImportError:  # pragma: no cover - friendly runtime message
    print("Missing dependency: bleak. Install with: python3 -m pip install -r requirements.txt", file=sys.stderr)
    raise SystemExit(2)

RPC_SERVICE_UUID = "5f6d4f53-5f52-5043-5f53-56435f49445f"
DATA_CHARACTERISTIC_UUID = "5f6d4f53-5f52-5043-5f64-6174615f5f5f"
TX_CONTROL_CHARACTERISTIC_UUID = "5f6d4f53-5f52-5043-5f74-785f63746c5f"
RX_CONTROL_CHARACTERISTIC_UUID = "5f6d4f53-5f52-5043-5f72-785f63746c5f"

RX_POLL_INTERVAL = 0.1
RX_POLL_MAX_ATTEMPTS = 50

# Put your Shelly BLE MAC address here.
TARGET_MAC = "A0:DD:6C:4A:94:3A"


class ShellyBleError(RuntimeError):
    """Raised for Shelly BLE/RPC failures."""


@dataclass
class ShellyBleRpc:
    device: BLEDevice
    pair: bool = False
    timeout: float = 15.0

    def __post_init__(self) -> None:
        self._client: BleakClient | None = None
        self._call_id = 0

    async def __aenter__(self) -> "ShellyBleRpc":
        await self.connect()
        return self

    async def __aexit__(self, *_exc: object) -> None:
        await self.disconnect()

    async def connect(self) -> None:
        if self._client and self._client.is_connected:
            return

        self._client = BleakClient(self.device, pair=self.pair, timeout=self.timeout)
        try:
            await self._client.connect()
            await self._verify_rpc_service()
        except Exception:
            await self.disconnect()
            raise

    async def disconnect(self) -> None:
        if self._client is not None:
            try:
                if self._client.is_connected:
                    await self._client.disconnect()
            finally:
                self._client = None

    async def _verify_rpc_service(self) -> None:
        assert self._client is not None
        services = self._client.services
        if services.get_service(RPC_SERVICE_UUID) is None:
            raise ShellyBleError(
                "Shelly BLE RPC service not found. Check that BLE RPC is enabled "
                "and that this is a Shelly Gen2/Gen3/Gen4 device."
            )
        for label, uuid in {
            "data": DATA_CHARACTERISTIC_UUID,
            "TX control": TX_CONTROL_CHARACTERISTIC_UUID,
            "RX control": RX_CONTROL_CHARACTERISTIC_UUID,
        }.items():
            if services.get_characteristic(uuid) is None:
                raise ShellyBleError(f"Missing Shelly BLE RPC {label} characteristic: {uuid}")

    async def call(self, method: str, params: dict[str, Any] | None = None) -> Any:
        assert self._client is not None
        if not self._client.is_connected:
            await self.connect()

        self._call_id += 1
        request: dict[str, Any] = {"id": self._call_id, "method": method}
        if params is not None:
            request["params"] = params

        payload = json.dumps(request, separators=(",", ":")).encode("utf-8")
        await self._send(payload)
        response = await self._receive()

        try:
            frame = json.loads(response.decode("utf-8"))
        except ValueError as exc:
            raise ShellyBleError(f"Invalid JSON response: {response!r}") from exc

        if frame.get("id") != self._call_id:
            raise ShellyBleError(f"RPC response id mismatch: expected {self._call_id}, got {frame.get('id')}")
        if "error" in frame:
            error = frame["error"]
            raise ShellyBleError(f"RPC error {error.get('code')}: {error.get('message')}")
        return frame.get("result")

    async def _send(self, data: bytes) -> None:
        assert self._client is not None
        await self._client.write_gatt_char(TX_CONTROL_CHARACTERISTIC_UUID, struct.pack(">I", len(data)))
        await self._client.write_gatt_char(DATA_CHARACTERISTIC_UUID, data)

    async def _receive(self) -> bytes:
        assert self._client is not None
        frame_length = 0

        for _ in range(RX_POLL_MAX_ATTEMPTS):
            raw_length = await self._client.read_gatt_char(RX_CONTROL_CHARACTERISTIC_UUID)
            if len(raw_length) < 4:
                raise ShellyBleError(f"Invalid RX frame length: {raw_length.hex()}")
            frame_length = struct.unpack(">I", bytes(raw_length[:4]))[0]
            if frame_length:
                break
            await asyncio.sleep(RX_POLL_INTERVAL)

        if not frame_length:
            raise ShellyBleError("Timed out waiting for Shelly BLE RPC response")

        chunks = bytearray()
        empty_reads = 0
        while len(chunks) < frame_length:
            chunk = bytes(await self._client.read_gatt_char(DATA_CHARACTERISTIC_UUID))
            if not chunk:
                empty_reads += 1
                if not chunks and empty_reads < RX_POLL_MAX_ATTEMPTS:
                    await asyncio.sleep(RX_POLL_INTERVAL)
                    continue
                break
            chunks.extend(chunk)

        if len(chunks) < frame_length:
            # Some Shelly firmware versions can report a bad frame length while
            # still returning a complete JSON frame. Accept it if JSON parses.
            try:
                json.loads(chunks.decode("utf-8"))
                return bytes(chunks)
            except ValueError:
                raise ShellyBleError(f"Incomplete response: expected {frame_length} bytes, got {len(chunks)}")

        return bytes(chunks[:frame_length])


def ensure_adapter_powered() -> None:
    """Best-effort adapter power-on using bluez-utils' bluetoothctl."""
    if shutil.which("bluetoothctl") is None:
        return

    try:
        show = subprocess.run(
            ["bluetoothctl", "show"],
            check=False,
            text=True,
            capture_output=True,
            timeout=5,
        )
    except Exception:
        return

    if "Powered: no" in show.stdout:
        subprocess.run(["bluetoothctl", "power", "on"], check=False, timeout=5)


async def resolve_device(scan_timeout: float) -> BLEDevice:
    device = await BleakScanner.find_device_by_address(TARGET_MAC, timeout=scan_timeout)
    if device is None:
        raise ShellyBleError(
            f"BLE device not found by address: {TARGET_MAC}. "
            "Update TARGET_MAC in this script."
        )
    return device


async def run(args: argparse.Namespace) -> int:
    ensure_adapter_powered()
    device = await resolve_device(args.scan_timeout)

    try:
        async with ShellyBleRpc(device, pair=args.pair, timeout=args.timeout) as rpc:
            if args.command == "status":
                result = await rpc.call("Switch.GetStatus", {"id": args.switch_id})
            else:
                result = await rpc.call("Switch.Set", {"id": args.switch_id, "on": args.command == "on"})
    except BleakError as exc:
        raise ShellyBleError(str(exc)) from exc

    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Control a Shelly plug over Bluetooth LE RPC")
    parser.add_argument("--switch-id", type=int, default=0, help="Switch component id, default: 0")
    parser.add_argument("--scan-timeout", type=float, default=8.0, help="BLE scan timeout in seconds, default: 8")
    parser.add_argument("--timeout", type=float, default=15.0, help="BLE connection timeout in seconds, default: 15")
    parser.add_argument("--pair", action="store_true", help="Ask BlueZ/Bleak to pair while connecting")
    parser.add_argument("command", choices=("status", "on", "off"))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        return asyncio.run(run(args))
    except KeyboardInterrupt:
        return 130
    except ShellyBleError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
