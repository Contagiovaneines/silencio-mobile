"""Local review of the explicitly selected Android test device; never clears data."""
import argparse
import sys
sys.stdout.reconfigure(encoding="utf-8")
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument('action', choices=['capture', 'inspect', 'tap', 'swipe'])
parser.add_argument('values', nargs='+')
args = parser.parse_args()
adb = ['adb', '-s', 'RQCX505FQMJ']
if args.action in ('capture', 'inspect'):
    if args.action == 'inspect':
        remote = '/sdcard/Download/silencio-review.xml'
        subprocess.run(adb + ['shell', 'uiautomator', 'dump', remote], capture_output=True, check=True)
        xml = subprocess.run(adb + ['exec-out', 'cat', remote], capture_output=True, check=True).stdout
        for node in ET.fromstring(xml).iter('node'):
            label = node.get('content-desc') or node.get('text')
            if label:
                print(label, node.get('bounds'))
    label = args.values[0]
    if not label.replace('-', '').replace('_', '').isalnum():
        raise ValueError('Use a simple screenshot label')
    target = Path(__file__).resolve().parents[1] / 'docs' / 'screenshots' / f'android04-{label}.png'
    data = subprocess.run(adb + ['exec-out', 'screencap', '-p'], capture_output=True, check=True).stdout
    target.write_bytes(data)
    print(target)
else:
    values = [str(int(v)) for v in args.values]
    expected = 2 if args.action == 'tap' else 5
    if len(values) != expected:
        raise ValueError('Unexpected input arguments')
    subprocess.run(adb + ['shell', 'input', args.action] + values, check=True)
