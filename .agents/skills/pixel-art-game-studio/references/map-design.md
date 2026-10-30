# Map design and Tiled

Design locations as connected playable spaces, not a decorative background. Give rooms, floors,
doors and exits stable IDs; record entry and exit positions and reciprocal links. Verify every
mission-critical path and intentionally gated route against collision geometry.

Recommended independent layers (names used by the validator): `Ground`, `Ground Details`,
`Buildings`, `Objects`, `Collision`, `Decorations`, `Above Player`, `Interactive Objects`.
Use object layers or custom properties where point/rectangle metadata is more suitable than tile
indices. Walls/roofs may be hidden for visibility while their collision remains active. Hide
unoccupied interiors to reduce visual clutter and draw cost.

Tiled JSON (`.tmj`) and XML (`.tmx`) are suitable authoring formats when the project chooses to use
them. JSON maps can refer to external `.tsx` tilesets; keep references relative and package all
required files. The validator checks required layer names and missing external files, but does not
verify semantic connections or rendering. Tiled itself and runtime import are separate concerns.

In Flame, `TiledComponent` belongs to the separate `flame_tiled` package; it is not provided by the
project's `flame` dependency alone. Check whether the package is already locked before using it.
Otherwise parse/convert map data through an existing project-owned loader; do not silently add the
dependency or rewrite the current custom world renderer.
