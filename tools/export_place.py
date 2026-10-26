"""Package the current Luau source into the user's original Roblox XML place.

This only rewrites Script/ModuleScript/LocalScript Source properties. The original
place remains unchanged, including its static Workspace objects and settings.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ORIGINAL = ROOT / 'reference/AnimeNexus_UI_Fixed_Studio_Build.original.rbxlx'
OUTPUT = ROOT / 'build/AnimeNexus_Test.rbxlx'
SCRIPTS = {
    ('ReplicatedStorage', 'NexusConfig'): ('ModuleScript', 'src/NexusConfig.luau'),
    ('ReplicatedStorage', 'NexusRoster'): ('ModuleScript', 'src/NexusRoster.luau'),
    ('ReplicatedStorage', 'NexusProgression'): ('ModuleScript', 'src/NexusProgression.luau'),
    ('ServerScriptService', 'NexusServer'): ('Script', 'src/NexusServer.server.luau'),
    ('ServerScriptService', 'NexusPersistence'): ('ModuleScript', 'src/NexusPersistence.luau'),
    ('ServerScriptService', 'NexusWorld'): ('ModuleScript', 'src/NexusWorld.luau'),
    ('ServerScriptService', 'NexusRankings'): ('ModuleScript', 'src/NexusRankings.luau'),
    ('ServerScriptService', 'NexusCoop'): ('ModuleScript', 'src/NexusCoop.luau'),
    ('StarterPlayerScripts', 'NexusClient'): ('LocalScript', 'src/NexusClient.client.luau'),
}


def name(item: ET.Element) -> str | None:
    return item.findtext("Properties/string[@name='Name']")


def child(parent: ET.Element, child_name: str) -> ET.Element:
    matches = [item for item in parent.findall('Item') if name(item) == child_name]
    if len(matches) != 1:
        raise ValueError(f'Expected one {child_name} under {name(parent)}, found {len(matches)}')
    return matches[0]


def validate(root: ET.Element) -> None:
    found: set[tuple[str, str]] = set()
    referents: set[str] = set()
    for item in root.iter('Item'):
        ref = item.get('referent')
        if not ref or ref in referents:
            raise ValueError(f'Missing or duplicate referent: {ref}')
        referents.add(ref)
    for (service, script_name), (class_name, source_path) in SCRIPTS.items():
        container = child(root, service) if service != 'StarterPlayerScripts' else child(child(root, 'StarterPlayer'), service)
        item = child(container, script_name)
        source = item.findtext("Properties/ProtectedString[@name='Source']")
        if item.get('class') != class_name or source != (ROOT / source_path).read_text(encoding='utf-8'):
            raise ValueError(f'Incorrect class or source for {service}/{script_name}')
        found.add((service, script_name))
    if found != set(SCRIPTS):
        raise ValueError('Script inventory does not match source manifest')
    child(child(root, 'Workspace'), 'Baseplate')


def build(output: Path) -> None:
    if not ORIGINAL.is_file():
        raise FileNotFoundError(ORIGINAL)
    root = ET.parse(ORIGINAL).getroot()
    if root.tag != 'roblox' or root.get('version') != '4':
        raise ValueError('Expected Roblox XML place format 4')
    for index, ((service, script_name), (class_name, source_path)) in enumerate(SCRIPTS.items()):
        container = child(root, service) if service != 'StarterPlayerScripts' else child(child(root, 'StarterPlayer'), service)
        existing = [item for item in container.findall('Item') if name(item) == script_name]
        if len(existing) > 1:
            raise ValueError(f'Duplicate script {script_name}')
        if existing:
            item = existing[0]
            if item.get('class') != class_name:
                raise ValueError(f'Class mismatch for existing {script_name}')
            props = item.find('Properties')
            source = props.find("ProtectedString[@name='Source']")
            if source is None:
                source = ET.SubElement(props, 'ProtectedString', {'name': 'Source'})
        else:
            item = ET.SubElement(container, 'Item', {'class': class_name, 'referent': f'NEXUS_SOURCE_{index:02d}'})
            props = ET.SubElement(item, 'Properties')
            ET.SubElement(props, 'string', {'name': 'Name'}).text = script_name
            ET.SubElement(props, 'bool', {'name': 'Disabled'}).text = 'false'
            source = ET.SubElement(props, 'ProtectedString', {'name': 'Source'})
        source.text = (ROOT / source_path).read_text(encoding='utf-8')
    validate(root)
    output.parent.mkdir(parents=True, exist_ok=True)
    ET.indent(root)
    ET.ElementTree(root).write(output, encoding='utf-8', xml_declaration=True)
    validate(ET.parse(output).getroot())
    print(f'{output} ({output.stat().st_size} bytes; {len(SCRIPTS)} embedded scripts)')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=OUTPUT)
    args = parser.parse_args()
    build(args.output)
