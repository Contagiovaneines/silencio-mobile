"""Validate the shipped PCM effects and report reproducible signal metrics."""
import json
import math
from pathlib import Path
import struct
import wave

results = []
for path in sorted(Path('assets/audio').glob('*.wav')):
    with wave.open(str(path), 'rb') as stream:
        assert stream.getnchannels() == 1 and stream.getsampwidth() == 2, path
        assert stream.getframerate() == 22050, path
        frames = stream.getnframes()
        samples = struct.unpack('<' + 'h' * frames, stream.readframes(frames))
    assert frames > 0 and max(map(abs, samples)) > 10, path
    peak = max(map(abs, samples)) / 32768
    assert peak < .99, f'Clipping risk: {path}'
    dc = sum(samples) / frames / 32768
    assert abs(dc) < .03, f'DC offset: {path}'
    result = {'file': path.name, 'duration_seconds': round(frames / 22050, 3),
              'peak_dbfs': round(20 * math.log10(peak), 2), 'dc': round(dc, 6)}
    if path.stem == 'rain':
        result['loop_seam'] = abs(samples[0] - samples[-1]) / 32768
        assert result['loop_seam'] < .03, 'Audible rain loop discontinuity'
    results.append(result)
out = Path('tools/art/out/audio-review')
out.mkdir(parents=True, exist_ok=True)
(out / 'signal-check.json').write_text(json.dumps(results, indent=2), encoding='utf8')
print(f'{len(results)} WAV assets: format, non-silence, peak, DC and rain seam OK.')
