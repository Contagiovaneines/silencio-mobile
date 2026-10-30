#!/usr/bin/env python3
"""Check Tiled TMX/XML or JSON map structure and referenced tilesets without rewriting it."""
import argparse
import json
from pathlib import Path
import xml.etree.ElementTree as ET

REQUIRED_LAYERS = ("Ground", "Ground Details", "Buildings", "Objects", "Collision", "Decorations", "Above Player", "Interactive Objects")


def validate_tiled_file(path: Path, require_layers: bool = True) -> dict:
    path = path.resolve()
    issues, warnings, refs, names = [], [], [], []
    try:
        if path.suffix.lower() in {".tmx", ".tsx"}:
            root = ET.parse(path).getroot()
            orientation = root.attrib.get("orientation", "tileset")
            width, height = int(root.attrib.get("tilewidth", "0")), int(root.attrib.get("tileheight", "0"))
            names = [node.attrib.get("name", "") for node in root.findall("layer") + root.findall("objectgroup")]
            refs = [path.parent / node.attrib["source"] for node in root.findall("tileset") if "source" in node.attrib]
            refs += [path.parent / node.attrib["source"] for node in root.findall("image") if "source" in node.attrib]
            refs += [path.parent / node.attrib["source"] for node in root.findall("tileset/image") if "source" in node.attrib]
        else:
            data = json.loads(path.read_text(encoding="utf-8"))
            orientation = data.get("orientation", "unknown")
            width, height = int(data.get("tilewidth", 0)), int(data.get("tileheight", 0))
            names = [layer.get("name", "") for layer in data.get("layers", [])]
            refs = [path.parent / row["source"] for row in data.get("tilesets", []) if "source" in row]
            refs += [path.parent / row["image"] for row in data.get("tilesets", []) if "image" in row]
        if orientation not in {"orthogonal", "isometric", "staggered", "hexagonal", "unknown", "tileset"}:
            issues.append(f"orientação Tiled desconhecida: {orientation}")
        if width <= 0 or height <= 0:
            issues.append("tilewidth/tileheight devem ser positivos")
        if require_layers and orientation != "tileset":
            missing = [name for name in REQUIRED_LAYERS if name not in names]
            if missing:
                issues.append("camadas ausentes: " + ", ".join(missing))
        for ref in refs:
            if not ref.is_file():
                issues.append(f"referência externa ausente: {ref}")
            elif ref.suffix.lower() == ".tsx":
                try:
                    tileset = ET.parse(ref).getroot()
                    for image_node in tileset.findall("image"):
                        image_ref = ref.parent / image_node.attrib["source"]
                        if not image_ref.is_file():
                            issues.append(f"imagem referenciada pelo TSX ausente: {image_ref}")
                except (OSError, KeyError, ET.ParseError) as error:
                    issues.append(f"tileset TSX inválido {ref}: {error}")
        if orientation == "isometric" and width != 2 * height:
            warnings.append("grade isométrica não usa proporção 2:1; confirmar que é intencional e compatível com o renderer")
    except (OSError, ValueError, KeyError, ET.ParseError, json.JSONDecodeError) as error:
        issues.append(f"arquivo Tiled inválido: {error}")
        orientation, width, height = "unknown", 0, 0
    return {"path": str(path), "ok": not issues, "orientation": orientation, "tile_size": [width, height], "layers": names, "references": [str(ref) for ref in refs], "warnings": warnings, "errors": issues}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("map", type=Path, help=".tmx, .tmj, .json ou .tsx")
    parser.add_argument("--allow-missing-layers", action="store_true", help="valida tileset/estrutura sem exigir mapa completo")
    args = parser.parse_args()
    result = validate_tiled_file(args.map, require_layers=not args.allow_missing_layers)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
