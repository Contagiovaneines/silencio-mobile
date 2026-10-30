# Sprite standards

## Brief and manifest

Before drawing, record: gameplay role; view/projection; native pixel dimensions; usable bounds;
palette/materials/light; facing directions; animation actions and frame timing; stable ground pivot;
collision footprint; output format; provenance; and approval status. The manifest describes what
exists—never infer frames or directions from filenames alone.

The game currently uses project-specific actor sheets and an isometric camera. Inspect
`lib/game/actor_frames.dart`, `lib/game/sprite_facing.dart`, and the loader in `lib/game/silencio_game.dart`
before producing character sheets. Do not impose a 32×32 person or a four-direction top-down sheet.

## Frames and transparency

- Use lossless PNG with a real alpha channel. Empty padding is transparent, not a checkerboard.
- Keep frame canvas and ground anchor constant. Set the anchor at the actor's ground contact, not
  at the visual center; actor collision belongs on the ground plane.
- Keep native pixel edges crisp. For nearest-neighbor resize, use integer scale factors where
  possible. Never use bilinear filtering for authored pixel art.
- Frame families must preserve character identity, outfit, silhouette, light direction and scale.
- At minimum inspect an ordered contact sheet, alpha checkerboard, game-scale view, and collision
  footprint. Flag isolated opaque pixels and inconsistent baselines for human review.

## Naming and provenance

Use stable semantic names such as `actor_caio_walk_SE_00.png`; names must agree with the manifest.
For each source record authoring tool or source URL, license/terms, transformations, and approval.
Separate source/editable art, review previews, and shipped assets; do not put authoring tools in the
app bundle.
