"""Verify packaged reference files without touching gameplay or user outputs."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[1] / 'prompt'
manifests = list(root.rglob('ASSETS.json'))
assert len(manifests) == 9
count = 0
total = 0
for manifest in manifests:
    assert (manifest.parent / 'PROMPT.md').is_file()
    for asset in json.loads(manifest.read_text(encoding='utf-8')):
        path = manifest.parent / asset['file']
        assert path.is_file(), path
        assert hashlib.sha256(path.read_bytes()).hexdigest() == asset['sha256'], path
        count += 1
        total += path.stat().st_size
entries = json.loads((root / 'video' / 'manifest.json').read_text(encoding='utf-8'))
assert len(entries) == 4
for entry in entries:
    assert not entry['required_for_beta']
    assert (root / 'video' / entry['output']).parent.is_dir()
    placeholder = root / 'video' / entry['placeholder_image']
    game_asset = root.parent / entry['game_asset']
    assert placeholder.is_file(), placeholder
    assert game_asset.is_file(), game_asset
    assert any(
        asset['file'] == 'assets/' + placeholder.name
        and asset['role'] == 'generated_static_keyframe_placeholder'
        for asset in json.loads(
            (root / 'video' / entry['id'] / 'ASSETS.json').read_text(encoding='utf-8')
        )
    )
print(f'OK: {len(manifests)} pacotes, {count} referencias verificadas, {total / 1024 / 1024:.1f} MiB.')
print('Quatro quadros-chave estaticos validados e quatro destinos de video preparados.')
