#!/usr/bin/env python3
"""Validate sprite PNG dimensions, real alpha, visible content, and optional frame manifest."""
import argparse
import json
from pathlib import Path

from PIL import Image


def validate_images(paths: list[Path], expect_size: tuple[int, int] | None = None, require_alpha: bool = False) -> list[dict]:
    results = []
    for path in paths:
        issues = []
        try:
            with Image.open(path) as opened:
                opened.verify()
            with Image.open(path) as opened:
                has_alpha = "A" in opened.mode or "transparency" in opened.info
                image = opened.convert("RGBA")
                if expect_size and image.size != expect_size:
                    issues.append(f"dimensão {image.width}x{image.height}; esperado {expect_size[0]}x{expect_size[1]}")
                alpha = image.getchannel("A")
                if require_alpha and (not has_alpha or alpha.getextrema() == (255, 255)):
                    issues.append("sem transparência útil (canal alpha ausente ou totalmente opaco)")
                if alpha.getbbox() is None:
                    issues.append("quadro vazio/transparente")
        except (OSError, ValueError) as error:
            issues.append(f"PNG inválido: {error}")
        results.append({"path": str(path), "ok": not issues, "issues": issues})
    return results


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path, help="PNG(s) ou diretório de frames")
    parser.add_argument("--manifest", type=Path, help="frames.json produzido por generate_sprites.py")
    parser.add_argument("--expect-size", help="tamanho WxH, ex.: 64x96")
    parser.add_argument("--require-alpha", action="store_true")
    parser.add_argument("--json", action="store_true", help="imprime relatório JSON")
    args = parser.parse_args()
    paths = list(args.paths)
    size = None
    if args.manifest:
        data = json.loads(args.manifest.read_text(encoding="utf-8"))
        paths += [(args.manifest.parent / row["path"]) for row in data["frames"]]
        if args.expect_size is None:
            size = tuple(map(int, data["canvas"]))
        names = [row["path"] for row in data["frames"]]
        if len(names) != len(set(names)):
            parser.error("manifest tem caminhos de frames duplicados")
    paths = [png for path in paths for png in (sorted(path.glob("*.png")) if path.is_dir() else [path])]
    if not paths:
        parser.error("informe PNGs, diretório ou --manifest")
    if args.expect_size:
        size = tuple(map(int, args.expect_size.lower().split("x")))
    results = validate_images(paths, size, args.require_alpha)
    print(json.dumps({"ok": all(row["ok"] for row in results), "files": len(results), "results": results}, ensure_ascii=False, indent=2 if args.json else None))
    return 0 if all(row["ok"] for row in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
