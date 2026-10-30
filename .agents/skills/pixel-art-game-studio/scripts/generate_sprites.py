#!/usr/bin/env python3
"""Normalize artist- or generator-authored sprite frames; never synthesizes placeholder art."""
import argparse
import json
from pathlib import Path

from PIL import Image


def normalize_frames(spec_path: Path, out_dir: Path) -> list[Path]:
    spec_path = spec_path.resolve()
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    width, height = map(int, spec["canvas"])
    target_anchor = tuple(map(int, spec["anchor"]))
    if width <= 0 or height <= 0 or not (0 <= target_anchor[0] < width and 0 <= target_anchor[1] < height):
        raise ValueError("canvas/anchor inválidos")
    out_dir.mkdir(parents=True, exist_ok=True)
    result, records = [], []
    for frame in spec["frames"]:
        source = (spec_path.parent / frame["source"]).resolve()
        image = Image.open(source).convert("RGBA")
        source_anchor = tuple(map(int, frame["source_anchor"]))
        if not (0 <= source_anchor[0] < image.width and 0 <= source_anchor[1] < image.height):
            raise ValueError(f"source_anchor fora do frame: {source}")
        scale = float(frame.get("scale", 1))
        if scale <= 0:
            raise ValueError(f"scale inválido: {source}")
        if scale != 1:
            size = (round(image.width * scale), round(image.height * scale))
            image = image.resize(size, Image.Resampling.NEAREST)
            source_anchor = (round(source_anchor[0] * scale), round(source_anchor[1] * scale))
        left, top = target_anchor[0] - source_anchor[0], target_anchor[1] - source_anchor[1]
        if left < 0 or top < 0 or left + image.width > width or top + image.height > height:
            raise ValueError(f"frame ultrapassa canvas após alinhar pelo pivot: {source}")
        if image.getbbox() is None:
            raise ValueError(f"frame vazio: {source}")
        cell = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        cell.alpha_composite(image, (left, top))
        name = f"{frame['action']}_{frame['direction']}_{int(frame['index']):02d}.png"
        if any(row["path"] == name for row in records):
            raise ValueError(f"nome de frame duplicado no manifest: {name}")
        output = out_dir / name
        cell.save(output, optimize=True)
        result.append(output)
        records.append({"path": name, "action": frame["action"], "direction": frame["direction"], "index": int(frame["index"]), "anchor": list(target_anchor)})
    manifest = {"canvas": [width, height], "anchor": list(target_anchor), "direction_order": spec.get("direction_order", []), "frames": records}
    (out_dir / "frames.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spec", required=True, type=Path, help="JSON com frames originais, direção, ação, índice e pivô")
    parser.add_argument("--out", required=True, type=Path, help="Diretório de saída fora de assets finais até revisão")
    args = parser.parse_args()
    try:
        paths = normalize_frames(args.spec, args.out)
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        parser.error(str(error))
    print(json.dumps({"ok": True, "frames": len(paths), "manifest": str(args.out / 'frames.json')}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
