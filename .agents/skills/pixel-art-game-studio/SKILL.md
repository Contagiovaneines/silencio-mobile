---
name: pixel-art-game-studio
description: >
  Plan, normalize, validate, atlas, and integrate original pixel-art sprites, animation frames,
  tilesets, and Tiled maps for the SILÊNCIO Flutter/Flame survival game. Use for asset production,
  animation or map pipelines, asset QA, and Flame integration; preserve existing art, projection,
  game behavior, and provenance.
---

# Pixel Art Game Studio — SILÊNCIO

Use this skill with the local `pxl-pixel-art`, `create-game-assets`, and, for environments,
`level-design` skills. It complements those workflows; it does not replace the existing `.px.js`
authoring pipeline or the game's painter-based renderer.

## Workflow

1. Inspect `AGENTS.md`, the relevant art/map skill, the existing asset manifest, renderer, camera,
   scale, projection, animation indexing, pivots, collisions, and target device. Record what is
   observed separately from assumptions. Preserve existing files and saves.
2. Define an asset brief and manifest before production: role, view, native dimensions, frame grid,
   directions/actions, anchor, collision footprint, palette, provenance/license, and review state.
   For this project, preserve the established isometric presentation and verify each actor's actual
   direction scheme; do not impose top-down or a fixed four-direction atlas.
3. Produce authored art with the approved image/PXL tool or licensed sources. Keep editable source
   outside runtime assets. Never make geometric placeholders and describe them as finished art.
4. Normalize only from explicit frame sources and anchors with `scripts/generate_sprites.py`; build
   atlases with `scripts/build_spritesheet.py`; validate PNGs/maps with the other scripts. Inspect
   contact sheets and the game at native size before promoting outputs into `assets/`.
5. Integrate using the installed package versions. Keep collision/navigation separate from pixels;
   visually hidden walls still block movement. Do not add a package or replace the custom renderer
   unless the task requires it and compatibility is established.
6. Report source/provenance, files changed, checks run, and any unverified in-game/mobile behavior.

## Defaults and quality bar

- 32×32 is a configurable tile starting point, not a project mandate. Match the current world grid,
  camera projection and actor scale. Pixel art uses nearest-neighbor filtering and real alpha.
- Keep animation canvases and foot/ground anchors stable. Review every direction and frame in order;
  ensure walk/run foot support alternates with travel, and check clipping, silhouette, and hitbox.
- Use separate Tiled layers for ground, details, buildings, objects, collision, decorations,
  above-player art, and interactive objects. Connect doors/windows through stable object IDs and
  destinations. Keep map data authoritative for navigation and story gating.
- For generated or third-party art, retain tool/source, license, edits and approval next to the
  asset manifest. No Project Zomboid code, sounds, or assets are to be copied.
- Current project baseline checked when this skill was authored: Flutter 3.47.7, Dart 3.13.5,
  Flame 1.38.2. Recheck `pubspec.lock` and installed APIs before using examples.

## Commands

Run from this skill folder or pass absolute paths. Pillow is required by the scripts; do not install
or upgrade it automatically. Use disposable outputs under `tools/art/out/` until visually approved.

```powershell
python scripts/validate_sprites.py --manifest path/to/frames.json --require-alpha --json
python scripts/build_spritesheet.py --manifest path/to/frames.json --action walk --out tools/art/out/caio_walk.png
python scripts/validate_tileset.py path/to/map.tmj
python -m unittest discover -s scripts/tests -v
```

Read the specific reference for sprite framing, animation, tiles, maps, or Flutter/Flame before
changing that part of the pipeline. The installed `pixel-art-game-builder` skill is an optional
external reference for idle-game art only; its React/CSS/Zustand code, fixed 12-color palette, and
16×16 rules do not govern SILÊNCIO.
