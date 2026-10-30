#!/usr/bin/env python3
"""Pack normalized, pivot-aligned frames into a deterministic direction-row atlas."""
import argparse
import json
from pathlib import Path

from PIL import Image


def build_sheet(manifest_path: Path, action: str, output: Path) -> Image.Image:
    manifest_path = manifest_path.resolve()
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    frames = [row for row in data["frames"] if row["action"] == action]
    if not frames:
        raise ValueError(f"ação não encontrada: {action}")
    direction_order = data.get("direction_order", [])
    directions = [d for d in direction_order if any(f["direction"] == d for f in frames)]
    directions += sorted({f["direction"] for f in frames} - set(directions))
    frames.sort(key=lambda row: (directions.index(row["direction"]), int(row["index"])))
    by_direction = {direction: [] for direction in directions}
    for frame in frames:
        by_direction[frame["direction"]].append(frame)
    counts = {direction: len(rows) for direction, rows in by_direction.items()}
    if len(set(counts.values())) != 1:
        raise ValueError(f"quantidade de frames inconsistente por direção: {counts}")
    for direction, rows in by_direction.items():
        indexes = sorted(int(row["index"]) for row in rows)
        if indexes != list(range(len(indexes))):
            raise ValueError(f"índices não contíguos em {direction}: {indexes}")
    width, height = map(int, data["canvas"])
    columns = next(iter(counts.values()))
    atlas = Image.new("RGBA", (width * columns, height * len(directions)), (0, 0, 0, 0))
    for row, direction in enumerate(directions):
        for column, frame in enumerate(by_direction[direction]):
            with Image.open(manifest_path.parent / frame["path"]) as image:
                cell = image.convert("RGBA")
                if cell.size != (width, height):
                    raise ValueError(f"tamanho diferente do manifest: {frame['path']}")
                atlas.alpha_composite(cell, (column * width, row * height))
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output, optimize=True)
    output.with_suffix(output.suffix + ".json").write_text(json.dumps({"action": action, "directions": directions, "frames_per_direction": columns, "frame_size": [width, height], "anchor": data["anchor"], "sheet_size": list(atlas.size)}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return atlas


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--action", required=True)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    try:
        image = build_sheet(args.manifest, args.action, args.out)
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        parser.error(str(error))
    print(json.dumps({"ok": True, "size": list(image.size), "output": str(args.out)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
