import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from build_spritesheet import build_sheet
from generate_sprites import normalize_frames
from validate_sprites import validate_images
from validate_tileset import validate_tiled_file


class PipelineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.src = self.root / "source"
        self.src.mkdir()
        for direction, x in (("south", 4), ("north", 5)):
            image = Image.new("RGBA", (8, 10), (0, 0, 0, 0))
            image.putpixel((x, 7), (220, 80, 45, 255))
            image.save(self.src / f"{direction}.png")

    def tearDown(self):
        self.temp.cleanup()

    def test_normalize_and_build_direction_rows(self):
        spec_path = self.root / "spec.json"
        spec_path.write_text(json.dumps({
            "canvas": [16, 20], "anchor": [8, 16],
            "frames": [
                {"source": "source/south.png", "direction": "south", "action": "walk", "index": 0, "source_anchor": [4, 7]},
                {"source": "source/north.png", "direction": "north", "action": "walk", "index": 0, "source_anchor": [5, 7]},
            ],
        }), encoding="utf-8")
        generated = normalize_frames(spec_path, self.root / "normalized")
        self.assertEqual(len(generated), 2)
        results = validate_images(generated, expect_size=(16, 20), require_alpha=True)
        self.assertTrue(all(result["ok"] for result in results))
        manifest = self.root / "normalized" / "frames.json"
        sheet = build_sheet(manifest, "walk", self.root / "walk.png")
        self.assertEqual(sheet.size, (16, 40))
        checked = subprocess.run(
            [sys.executable, str(Path(__file__).resolve().parents[1] / "validate_sprites.py"),
             "--manifest", str(manifest), "--require-alpha", "--json"],
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(checked.returncode, 0, checked.stdout + checked.stderr)

    def test_validator_rejects_opaque_background(self):
        path = self.root / "opaque.png"
        Image.new("RGBA", (4, 4), (20, 20, 20, 255)).save(path)
        self.assertFalse(validate_images([path], require_alpha=True)[0]["ok"])

    def test_tiled_json_checks_required_layers_and_tileset_paths(self):
        (self.root / "tiles.tsx").write_text('<tileset version="1.10" tiledversion="1.10" name="tiles" tilewidth="32" tileheight="32" tilecount="1" columns="1"><image source="tiles.png" width="32" height="32"/></tileset>', encoding="utf-8")
        (self.root / "tiles.png").write_bytes(b"fixture")
        path = self.root / "map.tmj"
        path.write_text(json.dumps({
            "type": "map", "orientation": "isometric", "tilewidth": 32, "tileheight": 16,
            "width": 2, "height": 2,
            "layers": [{"name": name, "type": "tilelayer", "data": [0, 0, 0, 0]} for name in (
                "Ground", "Ground Details", "Buildings", "Objects", "Collision", "Decorations", "Above Player", "Interactive Objects"
            )],
            "tilesets": [{"firstgid": 1, "source": "tiles.tsx"}],
        }), encoding="utf-8")
        result = validate_tiled_file(path)
        self.assertTrue(result["ok"], result["errors"])
        self.assertEqual(result["orientation"], "isometric")


if __name__ == "__main__":
    unittest.main()
