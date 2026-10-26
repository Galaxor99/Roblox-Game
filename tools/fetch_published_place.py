"""Download a place snapshot with an owner-authorized Roblox Open Cloud key.

This is read-only. It saves a separate reference file and never publishes a place.
The Asset Delivery API can return a binary .rbxl; use Studio to save that file as
.rbxlx before passing it to export_place.py.
"""
from __future__ import annotations

import argparse
import gzip
import json
import os
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import Request, urlopen
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PLACE_ID = 99438308921556
MAX_BYTES = 128 * 1024 * 1024


def _read_limited(response) -> bytes:
    data = response.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise ValueError('Place download exceeded 128 MiB')
    if response.headers.get('Content-Encoding', '').lower() == 'gzip':
        data = gzip.decompress(data)
        if len(data) > MAX_BYTES:
            raise ValueError('Decompressed place exceeded 128 MiB')
    return data


def _cdn_url(location: str) -> str:
    parsed = urlparse(location)
    host = parsed.hostname or ''
    if parsed.scheme != 'https' or not (host.endswith('.rbxcdn.com') or host == 'rbxcdn.com'):
        raise ValueError('Roblox returned an unexpected asset host')
    return location


def fetch(place_id: int, api_key: str, opener=urlopen) -> tuple[bytes, str]:
    if place_id <= 0 or not api_key:
        raise ValueError('A valid place ID and Open Cloud API key are required')
    endpoint = f'https://apis.roblox.com/asset-delivery-api/v1/assetId/{place_id}'
    request = Request(endpoint, headers={'x-api-key': api_key, 'Accept': 'application/json'})
    with opener(request, timeout=30) as response:
        metadata = json.loads(_read_limited(response))
    location = _cdn_url(metadata.get('location', ''))
    with opener(Request(location), timeout=90) as response:
        data = _read_limited(response)
    if data.startswith(b'<roblox!'):
        return data, '.rbxl'
    if data.lstrip().startswith((b'<?xml', b'<roblox')):
        root = ET.fromstring(data)
        if root.tag != 'roblox':
            raise ValueError('Downloaded XML is not a Roblox place')
        return data, '.rbxlx'
    raise ValueError('Downloaded asset is not a Roblox place file')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--place-id', type=int, default=PLACE_ID)
    parser.add_argument('--output-dir', type=Path, default=ROOT / 'reference')
    args = parser.parse_args()
    key = os.environ.get('NEXUS_ROBLOX_API_KEY', '')
    if not key:
        parser.error('Set NEXUS_ROBLOX_API_KEY in your environment; do not put it in the repository')
    data, extension = fetch(args.place_id, key)
    destination = args.output_dir / f'Nexus_Test.published{extension}'
    if destination.exists():
        parser.error(f'{destination} exists; move it aside before downloading a new snapshot')
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data)
    print(f'Saved {destination} ({len(data)} bytes). This did not publish or change the live place.')
    if extension == '.rbxl':
        print('Open the binary file in Studio and save it as .rbxlx before using export_place.py.')


if __name__ == '__main__':
    main()
