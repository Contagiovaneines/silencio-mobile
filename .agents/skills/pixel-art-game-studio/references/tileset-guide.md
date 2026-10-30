# Tileset guide

Tile dimensions are configurable. Begin with 32×32 only when it matches the actual world grid;
the current game uses an isometric projection and must remain consistent with its world-to-screen
transform. Do not change grid size by resampling a live map without checking every collider and
door coordinate.

Use repeatable, edge-tested tile families for ground, pavement, wall, roof, interior floor, and
transitions. Avoid baked shadows or collision cues that conflict with dynamic lighting/gameplay.
Check seams in at least a 3×3 repeated preview. Use sparse decals as separate objects so they can be
culled and do not make the base tile noisy.

Keep collision and interaction metadata out of decorative pixels. For Tiled, use stable custom
properties/IDs for doors, windows, entry/exit points, floor/room IDs, and mission gates. An open
window may change traversability; its art alone never changes collision.

`validate_tileset.py` checks file structure/references and the named layer set. It is not a map
playability test; check links, blocked paths, room visibility and performance in the game.
