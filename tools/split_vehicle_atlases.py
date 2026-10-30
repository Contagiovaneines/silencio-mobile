"""Split generated, transparent vehicle angle atlases into runtime sprites.

This is a lossless crop only: it does not recolor, resample, or alter pixels.
Requires Pillow, already present in the art environment.
"""

from pathlib import Path

from PIL import Image


PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT / "tools" / "art" / "source" / "vehicle_atlases"
OUTPUT = PROJECT / "assets" / "images"
VIEWS = ("front_left", "front_right", "side", "rear_three_quarter")
X_REGIONS = {
    "sedan": ((0, 520), (515, 1040), (1040, 1630), (1620, 2172)),
    "van": ((0, 520), (515, 1040), (1040, 1630), (1620, 2172)),
    "bus": ((0, 520), (515, 1040), (1040, 1630), (1620, 2172)),
}
PADDING = 8
ALPHA_THRESHOLD = 32


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for vehicle, regions in X_REGIONS.items():
        path = SOURCE / f"{vehicle}.png"
        with Image.open(path) as atlas:
            if atlas.mode != "RGBA":
                raise ValueError(f"Expected alpha atlas: {path}")
            alpha = atlas.getchannel("A")
            for view, (left, right) in zip(VIEWS, regions, strict=True):
                mask = alpha.crop((left, 0, right, atlas.height)).point(
                    lambda value: 255 if value >= ALPHA_THRESHOLD else 0
                )
                bounds = mask.getbbox()
                if bounds is None:
                    raise ValueError(f"No visible sprite: {vehicle}/{view}")
                x0, y0, x1, y1 = bounds
                crop_box = (
                    max(0, left + x0 - PADDING),
                    max(0, y0 - PADDING),
                    min(atlas.width, left + x1 + PADDING),
                    min(atlas.height, y1 + PADDING),
                )
                destination = OUTPUT / f"vehicle_{vehicle}_{view}.png"
                atlas.crop(crop_box).save(destination, optimize=True)
                print(f"{destination.name}: {destination.stat().st_size} bytes")


if __name__ == "__main__":
    main()
