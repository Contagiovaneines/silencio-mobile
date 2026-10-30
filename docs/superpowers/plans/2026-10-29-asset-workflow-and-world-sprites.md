# SILÊNCIO — Asset Workflow and World Sprites Plan

**Goal:** Make the project use the requested pixel-art authoring workflow and improve existing world assets without changing the isometric direction or adding art-generation runtime dependencies.

**Architecture:** Keep editable `.px.js` sources in `tools/art/`; install the PXL authoring skill under project-local `.agents/skills/pxl-pixel-art`; export only reviewed PNGs/metadata into `assets/`. Flutter/Flame loads exported assets and uses deterministic per-tile variation. `perfectPixel` remains an optional offline image utility and is not used on existing atlases or animation frames without per-asset review.

**Tech Stack:** Flutter, Flame, Dart tests, PXL CLI on the bundled Node 24 runtime. No Python dependency or runtime package is added to the Android app.

**Spec:** User’s ongoing SILÊNCIO art, animation, gameplay and mobile-performance request; project constraints in `AGENTS.md`.

## Global Constraints

- Preserve existing saved campaigns, campaign text and interaction IDs.
- Keep an isometric camera, current character scale, palette, transparent backgrounds and foot anchors.
- Do not copy commercial code or art from Project Zomboid.
- Source art stays editable in `tools/art/`; preview output stays outside app assets.
- Only reviewed exports enter `assets/`; no authoring tool or Python library is bundled in the APK.
- Keep world variation deterministic and cheap on mobile.

## Review Focus

- Tile variants preserve the 64×32 diamond and do not leave transparent gaps.
- Repeated runs produce stable ground appearance and do not flicker.
- NPC gait alternates feet only while moving and respects travel distance.
- Mirrored views remain legible and keep actor feet aligned to collision position.
- New art remains small enough for browser and Android builds.

---

### Task 1: Install the PXL authoring standard locally

**Files:**
- Create: `.agents/skills/pxl-pixel-art/` from `crsolver/claude-pxl` (MIT).
- Modify: `AGENTS.md` to make the project-local skill and CLI the canonical art workflow.
- Keep: `tools/art/*.px.js` as the editable source-of-truth.

- [ ] Clone into the previously absent project skill path; do not change global Codex settings.
- [ ] Run `node .agents/skills/pxl-pixel-art/bin/pxl.js --help` with the bundled Node executable.
- [ ] Record the intended `PXL build` and preview workflow in `AGENTS.md`.

### Task 2: Add reviewed, original concrete floor variants

**Files:**
- Create: `tools/art/concrete_floor.px.js`.
- Create and review: a compact four-variant 64×32 tile atlas under `assets/images/` plus JSON metadata only if Flutter needs it.
- Modify: asset loading and ground rendering where the current `tile_concrete.png` repeats.
- Test: ground variant selection stays in range and is stable by world coordinate.

- [ ] Build the source art, inspect the PXL preview, and confirm dimensions, alpha and isometric shape.
- [ ] Write the deterministic variation test and confirm its failure first.
- [ ] Integrate the reviewed atlas with coordinate-stable selection and cache it like existing floor layers.
- [ ] Run the focused test, full suite and a browser visual pass; reject the export if seams, noisy texture or scale mismatch appear.

### Task 3: Inspect and refine actor gait integration

**Files:**
- Inspect: `lib/game/actor_animation.dart`, `lib/game/silencio_game.dart`, NPC assets and current gait tests.
- Modify only the narrow animation/rendering boundary proven to cause the stiff walk.
- Test: phase/foot support changes with actual travel, idle has no stepping, injury remains asymmetric.

- [ ] Capture representative directions/frames before deciding whether new art or rig changes are needed.
- [ ] Add/adjust a regression test before changing production animation code.
- [ ] Verify browser appearance at the same actor scale; do not substitute unrelated character styles.

### Verification

- Run focused Dart tests, then `flutter test --no-pub`.
- Build web release and inspect a fresh browser session.
- Run `flutter analyze --no-pub`; report style infos separately from analysis errors.
- Inspect `git diff --check`, asset size and final changed-file list.
