"""Split the transparent bathroom fixture atlas into runtime PNG sprites."""

from pathlib import Path

from PIL import Image


PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT / "tools" / "art" / "source" / "bathroom_fixtures" / "fixtures.png"
OUTPUT = PROJECT / "assets" / "images"
REGIONS = {
    "bathroom_toilet": (0, 590),
    "bathroom_vanity": (590, 1180),
    "bathroom_shower": (1180, 1774),
}
PADDING = 8


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with Image.open(SOURCE) as atlas:
        if atlas.mode != "RGBA":
            raise ValueError(f"Expected alpha atlas: {SOURCE}")
        alpha = atlas.getchannel("A")
        for name, (left, right) in REGIONS.items():
            mask = alpha.crop((left, 0, right, atlas.height)).point(
                lambda value: 255 if value >= 32 else 0
            )
            bounds = mask.getbbox()
            if bounds is None:
                raise ValueError(f"No visible sprite: {name}")
            x0, y0, x1, y1 = bounds
            crop = (
                max(0, left + x0 - PADDING),
                max(0, y0 - PADDING),
                min(atlas.width, left + x1 + PADDING),
                min(atlas.height, y1 + PADDING),
            )
            destination = OUTPUT / f"{name}.png"
            atlas.crop(crop).save(destination, optimize=True)
            print(f"{destination.name}: {destination.stat().st_size} bytes")


if __name__ == "__main__":
    main()
