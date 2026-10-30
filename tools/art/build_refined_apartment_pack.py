"""Build the selected user-provided apartment sprites into a runtime atlas.

Usage:
  python tools/art/build_refined_apartment_pack.py "<asset pack directory>"

Only curated, individually exported RGBA sprites are included. The source pack
is never modified. Pillow is required by the offline art pipeline.
"""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image


ASSETS = {
    "sofa_parede_A": "01_Sala/PNG_Individuais/sofa_parede_A.png",
    "mesa_centro_B": "01_Sala/PNG_Individuais/mesa_centro_B.png",
    "rack_tv_A": "01_Sala/PNG_Individuais/rack_tv_A.png",
    "abajur_aceso_A": "01_Sala/PNG_Individuais/abajur_aceso_A.png",
    "planta_B": "01_Sala/PNG_Individuais/planta_B.png",
    "cama_parede_A": "02_Quarto/PNG_Individuais/cama_parede_A.png",
    "guarda_roupa_B": "02_Quarto/PNG_Individuais/guarda_roupa_B.png",
    "mesa_cabeceira_A": "02_Quarto/PNG_Individuais/mesa_cabeceira_A.png",
    "escrivaninha_A": "02_Quarto/PNG_Individuais/escrivaninha_A.png",
    "cadeira_A": "02_Quarto/PNG_Individuais/cadeira_A.png",
    "cadeira_B": "02_Quarto/PNG_Individuais/cadeira_B.png",
    "estante_A": "02_Quarto/PNG_Individuais/estante_A.png",
    "balcao_cuba_A": "03_Cozinha/PNG_Individuais/balcao_cuba_A.png",
    "fogao_B": "03_Cozinha/PNG_Individuais/fogao_B.png",
    "geladeira_fechada_A": "03_Cozinha/PNG_Individuais/geladeira_fechada_A.png",
    "armario_suspenso_B": "03_Cozinha/PNG_Individuais/armario_suspenso_B.png",
    "mesa_jantar_A": "03_Cozinha/PNG_Individuais/mesa_jantar_A.png",
    "gabinete_pia_A": "04_Banheiro/PNG_Individuais/gabinete_pia_A.png",
    "vaso_sanitario_B": "04_Banheiro/PNG_Individuais/vaso_sanitario_B.png",
    "box_chuveiro_A": "04_Banheiro/PNG_Individuais/box_chuveiro_A.png",
    "tapete_banheiro_A": "04_Banheiro/PNG_Individuais/tapete_banheiro_A.png",
    "espelho_A": "04_Banheiro/PNG_Individuais/espelho_A.png",
    "cesto_roupa_B": "04_Banheiro/PNG_Individuais/cesto_roupa_B.png",
    "caio_sentado_sofa": "06_Personagem/PNG_Individuais/caio_sentado_sofa.png",
    "caio_sentado_cadeira": "06_Personagem/PNG_Individuais/caio_sentado_cadeira.png",
    "caio_deitado_cama": "06_Personagem/PNG_Individuais/caio_deitado_cama.png",
}


def main(source_root: Path) -> None:
    project = Path(__file__).resolve().parents[2]
    output_image = project / "assets/images/apartment_refined_v1.png"
    output_data = project / "assets/data/apartment_refined_v1.json"
    loaded: dict[str, Image.Image] = {}
    for key, relative in ASSETS.items():
        path = source_root / relative
        if not path.is_file():
            raise SystemExit(f"Missing source sprite: {path}")
        sprite = Image.open(path).convert("RGBA")
        if sprite.getchannel("A").getextrema() == (255, 255):
            raise SystemExit(f"Sprite has no transparent pixels: {path}")
        loaded[key] = sprite

    width = 2048
    padding = 4
    x = y = row_height = 0
    placements: dict[str, list[int]] = {}
    ordered = sorted(loaded, key=lambda k: (-loaded[k].height, -loaded[k].width))
    for key in ordered:
        sprite = loaded[key]
        if x + sprite.width + padding > width:
            x = 0
            y += row_height + padding
            row_height = 0
        placements[key] = [x, y, sprite.width, sprite.height]
        x += sprite.width + padding
        row_height = max(row_height, sprite.height)
    height = y + row_height + padding
    atlas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    for key, sprite in loaded.items():
        left, top, _, _ = placements[key]
        atlas.alpha_composite(sprite, (left, top))
    output_image.parent.mkdir(parents=True, exist_ok=True)
    output_data.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output_image, optimize=True)
    data = {
        "image": "apartment_refined_v1.png",
        "source": "SILENCIO_Apartamento_Assets_Refinados; user-provided art pack",
        "size": [width, height],
        "sprites": placements,
        "source_files": ASSETS,
        "sha256": hashlib.sha256(output_image.read_bytes()).hexdigest(),
    }
    output_data.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(placements)} sprites into {output_image} ({width}x{height})")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    main(Path(sys.argv[1]).expanduser().resolve())
