# Fase 01 V3 Implementation Plan

> **For agentic workers:** Execute inline with TDD and verify the full player route.

**Goal:** Make the playable Fase 01 follow the approved V3 beat order and end/save on boarding the line 203 bus.

**Architecture:** Keep the existing Flutter/Flame session and campaign state machine. Move the pulse trigger to the street crossing, gate bus arrival on reading Helena's post-pulse message, and finalize the chapter after the existing short boarding transition. Preserve old save event IDs where practical.

**Tech Stack:** Dart, Flutter, Flame, existing campaign/session model.

**Spec:** `docs/narrative/SILENCIO_Historia_V3_Mundo_Aberto.md`, `docs/superpowers/specs/2026-10-30-open-world-story-v3-design.md`

## Global Constraints
- Caio is deaf and non-verbal; essential mission information remains visual/textual.
- No auto-walk to the map marker.
- The bus driver appears only with the arriving bus.
- The phase closes at confirmed boarding; Chapter 02 remains separately selectable.
- Preserve existing save data and unrelated in-progress changes.

## Review Focus
- Bus must not arrive before delivery, news, alley resolution, pulse, and Helena's message.
- Pulse and its required story beats occur before reaching the bus stop.
- Boarding must save `finish` and display phase completion without requiring the 02:00 chapter or bed return.
- An incomplete or legacy save must still decode safely.
- Full path must remain navigable and maintain correct stop/driver/vehicle state.

### Task 1: Pin V3 phase progression in tests
**Files:** Modify `test/game_session_test.dart`, `test/full_phase_player_test.dart`, `test/campaign_test.dart`.
- [x] Update session scenario to trigger the pulse at the street crossing, read Helena's message, board, and assert `finish` only after transit.
- [x] Update full-route scenario to stop at phase-completion screen instead of returning home.
- [x] Assert premature bus arrival/boarding is denied until the post-pulse message.
- [x] Run focused tests and confirm the expected red failures.

### Task 2: Implement the campaign/session sequence
**Files:** Modify `lib/models/campaign.dart`, `lib/game/game_session.dart`.
- [x] Add a derived bus-readiness condition and V3 objective wording.
- [x] Make crossing initiate the pulse before bus travel; keep the bus action limited to arrived/ready states.
- [x] Name the driver Nando and conclude/save `finish` when the transit reaches its end.
- [x] Keep chapter 2 start gated by the saved finish flag.

### Task 3: Gate world arrival and verify
**Files:** Modify `lib/game/world_model.dart`, focused tests as needed.
- [x] Spawn driver only on bus arrival and align the stop labels/objective with line 203.
- [x] Gate bus approach/arrival on V3 readiness.
- [x] Run focused and full phase tests, `flutter analyze`, and production web build.
- [x] Record any unavailable Android/device verification separately.

## Final verification

- The full phase route starts at a fresh campaign, walks/interacts through the story, waits for the line 203 bus, boards, and saves `finish` after the boarding transition.
- Optional Bia response is written, added to the journal, and persisted. Bia waits at the stop; Nando only appears beside the arriving bus.
- Kitchen and bathroom approach tests exposed the dining chair/table blocking the connecting aisle; furniture positions were corrected in the apartment model.
- See the 30/10/2026 V3 acceptance note in `docs/QA_FASE01_PERCURSO.md` for exact checks and build results.
