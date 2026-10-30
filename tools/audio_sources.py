"""Fetch public CC0 Freesound previews, keeping provenance outside the app."""
import json
import hashlib
import math
from pathlib import Path
import re
import random
import shutil
import struct
import subprocess
import urllib.request
import wave

OUT = Path('tools/art/out/audio-review')
OUT.mkdir(parents=True, exist_ok=True)


def inspect(name, url):
    request = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    html = urllib.request.urlopen(request, timeout=40).read().decode()
    (OUT / f'{name}.html').write_text(html, encoding='utf8')
    urls = sorted(set(re.findall(r'https[^\s\"<>]+\.(?:mp3|ogg|wav)', html)))
    print(json.dumps({'name': name, 'cc0': 'creativecommons.org/publicdomain/zero' in html,
                      'previews': urls}, ensure_ascii=False))
    return html, urls


SOURCES = [
        ('cat', 'https://freesound.org/people/tuberatanka/sounds/110011/'),
        ('rain', 'https://freesound.org/people/barkenov/sounds/640655/'),
        ('door', 'https://freesound.org/people/pagancow/sounds/15419/'),
        ('dog', 'https://freesound.org/people/ipears1/sounds/118072/'),
        ('step', 'https://freesound.org/people/ZNukem/sounds/697182/'),
        ('bird', 'https://freesound.org/people/JavierSerrat/sounds/524345/'),
        ('window', 'https://freesound.org/people/SamuelGremaud/sounds/437636/'),
]


def build():
    ffmpeg = shutil.which('ffmpeg')
    if not ffmpeg:
        raise RuntimeError('An existing FFmpeg is required.')
    evidence = []
    for name, url in SOURCES:
        html, previews = inspect(name, url)
        if 'creativecommons.org/publicdomain/zero' not in html:
            raise RuntimeError(f'CC0 license not confirmed: {url}')
        preview = next(p for p in previews if p.startswith('https://cdn.freesound.org/') and p.endswith('-hq.mp3'))
        source = OUT / f'{name}-source.mp3'
        urllib.request.urlretrieve(preview, source)
        limit = {'cat': 2, 'rain': 24, 'door': 2.2, 'dog': 2, 'step': .4, 'bird': 3, 'window': 2.6}[name]
        destination = OUT / f'{name}.wav'
        filters = 'highpass=f=65,lowpass=f=9500'
        if name != 'rain':
            filters += ',silenceremove=start_periods=1:start_threshold=-48dB:start_silence=0.01'
        command = [ffmpeg, '-y', '-v', 'error', '-i', str(source), '-t', str(limit),
                   '-af', filters, '-ac', '1', '-ar', '22050', '-c:a', 'pcm_s16le', str(destination)]
        subprocess.run(command, check=True)
        with wave.open(str(destination), 'rb') as stream:
            rate = stream.getframerate()
            samples = list(struct.unpack('<' + 'h' * stream.getnframes(), stream.readframes(stream.getnframes())))
        if not samples:
            raise RuntimeError(f'No audible samples: {name}')
        peak = max(abs(s) for s in samples)
        gain = min(5, 10 ** (-4 / 20) * 32767 / max(1, peak))
        samples = [int(s * gain) for s in samples]
        if name == 'rain':
            # Equal-gain overlap gives a continuous looping rain bed.
            overlap = int(rate * .75)
            join = [int(samples[-overlap+i] * (1-i/overlap) + samples[i] * (i/overlap)) for i in range(overlap)]
            samples = samples[overlap:-overlap] + join
        else:
            fade = min(int(rate * .012), len(samples) // 4)
            for i in range(fade):
                samples[i] = int(samples[i] * i / fade)
                samples[-i-1] = int(samples[-i-1] * i / fade)
        with wave.open(str(destination), 'wb') as stream:
            stream.setnchannels(1)
            stream.setsampwidth(2)
            stream.setframerate(rate)
            stream.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
        evidence.append({'cue': name, 'author': url.split('/people/')[1].split('/')[0], 'page': url, 'preview': preview,
                         'license': 'CC0-1.0', 'license_url': 'https://creativecommons.org/publicdomain/zero/1.0/',
                         'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                         'output_sha256': hashlib.sha256(destination.read_bytes()).hexdigest(),
                         'duration': len(samples)/rate, 'processing': 'mono 22050Hz, filtering, peak -4dBFS max, fades; rain overlap loop'})
    (OUT / 'sources.json').write_text(json.dumps(evidence, indent=2), encoding='utf8')
    rng = random.Random(290610)
    samples = []
    previous = 0.0
    for i in range(int(22050 * .26)):
        previous = .65 * previous + .35 * rng.uniform(-1, 1)
        envelope = math.sin(math.pi * i / (22050 * .26)) ** 2
        samples.append(int(previous * envelope * 22000))
    with wave.open(str(OUT / 'swing.wav'), 'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(22050)
        stream.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
    print('Built seven reviewed-source candidates outside assets.')


if __name__ == '__main__':
    build()
