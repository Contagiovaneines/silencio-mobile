#!/usr/bin/env python3
"""Build review-only contact sheets and motion loops from Caio's runtime atlases."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
ACTORS = ROOT / "assets" / "images" / "actors"
OUT = ROOT / "tools" / "art" / "out" / "caio-animation-qa"
CELL = (128, 144)
DIRECTIONS = ("Leste", "Sudeste", "Sul", "Sudoeste", "Oeste", "Noroeste", "Norte", "Nordeste")
ATLAS_COLUMNS = {"idle": 4, "walk": 6, "run": 6}


def checker(size: tuple[int, int], tile: int = 8) -> Image.Image:
    image = Image.new("RGBA", size, (16, 31, 40, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], tile):
        for x in range(0, size[0], tile):
            if (x // tile + y // tile) % 2:
                draw.rectangle((x, y, x + tile - 1, y + tile - 1), fill=(27, 44, 51, 255))
    return image


def build_action(action: str, columns: int, actor: str = "caio") -> dict[str, object]:
    path = ACTORS / f"actor_{actor}_{action}.png"
    with Image.open(path) as opened:
        atlas = opened.convert("RGBA")
    expected = (CELL[0] * columns, CELL[1] * len(DIRECTIONS))
    if atlas.size != expected:
        raise ValueError(f"{path.name}: esperado {expected}, obtido {atlas.size}")

    label_w = 104
    contact = checker((label_w + expected[0], expected[1]))
    draw = ImageDraw.Draw(contact)
    for row, direction in enumerate(DIRECTIONS):
        y = row * CELL[1]
        draw.text((6, y + 5), direction, fill=(226, 228, 216, 255), font=ImageFont.load_default())
        for column in range(columns):
            frame = atlas.crop((column * CELL[0], y, (column + 1) * CELL[0], y + CELL[1]))
            contact.alpha_composite(frame, (label_w + column * CELL[0], y))
    contact.save(OUT / f"{actor}_{action}_contact.png", optimize=True)

    frame_metrics: list[dict[str, object]] = []
    for row, direction in enumerate(DIRECTIONS):
        bottoms = []
        for column in range(columns):
            frame = atlas.crop((column * CELL[0], row * CELL[1], (column + 1) * CELL[0], (row + 1) * CELL[1]))
            bbox = frame.getchannel("A").getbbox()
            if bbox is None:
                raise ValueError(f"{path.name}: quadro vazio em {direction} #{column}")
            bottoms.append(bbox[3])
            frame_metrics.append({"direction": direction, "frame": column, "alpha_bbox": list(bbox)})
        # Keep the foot-contact edge steady; a two-pixel allowance handles authored stride lift.
        # Deliberate airborne run frames can lift both feet. Keep the authored
        # cell pivot fixed and allow this vertical silhouette motion.
        if max(bottoms) - min(bottoms) > (8 if action == "run" else 4):
            raise ValueError(f"{path.name}: base visual varia mais de 2 px em {direction}: {bottoms}")

    for row, direction in ((0, "leste"), (1, "sudeste"), (2, "sul"), (6, "norte")) if action in ("walk", "run") else ():
        frames = [atlas.crop((i * CELL[0], row * CELL[1], (i + 1) * CELL[0], (row + 1) * CELL[1])) for i in range(columns)]
        preview_frames = [Image.alpha_composite(checker(CELL), frame) for frame in frames]
        preview_frames[0].save(
            OUT / f"{actor}_{action}_{direction}.gif",
            save_all=True,
            append_images=preview_frames[1:],
            duration=140 if action != "run" else 105,
            loop=0,
            disposal=2,
        )

    return {
        "source": path.relative_to(ROOT).as_posix(),
        "actor": actor,
        "atlas_size": list(atlas.size),
        "frame_size": list(CELL),
        "directions": list(DIRECTIONS),
        "frames_per_direction": columns,
        "alpha_bboxes": frame_metrics,
    }


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    report = {
        "project": "SILÊNCIO",
        "purpose": "review only; contact sheets and GIFs are not runtime assets",
        "pivot_reference": "128x144 cell; expected sole at source y=119; 80x90 display rect",
        "actions": {
            f"{actor}_{action}": build_action(action, columns, actor)
            for actor, states in (("caio", ATLAS_COLUMNS), ("caio_nobag", {"walk": 6, "run": 6}))
            for action, columns in states.items()
        },
    }
    (OUT / "caio_animation_qa.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"QA sheets and motion loops written to {OUT}")


if __name__ == "__main__":
    main()
