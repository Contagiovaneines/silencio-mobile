"""Offline Java reference analysis. Outputs are development evidence, never assets.

Requires an explicitly selected local CFR JAR and Java runtime. Does not install
software, start the game, change REA configuration or download game files.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jar', type=Path, required=True)
    parser.add_argument('--cfr', type=Path, required=True)
    parser.add_argument('--java', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--class-name', action='append', dest='classes')
    args = parser.parse_args()
    source, cfr, java, output = (p.resolve() for p in (args.jar, args.cfr, args.java, args.output))
    assets = Path(__file__).resolve().parents[1] / 'assets'
    if output == assets or assets in output.parents:
        parser.error('Reference analysis must stay outside application assets.')
    for path in (source, cfr, java):
        if not path.is_file():
            parser.error(f'Missing input: {path}')
    selected = args.classes or ['zombie/iso/IsoCamera.class', 'zombie/iso/IsoObject.class', 'zombie/iso/IsoGridSquare.class']
    output.mkdir(parents=True, exist_ok=True)
    evidence = {'provider': 'CFR (direct CLI, not REA/JEB)', 'input': str(source),
                'input_sha256': digest(source), 'cfr': str(cfr), 'cfr_sha256': digest(cfr),
                'java': str(java), 'classes': []}
    failed = False
    with zipfile.ZipFile(source) as archive:
        for name in selected:
            target = (output / 'classes' / name).resolve()
            root = (output / 'classes').resolve()
            if root not in target.parents or not name.endswith('.class'):
                parser.error(f'Invalid class entry: {name}')
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(archive.read(name))
            command = [str(java), '-jar', str(cfr), str(target), '--outputdir',
                       str(output / 'decompiled'), '--extraclasspath', str(source), '--silent', 'true']
            log = output / f'{target.stem}.log'
            with log.open('w', encoding='utf8') as stream:
                result = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT, timeout=180, check=False)
            generated = output / 'decompiled' / Path(name).with_suffix('.java')
            ok = result.returncode == 0 and generated.is_file() and generated.stat().st_size > 0
            failed |= not ok
            evidence['classes'].append({'entry': name, 'class_sha256': digest(target),
                'command': command, 'returncode': result.returncode, 'output': str(generated),
                'output_sha256': digest(generated) if generated.is_file() else None,
                'log': str(log), 'decompiled': ok})
            print(f'{name}: {"OK" if ok else "FAILED"}', flush=True)
    (output / 'provenance.json').write_text(json.dumps(evidence, indent=2), encoding='utf8')
    raise SystemExit(1 if failed else 0)


if __name__ == '__main__':
    main()
